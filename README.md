# Deployment Guide

## Local Deployment Steps

Run the following steps to deploy the project locally on Azure using 
**Terraform** and **Kubernetes**. It will provision infrastructure with 
Terraform, configure secrets, build and push container images, and deploy 
services with Kubernetes.

### 1. Create `local.tfvars`
Create `./terraform/environments/local.tfvars` and supply your service 
principal credentials: 

```hcl
prefix             = "sit722aklocal"
subscription_id    = "<your-azure-subscription-id>"
tenant_id          = "<your-azure-tenant-id>"
client_id          = "<your-service-principal-app-id>"
client_secret      = "<your-service-principal-password>"
```

---

### 2. Provision Infrastructure with Terraform

```bash
terraform init
terraform apply -var-file="environments/local.tfvars"
```

This will create:
- Resource Group  
- Azure Kubernetes Service (AKS)  
- Azure Container Registry (ACR)  
- Storage Account  

Be sure to confirm that this file is added to `.gitignore` to avoid committing sensitive information.

To obtain the secrets needed later, run:
```bash
terraform output
```

---

### 3. Create Kubernetes Secrets

Create the file `./k8s/base/secrets.yaml`, replacing placeholders with actual values from Terraform output:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: global-secrets
type: Opaque
stringData:
  # Postgres credentials
  POSTGRES_USER: "postgres"
  POSTGRES_PASSWORD: "postgres"

  # RabbitMQ credentials
  RABBITMQ_USER: "guest"
  RABBITMQ_PASS: "guest"

  # Azure storage credentials
  AZURE_STORAGE_ACCOUNT_NAME: "sit722aklocalstorage"
  AZURE_STORAGE_ACCOUNT_KEY: "<replace-with-storage-account-key>"

```

Be sure to confirm that this file is added to `.gitignore` to avoid committing sensitive information.

---

### 4. Log in to Azure & Kubernetes

Authenticate:

```bash
az login
az aks get-credentials --resource-group sit722aklocalrg --name sit722aklocalaks
```

Login to ACR:

```bash
az acr login --name sit722aklocalacr
```

---

### 5. Build, Tag & Push Docker Images

```bash
docker build -t sit722aklocalacr.azurecr.io/product_service:latest ./backend/product_service
docker build -t sit722aklocalacr.azurecr.io/customer_service:latest ./backend/customer_service
docker build -t sit722aklocalacr.azurecr.io/order_service:latest ./backend/order_service
docker build -t sit722aklocalacr.azurecr.io/frontend:latest ./frontend
docker push sit722aklocalacr.azurecr.io/product_service:latest
docker push sit722aklocalacr.azurecr.io/customer_service:latest
docker push sit722aklocalacr.azurecr.io/order_service:latest
docker push sit722aklocalacr.azurecr.io/frontend:latest
```

---

### 6. Deploy Project with Kubernetes

```bash
kubectl apply -k k8s/overlays/local
```

---

### 7. Fetch Public IPs

Get external service IPs:

```bash
kubectl get svc
```

Note the `EXTERNAL-IP` values for:
- `product-service`
- `order-service`
- `customer-service`

---

### 8. Update Frontend

Edit `k8s/base/configmap.yaml` and replace Public service URLs with the URLs 
obtained from above:

```yaml
PRODUCT_SERVICE_PUBLIC_URL: http://<product-service-external-ip>:8000
ORDER_SERVICE_PUBLIC_URL: http://<order-service-external-ip>:8001
CUSTOMER_SERVICE_PUBLIC_URL: http://<customer-service-external-ip>:8002
```

Then restart the frontend deployment to apply changes:

```bash
kubectl apply -k k8s/overlays/local
kubectl rollout restart deployment frontend
```

---

### 9. Cleanup

#### Remove Kubernetes resources:

```bash
kubectl delete -k k8s/overlays/local
```

#### Destroy Terraform infrastructure:

```bash
terraform destroy -var-file="environments/local.tfvars"
```
