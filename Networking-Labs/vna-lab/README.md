# Azure Network Virtual Appliance (NVA) Lab
## VNet Peering vs NVA: A Practical Comparison

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Authentication Setup](#authentication-setup)
- [Infrastructure Deployment](#infrastructure-deployment)
- [Phase 1: VNet Peering Demo](#phase-1-vnet-peering-demonstration)
- [Phase 2: NVA Implementation](#phase-2-nva-implementation)
- [Phase 3: Selective Traffic Control](#phase-3-selective-traffic-control)
- [Troubleshooting](#troubleshooting)
- [Key Learnings](#key-learnings)
- [Cleanup](#cleanup)
- [Conclusion](#conclusion)

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

## 📡 Phase 1: VNet Peering Demonstration

### Objective

Establish direct VNet peering between Spoke1 and Spoke2 to demonstrate basic connectivity and identify limitations that an NVA solution addresses.

### Setup VNet Peering

**Create Peering: Spoke1 ↔ Spoke2**

1. Navigate to **Azure Portal** → **Virtual networks** → **spoke1-vnet**
2. Click **Peerings** → **+ Add**
3. Configure:
   - **This virtual network**
     - Peering link name: `spoke1-to-spoke2`
     - Traffic to remote virtual network: `Allow`
     - Traffic forwarded from remote virtual network: `Allow`
   - **Remote virtual network**
     - Peering link name: `spoke2-to-spoke1`
     - Virtual network: `spoke2-vnet`
     - Traffic to remote virtual network: `Allow`
     - Traffic forwarded from remote virtual network: `Allow`
4. Click **Add**
5. Wait for peering status to show **Connected**

### Test Connectivity

**SSH to Spoke1 VM:**
```bash
ssh -i vna-lab-key azureuser@<spoke1-public-ip>
```

**Ping Spoke2 (using private IP):**
```bash
ping 10.2.1.4 -c 4
```

**Expected Result:** ✅ Ping succeeds - VNet peering enables direct connectivity!

### Demonstrate Limitations

Now let's explore what VNet peering **CANNOT** do:

#### **Limitation 1: No Central Visibility**

**Problem:** Each VM can only see its own traffic, not network-wide traffic.

**Test:**
```bash
# On Spoke1 VM, run tcpdump
sudo tcpdump -i eth0 -n host 10.2.1.4

# Generate traffic (from another SSH session to Spoke1)
ping 10.2.1.4 -c 5
```

**Observation:**
- ✅ You can see traffic locally on Spoke1
- ❌ No central monitoring point
- ❌ To monitor all inter-VNet traffic, you'd need tcpdump on EVERY VM
- ❌ Not scalable for production environments

**Key Insight:** "I can only see what's happening on THIS VM. There's no network-level visibility."

#### **Limitation 2: No Selective Traffic Control**

**Problem:** Can't selectively allow some protocols while blocking others between VNets.

**Scenario:** What if we want to:
- ✅ Allow ICMP (ping) between Spoke1 ↔ Spoke2
- ❌ Block SSH between Spoke1 ↔ Spoke2
- ✅ But still allow SSH from the internet to both VMs

**With VNet peering:** **IMPOSSIBLE!**

Why?
- NSG rules apply to ALL traffic from that source, not just inter-VNet traffic
- If you block SSH in NSG, you block it from everywhere (including your laptop)
- It's all-or-nothing connectivity

**Key Insight:** "VNet peering is binary - either full connectivity or no connectivity. No granular control."

#### **Limitation 3: No Traffic Inspection**

**Test packet inspection:**
```bash
# On Spoke1, capture detailed packets
sudo tcpdump -i eth0 -A -n host 10.2.1.4
```

**Observation:**
- ✅ You see packets on the local VM
- ❌ No deep packet inspection at network level
- ❌ Can't detect threats or malicious patterns centrally
- ❌ No IDS/IPS capability

#### **Limitation 4: No Centralized Logging**

**Where are the connection logs?**
- No centralized logs of inter-VNet traffic
- Would need to enable NSG Flow Logs (limited detail)
- No real-time inspection capability
- Logs scattered across multiple VMs

### Summary: When VNet Peering Falls Short

| Requirement | VNet Peering | Impact |
|-------------|--------------|--------|
| **Central monitoring** | ❌ | Need tcpdump on every VM |
| **Selective control** | ❌ | Can't allow ICMP but block SSH |
| **Traffic inspection** | ❌ | No DPI or threat detection |
| **Centralized logging** | ❌ | Logs scattered |
| **IDS/IPS** | ❌ | Not possible |
| **Policy enforcement** | ❌ | NSG rules too broad |

### Clean Up Peering

Before proceeding to Phase 2, remove the VNet peering:

1. Go to **spoke1-vnet** → **Peerings**
2. Delete `spoke1-to-spoke2` peering
3. Go to **spoke2-vnet** → **Peerings**
4. Delete `spoke2-to-spoke1` peering

**Verify connectivity is broken:**
```bash
# From Spoke1
ping 10.2.1.4 -c 2
# Should fail now ❌
```

### Key Takeaway

VNet peering is excellent for simple connectivity scenarios, but when you need:
- Central visibility
- Granular traffic control
- Security inspection
- Compliance requirements

**You need an NVA solution!**

---

**Next:** Phase 2 - Implementing NVA Routing

## 🛡️ Phase 2: NVA Implementation

### Objective

Implement a Hub-and-Spoke topology with a Network Virtual Appliance (NVA) to route all traffic between Spoke1 and Spoke2 through a central inspection point.

### Architecture Overview
```
           Hub VNet (10.0.0.0/16)
                   |
              NVA VM (10.0.1.4)
              /            \
             /              \
    Spoke1 VNet          Spoke2 VNet
   (10.1.0.0/16)        (10.2.0.0/16)
        |                    |
   spoke1-vm            spoke2-vm
   (10.1.1.4)           (10.2.1.4)
```

**Traffic Flow:**
```
Spoke1 VM → Route Table → NVA → Route Table → Spoke2 VM
```

### Part A: Configure the NVA VM

The NVA VM must be configured to forward packets between networks.

**1. SSH to NVA VM:**
```bash
ssh -i vna-lab-key azureuser@<nva-public-ip>
```

**2. Enable IP Forwarding in Linux:**

Check current setting:
```bash
cat /proc/sys/net/ipv4/ip_forward
# Should show 0 (disabled)
```

Enable temporarily:
```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

Make it permanent (survives reboots):
```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
```

Verify it's enabled:
```bash
cat /proc/sys/net/ipv4/ip_forward
# Should show 1 (enabled) ✅
```

**3. Configure iptables:**

Allow packet forwarding:
```bash
# Set default FORWARD policy to ACCEPT
sudo iptables -P FORWARD ACCEPT

# View current rules
sudo iptables -L FORWARD -n -v
```

**4. Make iptables rules persistent:**
```bash
sudo apt-get update
sudo apt-get install -y iptables-persistent

# When prompted, select YES to save current IPv4 rules
# Select YES to save current IPv6 rules
```

**5. Verify Configuration:**
```bash
# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward  # Should be 1

# Check iptables
sudo iptables -L -n -v

# Check NIC has IP forwarding enabled (should already be set by Terraform)
# This is at Azure level, not Linux level
```

**Important:** Terraform already set `enable_ip_forwarding = true` on the NVA's NIC, but we need both Azure-level AND OS-level forwarding.

### Part B: Create Hub-Spoke VNet Peering

The NVA needs to reach both spoke networks. Create VNet peerings between Hub and each Spoke.

#### **Peering 1: Hub ↔ Spoke1**

1. Navigate to **Virtual networks** → **hub-vnet** → **Peerings**
2. Click **+ Add**
3. Configure:
   - **This virtual network (hub-vnet)**
     - Peering link name: `hub-to-spoke1`
     - Traffic to remote virtual network: `Allow`
     - **Traffic forwarded from remote virtual network: `Allow`** ⚠️ Critical!
   - **Remote virtual network**
     - Peering link name: `spoke1-to-hub`
     - Virtual network: `spoke1-vnet`
     - Traffic to remote virtual network: `Allow`
     - **Traffic forwarded from remote virtual network: `Allow`** ⚠️ Critical!
4. Click **Add**

#### **Peering 2: Hub ↔ Spoke2**

1. Still in **hub-vnet** → **Peerings**
2. Click **+ Add**
3. Configure:
   - **This virtual network (hub-vnet)**
     - Peering link name: `hub-to-spoke2`
     - Traffic to remote virtual network: `Allow`
     - **Traffic forwarded from remote virtual network: `Allow`** ⚠️ Critical!
   - **Remote virtual network**
     - Peering link name: `spoke2-to-hub`
     - Virtual network: `spoke2-vnet`
     - Traffic to remote virtual network: `Allow`
     - **Traffic forwarded from remote virtual network: `Allow`** ⚠️ Critical!
4. Click **Add**

**Why "Allow forwarded traffic" is critical:** This allows traffic originating from Spoke1 to pass through the Hub to reach Spoke2.

### Part C: Create Route Tables (UDRs)

User Defined Routes tell Azure to send traffic through the NVA instead of using default routing.

#### **Route Table 1: For Spoke1 Subnet**

**1. Create Route Table:**
- Go to **Route tables** → **+ Create**
- Resource group: `rg-vna-lab`
- Region: `East US`
- Name: `spoke1-to-nva-rt`
- Click **Review + create** → **Create**

**2. Add Route:**
- Open `spoke1-to-nva-rt` → **Routes** → **+ Add**
- Route name: `to-spoke2-via-nva`
- Address prefix: `10.2.0.0/16` (Spoke2 VNet range)
- Next hop type: `Virtual appliance`
- Next hop address: `10.0.1.4` (NVA private IP)
- Click **Add**

**3. Associate with Spoke1 Subnet:**
- Click **Subnets** → **+ Associate**
- Virtual network: `spoke1-vnet`
- Subnet: `vm-subnet`
- Click **OK**

#### **Route Table 2: For Spoke2 Subnet**

**1. Create Route Table:**
- Go to **Route tables** → **+ Create**
- Resource group: `rg-vna-lab`
- Region: `East US`
- Name: `spoke2-to-nva-rt`
- Click **Review + create** → **Create**

**2. Add Route:**
- Open `spoke2-to-nva-rt` → **Routes** → **+ Add**
- Route name: `to-spoke1-via-nva`
- Address prefix: `10.1.0.0/16` (Spoke1 VNet range)
- Next hop type: `Virtual appliance`
- Next hop address: `10.0.1.4` (NVA private IP)
- Click **Add**

**3. Associate with Spoke2 Subnet:**
- Click **Subnets** → **+ Associate**
- Virtual network: `spoke2-vnet`
- Subnet: `vm-subnet`
- Click **OK**

### Verify Routing Configuration

**Check Effective Routes on Spoke1 VM:**

1. Go to **Virtual machines** → **spoke1-vm** → **Networking**
2. Click on network interface: **spoke1-vm-nic**
3. Click **Effective routes** (under Support + troubleshooting)
4. Look for:
   - Address prefix: `10.2.0.0/16`
   - Next hop type: `Virtual appliance`
   - Next hop IP: `10.0.1.4`

✅ **If you see this route, routing is configured correctly!**

### Test Traffic Through NVA

Now the moment of truth - verify traffic flows through the NVA!

**Terminal 1 - Monitor NVA Traffic:**
```bash
# SSH to NVA
ssh -i vna-lab-key azureuser@<nva-public-ip>

# Run tcpdump to capture inter-spoke traffic
sudo tcpdump -i eth0 -n host 10.1.1.4 or host 10.2.1.4
```

**Terminal 2 - Generate Traffic:**
```bash
# SSH to Spoke1
ssh -i vna-lab-key azureuser@<spoke1-public-ip>

# Ping Spoke2
ping 10.2.1.4 -c 4
```

**Expected Result on NVA tcpdump:**
```
IP 10.1.1.4 > 10.2.1.4: ICMP echo request, id 1, seq 1, length 64
IP 10.0.1.4 > 10.2.1.4: ICMP echo request, id 1, seq 1, length 64
IP 10.2.1.4 > 10.0.1.4: ICMP echo reply, id 1, seq 1, length 64
IP 10.2.1.4 > 10.1.1.4: ICMP echo reply, id 1, seq 1, length 64
```

✅ **SUCCESS!** You're seeing traffic flow through the NVA!

### What We Achieved

**Compared to VNet Peering:**

| Capability | VNet Peering | NVA Solution |
|-----------|--------------|--------------|
| **Connectivity** | ✅ Direct | ✅ Via NVA |
| **Central visibility** | ❌ No | ✅ **tcpdump on NVA sees ALL traffic** |
| **Monitoring point** | ❌ Must monitor each VM | ✅ **One central point** |
| **Traffic control** | ❌ All-or-nothing | ✅ Ready for granular rules |
| **Scalability** | ❌ N-to-N peering | ✅ Hub-and-spoke model |

### Key Observations

1. **Central Choke Point:** All Spoke1 ↔ Spoke2 traffic now passes through the NVA
2. **Full Visibility:** Single tcpdump session sees all inter-spoke traffic
3. **Foundation for Control:** We can now add filtering, logging, and security policies
4. **No Changes to VMs:** Spoke VMs don't need any configuration - routing is transparent

---

**Next:** Phase 3 - Selective Traffic Control (The Killer Feature!)
