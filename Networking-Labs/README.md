# NSG and VNet Peering Lab

## Overview
This lab demonstrates Azure Network Security Groups (NSGs) and VNet Peering by creating two Ubuntu VMs in separate VNets and establishing secure communication between them.

## Architecture
```
Internet → NSG Rules → VM-1 (10.1.1.x) ←→ VNet Peering ←→ VM-2 (10.2.1.x)
              ↓                                              ↓
    lab-vnet-1 (10.1.0.0/16)                    lab-vnet-2 (10.2.0.0/16)
         web-subnet (10.1.1.0/24)                   web-subnet (10.2.1.0/24)
         app-subnet (10.1.2.0/24)                   app-subnet (10.2.2.0/24)
```

## Lab Components

### Virtual Networks
- **lab-vnet-1**: 10.1.0.0/16 (networking-lab-rg-1)
  - web-subnet: 10.1.1.0/24
  - app-subnet: 10.1.2.0/24
- **lab-vnet-2**: 10.2.0.0/16 (networking-lab-rg-2)
  - web-subnet: 10.2.1.0/24
  - app-subnet: 10.2.2.0/24

### Virtual Machines
- **lab-vm-1**: Ubuntu 22.04 (Standard_B1s) in lab-vnet-1/web-subnet
- **lab-vm-2**: Ubuntu 22.04 (Standard_B1s) in lab-vnet-2/web-subnet

### Network Security Group (nsg-lab-1)
Applied to both subnets with the following inbound rules:

| Priority | Name | Source | Destination | Service | Action |
|----------|------|--------|-------------|---------|--------|
| 100 | AllowSSHInternet | Your Public IP | Any | SSH (22) | Allow |
| 110 | AllowVM1toVM2 | 10.2.1.0/24 | 10.1.1.0/24 | SSH (22) | Allow |
| 120 | AllowVM2toVM1 | 10.1.1.0/24 | 10.2.1.0/24 | SSH (22) | Allow |

## Deployment Process

### 1. Infrastructure Setup
```powershell
# Create VMs using ARM template
New-AzResourceGroupDeployment `
    -ResourceGroupName "networking-lab-rg-1" `
    -TemplateUri "https://raw.githubusercontent.com/nagece2000/Azure/main/ARM/templates/virtual-machine.json" `
    -vmName "lab-vm-1" `
    -vmSize "Standard_B1s" `
    -adminUsername "labadmin" `
    -subnetId $subnetId1 `
    -storageAccountName "labstorage12048" `
    -osDiskType "StandardSSD_LRS" `
    -osDiskSizeGB 30
```

### 2. Network Security Group Configuration
1. Created NSG: `nsg-lab-1`
2. Added inbound rules for SSH access
3. Associated NSG with both subnets

### 3. VNet Peering Setup
1. Configured bidirectional peering between lab-vnet-1 and lab-vnet-2
2. Enabled traffic forwarding and gateway transit options

## Key Learnings

### NSG Rule Configuration
- **Source Port Range**: Use `*` (any) for client connections, not specific ports
- **Destination Port Range**: Specify service ports (22 for SSH, 80 for HTTP)
- **Rule Priority**: Lower numbers = higher priority (100 beats 500)
- **Subnet-based Rules**: More scalable than VM-specific IP rules

### VNet Peering Requirements
- **Non-overlapping Address Spaces**: Cannot peer VNets with same CIDR blocks
- **Bidirectional Configuration**: Peering must be configured on both VNets
- **Cross-Region Support**: Works across Azure regions

### Troubleshooting Lessons
- **Connection Timeout**: Usually NSG blocking traffic
- **Connection Refused**: Service not running or wrong port
- **Address Space Conflicts**: Must delete/recreate resources to change CIDR blocks

## Testing Connectivity

### Internet to VM Access
```bash
# SSH from local machine to VM-1
ssh labadmin@<vm1-public-ip>

# SSH from local machine to VM-2
ssh labadmin@<vm2-public-ip>
```

### Inter-VM Communication
```bash
# From VM-1, SSH to VM-2 using private IP
ssh labadmin@10.2.1.x

# From VM-2, SSH to VM-1 using private IP
ssh labadmin@10.1.1.x
```

## Network Diagnostic Tools
- **Azure Network Watcher**: Connection troubleshoot feature
- **VM Diagnostics**: Effective security rules analysis
- **Serial Console**: Direct VM access for troubleshooting

## Common Issues and Solutions

### SSH Connection Timeout
**Problem**: Cannot connect to VM via SSH
**Solution**: 
1. Check NSG rules allow port 22
2. Verify source IP in NSG rule matches your public IP
3. Ensure VM is running

### VNet Peering Conflicts
**Problem**: Cannot create peering due to overlapping address spaces
**Solution**:
1. Delete VMs in conflicting VNet
2. Update VNet address space
3. Recreate subnets with new CIDR blocks
4. Redeploy VMs

### NSG Rule Source Ports
**Problem**: SSH works from portal but not local machine
**Solution**: Change source port range from specific port to `*` (any)

## Cost Optimization
- **VM Size**: Standard_B1s (burstable, cost-effective for labs)
- **Disk Type**: StandardSSD_LRS (balance of cost and performance)
- **Disk Size**: 30GB minimum (reduces storage costs)

## Next Steps
- [ ] Add Application Security Groups (ASG) for better rule organization
- [ ] Implement Load Balancer for traffic distribution
- [ ] Configure NAT Gateway for outbound internet access
- [ ] Explore Hub-Spoke architecture with third VNet
- [ ] Add Network Virtual Appliances (firewall/routing)

## Related Resources
- [ARM Templates](../../ARM/templates/)
- [Azure NSG Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview)
- [VNet Peering Documentation](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-peering-overview)

## Lab Completion
- ✅ Created 2 VNets with non-overlapping address spaces
- ✅ Deployed Ubuntu VMs using ARM templates
- ✅ Configured NSG rules for secure access
- ✅ Established VNet peering
- ✅ Verified VM-to-VM connectivity across VNets
- ✅ Documented lessons learned and troubleshooting steps

---
**Date Completed**: July 19, 2025  
**Duration**: ~2-3 hours  
**Difficulty**: Beginner to Intermediate
