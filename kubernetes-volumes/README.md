## HW 5. Kubernetes Volumes, Storages, StatefulSet

- Deployed `StatefulSet` with MinIO application as local S3 storage
- Created headless service for the app
- Installed `mc` CLI tool for MinIO and managed resources in the storage using this tool
- :star: Added `Secret` object to store MinIO access and secret keys and configured `StatefulSet` to use data from `Secret`
