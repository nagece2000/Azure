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
- Basic Linux command line
- Basic understanding of IaC principles
