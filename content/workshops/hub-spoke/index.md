---
author: "Maarten van Diemen"
title: "Hub-spoke on Azure workshop"
date: "2026-11-12"
draft: true
weight: 1
description: "Hands-on workshop on building a hub-spoke network topology"
tags: ["Azure", "Networking", "Hub-spoke", "Workshop"]
ShowToc: false
ShowBreadCrumbs: true
---

## Overview
As a developer on Azure you often hear "that's in the hub", "it goes through the firewall" or "check the private DNS zone". 
This hands-on workshop makes those terms concrete. You start with a simple, public web app and database, then move it step by step into a hub-spoke network, until it is only reachable through a controlled entrance. 
You build and test every step yourself. 
This workshop is meant for developers who build and run applications on Azure and want to understand the network underneath them. 
No networking background needed.

## What you will learn
- Network basics: VNets, subnets and address planning.
- Hub-spoke: what belongs in the hub and what in a spoke, and how peering works.
- Traffic control: network security groups, firewall and routing between spokes.
- Private endpoints and private DNS: taking SQL, Key Vault and the web app off the internet, and why DNS is the usual culprit.
- Controlled entrance: an Application Gatewaint.
- Troubleshooting: a fixed order of checks and the tools for each.
- Infrastructure as code: the whole environment a pipeline.

## Prerequisites
- Azure subscription (approxomately costs per 24h of running: 15 dollar)
    * Preferable an Azure subscription that's not connected to your company account. Since the change is high that policies are applied to this subscription which will result in that you can't complete the excercises.
- [.NET 11](https://dotnet.microsoft.com/en-us/download/dotnet/11.0) 
- [Docker](https://www.docker.com/) or [podman](https://podman.io/)  (for running the application locally)
- [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/)

## Exercises

### Overview
Imagine you work at a company that has a to-do list application, called **TodoItems**. It runs in the background: other applications and users send it requests to create and read to-do items.

An item can get a due date, but only on a working day, never in a weekend or on a public holiday. Working out what counts as a working day is more complicated than it sounds, because it depends on the country and its holidays. 
So TodoItems does not do this itself. It asks the **Calendar API**, a separate service that is built and run by a different team. That way every application in the company can use the same calendar instead of building its own.

![System overview: a user sends requests to the TodoItems application, which asks the Calendar API, owned by another team, for the due date of a new item.](./SystemOverview.svg)
Right now everything is simply deployed in Azure, with no boundaries in the network. Anyone on the internet can reach every part. You have been assigned the task to make the application more secure.


### Exercise 1 - Deploy the application
_Expected time: 15 minutes_

0. Ensure you have the [prerequisites](#prerequisites) installed
0. Clone repository: https://github.com/maartenvandiemen/workshop_hub-spoke.
    1. _[Optional]_ run app locally by starting Aspire appHost.
    1. Play with the API by navigating to the url's of the application.
0. Run ```AZD UP``` and follow the instructions.
    1. If you get one warning about permissions you can safely accept this.
0. Browse to the url's that are shown on the screen. Can you post succesfully a todo item?

### Excercise 2 - Create Hub, link spokes
_Expected time: 45 minutes_

In this excercise we're going to setup the resources for the hub-spoke architecture. 
At the end our solution will look like the following:
{{< figure src="NetworkOverview.svg" link="NetworkOverview.svg" target="_blank" alt="Network overview" caption="Click the picture for a larger version" >}}

#### Setup hub-spoke
1. Create the network hub (resource group).
1. Create a virtual network. Address space 10.0.0.0/16
    - During the creation of the virtual network deploy a firewall. SKU _basic_
    - Ensure that the subnet addresses match the Network overview diagram above
1. Create a VM from Azure configure the following settings:
    1. Networking
        1. Virtual network: select the spoke network
        1. Subnet: select the subnet of the spoke network
        1. Public IP: none
        1. NIC: basic
        1. Public inbound ports: none
        1. Delete NIC when VM is deleted: enable
    1. Monitoring
        1. Boot diagnostics
1. Setup peering for both spokes.
1. Create route table in Azure and configure this
    1. Tip: write down the private ip of the Azure firewall in advance
1. Configure firewall policy
    1. Tip: add a new _Rule collection_.

#### Test
##### Setup machines for testing
Perform the following steps for each machine:
1. Connect to the VM though Bastion
    - Select developer tier (_only limitation is that you can connect to one VM at a time._)
1. Run the following commands with Powershell when logged in on Bastion
    - ```Install-WindowsFeature -name Web-Server -IncludeManagementTools```
    - ```New-NetFirewallRule -DisplayName "Allow ICMPv4 Echo" -Protocol ICMPv4 -IcmpType 8 -Direction Inbound -Action Allow```
1. Write down the private IP's of both machines

##### Verify
1. Verify the route
    1. Login on the machine of spoke1 (todoitems)
    2. Browse to the private IP of the machine of spoke2 in a browser
        - You should see the default site of IIS.
    3. Open CMD
        1. Run: 
            - ```ping 10.1.1.4```
            - ```tracert -d 10.1.1.4```

##### [Optional] private DNS
Right now the machine is reachable by IP. Fix this by create a private DNS, so that you can browse to the url by web.workshop.local.
   - Editting hosts file is not allowed! 

##### Cleanup
1. Remove manual the following resources per spoke after deleting the virtual machine
    - Bastion
    - VM NSG

### Excercise 3 - Connect app service
_Expected time: 30 minutes_
For both app services
1. Disable public network access
1. Configure virtual network configuration
    1. Create a new subnet. With dubnet delegatyion set to: ```Microsoft.Web/serverfarms```.
    1. Associate new subnet to routetable
    1. Associate the app service to the new subnet
        - Ignore warning: _Used by another App Service Plan_
1. Setup private endpoint
    1. Create a new subnet for your private endpoint (CIDR:27 is enough)
    1. If you get the option Express vs Advanced. Choose: Advanced
        1. Virtual network: private IP configuration: _Dynamically allocate IP address_.
        1. Integrate with private DNS: yes. Create this in the *hub* resourcegroup.  
1. Add NSG to each VNET with the following rules:
    1. Destination: Keyvault. Protocol/ports: TCP 443. Action: Allow
    1. Destination: Sql.SwedenCentral. Protocol/ports: TCP 1433, 11000-11999. Action: Allow.
    1. Destination: 10.0.0.0/8. Protocol/ports: Any. Action: Allow
    1. Destination: Any. Protocol/ports; Any. Action: Deny. 
1. Setup app Gateway


### [Optional] Excercise 4 - SQL and Key Vault



### [Optional] Excercise 5 - Logging
