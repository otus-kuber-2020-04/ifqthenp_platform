## HW 10. Hashicorp Vault + k8s

### Installing Hashicorp Vault

Run `kubectl logs vault-0` after installing Vault helm chart

```text
==> Vault server configuration:

             Api Address: http://10.56.1.8:8200
                     Cgo: disabled
         Cluster Address: https://vault-0.vault-internal:8201
              Listener 1: tcp (addr: "[::]:8200", cluster address: "[::]:8201", max_request_duration: "1m30s", max_request_size: "33554432", tls: "disabled")
               Log Level: info
                   Mlock: supported: true, enabled: false
           Recovery Mode: false
                 Storage: consul (HA available)
                 Version: Vault v1.4.2

==> Vault server started! Log data will stream in below:

2020-07-05T14:41:59.384Z [INFO]  proxy environment: http_proxy= https_proxy= no_proxy=
2020-07-05T14:41:59.385Z [WARN]  storage.consul: appending trailing forward slash to path
2020-07-05T14:42:05.419Z [INFO]  core: seal configuration missing, not initialized
2020-07-05T14:42:08.426Z [INFO]  core: seal configuration missing, not initialized
2020-07-05T14:42:11.417Z [INFO]  core: seal configuration missing, not initialized
... ... ...
```

### Initializing and unsealing Hashicorp Vault

Run `kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1`
to initialize the vault (it can be done with any pod available):

```text
Unseal Key 1: nNN1x807NYX/B2gOZ60WRC7+xLTEPDMjJBeiNRfhkIM=

Initial Root Token: s.NQMZ6VSr8Cj8GGYvS4Pa6EkR

Vault initialized with 1 key shares and a key threshold of 1. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 1 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated master key. Without at least 1 key to
reconstruct the master key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.
```

Run `kubectl exec -it vault-0 -- vault status`. The pod has been initialized but hasn't been unsealed yet.

```text
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       1
Threshold          1
Unseal Progress    0/1
Unseal Nonce       n/a
Version            1.4.2
HA Enabled         true
command terminated with exit code 2
```

Run `kubectl exec -it vault-0 env | grep VAULT` to see Vault's environment variables.

```text
VAULT_CLUSTER_ADDR=https://vault-0.vault-internal:8201
VAULT_K8S_NAMESPACE=default
VAULT_ADDR=http://127.0.0.1:8200
VAULT_API_ADDR=http://10.56.2.8:8200
VAULT_K8S_POD_NAME=vault-0
VAULT_PORT_8200_TCP_ADDR=10.59.253.148
VAULT_UI_PORT_8200_TCP=tcp://10.59.252.98:8200
VAULT_ACTIVE_PORT=tcp://10.59.247.99:8200
VAULT_AGENT_INJECTOR_SVC_SERVICE_PORT=443
VAULT_PORT_8201_TCP_PROTO=tcp
VAULT_STANDBY_PORT_8200_TCP_ADDR=10.59.253.170
VAULT_ACTIVE_PORT_8200_TCP=tcp://10.59.247.99:8200
VAULT_PORT_8201_TCP=tcp://10.59.253.148:8201
VAULT_ACTIVE_SERVICE_PORT_HTTPS_INTERNAL=8201
VAULT_ACTIVE_PORT_8200_TCP_PORT=8200
VAULT_PORT_8200_TCP=tcp://10.59.253.148:8200
VAULT_STANDBY_SERVICE_PORT_HTTP=8200
VAULT_STANDBY_PORT_8200_TCP_PROTO=tcp
VAULT_ACTIVE_PORT_8201_TCP=tcp://10.59.247.99:8201
VAULT_ACTIVE_PORT_8201_TCP_PROTO=tcp
VAULT_SERVICE_HOST=10.59.253.148
VAULT_PORT_8201_TCP_ADDR=10.59.253.148
VAULT_STANDBY_PORT_8200_TCP_PORT=8200
VAULT_STANDBY_PORT_8201_TCP_PROTO=tcp
VAULT_UI_SERVICE_HOST=10.59.252.98
VAULT_STANDBY_PORT_8200_TCP=tcp://10.59.253.170:8200
VAULT_SERVICE_PORT_HTTP=8200
VAULT_PORT=tcp://10.59.253.148:8200
VAULT_STANDBY_PORT=tcp://10.59.253.170:8200
VAULT_ACTIVE_PORT_8200_TCP_PROTO=tcp
VAULT_UI_PORT=tcp://10.59.252.98:8200
VAULT_ACTIVE_PORT_8200_TCP_ADDR=10.59.247.99
VAULT_AGENT_INJECTOR_SVC_PORT_443_TCP_ADDR=10.59.243.69
VAULT_STANDBY_PORT_8201_TCP_ADDR=10.59.253.170
VAULT_ACTIVE_SERVICE_PORT=8200
VAULT_STANDBY_SERVICE_PORT_HTTPS_INTERNAL=8201
VAULT_SERVICE_PORT_HTTPS_INTERNAL=8201
VAULT_AGENT_INJECTOR_SVC_PORT=tcp://10.59.243.69:443
VAULT_STANDBY_PORT_8201_TCP_PORT=8201
VAULT_UI_SERVICE_PORT=8200
VAULT_STANDBY_SERVICE_HOST=10.59.253.170
VAULT_UI_PORT_8200_TCP_PORT=8200
VAULT_PORT_8200_TCP_PROTO=tcp
VAULT_PORT_8201_TCP_PORT=8201
VAULT_UI_PORT_8200_TCP_ADDR=10.59.252.98
VAULT_AGENT_INJECTOR_SVC_PORT_443_TCP=tcp://10.59.243.69:443
VAULT_STANDBY_SERVICE_PORT=8200
VAULT_ACTIVE_SERVICE_HOST=10.59.247.99
VAULT_UI_PORT_8200_TCP_PROTO=tcp
VAULT_AGENT_INJECTOR_SVC_SERVICE_HOST=10.59.243.69
VAULT_ACTIVE_PORT_8201_TCP_ADDR=10.59.247.99
VAULT_SERVICE_PORT=8200
VAULT_ACTIVE_SERVICE_PORT_HTTP=8200
VAULT_ACTIVE_PORT_8201_TCP_PORT=8201
VAULT_PORT_8200_TCP_PORT=8200
VAULT_UI_SERVICE_PORT_HTTP=8200
VAULT_AGENT_INJECTOR_SVC_PORT_443_TCP_PROTO=tcp
VAULT_AGENT_INJECTOR_SVC_PORT_443_TCP_PORT=443
VAULT_STANDBY_PORT_8201_TCP=tcp://10.59.253.170:8201
```

Run `kubectl exec -it vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY`. The pod has been unsealed.

```text
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    1
Threshold       1
Version         1.4.2
Cluster Name    vault-cluster-48475aa5
Cluster ID      d5a38c3b-1013-a99f-60a0-4d8c46ffa9b4
HA Enabled      true
HA Cluster      https://vault-0.vault-internal:8201
HA Mode         active
```

Apply this operation to all remaining vaults.

Run `kubectl exec -it vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY`

```text
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.4.2
Cluster Name           vault-cluster-48475aa5
Cluster ID             d5a38c3b-1013-a99f-60a0-4d8c46ffa9b4
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.56.2.8:8200
```

Run `kubectl exec -it vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY`

```text
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.4.2
Cluster Name           vault-cluster-48475aa5
Cluster ID             d5a38c3b-1013-a99f-60a0-4d8c46ffa9b4
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.56.2.8:8200
```

Now all vaults are ready and running. Run `kubectl get pods -n default`

```text
NAME                                    READY   STATUS    RESTARTS   AGE
consul-j857t                            1/1     Running   0          33m
consul-nslvv                            1/1     Running   0          33m
consul-qgg9r                            1/1     Running   0          33m
consul-server-0                         1/1     Running   0          33m
consul-server-1                         1/1     Running   0          33m
consul-server-2                         1/1     Running   0          33m
vault-0                                 1/1     Running   0          33m
vault-1                                 1/1     Running   0          33m
vault-2                                 1/1     Running   0          33m
vault-agent-injector-7898f4df86-z52kz   1/1     Running   0          33m
```

### Login into vault

Running `kubectl exec -it vault-0 -- vault auth list` will result in following error

```text
Error listing enabled authentications: Error making API request.

URL: GET http://127.0.0.1:8200/v1/sys/auth
Code: 400. Errors:

* missing client token
command terminated with exit code 2
```

Login into vault using root token: `kubectl exec -it vault-0 -- vault login "${VAULT_INITIAL_ROOT_TOKEN}"`

```text
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.NQMZ6VSr8Cj8GGYvS4Pa6EkR
token_accessor       NJNEoQrR5dkFq2ayQkZwwufC
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]
```

Run `kubectl exec -it vault-0 -- vault auth list` again. This time you can list the enabled auth methods.

```text
Path      Type     Accessor               Description
----      ----     --------               -----------
tokens.X1Tk7hH0RgEpABRJsW2ZliXV
```

### Add secrets

```bash
kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
kubectl exec -it vault-0 -- vault secrets list --detailed
kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
```

```text
❯ kubectl exec -it vault-0 -- vault read otus/otus-ro/config
Key                 Value
---                 -----
refresh_interval    768h
password            asajkjkahs
username            otus
```

```text
❯ kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config
====== Data ======
Key         Value
---         -----
password    asajkjkahs
username    otus
```

### Enable k8s authorisation

```bash
kubectl exec -it vault-0 -- vault auth enable kubernetes
```

```text
❯ kubectl exec -it vault-0 -- vault auth list
Path           Type          Accessor                    Description
----           ----          --------                    -----------
kubernetes/    kubernetes    auth_kubernetes_1fd07986    n/a
tokens.X1Tk7hH0RgEpABRJsW2ZliXV
```

### Create Service Account

```bash
# create a service account 'vault-auth'
kubectl create serviceaccount vault-auth

# update the 'vault-auth' service account
kubectl apply -f vault-auth-service-account.yaml
```

### Save k8s configuration to the vault

```bash
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret "${VAULT_SA_NAME}" -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret "${VAULT_SA_NAME}" -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
# sed expression will remove colors from the output
export K8S_HOST=$(kubectl cluster-info | grep 'Kubernetes master' | awk '/https/ {print $NF}' | sed 's/\x1b\[[0-9;]*m//g')

kubectl exec -it vault-0 -- vault write auth/kubernetes/config \
token_reviewer_jwt="${SA_JWT_TOKEN}" \
kubernetes_host="${K8S_HOST}" \
kubernetes_ca_cert="${SA_CA_CRT}"
```

Alternative way to get Kubernetes master host (but make sure the output of this command is a single IP address):

```bash
export K8S_HOST=$(more ~/.kube/config | grep server | awk '/https/ {print $NF}')
```

### Create policies and roles in Vault, and use them

Create policy file

```bash
tee otus-policy.hcl <<EOF
path "otus/otus-ro/*" {
    capabilities = ["read", "list"]
}
path "otus/otus-rw/*" {
    capabilities = ["read", "list", "create", "update"]
}
EOF
```

Copy policy file to the vault (['Permission denied' error explained](https://stackoverflow.com/questions/57734514/kubectl-cp-to-a-pod-is-failing-because-of-permission-denied))

```bash
kubectl cp otus-policy.hcl vault-0:./tmp

kubectl exec -it vault-0 -- vault policy write otus-policy /tmp/otus-policy.hcl

kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
bound_service_account_names=vault-auth \
bound_service_account_namespaces=default \
policies=otus-policy \
ttl=24h
```

Make sure authorization works

```bash
kubectl run --generator=run-pod/v1 tmp --rm -i --tty --serviceaccount=vault-auth --image=alpine:3.7
```

Run the following code inside the `tmp` pod created earlier :point_up:

```bash
# Install curl and jq
apk add curl jq

# Login and get client token
VAULT_ADDR=http://vault:8200
KUBE_TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
curl --request POST --data '{"jwt": "'${KUBE_TOKEN}'", "role": "otus"}' "${VAULT_ADDR}"/v1/auth/kubernetes/login | jq
TOKEN=$(curl -k -s --request POST --data '{"jwt": "'${KUBE_TOKEN}'", "role": "otus"}' "${VAULT_ADDR}"/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')

# Read configs using client token
curl --header "X-Vault-Token:${TOKEN}" "${VAULT_ADDR}"/v1/otus/otus-ro/config
curl --header "X-Vault-Token:${TOKEN}" "${VAULT_ADDR}"/v1/otus/otus-rw/config

# Write configs using client token
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:${TOKEN}" "${VAULT_ADDR}"/v1/otus/otus-ro/config
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:${TOKEN}" "${VAULT_ADDR}"/v1/otus/otus-rw/config
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:${TOKEN}" "${VAULT_ADDR}"/v1/otus/otus-rw/config1
```

Currently `otus-policy` does not allow update configs created earlier, however, creating new configs is allowed.
Recreate `otus-policy.hcl` with new configurations and write it to the Vault.

```bash
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
```

### Authorising Nginx with Vault

Run examples from Hashicorp repository `https://github.com/hashicorp/vault-guides.git`

```bash
kubectl apply -f configmap.yaml -f example-k8s-spec.yaml
kubectl cp vault-agent-example:usr/share/nginx/html/index.html -c nginx-container ./index.html
```

Make sure the `index.html` file copied from `vault-agent-example` pod looks similar to this output

```text
<html>
<body>
<p>Some secrets:</p>
<ul>
<li><pre>username: otus</pre></li>
<li><pre>password: asajkjkahs</pre></li>
</ul>
</body>
</html>
```

### Creating Certificate Authority (CA) with Vault

Enable `pki` secrets

```bash
kubectl exec -it vault-0 -- vault secrets enable pki
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal \
common_name="example.ru" ttl=87600h > CA_cert.crt
```

Assign URLs for CA and revoked certificates

```bash
kubectl exec -it vault-0 -- vault write pki/config/urls \
issuing_certificates="http://vault:8200/v1/pki/ca" \
crl_distribution_points="http://vault:8200/v1/pki/crl"
```

Create intermediate certificate

```bash
kubectl exec -it vault-0 -- vault secrets enable --path=pki_int pki
kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
kubectl exec -it vault-0 -- vault write -format=json pki_int/intermediate/generate/internal \
common_name="example.ru Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr
```

Save intermediate certificate into Vault

```bash
kubectl cp pki_intermediate.csr vault-0:/tmp
kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate csr=@/tmp/pki_intermediate.csr \
format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem
kubectl cp intermediate.cert.pem vault-0:/tmp
kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem
```

Create a role for issuing certificates. Pay attention to the role name and allowed domains for this role.

```bash
kubectl exec -it vault-0 -- vault write pki_int/roles/example-dot-ru \
allowed_domains="example.ru" allow_subdomains=true max_ttl="720h"
```

Issue a certificate

```bash
kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name="gitlab.example.ru" ttl="24h"
```

Issuing output example

```text
[0mKey                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUDuXudcP7pMionIboIdHM6hGgzeAwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhhbXBsZS5ydTAeFw0yMDA3MTExNzU3MDFaFw0yNTA3
MTAxNzU3MzFaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPVBODOwIHzQ
+KZx3a0nfe160PpSlyUS0TFQdobu80oV/oivvUF5f1AJY4estQf7h2OfP0YvvXZa
pRsbt8aLzVLR09N7IUkfOi4e1NJ9j1GgU+9iSrEQq4gYamMqLBywPj/yJVCugmhs
6E67O3iX7BHT0IRADqWrEuwyz3bL7rlj6tm+c8lFBuS0OorG/Tnza2tTdXT6CvuZ
ZKtmNLMdyD79P6rFsnvHLCSmu5osGzWgSh6Al2DG6zzQv0vA8euFc21ZgrkFsdz6
J277WL9etGeScHvfqCHPLQSM0/tfGRl8I7ABMT0ZkCUHwvhwweTm1yyoyWXfko4/
oAXE0wrUcOcCAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQUbX/XXXiPMae73y1k5KKpNtP++i4wHwYDVR0jBBgwFoAU
trckH1m16qPnNjVogfqEduG5KRMwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
m3A/Pc9TMEDxyYOF7CgszRPbzhoCVBgK1J9ePZlGlo4axm15cOhm4Z56JPLYZzwE
wqdRuixMd+dS4ip5pW/zlgqI5sHrJTZeB9TriK4qgcMjmXuwdIIVWDxJD9teB7Vv
ZVjjMx0qignQHattsC4ZqyFQWxUdvXNoxVramHNbm6QdtEEDdvF6q41yj+U4AT3P
JB/GaCq0lm2F0snNOZOd1mvqNJdo7gj9LO9hb0LFHqg1Rote+vAN48Rn97IvxG5s
a7vsnA60PjEzc6wh5BCG+JoQq8YxFD3mcabfwj2B+WTH0ragv9lVg8mYNcoGgM5C
q14NtxmPdFCHPMhvkPzbcw==
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDZzCCAk+gAwIBAgIUDLZAFk0Id9MOgyyUqU/RI9mfZUEwDQYJKoZIhvcNAQEL
BQAwLDEqMCgGA1UEAxMhZXhhbXBsZS5ydSBJbnRlcm1lZGlhdGUgQXV0aG9yaXR5
MB4XDTIwMDcxMTE4MTQxM1oXDTIwMDcxMjE4MTQ0M1owHDEaMBgGA1UEAxMRZ2l0
bGFiLmV4YW1wbGUucnUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx
vKGWnhgQswh0a6oA5fnbb8P6UgYPyR0oAoHpLYDKXmTqD2mKj/Z2VFKpaLRRCVQS
00BK+n/r2H++tuBdgrVuPnyYL+EM/Viff6+tspvVaiVAGV7ftcMpIc7YhaEHu8WC
p1Dlp+LZU8xJUNkYGVE2iQHmNpAOp6CKRWV0Or7iNYmQ0Mn1ER8ZxkmE1D0X87Np
M+Va9vL7k1SZSQTiI1DZMKu9DFz3xSm66DEx1dOZzxh6fm7uo/N0uUZSmDKH/l/g
uaOY1z3jGF7ccGS+GSh3ILtBnjZpPJJRiJM8tp661q/A8gWXOwEEvuRp0n9uL7tz
PTiWpycxzuwJ6UAO6K+RAgMBAAGjgZAwgY0wDgYDVR0PAQH/BAQDAgOoMB0GA1Ud
JQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAdBgNVHQ4EFgQUy8YjSbxSzf7G1apO
JvOis2fLSrcwHwYDVR0jBBgwFoAUbX/XXXiPMae73y1k5KKpNtP++i4wHAYDVR0R
BBUwE4IRZ2l0bGFiLmV4YW1wbGUucnUwDQYJKoZIhvcNAQELBQADggEBAJlye/gB
SMIETJktfu+r+rcNvSvYAkdxbPixy5AyQD7a0VWw1w56iR6Rg4tvGfqgtdyzBeQl
bYzKoQvY5Lu2uJuR7+rhLkS2+X+yLXrU5uyPn5d/Tkf9VTFAB92OUOea4b3OFvEz
T9z4IhWSgxeU3pjVCsCe4gTwFCSwFGbfQ1wwe2ctTQG+CEgMIXdBxGzQDKTjyim0
ZlGkcUGR5l1dgH5n+LqSaRihcmoWDRXYXzuxf8FBXDyr2L6AKvK/1iJ1fhOAnn8X
n0IN61hEa/c0IvL3xTlCLLbMDrgjWT6Ifb8hGQq2XMIi49A3rrfmR06Egm4xEVJE
yDGx9y3dfULMfr8=
-----END CERTIFICATE-----
expiration          1594577683
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUDuXudcP7pMionIboIdHM6hGgzeAwDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhhbXBsZS5ydTAeFw0yMDA3MTExNzU3MDFaFw0yNTA3
MTAxNzU3MzFaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAPVBODOwIHzQ
+KZx3a0nfe160PpSlyUS0TFQdobu80oV/oivvUF5f1AJY4estQf7h2OfP0YvvXZa
pRsbt8aLzVLR09N7IUkfOi4e1NJ9j1GgU+9iSrEQq4gYamMqLBywPj/yJVCugmhs
6E67O3iX7BHT0IRADqWrEuwyz3bL7rlj6tm+c8lFBuS0OorG/Tnza2tTdXT6CvuZ
ZKtmNLMdyD79P6rFsnvHLCSmu5osGzWgSh6Al2DG6zzQv0vA8euFc21ZgrkFsdz6
J277WL9etGeScHvfqCHPLQSM0/tfGRl8I7ABMT0ZkCUHwvhwweTm1yyoyWXfko4/
oAXE0wrUcOcCAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQUbX/XXXiPMae73y1k5KKpNtP++i4wHwYDVR0jBBgwFoAU
trckH1m16qPnNjVogfqEduG5KRMwNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
m3A/Pc9TMEDxyYOF7CgszRPbzhoCVBgK1J9ePZlGlo4axm15cOhm4Z56JPLYZzwE
wqdRuixMd+dS4ip5pW/zlgqI5sHrJTZeB9TriK4qgcMjmXuwdIIVWDxJD9teB7Vv
ZVjjMx0qignQHattsC4ZqyFQWxUdvXNoxVramHNbm6QdtEEDdvF6q41yj+U4AT3P
JB/GaCq0lm2F0snNOZOd1mvqNJdo7gj9LO9hb0LFHqg1Rote+vAN48Rn97IvxG5s
a7vsnA60PjEzc6wh5BCG+JoQq8YxFD3mcabfwj2B+WTH0ragv9lVg8mYNcoGgM5C
q14NtxmPdFCHPMhvkPzbcw==
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAsbyhlp4YELMIdGuqAOX522/D+lIGD8kdKAKB6S2Ayl5k6g9p
io/2dlRSqWi0UQlUEtNASvp/69h/vrbgXYK1bj58mC/hDP1Yn3+vrbKb1WolQBle
37XDKSHO2IWhB7vFgqdQ5afi2VPMSVDZGBlRNokB5jaQDqegikVldDq+4jWJkNDJ
9REfGcZJhNQ9F/OzaTPlWvby+5NUmUkE4iNQ2TCrvQxc98UpuugxMdXTmc8Yen5u
7qPzdLlGUpgyh/5f4LmjmNc94xhe3HBkvhkodyC7QZ42aTySUYiTPLaeutavwPIF
lzsBBL7kadJ/bi+7cz04lqcnMc7sCelADuivkQIDAQABAoIBAGGcTsIBIQZKzKHj
XwIPSyEQSHj5Aws4UCLg/aeprcl1/cXtoPDQD3L87EjNj/nRPbL5AZ4r5IUJ6V47
4Qx59FoPRy3tXZNcr4cpALpMFPknyj1hsZD6qau1PXv8J2uv29DdQrhdc2AXfWHm
XNO3U7q3k6ty27qwpKJLamRivuJLyZjVJHZc1eQiIFMr/CFxP8F4a4tv32ZTcLba
8XpdL8XphNcmU3DJJBUtZvYitF9IKJVXggCgFnEzYKv7SpkcHI4ZrcP7/NhZP1yo
nSdHAvaRrybg5sIDuZfHWNzGW2tcgH+QfPUdC0/x4J4JnmNzWNdiZINGS38sq55r
wbtxngECgYEAxBfWm9bxbMwKQ9AAQAJgvbx18SZicRsClaMxN8cFyDXaTY474TtP
LWlKlmLvmeciR1OpF4B3c7dOaWh4vIWS4URkf3b3gXNm9Qro7DoDVfzfUipN5Hg1
VRr2KeNR/G5APGKYI5SMPRWdyonZLL6GaEb42kFdoifVr0x5ztk7uDkCgYEA6Aks
ulriqvTaqRcCbNtweARP7Xas5d2zPC9sd+L2in5mKr03Zlj2485j4ItYaK86j0cJ
+uhTmNMG7jeYN1ReBohfaa6/7BbE/VJ33epOw8HcilFLyObh1EMG09bsZlAPKxMe
yXIyCL/dNqrtADMmBcR0pnGpPJ8N7fddkvU9QhkCgYAHi8tMb/cWcruqZGS+Edlb
M9duEkYTiDCPRZptRRFp5Pijp2eSgU/ItZaTNvd1ermM+SE2sFDoeRNhZw3OY22F
kbY0WYWoy6IYp/TSsmDSfEqzxMD+m8mhnsn+TqsnBa8fI8QrClpjN2O9GZTr7eEK
PkDxVTafON02Q8EkPqPXsQKBgQCxJogKgub5JFVosRN97o9QYeJv5qIcIQX9ViuW
4CXgGJ6B1NJeBmAADou8XEaULewkhVT+Ra/FRp/M8Y759ySOEkHeGreWVM/yo6q2
N3QJCpII3AZjDLqvZrjotPbpKghal49ytweyHGGUoiytcV9/Gb0BcleF290zqB69
2xP4yQKBgQDCrh2M0Wi1kQChcGsjtzumhtkc+B8v5KMlNCoqZPq6eWk+YtoVri6l
Yz+jBfVqdNJ4cWhSjFUeTdTwMGl0OgZAufjywMOa3R+tlCfUdStpkFfG33EzWb5+
UlFlX3igDwIdYbFAGgrVcZUYo3xoAfQvBscFsHTQdjOaf7E9RwUnfw==
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       0c:b6:40:16:4d:08:77:d3:0e:83:2c:94:a9:4f:d1:23:d9:9f:65:41[0m
```

Get the serial number from the actual output and revoke certificate

```bash
kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="0c:b6:40:16:4d:08:77:d3:0e:83:2c:94:a9:4f:d1:23:d9:9f:65:41"
```

### Enabling TLS

Left to do :point_up:
