# Argoapps - Application Manifests

This repository contains all Kubernetes application manifests and ArgoCD applications for the Bo Kube VM project.

## Repository Structure

```
├── application/           # Kubernetes application manifests
│   └── spring-boot-todo/  # Spring Boot Todo application
│       ├── configmap.yaml
│       ├── deployment.yaml
│       ├── ingress.yaml
│       ├── kustomization.yaml
│       ├── namespace.yaml
│       └── service.yaml
└── argo-apps/            # ArgoCD application definitions
    ├── apps/             # Individual ArgoCD applications
    │   ├── gatekeeper-application.yaml
    │   ├── grafana-application.yaml
    │   ├── prometheus-application.yaml
    │   └── spring-boot-todo-application.yaml
    └── argo-apps-root.yaml
```

## Dependencies

- **Infrastructure Repository**: [GitLab - bo-kube-vm](git@gitlab.common.cloud.riag.digital:riag/tech/platforms/sre/assessment-center/training-center/bo-kube-vm.git)
  - Contains Terraform infrastructure and startup scripts
  - References this repository for ArgoCD app deployment

## Applications

### 1. Spring Boot Todo Application
- **Path**: `application/spring-boot-todo/`
- **Namespace**: `spring-boot-todo`
- **Features**:
  - Kustomize-based configuration
  - Configurable Docker image via kustomization
  - Health checks (startup, liveness, readiness probes)
  - Prometheus metrics integration
  - HTTPS ingress with cert-manager

### 2. ArgoCD Applications
- **Path**: `argo-apps/apps/`
- **Purpose**: Defines all applications to be deployed by ArgoCD
- **Applications**:
  - Gatekeeper (Policy management)
  - Grafana (Monitoring dashboard)
  - Prometheus (Metrics collection)
  - Spring Boot Todo (Main application)

## ArgoCD Configuration

### Root Application
The infrastructure repository deploys a root ArgoCD application that points to:
- **Repository**: `https://github.com/BoXuan21/Argoapps.git`
- **Path**: `argo-apps/apps`
- **Project**: `platform-apps` (custom project, not default)

### Application References
All ArgoCD applications in `argo-apps/apps/` reference back to this repository for their source manifests.

## Spring Boot Todo Configuration

### Image Management
Controlled via `application/spring-boot-todo/kustomization.yaml`:
```yaml
images:
  - name: spring-boot-todo-app
    newName: boxuanyang/spring-boot-todo-app
    newTag: v1.0.3
```

### Ingress Configuration
- **Host**: `spring-boot-todo.{EXTERNAL_IP}.nip.io`
- **HTTPS**: Enabled with cert-manager
- **Certificate**: Managed by Let's Encrypt or ZeroSSL

## Deployment Flow

1. **Infrastructure** deploys ArgoCD and root application
2. **ArgoCD** syncs applications from this repository
3. **Applications** are deployed to their respective namespaces
4. **Monitoring** stack (Prometheus/Grafana) monitors all applications

## Key Features

- ✅ GitOps workflow with ArgoCD
- ✅ Automated certificate management
- ✅ Monitoring and observability
- ✅ Health checks and probes
- ✅ Kustomize-based configuration
- ✅ Namespace isolation

## Usage

This repository is automatically synchronized by ArgoCD. Manual deployment is not required.

To update applications:
1. Modify the relevant YAML files
2. Commit and push changes
3. ArgoCD will automatically detect and sync changes

## Network Access

Once deployed, applications are available at:
- **Spring Boot Todo**: `https://spring-boot-todo.{EXTERNAL_IP}.nip.io`
- **Grafana**: `https://grafana.{EXTERNAL_IP}.nip.io`
- **Prometheus**: `https://prometheus.{EXTERNAL_IP}.nip.io`
- **ArgoCD**: `https://argocd.{EXTERNAL_IP}.nip.io`

## Notes

- All applications use HTTPS with automatic certificate management
- Applications are monitored by Prometheus
- Grafana provides dashboards for monitoring
- ArgoCD provides GitOps deployment automation
