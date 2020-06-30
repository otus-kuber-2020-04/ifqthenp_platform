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
