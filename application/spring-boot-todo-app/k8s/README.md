# Spring Boot Todo App - Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the Spring Boot Todo application.

## Prerequisites

1. Kubernetes cluster running
2. ArgoCD installed and configured
3. Docker image built and pushed to a registry

## Building the Docker Image

From the `spring-boot-todo-app/spring-boot-todo-app` directory, run:

```bash
# Build the Docker image
docker build -t todo-app:latest .

# Tag for your registry (replace with your registry)
docker tag todo-app:latest your-registry/todo-app:latest

# Push to registry
docker push your-registry/todo-app:latest
```

## Kubernetes Resources

- `namespace.yaml` - Creates the todo-app namespace
- `configmap.yaml` - Application configuration
- `deployment.yaml` - Deployment and Service definitions
- `kustomization.yaml` - Kustomize configuration

## Manual Deployment

If deploying manually without ArgoCD:

```bash
# Apply all resources
kubectl apply -k .

# Check deployment status
kubectl get pods -n todo-app

# Port forward to access the application
kubectl port-forward svc/todo-app-service 8080:80 -n todo-app
```

## ArgoCD Deployment

The application is configured to be deployed via ArgoCD using the `todo-app-application.yaml` in the `argo-apps/apps/` directory.

## Accessing the Application

Once deployed, the application will be available:
- Internally: `http://todo-app-service.todo-app.svc.cluster.local`
- Via port-forward: `http://localhost:8080`

## Configuration

The application configuration is managed through the ConfigMap. Update `configmap.yaml` to modify application settings.

## Health Checks

The application includes:
- Liveness probe on `/actuator/health`
- Readiness probe on `/actuator/health`
- Proper resource limits and requests 