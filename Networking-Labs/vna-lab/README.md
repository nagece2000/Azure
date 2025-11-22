# Azure Network Virtual Appliance (NVA) Lab
## VNet Peering vs NVA: A Practical Comparison

### 🎯 Project Overview

This lab demonstrates the differences between Azure VNet Peering and routing through a Network Virtual Appliance (NVA). Through hands-on implementation, we explore when simple VNet peering is sufficient and when an NVA solution provides critical capabilities that peering cannot deliver.

**Key Question:** When is VNet peering not enough?

### 🏗️ Architecture

**Hub-and-Spoke Topology:**
```
        Hub VNet (10.0.0.0/16)
              |
         NVA (10.0.1.4)
            /    \
           /      \
    Spoke1 VNet   Spoke2 VNet
   (10.1.0.0/16) (10.2.0.0/16)
```

### 📋 What We Built

- **3 Virtual Networks** (Hub, Spoke1, Spoke2)
- **3 Ubuntu VMs** (2 test VMs + 1 NVA)
- **Network Security Groups** (Subnet-level)
- **Route Tables (UDRs)** for traffic routing
- **Configured Linux NVA** with iptables

### ✅ What You'll Learn

1. Infrastructure as Code with Terraform
2. VNet Peering capabilities and limitations
3. Hub-and-Spoke network topology
4. Configuring a Linux VM as an NVA
5. User Defined Routes (UDRs)
6. Selective traffic control with iptables
7. Troubleshooting Azure networking

### 🛠️ Prerequisites

**Tools Required:**
- Terraform (v1.0+)
- Azure CLI (v2.0.79+)
- SSH client
- Azure subscription

**Knowledge:**
- Basic Azure networking concepts

- ## 🔐 Authentication Setup

This lab uses Azure Service Principal authentication for Terraform, which is more secure and suitable for automation compared to Azure CLI authentication.

### Why Service Principal?

- ✅ No dependency on Azure CLI being in PATH
- ✅ Works in CI/CD pipelines
- ✅ Explicitly defined credentials
- ✅ Can be scoped to specific permissions
- ✅ Better for automation and team environments

### Create Service Principal

**Option 1: Using Azure Portal**

1. Navigate to **Azure Active Directory** (or **Microsoft Entra ID**)
2. Go to **App registrations** → **New registration**
   - Name: `terraform-vna-lab`
   - Account type: "Accounts in this organizational directory only"
   - Click **Register**

3. Note the **Application (client) ID** and **Directory (tenant) ID**

4. Create a client secret:
   - Go to **Certificates & secrets** → **New client secret**
   - Description: `terraform-secret`
   - Expiry: Choose duration (e.g., 24 months)
   - Click **Add**
   - **⚠️ Copy the secret value immediately** (you can't see it again!)

5. Assign permissions:
   - Go to **Subscriptions** → Select your subscription
   - Click **Access control (IAM)** → **Add role assignment**
   - Role: **Contributor**
   - Assign access to: Your service principal (`terraform-vna-lab`)

**Option 2: Using Azure CLI**
```bash
az ad sp create-for-rbac --name "terraform-vna-lab" \
  --role="Contributor" \
  --scopes="/subscriptions/<YOUR_SUBSCRIPTION_ID>"
```

### Configure Terraform Authentication

Set environment variables (session-based):
```cmd
# Windows Command Prompt
set ARM_CLIENT_ID=<your-client-id>
set ARM_CLIENT_SECRET=<your-client-secret>
set ARM_SUBSCRIPTION_ID=<your-subscription-id>
set ARM_TENANT_ID=<your-tenant-id>
```
```bash
# Linux/Mac/WSL
export ARM_CLIENT_ID="<your-client-id>"
export ARM_CLIENT_SECRET="<your-client-secret>"
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
export ARM_TENANT_ID="<your-tenant-id>"
```

### Important Security Notes

⚠️ **Never commit secrets to Git!**
- Add `terraform.tfvars` to `.gitignore`
- Add `*.tfvars` to `.gitignore` (except `*.tfvars.example`)
- Never hardcode credentials in Terraform files
- Basic Linux command line
- Basic understanding of IaC principles
