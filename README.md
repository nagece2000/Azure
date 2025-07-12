# Azure Infrastructure as Code (IaC) Templates
This repository contains ARM templates and scripts for deploying Azure lab environments and infrastructure using modular, reusable templates.

## Repository Structure

- **lab-setup/** - Main lab environment directory
  - **ARM/** - ARM templates and related files
    - **templates/** - ARM template definitions
    - **parameters/** - Environment-specific parameter files
    - **scripts/** - Deployment and management scripts

### 1. Resource Group Template
**File**: `lab-setup/ARM/templates/resource-group.json`  
**Purpose**: Creates resource groups with standardized tags  
**Deployment Level**: Subscription 

**Deploy Command**:
```powershell
New-AzSubscriptionDeployment `
    -Location "East US" `
    -TemplateUri "https://raw.githubusercontent.com/nagece2000/Azure/main/lab-setup/ARM/templates/resource-group.json" `
    -resourceGroupName "your-rg-name"
```

**Parameters**:
- resourceGroupName (string): Name of the resource group to create
- location (string): Azure region `(default: "East US")`

### 1. Virtual Network Template
**File**: `lab-setup/ARM/templates/virtual-network.json`  
**Purpose**: Creates VNet with multiple subnets for networking labs 
**Deployment Level**: Resource Group 

**Deploy Command**:
```powershell
New-AzResourceGroupDeployment `
    -ResourceGroupName "your-rg-name" `
    -TemplateUri "https://raw.githubusercontent.com/nagece2000/Azure/main/lab-setup/ARM/templates/virtual-network.json" `
    -vnetName "your-vnet-name"
```

**Parameters**:
- vnetName (string): Name of the virtual network
- vnetAddressSpace (string): VNet CIDR `(default: "10.1.0.0/16")`
- location (string): Azure region `(default: resource group location)`
- 
