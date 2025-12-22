# Kubernetes and Docker quickstart

This file shows how to build the Docker image for this Symfony project and deploy both the application and a MySQL database to a Kubernetes cluster.

Files added:
- `Dockerfile` — multi-stage Dockerfile that installs composer deps and serves the app with php:8.1-apache
- `k8s/namespace.yaml` — `ecommerce` namespace
- `k8s/secrets.yaml` — MySQL credentials (stringData; edit before use)
- `k8s/mysql-pvc.yaml` — PersistentVolumeClaim for MySQL
- `k8s/mysql-deployment.yaml` — MySQL Deployment + Service
- `k8s/app-deployment.yaml` — App Deployment + Service

Prereqs (on your machine / cluster):
- Docker (or a container builder like Buildah)
- kubectl configured to talk to a cluster (kind, minikube, k3s, or managed cluster)

Build and push image (recommended: tag and push to a registry the cluster can pull from):

```bash
# from repository root
docker build -t your-registry/your-namespace/ecommerce:latest .
docker push your-registry/your-namespace/ecommerce:latest
```

If you're using `kind` (local Kubernetes), you can load the image into the cluster instead of pushing:

```bash
kind load docker-image your-registry/your-namespace/ecommerce:latest
```

Edit `k8s/secrets.yaml` and change `MYSQL_ROOT_PASSWORD`, `MYSQL_USER`, `MYSQL_PASSWORD`, and `MYSQL_DATABASE` to secure values.
Edit `k8s/app-deployment.yaml` and update the `image:` line to the image you built (if you didn't use `kind load`, use the pushed image path).

Apply manifests:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/mysql-pvc.yaml
kubectl apply -f k8s/mysql-deployment.yaml
kubectl apply -f k8s/app-deployment.yaml
```

Verify:

```bash
kubectl -n ecommerce get all
kubectl -n ecommerce describe svc ecommerce-service
```

Notes & tips:
- If your Kubernetes environment doesn't provide `LoadBalancer` services, change `ecommerce-service` to `NodePort` or set up an Ingress.
- After the DB pod initializes, you may need to run migrations or import `e-commerce-symfo.sql` (in repo root) into the MySQL pod. For example:

```bash
# copy SQL into the mysql pod and run mysql client inside pod
kubectl -n ecommerce cp e-commerce-symfo.sql $(kubectl -n ecommerce get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}'):/tmp/e-commerce-symfo.sql
kubectl -n ecommerce exec -it $(kubectl -n ecommerce get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}') -- bash -c "mysql -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE < /tmp/e-commerce-symfo.sql"
```

If you want, I can:
- Build the image here (if Docker is available). Note: previous checks showed no apt/git, and Docker may not be installed.
- Create a Kubernetes `Job` to load the SQL automatically after the DB is ready.
