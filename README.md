# SIT722 Microservices CI/CD Project

This project demonstrates a complete CI/CD pipeline for a microservices application deployed on Azure Kubernetes Service (AKS). The application consists of three backend services (Product, Order, Customer) with a frontend, all orchestrated through automated testing and deployment pipelines.

## 🏗️ Architecture Overview

- **Backend Services**: FastAPI microservices (Product, Order, Customer)
- **Frontend**: Nginx-served static application
- **Infrastructure**: Azure AKS, ACR, PostgreSQL, RabbitMQ
- **CI/CD**: GitHub Actions with automated testing and deployment
- **IaC**: Terraform for infrastructure management
- **Orchestration**: Kubernetes with Kustomize overlays

## 📋 Prerequisites

- Azure CLI installed and configured
- Docker installed
- Terraform >= 1.9.7
- kubectl installed
- kustomize installed
- Git and GitHub account

---

## 🔧 1. Azure Configuration

### Service Principal Setup

The application expects to work with an Azure Service Principal. You'll need different configurations for local development vs GitHub Actions.

#### For Local Development (App Key)

1. Create a Service Principal with app key:
```bash
az ad sp create-for-rbac --name "sit722-microservices-sp" --role Contributor --scopes /subscriptions/<your-subscription-id>
```

2. Note down the output:
   - `appId` → `client_id`
   - `password` → `client_secret`
   - `tenant` → `tenant_id`

#### For GitHub Actions (OIDC Federation)

1. Create a Service Principal for OIDC:
```bash
az ad sp create-for-rbac --name "sit722-microservices-github" --role Contributor --scopes /subscriptions/<your-subscription-id> --sdk-auth
```

2. Configure OIDC federation for your GitHub repository:
```bash
az ad app federated-credential create --id <app-id> --parameters '{
  "name": "sit722-microservices-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<your-github-username>/<your-repo-name>:ref:refs/heads/main",
  "description": "Main branch deployment",
  "audiences": ["api://AzureADTokenExchange"]
}'

az ad app federated-credential create --id <app-id> --parameters '{
  "name": "sit722-microservices-testing",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:<your-github-username>/<your-repo-name>:ref:refs/heads/testing",
  "description": "Testing branch deployment",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

### Required Azure Permissions

Ensure your Service Principal has the following permissions:
- **Contributor** role on the subscription
- **AcrPush** role on Azure Container Registry
- **Azure Kubernetes Service Cluster User** role on AKS

---

## 🔐 2. GitHub Configuration

### Required Secrets

Configure the following secrets in your GitHub repository (`Settings > Secrets and variables > Actions`):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AZURE_CLIENT_ID` | Service Principal App ID | `12345678-1234-1234-1234-123456789012` |
| `AZURE_TENANT_ID` | Azure Tenant ID | `87654321-4321-4321-4321-210987654321` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | `abcdef12-3456-7890-abcd-ef1234567890` |
| `AZURE_ACR_NAME` | Azure Container Registry name | `sit722akprodacr` |
| `AZURE_RG_NAME` | Production Resource Group name | `sit722akprodrg` |
| `AZURE_AKS_NAME` | Production AKS cluster name | `sit722akprodaks` |
| `AZURE_STORAGE_NAME` | Production Storage Account name | `sit722akprodstorage` |

**Note**: No keys or secrets are stored in GitHub. All authentication uses OIDC federation, and storage keys are auto-discovered during pipeline execution.

### GitHub Environments

Configure the following environments in your repository:
- **Production**: For main branch deployments
- **Testing**: For testing branch deployments

---

## 🏭 3. Production Infrastructure Deployment

### Initial Setup

**⚠️ IMPORTANT**: This step must be completed first as all other functions depend on the production infrastructure.

1. **Create terraform.tfvars file** in `terraform/prod/`:
```hcl
subscription_id    = "<your-azure-subscription-id>"
tenant_id          = "<your-azure-tenant-id>"
client_id          = "<your-service-principal-app-id>"
client_secret      = "<your-service-principal-password>"
```

2. **Deploy production infrastructure**:
```bash
cd terraform/prod
terraform init
terraform apply
```

This creates:
- Production Resource Group (`sit722akprodrg`)
- Production AKS cluster (`sit722akprodaks`)
- Production Azure Container Registry (`sit722akprodacr`)
- Production Storage Account (`sit722akprodstorage`)
- Terraform state storage container

3. **Verify deployment**:
```bash
terraform output
```

### Destroying Production Infrastructure

When needed, you can destroy the production infrastructure:
```bash
cd terraform/prod
terraform destroy
```

**⚠️ WARNING**: This will destroy all production resources and data.

---

## 🐳 4. Local Container Image Management

### Login to Azure and ACR

```bash
# Login to Azure
az login

# Login to ACR (replace with your ACR name)
az acr login --name sit722akprodacr
```

### Build and Push Images Locally

```bash
# Build all images
docker build -t sit722akprodacr.azurecr.io/product_service:latest ./backend/product_service
docker build -t sit722akprodacr.azurecr.io/customer_service:latest ./backend/customer_service
docker build -t sit722akprodacr.azurecr.io/order_service:latest ./backend/order_service
docker build -t sit722akprodacr.azurecr.io/frontend:latest ./frontend

# Push all images
docker push sit722akprodacr.azurecr.io/product_service:latest
docker push sit722akprodacr.azurecr.io/customer_service:latest
docker push sit722akprodacr.azurecr.io/order_service:latest
docker push sit722akprodacr.azurecr.io/frontend:latest
```

### Alternative: Build with Tags

For versioned deployments:
```bash
export IMAGE_TAG=$(git rev-parse --short HEAD)

# Build with specific tag
docker build -t sit722akprodacr.azurecr.io/product_service:$IMAGE_TAG ./backend/product_service
docker push sit722akprodacr.azurecr.io/product_service:$IMAGE_TAG
# Repeat for other services...
```

---

## 🧪 5. Staging Infrastructure (Local Deployment)

### Deploy Staging Infrastructure

The staging terraform uses the production storage container for state management, ensuring consistency between local and GitHub Actions deployments.

```bash
cd terraform/staging
terraform init
terraform apply
```

This creates:
- Staging Resource Group (`sit722akstagingrg`)
- Staging AKS cluster (`sit722akstagingaks`)
- Staging Storage Account (`sit722akstagestorage`)
- ACR pull permissions for staging AKS

### Verify Staging Deployment

```bash
terraform output
```

### Destroy Staging Infrastructure

```bash
cd terraform/staging
terraform destroy
```

**Note**: Staging infrastructure can be safely destroyed and recreated as needed.

---

## 🚀 6. Local Kubernetes Deployment

### Get AKS Credentials

For production deployment:
```bash
az aks get-credentials --resource-group sit722akprodrg --name sit722akprodaks --overwrite-existing
```

For staging deployment:
```bash
az aks get-credentials --resource-group sit722akstagingrg --name sit722akstagingaks --overwrite-existing
```

### Configure Container Images

Update the desired overlay (`k8s/overlays/prod/kustomization.yaml` or `k8s/overlays/staging/kustomization.yaml`) with your image tags:

```bash
cd k8s/overlays/prod
kustomize edit set image product_service=sit722akprodacr.azurecr.io/product_service:latest
kustomize edit set image order_service=sit722akprodacr.azurecr.io/order_service:latest
kustomize edit set image customer_service=sit722akprodacr.azurecr.io/customer_service:latest
kustomize edit set image frontend=sit722akprodacr.azurecr.io/frontend:latest
```

### Create Kubernetes Secrets

```bash
# Get storage account key
STORAGE_KEY=$(az storage account keys list \
  --resource-group sit722akprodrg \
  --account-name sit722akprodstorage \
  --query '[0].value' -o tsv)

# Create secrets
kubectl create secret generic global-secrets \
  --from-literal=POSTGRES_USER=postgres \
  --from-literal=POSTGRES_PASSWORD=postgres \
  --from-literal=RABBITMQ_USER=guest \
  --from-literal=RABBITMQ_PASS=guest \
  --from-literal=AZURE_STORAGE_ACCOUNT_NAME=sit722akprodstorage \
  --from-literal=AZURE_STORAGE_ACCOUNT_KEY=$STORAGE_KEY \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Deploy Application

```bash
kubectl apply -k k8s/overlays/prod
```

### Get External IPs and Update Frontend

1. **Wait for LoadBalancer IPs**:
```bash
kubectl get svc -w
```

2. **Update ConfigMap with real IPs**:
```bash
PRODUCT_IP=$(kubectl get svc product-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
ORDER_IP=$(kubectl get svc order-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
CUSTOMER_IP=$(kubectl get svc customer-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

kubectl create configmap global-config \
  --from-literal=PRODUCT_SERVICE_PUBLIC_URL=http://$PRODUCT_IP:8000 \
  --from-literal=ORDER_SERVICE_PUBLIC_URL=http://$ORDER_IP:8001 \
  --from-literal=CUSTOMER_SERVICE_PUBLIC_URL=http://$CUSTOMER_IP:8002 \
  --from-literal=PRODUCT_SERVICE_URL=http://product-service:8000 \
  --from-literal=ORDER_SERVICE_URL=http://order-service:8001 \
  --from-literal=CUSTOMER_SERVICE_URL=http://customer-service:8002 \
  --from-literal=RABBITMQ_HOST=rabbitmq \
  --from-literal=RABBITMQ_PORT=5672 \
  --from-literal=PRODUCT_DB_HOST=product-db \
  --from-literal=PRODUCT_DB_NAME=products \
  --from-literal=CUSTOMER_DB_HOST=customer-db \
  --from-literal=CUSTOMER_DB_NAME=customers \
  --from-literal=ORDER_DB_HOST=order-db \
  --from-literal=ORDER_DB_NAME=orders \
  --from-literal=AZURE_STORAGE_CONTAINER_NAME=images \
  --from-literal=AZURE_SAS_TOKEN_EXPIRY_HOURS=24 \
  --dry-run=client -o yaml | kubectl apply -f -
```

3. **Restart frontend to pick up new configuration**:
```bash
kubectl rollout restart deployment frontend
kubectl rollout status deployment/frontend --timeout=300s
```

### Cleanup Local Deployment

```bash
kubectl delete -k k8s/overlays/prod
```

---

## 🧪 7. Testing Pipeline (testing branch)

### Pipeline Trigger

The testing pipeline is triggered on pushes to the `testing` branch that modify:
- `backend/**`
- `.github/workflows/**`
- `terraform/**`
- `k8s/**`
- `tests/**`

### Pipeline Stages

1. **Backend Testing** (`test_backends`)
   - Spins up ephemeral PostgreSQL databases and RabbitMQ
   - Runs pytest for all three backend services
   - Uses GitHub Actions services for isolated testing

2. **Image Building** (`build_and_push_images`)
   - Builds Docker images for all services
   - Tags with commit SHA and `staging-latest`
   - Pushes to production ACR (shared resource)

3. **Infrastructure Provisioning** (`terraform_apply`)
   - Deploys staging infrastructure using Terraform
   - Uses OIDC authentication
   - Outputs infrastructure details for deployment

4. **Staging Deployment** (`deploy_to_staging`)
   - Deploys application to staging AKS
   - Dynamically updates Kustomize with commit SHA tags
   - Waits for LoadBalancer IPs
   - Updates ConfigMap with real service IPs
   - Restarts frontend with new configuration

5. **Integration Testing**
   - Runs acceptance tests against live staging environment
   - Tests all service endpoints and functionality
   - Validates cross-service communication

6. **Cleanup** (`cleanup_staging`)
   - Always runs (even if previous steps fail)
   - Destroys staging infrastructure to save costs
   - Uses Terraform destroy

### Key Features

- **Cost Optimization**: Automatic staging cleanup
- **Dynamic Configuration**: Real IP injection into ConfigMap
- **Comprehensive Testing**: Unit + Integration + Acceptance tests
- **Security**: OIDC authentication, no stored secrets
- **Isolation**: Each test run gets fresh infrastructure

---

## 🚀 8. Production Pipeline (main branch)

### Pipeline Trigger

The production pipeline is triggered on pushes to the `main` branch (typically via pull request merges).

### Pipeline Stages

1. **Production Image Building** (`build_and_push_prod_images`)
   - Builds Docker images for all services
   - Tags with commit SHA and `prod-latest`
   - Pushes to production ACR

2. **Production Deployment** (`deploy_to_production`)
   - Deploys to existing production AKS cluster
   - Updates Kustomize with commit SHA tags
   - Waits for LoadBalancer IPs
   - Updates ConfigMap with real service IPs
   - Restarts frontend with new configuration

### Key Features

- **Zero-Downtime Deployment**: Rolling updates with Kubernetes
- **Immutable Deployments**: Each deployment tagged with commit SHA
- **Production Safety**: No infrastructure changes, only application updates
- **Monitoring Ready**: External IPs available for monitoring setup

### Production Access

After deployment, services are available at:
- Product Service: `http://<PRODUCT_IP>:8000`
- Order Service: `http://<ORDER_IP>:8001`
- Customer Service: `http://<CUSTOMER_IP>:8002`
- Frontend: `http://<FRONTEND_IP>`

---

## 🔍 Monitoring and Troubleshooting

### Check Pipeline Status

```bash
# View GitHub Actions runs
gh run list

# View specific run details
gh run view <run-id>
```

### Debug Kubernetes Deployments

```bash
# Check pod status
kubectl get pods

# View pod logs
kubectl logs -f deployment/product-service

# Describe problematic pods
kubectl describe pod <pod-name>

# Check services and IPs
kubectl get svc
```

### Debug Terraform

```bash
# Check Terraform state
terraform show

# View outputs
terraform output

# Validate configuration
terraform validate
terraform plan
```

---

## 📁 Project Structure

```
├── .github/workflows/          # GitHub Actions pipelines
│   ├── testing-ci.yml         # Testing branch pipeline
│   └── production-ci.yml      # Production branch pipeline
├── backend/                   # Backend microservices
│   ├── customer_service/      # Customer management service
│   ├── order_service/         # Order management service
│   └── product_service/       # Product catalog service
├── frontend/                  # Frontend application
├── k8s/                      # Kubernetes manifests
│   ├── base/                 # Base Kubernetes resources
│   └── overlays/             # Environment-specific overlays
│       ├── local/            # Local development
│       ├── staging/          # Staging environment
│       └── prod/             # Production environment
├── terraform/                # Infrastructure as Code
│   ├── prod/                 # Production infrastructure
│   └── staging/              # Staging infrastructure
├── tests/                    # Integration tests
└── docker-compose.yml        # Local development setup
```

---

## 🎯 Development Workflow

1. **Feature Development**: Work on feature branches
2. **Testing**: Push to `testing` branch to trigger full pipeline
3. **Code Review**: Create pull request to `main` branch
4. **Production**: Merge PR triggers production deployment

This setup provides a complete CI/CD pipeline with proper testing, staging, and production deployment automation while maintaining cost efficiency through automated cleanup.