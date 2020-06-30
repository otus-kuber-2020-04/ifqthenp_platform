## HW 9. Central Logging Services for k8s and Applications.

### How to start GKE cluster

Export `TF_VAR_credentials_json` and run Terraform scripts from `kubernetes-logging/infra` folder.

```bash
terraform init
terraform plan
terraform apply -auto-approve
```

The output of `kubectl get nodes` should look similar to this:

```
NAME                                                STATUS   ROLES    AGE   VERSION
gke-otus-kubernetes-hw-default-pool-bd00f111-r9pn   Ready    <none>   30m   v1.16.9-gke.6
gke-otus-kubernetes-hw-infra-pool-2b16d5c7-bb40     Ready    <none>   31m   v1.16.9-gke.6
gke-otus-kubernetes-hw-infra-pool-2b16d5c7-c5f1     Ready    <none>   31m   v1.16.9-gke.6
gke-otus-kubernetes-hw-infra-pool-2b16d5c7-sdkw     Ready    <none>   31m   v1.16.9-gke.6
```

Note one `default-pool` and three `infra-pool`s.

### Install HipsterShop app

Deploy HipsterShop application

```bash
kubectl create ns microservices-demo
kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Logging/microservices-demo-without-resources.yaml -n microservices-demo
```

Ensure all pods have been deployed in `default-pool` node. Running `kubectl get pods -n microservices-demo -o wide`
should result in output similar to this:

```
NAME                                     READY   STATUS    RESTARTS   AGE   IP           NODE                                                NOMINATED NODE   READINESS GATES
adservice-cb695c556-rmqng                1/1     Running   0          28m   10.56.4.18   gke-otus-kubernetes-hw-default-pool-bd00f111-r9pn   <none>           <none>
cartservice-f4677b75f-6tnnk              1/1     Running   2          28m   10.56.4.14   gke-otus-kubernetes-hw-default-pool-bd00f111-r9pn   <none>           <none>
checkoutservice-664f865b9b-9wfv5         1/1     Running   0          28m   10.56.4.9    gke-otus-kubernetes-hw-default-pool-bd00f111-r9pn   <none>           <none>
currencyservice-bb9d998bd-zqgst          1/1     Running   0          28m   10.56.4.17   gke-otus-kubernetes-hw-default-pool-bd00f111-r9pn   <none>           <none>
```

### Install EFK stack using Helm charts

Add recommended Helm chart repo for ElasticSearch and Kibana

```bash
helm repo add elastic https://helm.elastic.co
```

Install required components with default values

```bash
kubectl create ns observability
helm upgrade --install elasticsearch elastic/elasticsearch --version 7.8.0 --namespace observability
helm upgrade --install kibana elastic/kibana --version 7.8.0 --namespace observability
helm upgrade --install fluent-bit stable/fluent-bit --version 2.8.17 --namespace observability
```

Services need to be installed to the `infra-pool` nodes. Create `elasticsearch.values.yaml` in `kubernetes-logging` folder,
add the following configuration

```yaml
tolerations:
  - key: node-role
    operator: Equal
    value: infra
    effect: NoSchedule
nodeSelector:
  cloud.google.com/gke-nodepool:infra-pool
```

Update ElasticSearch release

```bash
helm upgrade --install elasticsearch elastic/elasticsearch --version 7.8.0 --namespace observability -f elasticsearch.values.yaml
```

### Install nginx-ingress

Create a namespace and install `nginx-ingress` release

```bash
kubectl create ns nginx-ingress
helm upgrade --install nginx-ingress stable/nginx-ingress --version 1.40.1 --wait --namespace nginx-ingress
```

### Install Kibana

Create `kibana.values.yaml` file in `kubernetes-logging` folder and the following config for ingress

```yaml
ingress:
  enabled: true
  annotations: {
    kubernetes.io/ingress.class: nginx
  }
  path: /

  # This value will be replaced with KIBANA_INGRESS variable from 'install.sh' script
  # https://helm.sh/docs/intro/using_helm/#helm-install-installing-a-package
  # Otherwise, if running 'install.sh' is not an option, replace INGRESS_EXTERNAL_IP with external ingress IP
  hosts:
    - kibana.INGRESS_EXTERNAL_IP.xip.io
```

To see LoadBalancer external IP run `kubectl get svc -n nginx-ingress nginx-ingress-controller`

Update Kibana release

```bash
KIBANA_INGRESS_IP=$(kubectl -n nginx-ingress get svc nginx-ingress-controller -o jsonpath="{.status.loadBalancer.ingress[*].ip}")
KIBANA_INGRESS="kibana.$KIBANA_INGRESS_IP.xip.io"
helm upgrade --install kibana elastic/kibana --version 7.8.0 --namespace observability -f kibana.values.yaml --set ingress.hosts={${KIBANA_INGRESS}}
```

### Install Fluent Bit

Create `fluent-bit.values.yaml` file in `kubernetes-logging` folder with the following config

```yaml
backend:
  type: es
  es:
    host: elasticsearch-master
rawConfig: |
  @INCLUDE fluent-bit-service.conf
  @INCLUDE fluent-bit-input.conf
  @INCLUDE fluent-bit-filter.conf
  @INCLUDE fluent-bit-output.conf

  [FILTER]
    Name modify
    Match *
    Remove time
    Rename @timestamp my_timestamp
```

Update Fluent Bit release

```yaml
helm upgrade --install fluent-bit stable/fluent-bit --version 2.8.17 --namespace observability -f fluent-bit.values.yaml
```

### ElasticSearch monitoring

Install `prometheus-operator` into `observability` namespace

```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml --namespace observability
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml --namespace observability
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml --namespace observability
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml --namespace observability
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml --namespace observability
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml --namespace observability

helm upgrade --install prometheus-operator stable/prometheus-operator \
    --version 8.15.6 \
    --namespace observability \
    --set prometheusOperator.createCustomResource=false \
    --set prometheus.serviceMonitorSelectorNilUsesHelmValues=false
```

Create `prometheus-operator.values.yaml`, add a configuration for Prometheus Operator and ingress
for Prometheus, Grafana and Alertmanager.

```yaml
prometheusOperator:
  createCustomResource: false

  nodeSelector:
    cloud.google.com/gke-nodepool: infra-pool

  tolerations:
    - key: node-role
      operator: Equal
      value: infra
      effect: NoSchedule

prometheus:
  ingress:
    enabled: true
    annotations: {
      kubernetes.io/ingress.class: nginx
    }
    path: /

    # This value will be replaced with PROMETHEUS_INGRESS variable from 'install.sh' script
    # https://helm.sh/docs/intro/using_helm/#helm-install-installing-a-package
    hosts:
      - prometheus.INGRESS_EXTERNAL_IP.xip.io
```

Use Prometheus exporter to monitor ElasticSearch metrics.

```bash
helm upgrade --install elasticsearch-exporter stable/elasticsearch-exporter \
    --version 3.4.0 \
    --namespace observability \
    --set es.uri=http://elasticsearch-master:9200 \
    --set serviceMonitor.enabled=true
```

Import [Elasticsearch detailed dashboard](https://grafana.com/grafana/dashboards/4358)
using Grafana UI.

Make sure the metrics do the job. Drain one node from the `infra` pool: `kubectl drain <NODE_NAME> --ignore-daemonsets`.
This reduces the number of nodes by one, but the `Cluster health status` metric remains green. [Prometheus alert](https://github.com/justwatchcom/elasticsearch_exporter/blob/master/examples/prometheus/elasticsearch.rules)
can be used to detect a problem with number of running Elasticsearch nodes:

```text
# alert if too few nodes are running
ALERT ElasticsearchTooFewNodesRunning
  IF elasticsearch_cluster_health_number_of_nodes < 3
  FOR 5m
  LABELS {severity="critical"}
  ANNOTATIONS {description="There are only {{$value}} < 3 ElasticSearch nodes running", summary="ElasticSearch running on less than 3 nodes"}
```

Run `kubectl uncordon <NODE_NAME>` to put the node back into operation.

Import Nginx dashboards to Kibana from `export.ndjson` file.

### nginx-ingress logs in EFK stack

The current nginx logs format is inadequate to work with Kibana features such as KQL, analytics, building dashboards
using logs data.

```text
...
  "_source": {
    "@timestamp": "2020-06-28T11:16:58.158Z",
    "log": "10.56.5.1 - - [28/Jun/2020:11:16:58 +0000] \"GET /api/datasources/proxy/1/api/v1/query_range?query=elasticsearch_cluster_health_delayed_unassigned_shards%7Bcluster%3D%22elasticsearch%22%7D&start=1593299400&end=1593342600&step=600 HTTP/1.1\" 200 258 \"http://grafana.34.89.109.245.xip.io/d/alUGiRGMk/elasticsearch\" \"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36\" 682 0.004 [observability-prometheus-operator-grafana-80] [] 10.56.1.25:3000 258 0.003 200 e0d3d61e090d32c04d57da662e83821d\n"
    ...
  }
...
```

To fix that, add [log-format-escape-json](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#log-format-escape-json)
and [log-format-upstream](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#log-format-upstream)
keys in `nginx-ingress.values.yaml`.

### Grafana Loki (log aggregation system)

Install Loki and Promtail using Helm 3

```bash
helm repo add loki https://grafana.github.io/loki/charts
helm repo update

helm upgrade --install loki loki/loki \
    --version 0.30.1 \
    --namespace observability

helm upgrade --install promtail loki/promtail \
    --version 0.23.2 \
    --namespace observability \
    --set loki.serviceName=loki \
    --values loki.values.yaml
```

Import Nginx Ingress controller dashboard to Grafana using `nginx-ingress.json` file.
