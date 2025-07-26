# Azure Load Balancer Lab
## Overview
- This lab demonstrates Azure Standard Load Balancer by creating a web application distributed across multiple VMs with automatic health monitoring and traffic distribution.

Internet → Load Balancer Frontend IP → Backend Pool (VM-1 + VM-3)
                                    ↓
                              Health Probes
                                    ↓
                          Traffic Distribution

## Lab Prerequisites

- Completed NSG and VNet Peering Lab
- lab-vm-1: Running nginx in lab-vnet-1/web-subnet
- NSG rules: Allow HTTP (port 80) traffic

## Load Balancer Configuration

- Name: lab-loadbalancer
- Type: Public Standard Load Balancer
- SKU: Standard
- Tier: Regional

## Frontend IP Configuration
- Name: lab-lb-ip
- Type: Public IP Address
- Allocation: Static
- Purpose: Single entry point for users

## Backend Pool
- Name: lab-lb-backendpool
- Virtual Network: lab-vnet-1
- Members:
- lab-vm-1 (10.1.1.4)
- lab-vm-3 (10.1.1.5) - Temporary test VM

## Health Probe
- Name: lab-lb-hp
- Protocol: HTTP
- Port: 80
- Path: / (root)
- Interval: 15 seconds
- Unhealthy threshold: 2 failures

## Load Balancing Rule
- Name: lab-lb-rule
- Frontend Port: 80
- Backend Port: 80
- Protocol: TCP
- Session Persistence: None
- Idle Timeout: 4 minutes

# Implementation Steps
# 1. Web Server Setup
## Install nginx on both VMs
- sudo apt update
- sudo apt install nginx -y
- sudo systemctl start nginx
- sudo systemctl enable nginx

<pre><code>

bash
# Create unique content for each VM  
# VM-1:  
echo '<h1>Hello from VM-1 (10.1.1.4)</h1>' | sudo tee /var/www/html/index.html
  
</code></pre>

# VM-3:
echo '<h1>Hello from TEMP VM (10.1.1.5)</h1>' | sudo tee /var/www/html/index.html

# 2. NSG Configuration
- Updated existing nsg-lab-1 with HTTP access:
- Priority: 130
- Source: Your Public IP
- Destination: 10.1.1.0/24
- Service: HTTP (Port 80)
- Action: Allow

# 3. Load Balancer Creation
# Portal Steps:
- Create Load Balancer → Standard Public
- Configure Frontend IP → Create new public IP
- Configure Backend Pool → Add VMs from lab-vnet-1
- Create Health Probe → HTTP on port 80
- Create Load Balancing Rule → Port 80 traffic distribution

# 4. Backend Pool Configuration
# VMs added to backend pool:
- Resource Name: lab-vm-1
- IP Address: 10.1.1.4
- Resource Group: networking-lab-rg-1

- Resource Name: lab-vm-3  
- IP Address: 10.1.1.5
- Resource Group: networking-lab-rg-1

## Testing Load Balancing
# Browser Testing
# Access load balancer frontend IP
- http://<load-balancer-frontend-ip>

# Expected behavior:
# - Regular browser: May cache connection to one VM
# - Incognito mode: Shows true load balancing
# - Multiple refreshes should alternate between VMs

# Command Line Testing
# Use curl for clean connections
- curl http://<load-balancer-frontend-ip>
- curl http://<load-balancer-frontend-ip>
- curl http://<load-balancer-frontend-ip>

# Should show alternating responses:
# "Hello from VM-1 (10.1.1.4)"
# "Hello from TEMP VM (10.1.1.5)"

## Health Monitoring
# Backend Pool Status Check:

- Navigate to: Load Balancer → Backend pools → lab-lb-backendpool
- Verify both VMs show healthy/running status
- Health probe automatically removes failed VMs from rotation

## Key Learnings
# Load Balancer Concepts
- Frontend IP: Single point of entry for applications
- Backend Pool: Group of servers hosting the application
- Health Probes: Automatic monitoring and failover
- Load Balancing Rules: Traffic distribution logic

# Session Persistence
- None: True load balancing, requests distributed randomly
- Client IP: Same client always goes to same server
- Client IP + Protocol: Even stickier session management

# Browser Behavior
- Regular browsing: Connection reuse and caching affects load balancing visibility
- Incognito mode: Clean connections show true load balancing
- Hard refresh: Ctrl+F5 forces new connections

# High Availability Benefits
- Automatic failover: If VM-1 fails, all traffic goes to VM-3
- Health monitoring: Unhealthy servers automatically removed
- Zero downtime: Maintenance on one VM doesn't affect service

# Load Balancer vs Direct VM Access
# Direct VM Access
# Individual VM endpoints
- http://<vm1-public-ip>  # Always goes to VM-1
- http://<vm3-public-ip>  # Always goes to VM-3

# Load Balanced Access
# Single endpoint, distributed backend
- http://<load-balancer-ip>  # Distributes between VM-1 and VM-3

## Troubleshooting
- Load Balancer Not Distributing Traffic
- Symptoms: Always connects to same VM
# Solutions:
- Check session persistence setting (should be "None")
- Use incognito/private browsing mode
- Clear browser cache
- Use curl instead of browser
- Verify health probe status

# VMs Not Appearing in Backend Pool
- Symptoms: Cannot add VMs to backend pool
# Solutions:
- Ensure VMs are in same VNet as load balancer
- Check VM location matches load balancer region
- Verify VNet peering if using cross-VNet setup

# Symptoms: VMs showing as unhealthy
# Solutions:
- Verify web server is running: sudo systemctl status nginx
- Check NSG allows health probe traffic
- Test local connectivity: curl localhost
- Verify health probe path exists

# Lab Completion Checklist

✅ Created Standard Load Balancer with public frontend
✅ Configured backend pool with multiple VMs
✅ Implemented HTTP health probes
✅ Created load balancing rules for port 80
✅ Tested traffic distribution across VMs
✅ Verified automatic health monitoring
✅ Demonstrated browser vs incognito mode behavior
✅ Documented load balancer concepts and troubleshooting


