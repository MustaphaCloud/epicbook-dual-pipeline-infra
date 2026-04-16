# EpicBook Infrastructure Pipeline

Azure DevOps CI/CD pipeline that provisions the full Azure infrastructure for the EpicBook bookstore application using Terraform. This is Pipeline 1 of a dual-pipeline capstone deployment built as part of the DevOps Micro Internship (DMI) Cohort-2.

---

## Project Overview

This repository contains the Terraform configuration and Azure DevOps pipeline definition to provision all Azure cloud infrastructure required to run the EpicBook Node.js bookstore application.

The pipeline is triggered on every push to the `main` branch. It authenticates to Azure using a Service Principal, then runs Terraform to provision a complete environment from scratch.

---

## Architecture

```
Azure DevOps (infra-epicbook repo)
        |
        | git push to main
        v
Azure DevOps Pipeline (infra pipeline)
        |
        | ARM_CLIENT_ID / ARM_CLIENT_SECRET / ARM_SUBSCRIPTION_ID / ARM_TENANT_ID
        v
Terraform (plain bash tasks, no TerraformTaskV4)
        |
        v
Azure Resources (epicbook-rg)
  ├── Virtual Network (epicbook-vnet) - 10.0.0.0/16
  ├── Subnet (epicbook-subnet) - 10.0.1.0/24
  ├── Network Security Group (epicbook-nsg)
  │     ├── Allow port 22 (SSH)
  │     ├── Allow port 80 (HTTP)
  │     └── Allow port 3000 (App fallback)
  ├── Public IP (Standard SKU, static)
  ├── Network Interface (epicbook-nic)
  ├── Linux Virtual Machine (epicbook-vm)
  │     ├── Size: Standard_D2s_v3
  │     ├── OS: Ubuntu 22.04 LTS
  │     └── Auth: SSH key (injected via pipeline variable)
  └── MySQL Flexible Server (<MYSQL_SERVER_NAME>)
        ├── SKU: B_Standard_B1ms
        ├── MySQL version: 8.0.21
        ├── Database: <MYSQL_DB_NAME>
        └── Firewall: Allow Azure services
```

---

## Repository Structure

```
infra-epicbook/
├── azure-pipelines.yml       # Azure DevOps pipeline definition
├── main.tf                   # Core Terraform resources
├── variables.tf              # Input variable declarations
├── outputs.tf                # Output values (VM IP, MySQL FQDN, etc.)
├── terraform.tfstate         # Local state (tracked for this setup)
└── README.md
```

---

## Pipeline Definition

**File:** `azure-pipelines.yml`

```yaml
trigger:
- main

pool:
  name: epicbook-pool    # Self-hosted agent running on epicbook-agent-vm

steps:
- script: terraform init
  displayName: 'Terraform Init'
  env:
    ARM_CLIENT_ID: $(ARM_CLIENT_ID)
    ARM_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
    ARM_SUBSCRIPTION_ID: $(ARM_SUBSCRIPTION_ID)
    ARM_TENANT_ID: $(ARM_TENANT_ID)

- script: terraform apply -auto-approve
  displayName: 'Terraform Apply'
  env:
    ARM_CLIENT_ID: $(ARM_CLIENT_ID)
    ARM_CLIENT_SECRET: $(ARM_CLIENT_SECRET)
    ARM_SUBSCRIPTION_ID: $(ARM_SUBSCRIPTION_ID)
    ARM_TENANT_ID: $(ARM_TENANT_ID)
    TF_VAR_ssh_public_key: $(TF_VAR_ssh_public_key)
```

**Why plain bash tasks instead of TerraformTaskV4:** The `TerraformTaskV4` extension requires a `backendServiceArm` parameter even when using local state. Using plain `script` tasks with ARM environment variables avoids that constraint and keeps the pipeline self-contained.

---

## Key Terraform Files

### `main.tf`

Provisions all Azure resources inside the `epicbook-rg` resource group in a specified Azure region. The SSH public key for the VM is passed in as a Terraform variable (`TF_VAR_ssh_public_key`) rather than read from disk using `file()`. This is because the `file()` function fails inside Azure DevOps pipelines where the local filesystem does not contain the key.

### `variables.tf`

| Variable | Default | Description |
|---|---|---|
| `location` | `<AZURE_REGION>` | Azure region |
| `admin_username` | `<VM_ADMIN_USERNAME>` | VM SSH username |
| `mysql_admin_username` | `<MYSQL_ADMIN_USERNAME>` | MySQL admin username |
| `mysql_admin_password` | (secret) | MySQL admin password |
| `mysql_db_name` | `<MYSQL_DB_NAME>` | MySQL database name |
| `ssh_public_key` | (pipeline variable) | Public key for VM SSH access |

### `outputs.tf`

| Output | Description |
|---|---|
| `app_public_ip` | Public IP address of the EpicBook VM |
| `mysql_fqdn` | Fully qualified domain name of the MySQL server |
| `mysql_admin_username` | MySQL admin username |
| `mysql_db_name` | MySQL database name |

---

## Pipeline Variables

The following variables must be configured in Azure DevOps under Pipeline > Variables before running:

| Variable | Type | Description |
|---|---|---|
| `ARM_CLIENT_ID` | Secret | Service Principal application ID |
| `ARM_CLIENT_SECRET` | Secret | Service Principal password |
| `ARM_SUBSCRIPTION_ID` | Secret | Azure subscription ID |
| `ARM_TENANT_ID` | Secret | Azure Active Directory tenant ID |
| `TF_VAR_ssh_public_key` | Secret | Content of `~/.ssh/epicbook-key.pub` |

---

## Agent Setup

This pipeline runs on a self-hosted agent inside `epicbook-agent-vm`, a separate Azure VM provisioned in a dedicated resource group using the Terraform configuration in the `agent-vm/` folder.

**Agent VM specs:**
- Resource group: `<AGENT_RESOURCE_GROUP>`
- Size: Standard_B2s
- OS: Ubuntu 22.04
- Agent pool: `epicbook-pool`
- Agent name: `epicbook-agent`

The agent VM is provisioned once and kept running while the pipelines are active. It is destroyed separately after all assignments are complete.

---

## Service Principal Setup

The Service Principal `epicbook-devops-sp` was created with Contributor access to the Azure subscription:

```bash
az ad sp create-for-rbac \
  --name epicbook-devops-sp \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>
```

The output `appId`, `password`, and `tenant` values were stored as pipeline secrets.

---

## Infrastructure Outputs After Successful Run

```
app_public_ip        = "<VM_PUBLIC_IP>"
mysql_fqdn           = "<MYSQL_SERVER_NAME>.mysql.database.azure.com"
mysql_admin_username = "<MYSQL_ADMIN_USERNAME>"
mysql_db_name        = "<MYSQL_DB_NAME>"
```

These values are consumed by the App Pipeline (Pipeline 2) to configure the Ansible inventory and MySQL connection.

---

## Destroying Infrastructure

```bash
cd infra-epicbook
terraform init
terraform destroy -auto-approve
```

Run this after verifying the deployment to avoid ongoing Azure costs.

---

## Related Repository

**App Pipeline:** [epicbook-dual-pipeline-app](https://github.com/MustaphaCloud/epicbook-dual-pipeline-app)

The app pipeline consumes the infrastructure provisioned by this repo and deploys the EpicBook Node.js application using Ansible.

---

## Part of DMI Cohort-2

Built as Assignment 4 (Capstone) of the DevOps Micro Internship led by Pravin Mishra.

Community: https://lnkd.in/eg8dbRrM

**GitHub:** [MustaphaCloud](https://github.com/MustaphaCloud)
