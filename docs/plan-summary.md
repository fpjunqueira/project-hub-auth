# Security Platform Plan Summary

This document describes the end-to-end plan for the security platform, covering architecture,
identity provider choices, application structure, client integration, Azure provisioning, and
delivery milestones.

## Goals

- Provide centralized authentication and authorization for multiple clients (web, mobile,
  terminals) and service-to-service communication.
- Protect sensitive banking data with modern security standards.
- Deploy all services and the Angular app to Azure with reproducible infrastructure.

## Architecture Overview

- **Primary pattern**: OAuth2 + OpenID Connect (OIDC).
- **Flows**:
  - Authorization Code + PKCE for web/mobile/terminal clients.
  - Client Credentials for service-to-service calls.
  - On-Behalf-Of (OBO) for downstream calls that preserve user context.
- **Tokens**: JWT access tokens validated locally by resource servers using JWKS.
- **Roles and permissions**:
  - Roles/groups come from the IdP and map to permissions.
  - Group-to-role mapping supported in Spring via `security.claims.group-role-mappings`.

## Identity Provider Options (Azure-first)

- **Recommended managed IdP**: Azure Entra ID or Azure AD B2C.
  - Benefits: MFA, Conditional Access, strong Azure integration.
- **Alternatives**: Keycloak, Auth0, Okta.
  - Use if you need on-prem control, custom flows, or non-Azure hosting.

## Applications and Responsibilities

### Security Service (new repo)

- **Purpose**: central policy and identity façade for microservices.
- **Key endpoints**:
  - `GET /me`: authenticated principal and claims.
  - `GET /permissions`: resolved permissions from roles/groups/scopes.
- **Spring stack**: Spring Security + OAuth2 Resource Server + OpenAPI.
- **Config**: `OIDC_ISSUER_URI` and `OIDC_AUDIENCE` for JWT validation.

### Project Hub (existing service)

- Migrated to OAuth2 Resource Server.
- Legacy `/api/auth/**` login removed.
- Relies on JWT validation from IdP and shared role mapping.

### Angular Client (existing app)

- Uses MSAL for Entra ID/B2C login.
- Auth flows use Authorization Code + PKCE.
- Tokens automatically attached via MSAL interceptor.

## Azure + Terraform Provisioning

Terraform provisions the base platform in `infra/`:

- Resource Group
- VNet + subnet
- AKS
- ACR
- Key Vault
- Log Analytics + App Insights
- Static Web App (Angular)
- Azure AD App Registrations (API apps + SPA app)

## CI/CD Pipelines

- **Services**: GitHub Actions build Docker images, push to ACR, deploy via Helm to AKS.
- **Angular**: GitHub Actions build and deploy to Azure Static Web Apps.

## Helm Deployments

Each service has a Helm chart with environment overlays:

- `values-dev.yaml`
- `values-stage.yaml`
- `values-prod.yaml`

Release notes are included via `templates/NOTES.txt`.

## Security and Compliance Notes

- Use short-lived access tokens with refresh tokens for interactive clients.
- Enforce least privilege with role-based mappings.
- Store secrets in Key Vault; use managed identities.
- Enable audit logging (App Insights) for access trails.

## Learning Cronogram (5 weeks)

- **Week 1**: OAuth2/OIDC fundamentals, JWT, PKCE, JWKS.
- **Week 2**: Entra ID/B2C app registrations, MSAL integration, claims mapping.
- **Week 3**: Service-to-service security (Client Credentials, OBO), audit logging.
- **Week 4**: Docker + AKS + secrets management.
- **Week 5**: Terraform end-to-end provisioning and CI/CD pipelines.

## Next Steps Checklist

- Replace placeholder OIDC values in apps and Helm overlays.
- Configure Entra ID/B2C app registrations and consent.
- Provision Azure infra with Terraform.
- Deploy services to AKS and Angular to Static Web Apps.
- Validate authorization policies using `GET /permissions`.
