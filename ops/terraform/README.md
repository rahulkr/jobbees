# Terraform — Azure infrastructure

**Status:** Placeholder. Build out as part of launch hardening before production deployment.

## Why Terraform (not Bicep)

ADR-001 chose Terraform over Bicep because:

- Multi-cloud capable (path to AWS/GCP if needed)
- Larger community + module ecosystem
- HCL syntax is widely understood
- Bicep would lock us into Azure

## Planned modules

When this is built:

```
ops/terraform/
├── modules/
│   ├── app-service/      # Azure App Service for api, admin, web
│   ├── postgres/         # Flexible Server with pgvector + HA
│   ├── redis/            # Azure Cache for Redis (Standard tier for HA)
│   ├── storage/          # Blob containers for media + RCTI PDFs
│   ├── keyvault/         # Secrets management
│   ├── monitor/          # Application Insights + Log Analytics workspace
│   └── networking/       # VNet, private endpoints, NSGs
├── environments/
│   ├── staging/
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   └── production/
│       ├── main.tf
│       └── terraform.tfvars
└── shared/               # provider config, backend (remote state in Azure Storage)
    └── backend.tf
```

## State management

Remote state in Azure Storage with locking via Azure blob lease (or `azurerm` backend). Never commit `terraform.tfstate` — gitignored.

## Workflow

```bash
# From ops/terraform/environments/staging
terraform init
terraform plan
terraform apply

# Production needs an additional approval gate via GitHub Actions
```

## CI integration (post-MVP)

GitHub Actions workflow:

- On PR touching `ops/terraform/**`: `terraform plan` against staging, post results to PR
- On merge to main: `terraform apply` against staging automatically; production requires manual approval
