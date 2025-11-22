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

## 🎯 Phase 3: Selective Traffic Control

### Objective

Demonstrate the **killer feature** of NVA routing: granular traffic control that is **impossible** with VNet peering alone.

**The Challenge:**
- ✅ Allow ICMP (ping) between Spoke1 ↔ Spoke2
- ❌ Block SSH (port 22) between Spoke1 ↔ Spoke2
- ✅ Keep SSH from the internet to VMs working

**Why this matters:** With VNet peering, this is impossible. NSG rules would block SSH from everywhere, not just between spokes.

### Configure iptables on NVA

**1. SSH to NVA VM:**
```bash
ssh -i vna-lab-key azureuser@<nva-public-ip>
```

**2. Clear existing rules and enable logging:**
```bash
# Clear FORWARD chain (start fresh)
sudo iptables -F FORWARD

# Set default policy to ACCEPT
sudo iptables -P FORWARD ACCEPT

# Add logging for all forwarded traffic (optional but useful)
sudo iptables -A FORWARD -j LOG --log-prefix "NVA-FORWARD: " --log-level 4
```

**3. Test baseline (everything should work):**

From another terminal:
```bash
# SSH to Spoke1
ssh -i vna-lab-key azureuser@<spoke1-public-ip>

# Test ping
ping 10.2.1.4 -c 2
# Should work ✅

# Test SSH connectivity to Spoke2 (port check)
nc -zv 10.2.1.4 22
# Should show: Connection succeeded ✅
```

**4. Add selective blocking rules:**

Back on NVA:
```bash
# Block SSH (port 22) FROM Spoke1 TO Spoke2
sudo iptables -I FORWARD 1 -p tcp --dport 22 -s 10.1.0.0/16 -d 10.2.0.0/16 -j DROP

# Block SSH FROM Spoke2 TO Spoke1
sudo iptables -I FORWARD 1 -p tcp --dport 22 -s 10.2.0.0/16 -d 10.1.0.0/16 -j DROP

# Explicitly allow ICMP (already allowed by default policy, but being explicit)
sudo iptables -I FORWARD 1 -p icmp -j ACCEPT
```

**5. View the rules:**
```bash
sudo iptables -L FORWARD -n -v --line-numbers
```

**Expected output:**
```
Chain FORWARD (policy ACCEPT)
num   pkts bytes target  prot opt in  out  source        destination
1        0     0 ACCEPT  icmp --  *   *    0.0.0.0/0     0.0.0.0/0
2        0     0 DROP    tcp  --  *   *    10.1.0.0/16   10.2.0.0/16  tcp dpt:22
3        0     0 DROP    tcp  --  *   *    10.2.0.0/16   10.1.0.0/16  tcp dpt:22
4        0     0 LOG     all  --  *   *    0.0.0.0/0     0.0.0.0/0    LOG flags 0 level 4 prefix "NVA-FORWARD: "
```

**6. Make rules persistent:**
```bash
# Save current rules
sudo netfilter-persistent save

# Or manually save
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

### Test Selective Control

Now for the magic moment!

#### **Test 1: Ping Still Works ✅**

**From Spoke1:**
```bash
ping 10.2.1.4 -c 4
```

**Expected Result:**
```
PING 10.2.1.4 (10.2.1.4) 56(84) bytes of data.
64 bytes from 10.2.1.4: icmp_seq=1 ttl=63 time=2.45 ms
64 bytes from 10.2.1.4: icmp_seq=2 ttl=63 time=1.89 ms
64 bytes from 10.2.1.4: icmp_seq=3 ttl=63 time=1.92 ms
64 bytes from 10.2.1.4: icmp_seq=4 ttl=63 time=1.88 ms

--- 10.2.1.4 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3005ms
```

✅ **ICMP traffic flows through NVA and is allowed!**

#### **Test 2: SSH Between Spokes is Blocked ❌**

**From Spoke1:**
```bash
# Test SSH connection to Spoke2
nc -zv 10.2.1.4 22
```

**Expected Result:**
```
nc: connect to 10.2.1.4 port 22 (tcp) failed: Connection timed out
```

❌ **SSH blocked by NVA! Perfect!**

Or try direct SSH:
```bash
ssh azureuser@10.2.1.4
# Will hang and timeout
```

#### **Test 3: SSH from Internet Still Works ✅**

**From your laptop:**
```bash
# SSH to Spoke1 (using public IP)
ssh -i vna-lab-key azureuser@<spoke1-public-ip>
# Should work ✅

# SSH to Spoke2 (using public IP)
ssh -i vna-lab-key azureuser@<spoke2-public-ip>
# Should work ✅
```

✅ **SSH from internet works because it doesn't route through NVA!**

### Monitor Traffic on NVA

**Watch the logs in real-time:**
```bash
# On NVA VM
sudo tail -f /var/log/kern.log | grep NVA-FORWARD
```

**Generate traffic from Spoke1** (ping and SSH attempts):
```bash
# From Spoke1
ping 10.2.1.4 -c 2
nc -zv 10.2.1.4 22
```

**What you'll see in logs:**
```
NVA-FORWARD: IN=eth0 OUT=eth0 SRC=10.1.1.4 DST=10.2.1.4 PROTO=ICMP
NVA-FORWARD: IN=eth0 OUT=eth0 SRC=10.1.1.4 DST=10.2.1.4 PROTO=TCP DPT=22
```

You can see both allowed (ICMP) and blocked (TCP/22) traffic!

### The Breakthrough

**What We Just Accomplished:**

| Requirement | VNet Peering | NVA Solution |
|------------|--------------|--------------|
| **Allow ICMP, block SSH between spokes** | ❌ **IMPOSSIBLE** | ✅ **DONE** |
| **Keep internet SSH working** | N/A | ✅ **Works** |
| **Central visibility** | ❌ No | ✅ **All logs on NVA** |
| **Granular control** | ❌ All-or-nothing | ✅ **Protocol-level** |

### Real-World Use Cases

This capability enables critical security scenarios:

**1. Micro-segmentation:**
```
Allow:  App Tier → Database Tier (port 3306)
Block:  App Tier → Database Tier (SSH)
Result: Apps can access DB, but can't SSH directly to DB servers
```

**2. Compliance Requirements:**
```
Allow:  Development → Staging (HTTP/HTTPS)
Block:  Development → Production (everything)
Result: Prevent dev from touching production
```

**3. Lateral Movement Prevention:**
```
Allow:  East-West traffic (normal operations)
Block:  East-West traffic (known attack patterns)
Result: Contain security breaches
```

**4. Protocol-Specific Policies:**
```
Allow:  ICMP (monitoring/health checks)
Block:  RDP/SSH (reduce attack surface)
Allow:  HTTPS only (encrypted traffic)
Result: Enforce security standards
```

### Advanced: Add More Rules

**Example: Allow HTTP/HTTPS, block everything else:**
```bash
# Clear current rules
sudo iptables -F FORWARD

# Allow ICMP
sudo iptables -A FORWARD -p icmp -j ACCEPT

# Allow HTTP (port 80)
sudo iptables -A FORWARD -p tcp --dport 80 -j ACCEPT

# Allow HTTPS (port 443)
sudo iptables -A FORWARD -p tcp --dport 443 -j ACCEPT

# Block all other TCP traffic between spokes
sudo iptables -A FORWARD -p tcp -s 10.1.0.0/16 -d 10.2.0.0/16 -j DROP
sudo iptables -A FORWARD -p tcp -s 10.2.0.0/16 -d 10.1.0.0/16 -j DROP

# Log everything
sudo iptables -A FORWARD -j LOG --log-prefix "NVA-FORWARD: "

# Allow everything else (outbound to internet, etc.)
sudo iptables -A FORWARD -j ACCEPT
```

### Comparison Summary

**With VNet Peering (Phase 1):**
- Direct connectivity ✅
- No visibility ❌
- No control ❌
- Simple to set up ✅

**With NVA (Phase 2 & 3):**
- Routed connectivity ✅
- Full visibility ✅
- Granular control ✅
- Requires configuration ⚠️

### Key Takeaway

**The NVA solution provides:**
1. ✅ **Central choke point** - All traffic in one place
2. ✅ **Full visibility** - See everything with tcpdump/logs
3. ✅ **Granular control** - Allow/block at protocol/port level
4. ✅ **Security enforcement** - Network-level policies
5. ✅ **Scalability** - One point controls all inter-VNet traffic

**This is impossible with VNet peering alone!**

---

**Next:** Troubleshooting Guide

## 🔧 Troubleshooting Guide

Common issues encountered during this lab and how to resolve them.

### Issue 1: Ping/SSH Fails - "Connection Timed Out"

**Symptom:**
```bash
ssh azureuser@4.246.218.45
# ssh: connect to host 4.246.218.45 port 22: Connection timed out
```

**Cause:** Your public IP changed (dynamic IPs change frequently).

**Solution:**

1. Check your current public IP:
```bash
curl ifconfig.me
```

2. Update NSG rules via Azure CLI:
```bash
az network nsg rule update \
  --resource-group rg-vna-lab \
  --nsg-name spoke1-nsg \
  --name Allow-SSH-From-MyIP \
  --source-address-prefixes "YOUR_NEW_IP/32"

# Repeat for spoke2-nsg and hub-nsg
```

Or update `terraform.tfvars` and run:
```bash
terraform apply
```

**Prevention:** Use static public IP for your home/office, or use Azure Bastion.

---

### Issue 2: Traffic Not Flowing Through NVA

**Symptom:**
```bash
# On NVA, tcpdump shows no traffic
sudo tcpdump -i eth0 -n host 10.1.1.4 or host 10.2.1.4
# No packets captured
```

**Possible Causes & Solutions:**

#### **A. Missing Hub-Spoke Peering**

**Check:**
```bash
# Verify Hub ↔ Spoke1 peering
az network vnet peering show \
  --resource-group rg-vna-lab \
  --vnet-name hub-vnet \
  --name hub-to-spoke1 \
  --query peeringState

# Should return "Connected"
```

**Fix:** Create missing peerings (see Phase 2, Part B).

#### **B. IP Forwarding Not Enabled (Azure Level)**

**Check:**
```bash
az network nic show \
  --resource-group rg-vna-lab \
  --name nva-vm-nic \
  --query "enableIpForwarding"
```

**Expected:** `true`

**Fix:**
```bash
az network nic update \
  --resource-group rg-vna-lab \
  --name nva-vm-nic \
  --ip-forwarding true
```

#### **C. IP Forwarding Not Enabled (OS Level)**

**Check on NVA:**
```bash
cat /proc/sys/net/ipv4/ip_forward
# Should show 1
```

**Fix:**
```bash
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
```

#### **D. Route Tables Not Associated**

**Check:**
```bash
az network vnet subnet show \
  --resource-group rg-vna-lab \
  --vnet-name spoke1-vnet \
  --name vm-subnet \
  --query "routeTable.id"
```

**Expected:** Should show route table resource ID, not `null`

**Fix:** Associate route table with subnet (see Phase 2, Part C).

#### **E. Wrong Route Configuration**

**Check Effective Routes:**
1. Go to Portal → **spoke1-vm** → **Networking**
2. Click NIC → **Effective routes**
3. Look for route: `10.2.0.0/16` → Next hop: `10.0.1.4`

**Fix:** Verify route table configuration has correct next hop IP.

---

### Issue 3: iptables Rules Not Working

**Symptom:** SSH still works between spokes when it should be blocked.

**Check Current Rules:**
```bash
sudo iptables -L FORWARD -n -v --line-numbers
```

**Common Issues:**

#### **A. Rules in Wrong Order**

iptables processes rules top-to-bottom. If ACCEPT rule comes before DROP, DROP never gets hit.

**Fix:**
```bash
# Use -I (insert) instead of -A (append) to add at top
sudo iptables -I FORWARD 1 -p tcp --dport 22 -s 10.1.0.0/16 -d 10.2.0.0/16 -j DROP
```

#### **B. Wrong Chain**

Make sure rules are in FORWARD chain, not INPUT or OUTPUT.

#### **C. Rules Not Persistent**

**Save rules:**
```bash
sudo netfilter-persistent save
```

Or manually:
```bash
sudo iptables-save | sudo tee /etc/iptables/rules.v4
```

**Verify saved:**
```bash
cat /etc/iptables/rules.v4
```

---

### Issue 4: Terraform Conflicts

**Symptom:**
```
Error: creating/updating resource: StatusCode=409
Conflict: Resource already exists
```

**Cause:** Resource created manually in Portal, but Terraform doesn't know about it.

**Solutions:**

**Option A: Delete manual resource, let Terraform manage it**
```bash
# Delete from Portal, then
terraform apply
```

**Option B: Import into Terraform (advanced)**
```bash
terraform import azurerm_resource_type.name /subscriptions/.../resourceId
```

**Option C: Remove from Terraform code**
- Comment out the resource in `main.tf`
- Manage it manually going forward

**Best Practice:** Choose ONE source of truth - either Terraform OR Portal, not both!

---

### Issue 5: VM Can't Be Started

**Symptom:**
```
az vm start --resource-group rg-vna-lab --name spoke1-vm
# Error: Quota exceeded
```

**Cause:** Azure subscription quota limits.

**Check Quotas:**
```bash
az vm list-usage --location eastus --output table
```

**Solutions:**
1. Delete unused VMs/resources
2. Request quota increase via Azure Portal → Quotas
3. Use smaller VM size (B1ls instead of B1s)
4. Try different region

---

### Issue 6: Standard SKU Public IP Quota Error

**Symptom:**
```
Error: Cannot create more than X Standard SKU public IP addresses
```

**Fix:** Already handled in Terraform - we use Standard SKU with Static allocation.

If you see this error:
1. Delete unused public IPs
2. Request quota increase
3. Use Basic SKU (not recommended for production)

---

### Issue 7: SSH Key Permission Errors

**Symptom:**
```bash
ssh -i vna-lab-key azureuser@10.1.1.4
# Permissions 0644 for 'vna-lab-key' are too open
```

**Fix:**
```bash
chmod 600 vna-lab-key
```

Private keys must have restricted permissions.

---

### Issue 8: tcpdump Shows Duplicate Packets

**Symptom:**
```
10.1.1.4 > 10.2.1.4: ICMP echo request
10.0.1.4 > 10.2.1.4: ICMP echo request  # Duplicate?
```

**Explanation:** This is NORMAL! You're seeing:
1. Incoming packet (source: 10.1.1.4)
2. Forwarded packet (source changed by NAT/routing)

This shows the NVA is working correctly!

---

### Issue 9: Peering Status Shows "Updating"

**Symptom:** Peering stuck in "Updating" state.

**Fix:**
1. Wait 2-3 minutes (can take time to propagate)
2. If still stuck after 5 minutes, delete and recreate
3. Check for conflicting peerings

---

### Issue 10: Can't Find Resources in Portal

**Symptom:** Resources created by Terraform not visible in Portal.

**Check:**
1. Correct subscription selected?
2. Correct resource group?
3. Resource actually created?

**Verify via CLI:**
```bash
az resource list --resource-group rg-vna-lab --output table
```

---

## Debugging Commands

**General Azure Resource Check:**
```bash
# List all resources in resource group
az resource list -g rg-vna-lab --output table

# Check VM status
az vm list -g rg-vna-lab --show-details --output table

# Check VNet peerings
az network vnet peering list -g rg-vna-lab --vnet-name hub-vnet --output table

# Check route tables
az network route-table list -g rg-vna-lab --output table

# Check NSG rules
az network nsg rule list -g rg-vna-lab --nsg-name spoke1-nsg --output table
```

**NVA Diagnostics:**
```bash
# On NVA VM:

# Check IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# Check network interfaces
ip addr show

# Check iptables rules
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v

# Check routing table
ip route show

# Monitor traffic
sudo tcpdump -i eth0 -n

# Check logs
sudo tail -f /var/log/kern.log | grep NVA-FORWARD
```

**Network Connectivity Tests:**
```bash
# From Spoke VMs:

# Test ping
ping 10.2.1.4 -c 4

# Test port connectivity
nc -zv 10.2.1.4 22
nc -zv 10.2.1.4 80

# Trace route
traceroute 10.2.1.4

# Check DNS
nslookup google.com

# Check default route
ip route show
```

---

## Tips for Success

1. **Work methodically:** Complete each phase before moving to the next
2. **Document as you go:** Take screenshots at each step
3. **Test incrementally:** Verify each component works before adding complexity
4. **Check both directions:** Test Spoke1→Spoke2 AND Spoke2→Spoke1
5. **Use multiple terminals:** Monitor NVA while generating traffic from Spokes
6. **Save your work:** Take snapshots or save iptables rules
7. **Clean up when done:** Stop/deallocate VMs to avoid unnecessary costs

---

**Next:** Key Learnings & Best Practices

## 📚 Key Learnings & Best Practices

This section captures important lessons learned during the implementation of this lab.

### Azure Networking Concepts

#### **1. VNet Peering vs Hub-and-Spoke**

**VNet Peering (Mesh):**
```
VNet1 ←→ VNet2
  ↓  ×    ↓
VNet3 ←→ VNet4
```
- **Pros:** Low latency, simple setup
- **Cons:** Scales poorly (N² connections), no central control
- **Use when:** Small number of VNets, no inspection needed

**Hub-and-Spoke with NVA:**
```
      Hub
    /  |  \
Spoke1 Spoke2 Spoke3
```
- **Pros:** Scales well, central control, inspection capability
- **Cons:** Additional latency, complexity, cost
- **Use when:** Security requirements, compliance, many VNets

#### **2. User Defined Routes (UDRs)**

**Critical Lessons:**
- UDRs override default Azure routing
- Applied at subnet level, not VM level
- Must be configured in BOTH directions (Spoke1→Spoke2 AND Spoke2→Spoke1)
- Check "Effective Routes" on VM NIC to verify what's actually applied
- Changes can take 1-2 minutes to propagate

**Common Mistake:**
```bash
# Wrong: Only creating route on Spoke1
Spoke1 can reach Spoke2 ✅
Spoke2 cannot reach Spoke1 ❌  # Asymmetric routing!
```

**Correct:** Create route tables on BOTH subnets.

#### **3. IP Forwarding - Two Levels**

**You need BOTH:**

**A. Azure NIC Level:**
```bash
az network nic show --name nva-vm-nic --query "enableIpForwarding"
```
- Controlled by Azure
- Set via Terraform: `enable_ip_forwarding = true`
- Can be updated without VM restart

**B. OS Level (Linux kernel):**
```bash
cat /proc/sys/net/ipv4/ip_forward
```
- Controlled inside the VM
- Must be configured: `sysctl -w net.ipv4.ip_forward=1`
- Make persistent: Add to `/etc/sysctl.conf`

**Both must be enabled** or forwarding fails!

#### **4. NSG Rule Hierarchy**

**What we learned:**
- NSG rules can be at **subnet level** OR **NIC level**
- **NIC-level rules take precedence** when both exist
- For NVA labs, subnet-level NSGs are cleaner and more manageable
- Priority matters: Lower number = evaluated first

**Best Practice:**
```
Priority 100: Allow SSH from your IP (specific)
Priority 110-120: Allow inter-VNet traffic (broader)
Priority 65000+: Azure default rules (last resort)
```

#### **5. VNet Peering - "Allow Forwarded Traffic"**

**Critical Setting:** When creating Hub ↔ Spoke peerings:
- ✅ **Must enable "Allow forwarded traffic"**
- Without this: Traffic from Spoke1 cannot transit through Hub to Spoke2
- This is what enables the Hub-and-Spoke topology

**Why:**
- Spoke1 traffic to Spoke2 originates from 10.1.x.x (not Hub)
- From Hub's perspective, this is "forwarded traffic"
- Must explicitly allow it

### Linux/iptables Learnings

#### **1. iptables Chains**

**Three main chains for our use case:**
- **INPUT:** Traffic destined FOR the NVA itself
- **OUTPUT:** Traffic originating FROM the NVA itself
- **FORWARD:** Traffic passing THROUGH the NVA (what we need!)

**Common Mistake:** Putting rules in INPUT/OUTPUT instead of FORWARD.

#### **2. iptables Rule Order Matters**

**Rules are evaluated top-to-bottom, first match wins:**
```bash
# Wrong order:
sudo iptables -A FORWARD -j ACCEPT     # Rule 1: Allow everything
sudo iptables -A FORWARD -p tcp --dport 22 -j DROP  # Rule 2: Never reached!

# Correct order:
sudo iptables -I FORWARD 1 -p tcp --dport 22 -j DROP  # Rule 1: Block SSH
sudo iptables -A FORWARD -j ACCEPT                     # Rule 2: Allow rest
```

**Use -I (insert) for specific blocks, -A (append) for catch-all rules.**

#### **3. Make iptables Rules Persistent**

**Rules are lost on reboot unless saved:**
```bash
# Save current rules
sudo netfilter-persistent save

# Or manually
sudo iptables-save > /etc/iptables/rules.v4
```

**Test after reboot:**
```bash
sudo reboot
# After reboot:
sudo iptables -L -n -v  # Verify rules are still there
```

#### **4. Logging for Debugging**

**Add logging to troubleshoot:**
```bash
sudo iptables -A FORWARD -j LOG --log-prefix "NVA-DEBUG: " --log-level 4

# Watch logs:
sudo tail -f /var/log/kern.log | grep NVA-DEBUG
```

**Warning:** Don't leave verbose logging in production (performance impact).

### Terraform/IaC Best Practices

#### **1. One Source of Truth**

**The Problem:**
- Created resource manually in Portal
- Also defined in Terraform
- Result: Conflicts, duplicate resources

**The Solution:** Pick ONE:
- **Option A:** Everything via Terraform (recommended for production)
- **Option B:** Terraform for base infrastructure, Portal for testing/temporary changes
- **Option C:** Hybrid - Clear documentation of what's managed where

**This Lab:** We used hybrid approach:
- Terraform: VNets, VMs, NSGs (foundational infrastructure)
- Portal: Peerings, Route Tables (demonstration/learning)

**For production:** 100% Terraform or other IaC tool.

#### **2. Service Principal vs Azure CLI Auth**

**What we learned:**

**Azure CLI Auth:**
- Easy for getting started
- Requires `az` command in PATH
- User's credentials
- Not suitable for automation

**Service Principal:**
- No external dependencies
- Explicit credentials
- Can be scoped/restricted
- **Better for CI/CD, team environments**

**This lab taught:** Service Principal setup once, use everywhere.

#### **3. Variable Management**

**Security:**
```hcl
# Never commit secrets!
terraform.tfvars  # Contains SSH keys, IPs - .gitignore this
terraform.tfvars.example  # Safe template - commit this
```

**Best Practice:**
```bash
# In CI/CD: Use Azure Key Vault or environment variables
# Locally: Use terraform.tfvars (gitignored)
# Share with team: terraform.tfvars.example (sanitized)
```

#### **4. Terraform State Management**

**Local State (what we used):**
- Simple for learning
- `terraform.tfstate` file in local directory
- **Problem:** Can't collaborate, no locking

**Production:** Use remote state:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatestore"
    container_name       = "tfstate"
    key                  = "vna-lab.tfstate"
  }
}
```

### Troubleshooting Best Practices

#### **1. Systematic Debugging**

**The approach that worked:**

1. **Verify the expected behavior:** What SHOULD happen?
2. **Test from outside-in:** 
   - Can you reach VMs from internet? (Public IP)
   - Can VMs reach each other? (Private IP)
   - Is traffic going through NVA? (tcpdump)
3. **Check each layer:**
   - Azure routing (Effective Routes)
   - Azure NIC (IP forwarding enabled?)
   - OS config (IP forwarding in kernel?)
   - iptables rules (correct chain/order?)
4. **Use tcpdump liberally:** See what's actually happening vs what you think is happening

#### **2. Common Gotchas**

**Public IP Changes:**
- Dynamic IPs change frequently
- Always check: `curl ifconfig.me`
- Update NSG rules or use static IP

**Time-based Issues:**
- Route table changes take 1-2 minutes to propagate
- VNet peering takes 30-60 seconds to become "Connected"
- **Don't assume instant changes!**

**Both-Direction Configuration:**
- Routes needed in both directions
- VNet peerings are bidirectional (but need both created)
- iptables rules for both source→dest and dest→source

### Security Considerations

#### **1. Principle of Least Privilege**

**NSG Rules:**
```bash
# Bad: Allow from 0.0.0.0/0
source_address_prefix = "0.0.0.0/0"

# Good: Allow only from your IP
source_address_prefix = "203.45.123.89/32"

# Better: Allow from your organization's IP range
source_address_prefix = "203.45.0.0/16"
```

#### **2. Public IPs - When to Use**

**This lab:** Used public IPs for SSH convenience

**Production alternatives:**
- **Azure Bastion:** No public IPs on VMs, access via Azure Portal
- **VPN Gateway:** Site-to-site or Point-to-site VPN
- **ExpressRoute:** Private connection to Azure
- **Jump Box:** One hardened VM with public IP, SSH through it

#### **3. NVA Security**

**The NVA is critical - secure it:**
- ✅ Restrict SSH to known IPs only
- ✅ Keep OS patched and updated
- ✅ Monitor logs regularly
- ✅ Use managed identity for Azure API access
- ✅ Consider high availability (2+ NVAs with load balancer)

### Cost Optimization

**What we learned:**

**VM Sizing:**
- B1s ($7.50/month) sufficient for lab
- B1ls ($3.80/month) cheaper but limited RAM
- **Stop VMs when not using!**

**Quick stop commands:**
```bash
# Stop all VMs (saves money)
az vm deallocate --resource-group rg-vna-lab --name spoke1-vm --no-wait
az vm deallocate --resource-group rg-vna-lab --name spoke2-vm --no-wait
az vm deallocate --resource-group rg-vna-lab --name nva-vm --no-wait

# Start when needed
az vm start --resource-group rg-vna-lab --name spoke1-vm --no-wait
az vm start --resource-group rg-vna-lab --name spoke2-vm --no-wait
az vm start --resource-group rg-vna-lab --name nva-vm --no-wait
```

**Cost for 2-3 day lab:** ~$2-3 total if you stop VMs between sessions.

### Production Considerations

**If implementing this in production:**

#### **1. High Availability**

- Deploy 2+ NVAs in different availability zones
- Use Azure Load Balancer for active-active
- Or use Azure Route Server for BGP-based failover

#### **2. Monitoring**

- Send iptables logs to Azure Monitor/Log Analytics
- Set up alerts for dropped packets
- Monitor NVA CPU/memory
- Use Network Watcher for flow logs

#### **3. Performance**

- Use accelerated networking on NIC
- Use larger VM sizes (D-series, F-series)
- Consider Azure Virtual WAN with secured virtual hub
- Or Azure Firewall (managed NVA solution)

#### **4. Automation**

- Everything in Terraform/IaC
- Automated testing (ping tests, connectivity checks)
- CI/CD pipeline for changes
- GitOps workflow

### When to Use What

**Use VNet Peering When:**
- ✅ Simple connectivity needed
- ✅ Low latency critical
- ✅ No inspection requirements
- ✅ Small number of VNets (< 5)
- ✅ Trust between workloads

**Use NVA When:**
- ✅ Traffic inspection required
- ✅ Compliance/regulatory requirements
- ✅ Centralized security policies needed
- ✅ Many VNets (hub-and-spoke scales better)
- ✅ Zero-trust architecture
- ✅ Need IDS/IPS capabilities

**Consider Azure Firewall When:**
- ✅ Want managed NVA solution
- ✅ Integrated threat intelligence
- ✅ Don't want to manage VMs
- ✅ Budget allows (~$900/month)

### Real-World Application

**This lab demonstrates concepts used in:**

**1. Enterprise Hub-and-Spoke:** Central IT controls security, business units get spoke VNets

**2. Multi-tier Applications:** Web tier, app tier, database tier with controlled inter-tier traffic

**3. Dev/Test/Prod Isolation:** Development can't reach production directly

**4. Compliance Requirements:** Financial, healthcare industries requiring traffic inspection

**5. Zero Trust Networks:** Inspect all traffic, even between trusted zones

---

**Next:** Cleanup & Cost Management
