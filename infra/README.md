# Azure Infrastructure (Terraform)

This module provisions:
- Resource group, VNet + subnet
- AKS cluster
- ACR
- Key Vault
- Log Analytics + Application Insights
- Azure Static Web App

## Usage

```bash
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

## Variables

- `project_name` (default: `project-hub`)
- `location` (default: `eastus`)
- `resource_group_name` (default: `rg-project-hub`)
- `aks_node_count` (default: `2`)
- `aks_vm_size` (default: `Standard_DS2_v2`)
