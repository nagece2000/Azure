## 🏗️ Infrastructure Deployment with Terraform

### Project Structure
```
vna-lab/
├── README.md
├── terraform/
│   ├── main.tf
│   ├── terraform.tfvars.example
│   └── .gitignore
├── images/
└── scripts/
```

### Setup Steps

**1. Clone the Repository**
```bash
git clone https://github.com/nagece2000/Azure.git
cd Azure/Networking-Labs/vna-lab/terraform
```

**2. Generate SSH Key**
```bash
# Generate SSH key pair for VM access
ssh-keygen -t rsa -b 4096 -f vna-lab-key
# This creates: vna-lab-key (private) and vna-lab-key.pub (public)
```

**3. Get Your Public IP**
```bash
# Windows
curl ifconfig.me

# Linux/Mac
curl ifconfig.me
```

**4. Configure Variables**
```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# - Add your SSH public key (content of vna-lab-key.pub)
# - Add your public IP with /32 suffix
```

**5. Initialize Terraform**
```bash
terraform init
```

This downloads the Azure provider and prepares the working directory.

**6. Review the Plan**
```bash
terraform plan
```

Expected output: Plan to create ~18 resources (VNets, VMs, NSGs, etc.)

**7. Deploy Infrastructure**
```bash
terraform apply
```

Type `yes` when prompted. Deployment takes 5-10 minutes.

**8. Save Outputs**
```bash
terraform output > outputs.txt
```

This saves the VM IPs for easy reference.

### What Gets Created

**Networking:**
- 3 Virtual Networks (Hub, Spoke1, Spoke2)
- 6 Subnets (2 per VNet)
- 3 Network Security Groups (subnet-level)
- 3 Public IPs (for SSH access)
- 2 VNet Peerings (Hub ↔ Spoke1, Hub ↔ Spoke2)

**Compute:**
- 3 Ubuntu 22.04 VMs (Standard_B1s)
  - spoke1-vm (10.1.1.4)
  - spoke2-vm (10.2.1.4)
  - nva-vm (10.0.1.4)
- 3 Network Interfaces (with NVA NIC having IP forwarding enabled)

**Security:**
- SSH access restricted to your public IP
- Inter-VNet traffic allowed via NSG rules

### Cost Estimate

Approximate costs for running this lab:

| Resource | Cost |
|----------|------|
| 3 × B1s VMs | ~$23/month (~$0.75/day) |
| 3 × Public IPs (Standard) | ~$0.50/month |
| VNet/NSG/Routes | Free |
| **Total** | **~$24/month** |

💡 **Cost Saving Tip:** Stop (deallocate) VMs when not using:
```bash
az vm deallocate --resource-group rg-vna-lab --name spoke1-vm --no-wait
az vm deallocate --resource-group rg-vna-lab --name spoke2-vm --no-wait
az vm deallocate --resource-group rg-vna-lab --name nva-vm --no-wait
```

### Verify Deployment

**Check VMs are running:**
```bash
az vm list --resource-group rg-vna-lab --show-details --output table
```

**Test SSH access:**
```bash
ssh -i vna-lab-key azureuser@<spoke1-public-ip>
```
