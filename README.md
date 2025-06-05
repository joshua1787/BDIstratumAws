# 🚀 Project Stratum: Cloud-Native Backend Deployment on AWS EKS

A robust, scalable, and secure backend API for customer interactions, deployed on Amazon Elastic Kubernetes Service (EKS) using a comprehensive Infrastructure as Code (IaC) approach with Terraform and Helm.

## ✨ Project Overview

Project Stratum is a FastAPI-based backend application designed to manage customer interactions. This repository showcases a full-stack cloud-native deployment, emphasizing automation, scalability, and secure operational practices. It's built to demonstrate end-to-end deployment capabilities from application code to cloud infrastructure.

## 🌟 Key Features

- **RESTful API:** Provides standard CRUD operations for `CustomerInteraction` records.
- **Containerized Application:** Packaged with Docker for portability and consistency across environments.
- **Automated Infrastructure:** Full AWS infrastructure provisioning using Terraform.
- **Managed Database:** Utilizes AWS RDS for a highly available PostgreSQL database.
- **Scalable Orchestration:** Deployed to AWS EKS for robust container management and scaling.
- **Secure Credential Handling:** Integrates with AWS Secrets Manager for database credentials, accessed securely via IAM Roles for Service Accounts (IRSA).
- **External Access:** Exposed via an AWS Application Load Balancer (ALB) provisioned through Kubernetes Ingress.
- **Deployment Automation:** Packaged as a Helm chart for streamlined Kubernetes deployments and lifecycle management.

## 🛠️ Technologies Used

| Category | Technology | Description |
| --- | --- | --- |
| **Backend Application** | FastAPI, SQLAlchemy, PostgreSQL | Python backend framework, ORM, and relational database. |
| **Containerization** | Docker, AWS ECR | Containerization platform and AWS's managed container registry. |
| **Cloud Infrastructure** | AWS, EKS, RDS, Secrets Manager, ALB | Cloud provider, managed Kubernetes, managed database, secrets, and load balancing. |
| **Infrastructure as Code** | Terraform | Declarative IaC tool for provisioning and managing cloud resources. |
| **Orchestration** | Kubernetes, Helm | Container orchestration platform and its package manager for Kubernetes. |
| **Security Concepts** | IAM Roles for Service Accounts (IRSA) | Secure method for Kubernetes pods to access AWS services. |

## 🏗️ Architecture Overview

The project is deployed on AWS and follows a modern cloud-native architecture:

1. **VPC (Virtual Private Cloud):** A dedicated, isolated network with public and private subnets, and NAT Gateways for secure outbound internet access from private resources.
2. **AWS RDS (PostgreSQL):** A managed PostgreSQL database instance deployed in private subnets for high availability and security. Database credentials are securely stored in AWS Secrets Manager.
3. **AWS EKS (Elastic Kubernetes Service):** A managed Kubernetes cluster with worker nodes in private subnets.
4. **IAM Roles for Service Accounts (IRSA):** Kubernetes Service Accounts are explicitly mapped to AWS IAM roles, allowing backend pods to securely retrieve database credentials from Secrets Manager without hardcoding AWS access keys.
5. **AWS ECR (Elastic Container Registry):** A private Docker image repository for storing the backend application's container image.
6. **AWS Application Load Balancer (ALB):** Provisioned by the AWS Load Balancer Controller (running in EKS), this acts as the entry point for external traffic, routing requests to the backend application running in EKS.
7. **Helm Chart:** The entire backend application (Deployment, Service, Ingress, Service Account) is packaged as a Helm chart for consistent, repeatable, and manageable deployments to Kubernetes.

```
graph TD
    A[YOUR LOCAL MACHINE] -->|1. Terraform Apply| B(AWS Cloud);
    B --> C{AWS VPC};
    C --> D[Public Subnets];
    C --> E[Private Subnets];
    D --> F(ALB);
    E --> G(EKS Worker Nodes);
    G --> H(Pods: stratum-backend FastAPI app);
    H -->|Access via IRSA| I[AWS Secrets Manager<br>(DB Credentials)];
    E --> J(AWS RDS<br>(PostgreSQL));
    H -->|Pull image from| K(AWS ECR);
    F -->|Traffic Ingress| H;
    A -->|2. Docker Build & Push| K;
    A -->|3. Helm Install| B;
    B --> L(AWS Load Balancer Controller<br>(Helm Deployed in EKS));
    L --> F;
    L -->|Manages| F;
    H -->|Connects to| J;
    G -->|Contains| H;
    F -->|Routes to Service| M(Kubernetes Service<br>stratum-backend-svc);
    M --> N(Kubernetes Deployment<br>stratum-backend-app);
    N --> H;

```

## 📂 Project Structure

```
Stratum_JD_AWS/
├── backend/                  # FastAPI application code
│   ├── Dockerfile            # Defines Docker image build steps
│   ├── main.py               # FastAPI application entry point, API routes
│   ├── models.py             # SQLAlchemy models for database, Pydantic schemas for API
│   ├── database.py           # SQLAlchemy engine, session setup, Secrets Manager integration
│   ├── config.py             # Basic configuration variables
│   └── requirements.txt      # Python dependencies
├── terraform/                # Root Terraform configuration
│   ├── main.tf               # Orchestrates module calls and defines root outputs
│   ├── variables.tf          # Root variables with defaults for AWS region, project naming, etc.
│   ├── outputs.tf            # Exports key infrastructure IDs, ARNs, and endpoints
│   ├── terraform.tfvars      # (Optional) Override default variables here for specific deployments
│   └── modules/              # Reusable Terraform modules
│       ├── vpc/              # VPC, subnets, NAT Gateways, routing tables
│       ├── rds/              # RDS PostgreSQL instance, DB Subnet Group, Security Group, Secrets Manager
│       ├── eks/              # EKS cluster, managed node groups, IAM roles for EKS/IRSA
│       └── ecr/              # ECR repository for Docker images
└── helm-charts/
    └── stratum-backend-chart/ # Helm Chart for the backend application
        ├── Chart.yaml        # Helm chart metadata
        ├── values.yaml       # Customizable values for the chart (image, env, resources, etc.)
        └── templates/        # Kubernetes manifests templated with GoLang
            ├── _helpers.tpl  # Custom Helm template helpers
            ├── namespace.yaml
            ├── serviceaccount.yaml
            ├── deployment.yaml
            ├── service.yaml
            └── ingress.yaml

```

## 🚀 Setup and Deployment Guide

Follow these steps precisely to deploy the entire stack to your AWS account.

### 1. Prerequisites Installation

Ensure these tools are installed and configured on your local machine:

- **AWS CLI v2:** Follow official [installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
    - Configure: `aws configure` (Ensure your AWS user has `AdministratorAccess` for simplicity, or specific permissions for EKS, EC2, RDS, IAM, ECR, S3, Secrets Manager).
- **Docker:** Follow official [installation guide](https://docs.docker.com/get-docker/).
- **Terraform:** Follow official [installation guide](https://developer.hashicorp.com/terraform/downloads).
- **kubectl:** Follow official [installation guide](https://kubernetes.io/docs/tasks/tools/install-kubectl/).
- **Helm:** Follow official [installation guide](https://helm.sh/docs/intro/install/).

### 2. Project Setup & File Population

1. **Clone this Repository (or Create Project Directory):**
If you're provided with a ZIP, extract it. Otherwise, create the `Stratum_JD_AWS` root directory and then the internal structure (`backend`, `terraform`, `helm-charts`, `modules`, `templates` folders) as per the `Project Structure` above.
2. **Populate All Files:**
Copy the code for `main.py`, `models.py`, `database.py`, `config.py`, `requirements.txt`, `Dockerfile` into the `backend/` directory.
Copy all `.tf` files into their respective `terraform/` and `terraform/modules/` directories.
Copy all Helm `.yaml` and `.tpl` files into `helm-charts/stratum-backend-chart/` and its `templates/` subdirectory.

### 3. Identify and Fill Placeholders (Crucial!)

You need to gather specific AWS details and fill in all `YOUR_...` placeholders in your Terraform `variables.tf` (if overriding defaults) and **especially** in your Helm `values.yaml`.

1. **Get Your AWS Account ID:**
    
    ```
    aws sts get-caller-identity --query Account --output text
    # Copy this 12-digit number (e.g., 123456789012)
    
    ```
    
    This is `YOUR_AWS_ACCOUNT_ID`.
    
2. **Get Your Current Public IPv4 Address:**
Go to https://whatismyip.com/ in your browser. Note your IPv4 address (e.g., `117.196.36.92`).
This is `YOUR_CURRENT_PUBLIC_IP`. You'll use it in CIDR notation: `YOUR_CURRENT_PUBLIC_IP/32`.
3. **Fill in `terraform/variables.tf` (Optional, if overriding defaults):**
Open `~/Stratum_JD_AWS/terraform/variables.tf`.
    
    ```
    nano terraform/variables.tf
    
    ```
    
    - `aws_region`: Confirm or change `default = "us-east-1"` to your desired region.
    - `availability_zones`: **IMPORTANT!** Change `default = ["us-east-1a", "us-east-1b"]` to valid AZs for your chosen `aws_region`.
    - `eks_cluster_endpoint_public_access_cidrs`: For testing, `["0.0.0.0/0"]` is default. **For production, change to `default = ["YOUR_CURRENT_PUBLIC_IP/32"]` using your actual IP for security.**
    - `temporary_db_access_cidrs`: If you want direct access to the DB from your machine for debugging, uncomment and add `default = ["YOUR_CURRENT_PUBLIC_IP/32"]` here.
    Save and exit.

### 4. Terraform Infrastructure Provisioning

Navigate to your Terraform root directory:

```
cd ~/Stratum_JD_AWS/terraform/

```

1. **Initialize Terraform:**
    
    ```
    terraform init -upgrade
    
    ```
    
2. **Review Terraform Plan:**
    
    ```
    terraform plan
    
    ```
    
    Review all the resources Terraform proposes to create. This will be extensive.
    
3. **Apply Terraform Changes:**
    
    ```
    terraform apply
    
    ```
    
    Type `yes` when prompted. **This step will take a significant amount of time (20-40 minutes)** as it provisions the EKS cluster and RDS instance. Be patient.
    
4. **Capture Terraform Outputs (After `apply` completes):**
These outputs are essential for your Helm chart configuration.
    
    ```
    terraform output ecr_repository_url_backend
    terraform output backend_service_account_role_arn
    terraform output aws_lb_controller_role_arn
    terraform output eks_cluster_name
    terraform output vpc_id
    terraform output rds_db_credentials_secret_arn
    
    ```
    
    **Copy all these output values carefully.**
    

### 5. Docker Image Build and Push

Navigate to your backend application directory:

```
cd ~/Stratum_JD_AWS/backend/

```

1. **Authenticate Docker to ECR:**
    
    ```
    aws ecr get-login-password --region YOUR_AWS_REGION | docker login --username AWS --password-stdin YOUR_AWS_ACCOUNT_ID.dkr.ecr.YOUR_AWS_REGION.amazonaws.com
    
    ```
    
    Replace `YOUR_AWS_REGION` and `YOUR_AWS_ACCOUNT_ID` with your actual values.
    
2. **Generate Unique Image Tag:**
Using a unique timestamp ensures Kubernetes always pulls the fresh image.
    
    ```
    IMAGE_TAG=$(date +%Y%m%d%H%M%S)
    echo "Using image tag: $IMAGE_TAG"
    # Copy this exact timestamp (e.g., 20250605123456). This is YOUR_IMAGE_TAG.
    
    ```
    
3. **Build Docker Image (with no-cache for clean build):**
    
    ```
    docker build --no-cache -t stratum-backend:$IMAGE_TAG .
    
    ```
    
4. **Tag and Push Image to ECR:**
Replace `YOUR_ECR_REPOSITORY_URL_HERE` with the actual ECR URL you got from `terraform output ecr_repository_url_backend`.
    
    ```
    docker tag stratum-backend:$IMAGE_TAG YOUR_ECR_REPOSITORY_URL_HERE:$IMAGE_TAG
    docker push YOUR_ECR_REPOSITORY_URL_HERE:$IMAGE_TAG
    
    ```
    

### 6. Configure Helm Chart `values.yaml`

Navigate to your Helm chart's root:

```
cd ~/Stratum_JD_AWS/helm-charts/stratum-backend-chart/

```

1. **Open `values.yaml` for editing:**
    
    ```
    nano values.yaml
    
    ```
    
2. **Fill in all `YOUR_...` placeholders accurately:**
    - `image.repository`: Paste the ECR URL from `terraform output ecr_repository_url_backend`.
    - `image.tag`: Paste the `IMAGE_TAG` (timestamp) you generated in step 5.2.
    - `serviceAccount.annotations."eks.amazonaws.com/role-arn"`: Paste the ARN from `terraform output backend_service_account_role_arn`.
    - `env.dbCredentialsSecretArn`: Paste the ARN from `terraform output rds_db_credentials_secret_arn`.
    - `env.awsRegion`: Paste your AWS region.
    - *(Optional)* `ingress.annotations.alb.ingress.kubernetes.io/certificate-arn`: If you want HTTPS, uncomment and provide your ACM certificate ARN here.
    
    **Save and exit `values.yaml`.**
    

### 7. Deploy Application with Helm

1. **Configure kubectl Context:**
    
    ```
    aws eks update-kubeconfig --name YOUR_EKS_CLUSTER_NAME --region YOUR_AWS_REGION
    # Replace YOUR_EKS_CLUSTER_NAME (from terraform output eks_cluster_name) and YOUR_AWS_REGION
    
    ```
    
2. **Add Helm Repository for ALB Controller:**
    
    ```
    helm repo add aws-load-balancer-controller https://aws.github.io/eks-charts
    helm repo update
    
    ```
    
3. **Install AWS Load Balancer Controller:**
Navigate to your `kubernetes` folder:
    
    ```
    cd ~/Stratum_JD_AWS/kubernetes/
    
    ```
    
    If you've previously installed the ALB Controller via `kubectl apply -f setup.yaml`, ensure it's deleted. Helm will manage it now.
    
    ```
    # If setup.yaml exists and was applied:
    # kubectl delete -f setup.yaml # (If this file exists in your kubernetes folder)
    
    ```
    
    Install the ALB Controller using Helm. Replace placeholders with actual values:
    
    ```
    helm install aws-load-balancer-controller aws-load-balancer-controller/aws-load-balancer-controller \
      -n kube-system \
      --set clusterName=YOUR_EKS_CLUSTER_NAME \
      --set serviceAccount.create=false \
      --set serviceAccount.name=aws-load-balancer-controller \
      --set image.repository=602401143452.dkr.ecr.YOUR_AWS_REGION.amazonaws.com/amazon/aws-load-balancer-controller \
      --set defaultTags.Environment=Dev \
      --set defaultTags.Project=Stratum \
      --set defaultTags.Service=ALBC \
      --set region=YOUR_AWS_REGION \
      --set vpcId=YOUR_VPC_ID \
      --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="YOUR_LB_CONTROLLER_ROLE_ARN"
    
    ```
    
    Verify ALB Controller pods are running:
    
    ```
    kubectl get deployment aws-load-balancer-controller -n kube-system
    kubectl get pods -l app.kubernetes.io/name=aws-load-balancer-controller -n kube-system
    
    ```
    
    Ensure they are `1/1 READY` and `Running`.
    
4. **Lint Your Backend Helm Chart:**
Navigate to your Helm chart's root:
    
    ```
    cd ~/Stratum_JD_AWS/helm-charts/stratum-backend-chart/
    helm lint .
    
    ```
    
    **Expected Outcome:** `0 chart(s) failed`. (If it fails, fix errors based on output).
    
5. **Clean Up Namespace (Important for a fresh Helm install):**
This step ensures a clean slate for Helm to manage the namespace.
    
    ```
    kubectl delete namespace stratum-ns
    
    ```
    
    **Wait for deletion to complete:**
    
    ```
    kubectl get namespace stratum-ns
    # Keep running this until it returns "Error from server (NotFound): namespaces "stratum-ns" not found"
    
    ```
    
6. **Install Your Backend Helm Chart:**
    
    ```
    helm install stratum-backend . -n stratum-ns --create-namespace
    
    ```
    
    **Expected Outcome:** Successful Helm release installation message.
    

## 8. Verify Application Deployment & Test

1. **Monitor Kubernetes Pods:**
    
    ```
    kubectl get pods -n stratum-ns
    
    ```
    
    Wait for `stratum-backend-deployment-XXXXX` pods to show `1/1 READY` and `Running` status. This may take a few minutes.
    
    - **If pods are still crashing (`CrashLoopBackOff`):** Get logs: `kubectl logs <POD_NAME> -n stratum-ns`. Debug the new error message.
2. **Verify All Kubernetes Resources:**
    
    ```
    kubectl get all -n stratum-ns
    
    ```
    
    This shows your deployment, service, pods, and ingress.
    
3. **Get Application Load Balancer (ALB) DNS Name:**
The ALB provisioning takes a few minutes after the Ingress is created.
    
    ```
    kubectl get ingress stratum-backend-ingress -n stratum-ns -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
    
    ```
    
    Copy the DNS name (e.g., `k8s-strumbac-abcde12345-1234567890.us-east-1.elb.amazonaws.com`).
    
4. **Test Your Application (External Access):**
Open your web browser and navigate to `http://YOUR_ALB_DNS_NAME/`.
You should see: `{"message": "Welcome to Stratum Backend API!"}`.
You can also test API endpoints like `http://YOUR_ALB_DNS_NAME/interactions/`.

## 9. Local Development (Optional)

You can run the backend application locally without deploying to AWS EKS for development and testing.

1. **Navigate to backend directory:**
    
    ```
    cd ~/Stratum_JD_AWS/backend/
    
    ```
    
2. **Install dependencies:**
    
    ```
    pip install -r requirements.txt
    
    ```
    
3. **Set a local SQLite database URL (optional, if you don't want to connect to RDS):**
    
    ```
    export DATABASE_URL="sqlite:///./local_sql_app.db"
    
    ```
    
    *(If you want to connect to your RDS instance locally, you would set `DATABASE_URL` to its endpoint and ensure your local IP is allowed in the RDS security group.)*
    
4. **Run the application:**
    
    ```
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload
    
    ```
    
    Access at `http://localhost:8000`.
    

## 10. Cleanup (IMPORTANT to avoid ongoing AWS costs!)

When you are finished with the project (especially after submission), delete all deployed resources to avoid incurring ongoing AWS charges.

1. **Uninstall Helm Release:**
    
    ```
    cd ~/Stratum_JD_AWS/helm-charts/stratum-backend-chart/
    helm uninstall stratum-backend -n stratum-ns
    
    ```
    
2. **Uninstall AWS Load Balancer Controller:**
    
    ```
    # Go to your kubernetes folder or any directory
    cd ~/Stratum_JD_AWS/kubernetes/
    helm uninstall aws-load-balancer-controller -n kube-system
    
    ```
    
3. **Delete `stratum-ns` Namespace:**
    
    ```
    kubectl delete namespace stratum-ns
    
    ```
    
4. **Destroy Terraform Infrastructure:**
Navigate to your Terraform root:
    
    ```
    cd ~/Stratum_JD_AWS/terraform/
    terraform destroy
    
    ```
    
    Type `yes` when prompted. This will remove all AWS resources created by Terraform (VPC, EKS, RDS, ECR, IAM roles). This step also takes significant time.
    

