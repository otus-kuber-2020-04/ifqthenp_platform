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
