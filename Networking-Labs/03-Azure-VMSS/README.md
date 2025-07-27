# VM Scale Sets (VMSS) and Load Balancer Integration Lab

## Overview
This lab demonstrates Azure Virtual Machine Scale Sets (VMSS) integration with existing Load Balancer infrastructure, including auto-scaling configuration, manual scaling testing, and comprehensive troubleshooting of real-world Azure networking challenges.

## Architecture
Internet → Load Balancer (20.242.230.248) → Backend Pool → VMSS Instances
↓
Auto-scaling (CPU-based)
↓
Automatic Backend Pool Registration

## Lab Prerequisites
- Completed [Azure Load Balancer Lab](../02-Azure-Load-Balancer/)
- **Existing Load Balancer**: lab-loadbalancer with frontend IP
- **NSG Configuration**: nsg-lab-1 with HTTP/SSH rules
- **VNet Setup**: lab-vnet-1 with web-subnet

## Lab Objectives
- ✅ Create VMSS with Load Balancer integration
- ✅ Configure auto-scaling based on CPU metrics
- ✅ Test manual and automatic scaling
- ✅ Troubleshoot real-world Azure configuration issues
- ✅ Document lessons learned from production-like scenarios

## VMSS Configuration

### Basic Settings
- **Name**: lab-vmss
- **Region**: East US
- **Orchestration mode**: Uniform
- **Image**: Ubuntu Server 22.04 LTS
- **Size**: Standard_B1s
- **Authentication**: Password-based

### Scaling Configuration
- **Initial instance count**: 2
- **Minimum instances**: 2
- **Maximum instances**: 4
- **Scale-out threshold**: 40% CPU (sustained for 5 minutes)
- **Scale-in threshold**: 20% CPU (sustained for 5 minutes)

### Network Configuration
- **Virtual network**: lab-vnet-1
- **Subnet**: web-subnet (10.1.1.0/24)
- **Public IP**: Enabled per instance
- **Load balancer**: lab-loadbalancer
- **Backend pool**: lab-lb-backendpool

## Implementation Journey

### Phase 1: Initial VMSS Creation (Failed Approach)
**First Attempt - Private IPs Only:**
- Created VMSS without public IPs
- Attempted Custom Script Extension for nginx installation
- **Issue**: No outbound internet connectivity for package installation

### Phase 2: Network Connectivity Troubleshooting
Problem: VMSS instances couldn't reach Ubuntu repositories

### Error encountered:
W: Failed to fetch http://azure.archive.ubuntu.com/ubuntu/dists/jammy/InRelease
Could not connect to azure.archive.ubuntu.com:80

### Root Cause: 
Missing outbound NSG rules for internet access
### Attempted Solution: 
Added outbound NSG rules
HTTP (port 80) → Internet
HTTPS (port 443) → Internet
DNS (port 53) → Internet

### Result: Still no connectivity - Azure default outbound access limitations

## Phase 3: Clean Slate Approach (Successful)
### Decision: 
Recreate VMSS with public IPs for direct access
### New VMSS Configuration:
Public IP per instance: Enabled
NSG: Combined approach (basicNsglab-vnet-1-nic01 + nsg-lab-1)
Direct SSH access: For nginx installation and management

## Phase 4: NSG Troubleshooting - Real-World Issues
## Issue 1: 
Dynamic Public IP Changes
## SSH connection timeout
ssh labadmin@<vmss-instance-ip>
## Connection timed out

## Root Cause: 
ISP changed public IP, NSG rules pointed to old IP
## Solution: 
Update NSG source IP rules to current public IP
## Learning: 
Dynamic IPs require flexible NSG configurations

Issue 2: NSG Rule Hierarchy
Problem: HTTP access not working despite correct NSG rules
Root Cause: Multiple NSG layers

NIC-level NSG: basicNsglab-vnet-1-nic01 (missing HTTP rules)
Subnet-level NSG: nsg-lab-1 (had HTTP rules)

NSG Hierarchy Understanding:
NIC-level NSG (highest priority)
    ↓
Subnet-level NSG (lower priority)

Solution: Add HTTP rules to NIC-level NSG (basicNsglab-vnet-1-nic01)

Phase 5: VMSS-Load Balancer Integration
Critical Learning: VMSS configuration changes require instance upgrades
Issue: Backend pool integration not working initially
Azure Message:

"Backend pool 'lab-lb-backendpool' was added to Virtual machine scale set 'lab-vmss'. Upgrade all the instances of 'lab-vmss' for this change to work."

Solution: Manual instance upgrade required

VMSS → Instances → Select all instances
Click "Upgrade"
Wait for configuration propagation

Result: Instances automatically appeared in load balancer backend pool
Web Server Configuration
Manual Installation Process
Instance 1 (lab-vmss_0):

ssh labadmin@52.186.70.117
sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
echo "<h1>Hello from VM-0 of VMSS</h1>" | sudo tee /var/www/html/index.html

Instance 2 (lab-vmss_1):

ssh labadmin@<instance-2-public-ip>
sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
echo "<h1>Hello from VM-1 of VMSS</h1>" | sudo tee /var/www/html/index.html

Load Balancer Testing
Direct Instance Access:

VM-0: http://52.186.70.117 → "Hello from VM-0 of VMSS"
VM-1: http://<vm-1-public-ip> → "Hello from VM-1 of VMSS"

Load Balanced Access:

Load Balancer: http://20.242.230.248 → Alternates between instances
Browser caching: Regular browser may show same instance
Incognito mode: Shows true load balancing behavior

Scaling Testing
Manual Scaling (Successful)
Test Process:

Initial state: 2 instances running
Scale up: Manual scale to 3 instances
Verification: New instance automatically added to backend pool
Load testing: Traffic distributed across all 3 instances

Results:

✅ Instance creation: ~3-5 minutes
✅ Backend pool registration: Automatic
✅ Load distribution: Immediate after health probe success

Auto-Scaling (Configuration Challenge)
Issue Encountered: Resource group targeting mismatch

Autoscale setting: Targeting "lab-vmss_group"
Actual VMSS: Located in "networking-lab-rg-1"
Result: Autoscale rules not applied to VMSS

Root Cause: Azure auto-created resource group during VMSS deployment

Attempted Solutions:

Resource move: VMSS to correct resource group (validation ongoing)
Autoscale reconfiguration: Limited edit options
Manual scaling alternative: Successful workaround

Stress Testing Setup
CPU Load Generation:
# Install stress testing tool
sudo apt install stress-ng -y

# Generate sustained CPU load (10 minutes)
stress-ng --cpu 0 --timeout 600s

Monitoring Results:

CPU utilization: 100% sustained load
Expected trigger: 40% threshold for 5 minutes
Autoscale status: Configuration issues prevented automatic scaling

Key Learning Outcomes
1. VMSS Configuration Management

Upgrade policies: Manual vs automatic upgrade modes
Configuration changes: Require explicit instance upgrades
Load balancer integration: Post-deployment modifications need upgrades

2. Azure Networking Complexity

NSG hierarchy: NIC-level rules override subnet-level rules
Multiple NSG scenarios: Common in VMSS deployments
Dynamic IP management: ISP changes affect security rules

3. Real-World Azure Challenges

Resource group targeting: Auto-created groups cause configuration issues
Outbound connectivity: Modern Azure restrictions on default internet access
Troubleshooting methodology: Systematic approach to complex networking issues

4. Load Balancer Integration Benefits

Automatic registration: New VMSS instances join backend pool automatically
Health monitoring: Load balancer health probes ensure traffic routing
Seamless scaling: No manual backend pool management required

Troubleshooting Guide
Common Issues and Solutions
SSH Connection Timeouts
Symptoms: ssh: connect to host <ip> port 22: Connection timed out
Causes:

Dynamic IP change: NSG rules point to old public IP
Missing SSH rules: NIC-level NSG lacks SSH permissions
Wrong NSG configuration: Rules in wrong NSG layer

Solutions:

Update NSG source IP: Check current public IP vs NSG rules
Verify NSG hierarchy: Check both NIC and subnet level NSGs
Add SSH rules: Ensure SSH (port 22) allowed from your IP

HTTP Access Issues
Symptoms: curl: (28) Failed to connect to server
Diagnosis Steps:
# Test locally on instance
ssh into instance
curl localhost  # Should work if nginx is running

# Check NSG rules
# Verify HTTP (port 80) rules in correct NSG
Solutions:

Add HTTP rules to NIC-level NSG: Not just subnet-level
Verify nginx status: sudo systemctl status nginx
Check destination rules: Use "Any" instead of specific subnets

VMSS Backend Pool Registration
Symptoms: VMSS instances not appearing in load balancer backend pool
Solution: Manual instance upgrade required

# Via Azure Portal:
VMSS → Instances → Select All → Upgrade
Autoscale Configuration Issues
Symptoms: CPU at 100% but no scaling events
Common Causes:

Resource group mismatch: Autoscale targeting wrong RG
Disabled autoscale: Check if autoscale is enabled
Incorrect thresholds: Verify CPU percentage settings
Timeline requirements: Sustained load for full duration

Related Documentation

NSG and VNet Peering Lab
Azure Load Balancer Lab
Azure VMSS Documentation
Load Balancer Integration Guide

Lab Completion Summary

✅ VMSS Creation: Successfully deployed with load balancer integration
✅ Manual Scaling: Tested scaling from 2 to 3 instances
✅ Load Balancing: Verified traffic distribution across instances
✅ Network Troubleshooting: Resolved NSG hierarchy and dynamic IP issues
✅ Real-world Learning: Experienced and solved production-like challenges
✅ Instance Management: Understood VMSS upgrade policies and configurations
⚠️ Auto-scaling: Configuration challenges due to resource group targeting

Key Achievements
This lab provided invaluable hands-on experience with:

Complex Azure networking scenarios
Real-world troubleshooting methodologies
VMSS operational management
Load balancer integration patterns
Production-ready scaling concepts

Date Completed: July 27, 2025
Duration: ~3-4 hours
Difficulty: Intermediate to Advanced
Dependencies: Load Balancer Lab, NSG and VNet Peering Lab
Next Steps: Application Gateway or NAT Gateway implementation
