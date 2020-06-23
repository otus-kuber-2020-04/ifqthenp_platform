# ifqthenp_platform

ifqthenp Platform repository

## HW 1. Kubernetes Intro

- Created Docker image with simple http server using `kubernetes-intro/web/Dockerfile` file
- Created Kubernetes manifest file describing Pod with `containers` and `initContainer` specs
- :star: Fixed broken `frontend` Pod from [Hipster Shop repo][1] and saved result in `kubernetes-intro/frontend-pod-healthy.yaml`

[1]: https://github.com/GoogleCloudPlatform/microservices-demo

## HW 2. Kubernetes Controllers

- Launched Kubernetes cluster using [Kind][1] tool
- Created ReplicaSet resource for the `frontend` microservice
- Changed the number of replicas using ad-hoc command `kubectl scale replicaset frontend --replicas=3`
- Updated pod template in the `frontend` ReplicaSet to use different docker image:
  - `export KUBE_EDITOR="/usr/local/bin/code"`
  - `kubectl edit rs frontend` (change image tag either to `v0.0.1` or `v.0.0.2`)
  - `kubectl get replicaset frontend -o=jsonpath='{.spec.template.spec.containers[0].image}'`
  - `kubectl get pods -l app=frontend -o=jsonpath='{.items[0:3].spec.containers[0].image}'`
  - alternatively, make changes in `frontend-replicaset.yaml` file and re-apply it with `kubectl apply -f frontend-replicaset.yaml`
- Created ReplicaSet and Deployment resources for the `payment` microservice
- :star: Used `maxSurge` and `maxUnavailable` parameters in `payment` microservice to create deployment strategies similar to **Blue/Green** and **Reverse Rolling Update**
- Added pod readiness probes to `frontend` microservice:
  - `kubectl rollout status deployment/frontend --timeout=60s`
  - `kubectl rollout undo deployment/frontend` (in case of readiness probe failure)
- :star::star: Created manifest `node-exporter-daemonset.yaml` configured to collect hardware and OS metrics for both worker and master nodes using [Node Exporter][2]:
  - `kubectl port-forward <POD_NAME> 9100:9100`
  - `curl localhost:9100/metrics`

[1]: https://kind.sigs.k8s.io/docs/user/quick-start
[2]: https://github.com/prometheus/node_exporter

## HW 3. Kubernetes Security

Kubectl Reference Documents for ["kubectl auth can-i"][1]

Account usernames are formatted like this: `system:serviceaccount:<namespace>:<service account name>`

List available API resources: `kubectl api-resources`

### Task 1

Created ServiceAccount `bob` and assigned default ClusterRole `admin` to it,
using ClusterRoleBinding.

- `kubectl auth can-i --list --namespace=kube-system --as=system:serviceaccount:default:bob`
- `kubectl auth can-i --list --namespace=default --as=system:serviceaccount:default:bob`

Created ServiceAccount `dave` and assigned Role `dave` to it, using RoleBinding.
This role has permissions for using all resources and verbs within  `default` namespace.

- `kubectl auth can-i --list --namespace=kube-system --as=system:serviceaccount:default:dave`
- `kubectl auth can-i --list --namespace=default --as=system:serviceaccount:default:dave`

### Task 2

Created ServiceAccount `carol` in the Namespace `prometheus` and assigned permissions to `carol`
to read, list and watch Pods in all Namespaces of the cluster

- `kubectl auth can-i --list --namespace=kube-system --as=system:serviceaccount:prometheus:carol`
- `kubectl auth can-i watch pods --all-namespaces --as=system:serviceaccount:prometheus:carol`

### Task 3

Created Namespace `dev` and two ServiceAccounts `jane` and `ken`, assigned ClusterRole `admin`
and `view` to `jane` and `ken` respectively, using RoleBinding. A RoleBinding referring to
a ClusterRole only grants access to resources inside the RoleBinding's namespace.

- `kubectl auth can-i --list --as=system:serviceaccount:dev:jane -n dev`
- `kubectl auth can-i create deployments --as=system:serviceaccount:dev:jane --all-namespaces`
- `kubectl auth can-i create deployments --as=system:serviceaccount:dev:jane -n dev`
- `kubectl auth can-i --list --as=system:serviceaccount:dev:ken -n dev`
- `kubectl auth can-i list pods --as=system:serviceaccount:dev:ken -n default`
- `kubectl auth can-i list pods --as=system:serviceaccount:dev:ken -n dev`

[1]: https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-can-i-em

## HW 4. Kubernetes Networks

*TODO:* All tasks marked with :star2:

### Working with test web application

- Added readiness/liveness probes to a Pod
- Created Deployment object from `kubernetes-intro/web-pody.yam`
- Added services of `ClusterIP` type to the cluster
- Enabled IPVS load balancing mode in the cluster

### Accessing application from outside cluster

- Set up MetalLB in Layer2 mode
- Added `LoadBalancer` service
- Set up `Ingress` controller and `ingres-nginx` proxy
- Created `Ingress` rules

## HW 5. Kubernetes Volumes, Storages, StatefulSet

- Deployed `StatefulSet` with MinIO application as local S3 storage
- Created headless service for the app
- Installed `mc` CLI tool for MinIO and managed resources in the storage using this tool
- :star: Added `Secret` object to store MinIO access and secret keys and configured `StatefulSet` to use data from `Secret`

## HW 6. Kubernetes templating


### nginx-ingress

[nginx-ingress docs](https://github.com/helm/charts/tree/master/stable/nginx-ingress)

Add helm repo

```shell script
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo list
```

Create `namespace` and `release` nginx-ingress

```shell script
kubectl create ns nginx-ingress

helm upgrade --install nginx-ingress stable/nginx-ingress --wait \
--namespace=nginx-ingress \
--version=1.11.1
```

### cert-manager

[cert-manager installation docs](https://github.com/jetstack/cert-manager/tree/master/deploy/charts/cert-manager)
[cert-manager docs](https://docs.cert-manager.io/en/latest/)

Add helm repo for cert-manager

```shell script
helm repo add jetstack https://charts.jetstack.io
```

Create namespace

```shell script
kubectl create ns cert-manager
```

Add CRD

```shell script
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
```

Add a label to namespace

```shell script
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"
```

Install cert-manager

```shell script
helm upgrade --install cert-manager jetstack/cert-manager --wait \
--namespace=cert-manager \
--version=0.9.0
```

Create ClusterIssuers for staging and production

```shell script
kubectl apply -f letsencrypt-staging.yaml
kubectl apply -f letsencrypt-production.yaml
```

### chartmuseum

[chartmuseum helm chart docs](https://github.com/helm/charts/tree/master/stable/chartmuseum)
[chartmuseum values file](https://github.com/helm/charts/blob/master/stable/chartmuseum/values.yaml)

Install chartmuseum

```shell script
kubectl create ns chartmuseum

kubectl create secret generic -n chartmuseum chartmuseum-gcs-secret --from-file=credentials.json="/path/to/credentials/file"

helm upgrade --install chartmuseum stable/chartmuseum --wait \
--namespace=chartmuseum \
--version=2.3.2 \
-f kubernetes-templating/chartmuseum/values.yaml
```

Example of `values.yaml` file

```yaml
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    kubernetes.io/tls-acme: "true"
    # Change 'staging' to 'prod' if necessary
    certmanager.k8s.io/cluster-issuer: "letsencrypt-staging"
    certmanager.k8s.io/acme-challenge-type: http01
  hosts:
    - name: chartmuseum.example.com
      path: /
      tls: true
      tlsSecret: chartmuseum.example.com
env:
  open:
    DISABLE_API: false
    STORAGE: google
    STORAGE_GOOGLE_BUCKET: chartmuseum-otus-bucket
    STORAGE_GOOGLE_PREFIX: stage
gcp:
  secret:
    enabled: true
    name: chartmuseum-gcs-secret
    key: credentials.json
```

If having problems with staging certificate `x509: certificate signed by unknown authority`,
download the certificate and use `--ca-file` option providing path to the certificate

```shell script
helm repo add --ca-file chartmuseum/chartmuseum.34.89.7.206.nip.io.staging.crt chartmuseum https://chartmuseum.34.89.7.206.nip.io/
```

#### :star: chartmuseum use guide

To start using chartmuseum:

- Create Google Cloud Storage (GCS) service account with appropriate permissions
- Install [helm push plugin](https://github.com/chartmuseum/helm-push)
- Create your own chart: `helm create my-best-chart`
- Push your chart to the chartmuseum: `helm push my-best-chart`
  - if running chartmuseum on staging environment use `--ca-file /path/to/staging/cert` option
- Install your chart: `helm upgrade --install my-best-chart chartmuseum/my-best-chart --wait --namespace=chartmuseum --version=0.1.0`
- To uninstall it, run `helm uninstall -n chartmuseum my-best-chart`

### Harbor

Add harbor helm chart repo: `helm repo add harbor https://helm.goharbor.io`

```shell script
kubectl create ns harbor

helm upgrade --install harbor harbor/harbor --wait \
--namespace=harbor \
--version=1.1.2 \
-f harbor/values.yaml
```

### :star: Helmfile

Install [Helm Diff Plugin](https://github.com/databus23/helm-diff)

Run the script from the folder where your main `helmfile.yaml` is located

```shell script
helmfile sync
kubectl -n nginx-ingress get svc
```

Copy `EXTERNAL-IP` value and paste into `ingress.hosts.core` in`kubernetes-templating/helmfile/releases/harbor.yaml` file.
Run `helmfile apply` after that.

Run `helmfile destroy` to delete and then purge releases

### Hipster Shop

#### all-hipster-shop

This configuration is how to run Hipster Shop from `all-hipster-shop.yaml` file

```shell script
kubectl create ns hipster-shop
helm upgrade --install hipster-shop kubernetes-templates/hipster-shop --namespace hipster-shop
gcloud compute firewall-rules create frontend-svc-nodeport-rule --allow=tcp:$(kubectl -n hipster-shop get services frontend -o jsonpath="{.spec.ports[*].nodePort}")
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}'
```

#### frontend

Make sure you have `nginx-ingress` and `cert-manager` installed in a cluster.

Extract `Deployment` and `Service` for `frontend` microservice from `all-hipster-shop.yaml`, create new Helm chart `frontend` and
put extracted into newly created chart `templates` folder.

When `nginx-ingress` is created, copy `External-IP` from `LoadBalancer` and use for `ingress.yaml` host, i.e. `shop.35.246.25.233.nip.io`

```shell script
cd kubernetes-templating
kubectl create ns nginx-ingress
helm upgrade --install nginx-ingress stable/nginx-ingress --wait --namespace=nginx-ingress --version=1.11.1
kubectl create ns cert-manager
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"
helm upgrade --install cert-manager jetstack/cert-manager --wait --namespace=cert-manager --version=0.9.0
kubectl apply -f cert-manager/letsencrypt-issuers.yaml
kubectl create ns hipster-shop
helm upgrade --install hipster-shop hipster-shop --namespace hipster-shop
helm upgrade --install frontend frontend --namespace hipster-shop
```

#### Creating own Helm Chart

Delete `frontend` release from the previously created Hipster Shop

```shell script
helm delete frontend -n hipster-shop
```

Declare dependencies in `hipster-shop/Chart.yaml` and run `helm dep update kubernetes-templating/hipster-shop`

Update `hipster-shop` release and make sure that `frontend` resources are recreated again

```shell script
helm upgrade --install hipster-shop hipster-shop --namespace hipster-shop
```

Update `NodePort` value for the `frontend` release

```shell script
helm upgrade --install hipster-shop hipster-shop --namespace hipster-shop --set frontend.service.NodePort=31234
```

#### :star: Installing Redis using community chart

Remove Redis deployment and service from `all-hipster-shop.yaml` in `templates` folder.
Change service name in `cartservice` Deployment from `redis-cart` to `redis-cart-master`

```shell script
helm dep update hipster-shop
helm upgrade --install hipster-shop hipster-shop --namespace hipster-shop --values hipster-shop/redis-values.yaml
```

### Working with Helm secrets

[Instructions how to use GCP KMS](https://github.com/mozilla/sops#encrypting-using-gcp-kms)

```shell script
helm secrets upgrade --install hipster-shop hipster-shop \
--namespace hipster-shop \
-f kubernetes-templating/frontend/values.yaml \
-f kubernetes-templating/frontend/secrets.yaml
```

If the `frontend` has been installed via the `hipster-shop` Helm chart, then `frontend` release doesn't exist for Helm.
Use the following command for deploying a secret:

```shell script
helm secrets upgrade --install hipster-shop hipster-shop \
--namespace hipster-shop \
-f hipster-shop/secrets.yaml \
-f hipster-shop/redis-values.yaml
```

### Using Helm charts with Harbor

If using staging certificates, download the certificate and use it with `--ca-file` option

```shell script
helm repo add --ca-file harbor.34.89.83.66.nip.io.staging.crt templating https://harbor.34.89.83.66.nip.io/chartrepo/library
helm push --ca-file harbor.34.89.83.66.nip.io.staging.crt --username USERNAME --password PASSWORD ./frontend/ templating
helm push --ca-file harbor.34.89.83.66.nip.io.staging.crt --username USERNAME --password PASSWORD ./hipster-shop/ templating
```

Run `helm repo list` and expect the output similar to this

```
templating              https://harbor.34.89.83.66.nip.io/chartrepo/library
```

Run `helm search repo hipster` and observe the output

```
NAME                    CHART VERSION   APP VERSION     DESCRIPTION
templating/hipster-shop 0.1.0           1.16.0          A hipster-shop Helm chart
templating/frontend     0.1.0           1.16.0          Frontend chart for hipster-shop application
```

### Kubecfg

```shell script
cd kubernetes-templating/kubecfg
kubecfg show services.jsonnet
kubecfg update services.jsonnet --namespace hipster-shop
```

### Kustomize

[Kustomize GitHub](https://github.com/kubernetes-sigs/kustomize)

To apply configuration for development environment, run the following commands

```shell script
kubectl apply -k kustomize/overrides/development/
```

Pay attention to the names of the services in case if applying prefixes or suffixes with `kustomize`.
For example: `namePrefix: prod-` or `nameSuffix: -prod`

## HW 7. Operator, CustomResourceDefinition

To get it running in your cluster

```shell script
cd kubernetes-operators/deploy
kubectl apply -f service-account.yml \
-f role.yml \
-f role-binding.yml \
-f deploy-operator.yml \
-f crd.yml \
-f cr.yml
```

Make sure that `pvc` resources have been created

```shell script
kubectl get pvc
```

Add some data to the `mysql-instance`

```shell script
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -uroot -potuspassword -e "CREATE TABLE test ( id smallint unsigned not null auto_increment, name varchar(20) not null, constraint pk_example primary key (id) );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -uroot -potuspassword -e "INSERT INTO test ( id, name ) VALUES ( null, 'some data' );" otus-database
kubectl exec -it $MYSQLPOD -- mysql -uroot -potuspassword -e "INSERT INTO test ( id, name ) values ( null, 'some data-2' );" otus-database
```

check that the database has been modified

```shell script
kubectl exec -it $MYSQLPOD -- mysql -uroot -potuspassword -e "SELECT * from test;" otus-database
```

Delete `mysql-instance` and make sure that `pv` resource has been removed from the cluster, and `jobs.batch` resource has been completed

```shell script
kubectl delete mysqls.otus.homework mysql-instance
```

Wait for a little while and recreate `mysql-instance` custom resource

```shell script
kubectl apply -f cr.yml
export MYSQLPOD=$(kubectl get pods -l app=mysql-instance -o jsonpath="{.items[*].metadata.name}")
kubectl exec -it $MYSQLPOD -- mysql -uroot -potuspassword -e "SELECT * from test;" otus-database
```

The output should look similar to this

```shell script
mysql: [Warning] Using a password on the command line interface can be insecure.
+----+-------------+
| id | name        |
+----+-------------+
|  1 | some data   |
|  2 | some data-2 |
+----+-------------+
```

Run `kubectl get jobs` and the output should look similar to this

```
NAME                         COMPLETIONS   DURATION   AGE
backup-mysql-instance-job    1/1           1s         14m
restore-mysql-instance-job   1/1           6m17s      17m
```
