#!/usr/bin/env bash

HELM_REPOS=$(helm repo ls -o json)
if ! echo "$HELM_REPOS" | grep -q "https://helm.elastic.co"; then
    echo "Adding Elastic repo to Helm..."
    helm repo add elastic https://helm.elastic.co
fi

if ! echo "$HELM_REPOS" | grep -q "https://grafana.github.io/loki/charts"; then
    echo "Adding Loki repo to Helm..."
    helm repo add loki https://grafana.github.io/loki/charts
fi

helm repo update

ELASTICSEARCH_CHART_VERSION=7.8.0
KIBANA_CHART_VERSION=7.8.0
FLUENTBIT_CHART_VERSION=2.8.17
NGINX_INGRESS_CHART_VERSION=1.40.1
PROMETHEUS_OPERATOR_VERSION=8.15.6
ELASTICSEARCH_EXPORTER_VERSION=3.4.0
LOKI_VERSION=0.30.1
PROMTAIL_VERSION=0.23.2

gcloud container clusters get-credentials otus-kubernetes-hw \
    --zone europe-west2-a \
    --project otus-hw

kubectl create ns microservices-demo
kubectl create ns nginx-ingress
kubectl create ns observability

kubectl apply -f https://raw.githubusercontent.com/express42/otus-platform-snippets/master/Module-02/Logging/microservices-demo-without-resources.yaml \
    --namespace microservices-demo

# Install prometheus-operator CRDs first because nginx-ingress require ServiceMonitor object
# Otherwise the error may be thrown: no matches for kind "ServiceMonitor" in version "monitoring.coreos.com/v1"
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml -n observability
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml -n observability
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml -n observability
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml -n observability
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml -n observability
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/release-0.38/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml -n observability

# nginx-ingress chart
helm upgrade --install nginx-ingress stable/nginx-ingress \
    --version ${NGINX_INGRESS_CHART_VERSION} \
    --wait \
    --namespace nginx-ingress \
    --values nginx-ingress.values.yaml

# Get external IP from nginx-ingress
# https://helm.sh/docs/intro/using_helm/#helm-install-installing-a-package
INGRESS_EXTERNAL_IP=$(kubectl -n nginx-ingress get svc nginx-ingress-controller -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

# elasticsearch chart
helm upgrade --install elasticsearch elastic/elasticsearch \
    --version ${ELASTICSEARCH_CHART_VERSION} \
    --namespace observability \
    --values elasticsearch.values.yaml

# fluentbit chart
helm upgrade --install fluent-bit stable/fluent-bit \
    --version ${FLUENTBIT_CHART_VERSION} \
    --namespace observability \
    --values fluent-bit.values.yaml

# kibana chart
KIBANA_INGRESS="kibana.$INGRESS_EXTERNAL_IP.xip.io"
helm upgrade --install kibana elastic/kibana \
    --version ${KIBANA_CHART_VERSION} \
    --namespace observability \
    --values kibana.values.yaml \
    --set ingress.hosts={${KIBANA_INGRESS}}

# prometheus-operator chart
PROMETHEUS_INGRESS="prometheus.$INGRESS_EXTERNAL_IP.xip.io"
GRAFANA_INGRESS="grafana.$INGRESS_EXTERNAL_IP.xip.io"
ALERTMANAGER_INGRESS="alertmanager.$INGRESS_EXTERNAL_IP.xip.io"
helm upgrade --install prometheus-operator stable/prometheus-operator \
    --version ${PROMETHEUS_OPERATOR_VERSION} \
    --namespace observability \
    --values prometheus-operator.values.yaml \
    --set prometheus.ingress.hosts={${PROMETHEUS_INGRESS}} \
    --set grafana.ingress.hosts={${GRAFANA_INGRESS}} \
    --set alertmanager.ingress.hosts={${ALERTMANAGER_INGRESS}}

# elasticsearch-exporter chart
helm upgrade --install elasticsearch-exporter stable/elasticsearch-exporter \
    --version ${ELASTICSEARCH_EXPORTER_VERSION} \
    --namespace observability \
    --set es.uri=http://elasticsearch-master:9200 \
    --set serviceMonitor.enabled=true

# loki chart
helm upgrade --install loki loki/loki \
    --version ${LOKI_VERSION} \
    --namespace observability

# promtail chart
helm upgrade --install promtail loki/promtail \
    --version ${PROMTAIL_VERSION} \
    --namespace observability \
    --set loki.serviceName=loki \
    --values loki.values.yaml
