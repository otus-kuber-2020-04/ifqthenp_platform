#!/usr/bin/env bash

HELM_REPOS=$(helm repo ls -o json)
if ! echo "$HELM_REPOS" | grep -q "https://helm.releases.hashicorp.com"; then
    echo "Adding Hashicorp repo to Helm..."
    helm repo add hashicorp https://helm.releases.hashicorp.com
    helm repo update
fi

gcloud container clusters get-credentials otus-kubernetes-hw \
    --zone europe-west4-a \
    --project otus-hw

helm upgrade --install consul hashicorp/consul \
    --version 0.22.0 \
    --wait \
    --set global.name=consul

helm upgrade --install vault hashicorp/vault \
    --version 0.6.0 \
    --wait \
    --set server.standalone.enabled=false \
    --set server.ha.enabled=true \
    --set ui.enabled=true

sleep 5s

### Unseal vaults

CLUSTER_KEYS=$(kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json)
export VAULT_UNSEAL_KEY=$(echo "${CLUSTER_KEYS}" | jq -r '.unseal_keys_b64[]')
export VAULT_INITIAL_ROOT_TOKEN=$(echo "${CLUSTER_KEYS}" | jq -r '.root_token')

echo "VAULT_UNSEAL_KEY = ${VAULT_UNSEAL_KEY}"
echo "VAULT_INITIAL_ROOT_TOKEN = ${VAULT_INITIAL_ROOT_TOKEN}"

declare -a SEALED_VAULTS
SEALED_VAULTS=($(kubectl get pods -l app.kubernetes.io/name=vault,vault-sealed=true -o=jsonpath='{.items[*].metadata.name}'))
#SEALED_VAULTS=($(kubectl get pods -l app.kubernetes.io/name=vault,vault-sealed=true -o json | jq -r '.items[] | .metadata.name'))

for vault in "${SEALED_VAULTS[@]}"; do
    kubectl exec "${vault}" -- vault operator unseal "${VAULT_UNSEAL_KEY}"
    sleep 1s
done

sed -i "s%^Unseal Key 1:.*$%Unseal Key 1: ${VAULT_UNSEAL_KEY}%g" README.md
sed -i "s/^Initial Root Token:.*$/Initial Root Token: ${VAULT_INITIAL_ROOT_TOKEN}/g" README.md

### Login into vault

TOKEN_INFO=$(kubectl exec -it vault-0 -- vault login "${VAULT_INITIAL_ROOT_TOKEN}" -format=json)
echo "TOKEN_INFO = ${TOKEN_INFO}"

export TOKEN_ACCESSOR=$(echo "${TOKEN_INFO}" | jq -r '.auth.accessor')
echo "TOKEN_ACCESSOR = ${TOKEN_ACCESSOR}"

sed -i "s/\(^token\b\s*\).*$/\1${VAULT_INITIAL_ROOT_TOKEN}/g" README.md
sed -i "s/\(^token_accessor\b\s*\).*$/\1${TOKEN_ACCESSOR}/g" README.md

### Add secrets

kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
kubectl exec -it vault-0 -- vault secrets list --detailed
kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
kubectl exec -it vault-0 -- vault read otus/otus-ro/config
kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config

### Enable k8s authorisation

kubectl exec -it vault-0 -- vault auth enable kubernetes
kubectl exec -it vault-0 -- vault auth list

### Create Service Account

kubectl create serviceaccount vault-auth
kubectl apply -f vault-auth-service-account.yaml

### Save k8s configuration to the vault

export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret "${VAULT_SA_NAME}" -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret "${VAULT_SA_NAME}" -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST=$(kubectl cluster-info | grep 'Kubernetes master' | awk '/https/ {print $NF}' | sed 's/\x1b\[[0-9;]*m//g')
# export K8S_HOST=$(TERM=dumb kubectl cluster-info | grep 'Kubernetes master' | awk '/https/ {print $NF}')

kubectl exec -it vault-0 -- vault write auth/kubernetes/config \
token_reviewer_jwt="${SA_JWT_TOKEN}" \
kubernetes_host="${K8S_HOST}" \
kubernetes_ca_cert="${SA_CA_CRT}"

### Create policies and roles in Vault, and use them

tee otus-policy.hcl <<EOF
path "otus/otus-ro/*" {
    capabilities = ["read", "list"]
}
path "otus/otus-rw/*" {
    capabilities = ["read", "list", "create", "update"]
}
EOF

kubectl cp otus-policy.hcl vault-0:./tmp
kubectl exec -it vault-0 -- vault policy write otus-policy /tmp/otus-policy.hcl

kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
bound_service_account_names=vault-auth \
bound_service_account_namespaces=default \
policies=otus-policy \
ttl=24h

### Authorising Nginx with Vault

kubectl apply -f configmap.yaml -f example-k8s-spec.yaml
kubectl wait --for=condition=Ready pod/vault-agent-example
kubectl cp vault-agent-example:usr/share/nginx/html/index.html -c nginx-container ./index.html

### Creating Certificate Authority (CA) with Vault

kubectl exec -it vault-0 -- vault secrets enable pki
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal \
common_name="example.ru" ttl=87600h > CA_cert.crt

kubectl exec -it vault-0 -- vault write pki/config/urls \
issuing_certificates="http://vault:8200/v1/pki/ca" \
crl_distribution_points="http://vault:8200/v1/pki/crl"

kubectl exec -it vault-0 -- vault secrets enable --path=pki_int pki
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
kubectl exec -it vault-0 -- vault write -format=json pki_int/intermediate/generate/internal \
common_name="example.ru Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr

kubectl cp pki_intermediate.csr vault-0:/tmp
kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate csr=@/tmp/pki_intermediate.csr \
format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem
kubectl cp intermediate.cert.pem vault-0:/tmp
kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem

kubectl exec -it vault-0 -- vault write pki_int/roles/example-dot-ru \
allowed_domains="example.ru" allow_subdomains=true max_ttl="720h"

# issue a certificate
export CRT_SERIAL_NUMBER=$(kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name="gitlab.example.ru" ttl="24h" -format=json | jq -r '.data.serial_number')
echo "${CRT_SERIAL_NUMBER}"
# revoke certificate
# kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="${CRT_SERIAL_NUMBER}"
