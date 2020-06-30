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
