## HW 8. Service Monitoring in Kubernetes Cluster.

### What has been done

- Downloaded `prometheus-operator` helm chart using `helm pull stable/prometheus-operator --untar`
- Installed CRD manifests in `kubernetes-monitoring/prometheus-operatror/crds` folder
- Installed `prometheus-operator` helm chart using Helm 3
- Created manifests for Nginx application and ServiceMonitor

### How to run monitoring services

```bash
minikube start
./install.sh
```
