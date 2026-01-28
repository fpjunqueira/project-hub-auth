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

## Learning Cronogram (5 weeks, 3 hours/day)

### Week 1: OAuth2/OIDC fundamentals, JWT, PKCE, JWKS
- **Day 1 (3h)**: OAuth2 roles and grants overview; threat model for banking.
- **Day 2 (3h)**: OIDC discovery, JWKS, token structure walkthrough.
- **Day 3 (3h)**: Authorization Code + PKCE flow deep dive.
- **Day 4 (3h)**: Build a minimal Spring Resource Server locally.
- **Day 5 (3h)**: Token validation debugging and claim inspection.

### Week 2: Entra ID/B2C, MSAL, claims mapping
- **Day 1 (3h)**: Entra ID/B2C app registrations and scopes.
- **Day 2 (3h)**: SPA app registration + redirect URIs.
- **Day 3 (3h)**: MSAL Angular integration and login flow.
- **Day 4 (3h)**: Claims mapping in Spring (`roles`, `groups`, `scp`).
- **Day 5 (3h)**: End-to-end login + API call with JWT.

### Week 3: Service-to-service and audit
- **Day 1 (3h)**: Client Credentials flow and API protection.
- **Day 2 (3h)**: On-Behalf-Of flow and downstream calls.
- **Day 3 (3h)**: Permission modeling (RBAC/ABAC) review.
- **Day 4 (3h)**: Audit logging approach and App Insights basics.
- **Day 5 (3h)**: Security-service permission endpoint validation.

### Week 4: Docker + AKS + secrets
- **Day 1 (3h)**: Dockerize Spring Boot and Angular.
- **Day 2 (3h)**: AKS architecture and namespaces.
- **Day 3 (3h)**: Helm charts and values overlays.
- **Day 4 (3h)**: Key Vault + CSI driver secrets flow.
- **Day 5 (3h)**: Deploy to AKS and validate health endpoints.

### Week 5: Terraform + CI/CD
- **Day 1 (3h)**: Terraform basics, state, providers.
- **Day 2 (3h)**: Provision AKS/ACR/Key Vault/Static Web Apps.
- **Day 3 (3h)**: Azure AD app registrations in Terraform.
- **Day 4 (3h)**: CI/CD pipelines for services and SPA.
- **Day 5 (3h)**: End-to-end pipeline run + deployment verification.

## Topic Subjects and Concepts (summaries)

### Week 1: OAuth2/OIDC fundamentals, JWT, PKCE, JWKS
- **OAuth2 roles and grants**: Defines client, resource server, and auth server roles and the safe flow per client type.
- **Threat model for banking**: Maps risks (token theft, replay, escalation) to controls (MFA, short TTLs, audience checks).
- **OIDC discovery**: Uses metadata discovery to avoid hard-coded endpoints.
- **JWKS**: Retrieves and rotates public keys for JWT validation.
- **Authorization Code + PKCE**: Secure login without client secrets for SPAs/mobile.
- **Spring Resource Server basics**: Minimal configuration for JWT validation.
- **Token debugging**: Inspect issuer, audience, scopes, and claims for troubleshooting.

### Week 2: Entra ID/B2C, MSAL, claims mapping
- **App registrations**: Creates API + SPA apps, sets redirect URIs, and exposes scopes.
- **Scopes and consent**: Covers `access_as_user` and admin consent for delegated access.
- **MSAL setup**: Configures login, token acquisition, and cache management.
- **MSAL interceptor**: Attaches access tokens automatically to protected API calls.
- **Claims mapping**: Maps `roles`, `groups`, and `scp` to Spring authorities.
- **End-to-end auth test**: Verifies login → token → API access with correct claims.

### Week 3: Service-to-service and audit
- **Client Credentials flow**: Service identity for internal API access.
- **OBO flow**: Preserves user context across downstream services.
- **Permission modeling**: Compares RBAC and ABAC for least-privilege access.
- **Audit logging**: Captures user/actions for compliance and traceability.
- **Permission endpoint validation**: Confirms security-service permissions match roles.

### Week 4: Docker + AKS + secrets
- **Dockerization**: Packages services and SPA builds for consistent deploys.
- **AKS basics**: Namespaces, deployments, services, scaling fundamentals.
- **Helm charts**: Templates Kubernetes resources and manages env overlays.
- **Key Vault integration**: Protects secrets and injects them at runtime.
- **Health checks**: Validates readiness and liveness for reliability.

### Week 5: Terraform + CI/CD
- **Terraform foundations**: State, providers, modules, and variables.
- **Azure provisioning**: AKS, ACR, Key Vault, Static Web Apps, monitoring.
- **Azure AD via Terraform**: Automates app registrations and scopes.
- **CI/CD pipelines**: Build, push, and deploy via GitHub Actions + Helm.
- **Deployment verification**: Ensures services and SPA are reachable and secure.

## Next Steps Checklist

- Replace placeholder OIDC values in apps and Helm overlays.
- Configure Entra ID/B2C app registrations and consent.
- Provision Azure infra with Terraform.
- Deploy services to AKS and Angular to Static Web Apps.
- Validate authorization policies using `GET /permissions`.
