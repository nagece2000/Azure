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

### 2. Virtual Network Template
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

**Creates**:
- Virtual Network with custom address space
- web-subnet `(x.x.1.0/24)`
- app-subnet `(x.x.2.0/24)`

### 3. Storage Account Template
**File**: `lab-setup/ARM/templates/storage-account.json`  
**Purpose**: Creates secure storage accounts for VM disks and diagnostics  
**Deployment Level**: Resource Group 

**Deploy Command**:
```powershell
New-AzResourceGroupDeployment `
    -ResourceGroupName "your-rg-name" `
    -TemplateUri "https://raw.githubusercontent.com/nagece2000/Azure/main/lab-setup/ARM/templates/storage-account.json" `
    -storageAccountName "yourstorageaccount123"
```

**Parameters**:
- storageAccountName (string): Globally unique storage account name
- storageAccountType (string): Replication type `(default: "Standard_LRS")`
- location (string): Azure region `(default: resource group location)`

**Features**:
- Cool access tier `(cost-optimized)`
- Security best practices (HTTPS-only, TLS 1.2)
- Encryption enabled
- No public blob access

### 4. Virtual Machine Template
**File**: `lab-setup/ARM/templates/virtual-machine.json`  
**Purpose**: Creates Linux VMs for networking labs and testing 
**Deployment Level**: Resource Group 

**Deploy Command**:
```powershell
New-AzResourceGroupDeployment `
    -ResourceGroupName "your-rg-name" `
    -TemplateUri "https://raw.githubusercontent.com/nagece2000/Azure/main/lab-setup/ARM/templates/virtual-machine.json" `
    -vmName "your-vm-name" `
    -adminUsername "labadmin" `
    -subnetId "/subscriptions/.../subnets/subnet-name" `
    -storageAccountName "yourstorageaccount"
```

**Parameters**:
- vmName (string): Name of the virtual machine
- vmSize (string): VM size (default: "Standard_B1s") - Azure Policy compliant
- adminUsername (string): Admin username for SSH access
- adminPassword (securestring): Admin password
- subnetId (string): Resource ID of target subnet
- storageAccountName (string): Storage account for boot diagnostics
- location (string): Azure region `(default: resource group location)`

**Creates**:
- Ubuntu 22.04 LTS Virtual Machine
- Standard SKU Public IP (Static allocation)
- Network Interface connected to specified subnet
- Boot diagnostics enabled
- SSH ready `(requires NSG configuration for access)`

## Current Deployed Infrastructure

### Lab Environment 1 ✅ COMPLETE
- **Resource Group**: networking-lab-rg-1
- **Virtual Network**: lab-vnet-1 (10.1.0.0/16)
- web-subnet: 10.1.1.0/24
- app-subnet: 10.1.2.0/24
- **Storage Account**: Secure storage for VM disks and diagnostics
  - **Virtual Machine**: lab-vm-1 `(Ubuntu 22.04 LTS)`
  - Public IP: Ready for SSH `(requires NSG configuration)`
  - Private IP: 10.1.1.4 `(web-subnet)`
  - SSH Command: `ssh labadmin@[public-ip]`

## Infrastructure As Code
- **All resources deployed** using modular ARM templates from GitHub
- **URL-based deployment** workflow validated
- **Azure Policy compliance** verified `(VM sizes restricted)`

## Template Status
- [x] Resource Group template ✅
- [x] Virtual Network template ✅
- [x] Storage Account template ✅
- [x] Virtual Machine template ✅
- [ ] Network Security Group template (for SSH/security testing)
- [ ] Complete multi-VM networking lab deployment
- [ ] VNet Peering configuration

