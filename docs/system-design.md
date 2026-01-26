# System Design and Security Architecture

This document describes the full system design of the security platform, including
architecture, layers, technologies, routes, security dependencies, and integrations.

## 1) Architecture Summary

- **Style**: Microservices + centralized identity
- **Protocols**: OAuth2 + OpenID Connect (OIDC)
- **Token format**: JWT access tokens validated via JWKS
- **Deployment target**: Azure (AKS + Static Web Apps + Key Vault)

## 2) Core Components

### Identity Provider (Azure Entra ID / B2C)

**Responsibilities**
- User authentication and MFA
- Issuing JWT access tokens
- Managing roles and group claims

**Terraform artifacts**
- Azure AD app registrations (API apps + SPA app)
- Scopes for resource access (`access_as_user`)
- Service principals for each app

### Security Service

**Responsibilities**
- Central policy and claims mapping
- Permission derivation and audit-friendly endpoints
- Integration point for token exchange rules (future OBO)

**Key routes**
- `GET /me`
- `GET /permissions`

**Security dependencies**
- `spring-boot-starter-security`
- `spring-boot-starter-oauth2-resource-server`
- Custom JWT claims converter
- `security.claims.group-role-mappings`

### Project Hub (Business Service)

**Responsibilities**
- Domain CRUD APIs (projects, owners, addresses, files)
- Local JWT validation
- Role-based authorization

**Security dependencies**
- `spring-boot-starter-security`
- `spring-boot-starter-oauth2-resource-server`
- Custom JWT claims converter

**Legacy auth**
- Custom `/api/auth/**` login removed
- No local password auth or JWT issuance

### Angular Client

**Responsibilities**
- User interface for Project Hub
- OIDC login via MSAL

**Security dependencies**
- `@azure/msal-angular`
- `@azure/msal-browser`
- MSAL HTTP interceptor for bearer tokens

## 3) Security Patterns and Flows

### Interactive Clients

- **Authorization Code + PKCE**
- Used by web, mobile, and terminal clients
- Tokens obtained from IdP and attached to API calls

### Service-to-Service

- **Client Credentials**
- Each internal service has a client identity

### Delegated Downstream Calls

- **On-Behalf-Of (OBO)**
- Service receives a user token and exchanges for downstream access

## 4) Routes and APIs (Security-related)

### security-service
- `GET /me`
- `GET /permissions`

### project-hub
- Existing CRUD routes under `/api/*`
- No `/api/auth/**` endpoints

### Angular
- `/login` triggers MSAL redirect
- Guarded routes require valid session

## 5) Claims and Role Mapping

Roles and groups from Azure AD are mapped in Spring:

```yaml
security:
  claims:
    group-role-mappings:
      "aad-group-guid": "ADMIN"
```

The converter maps:
- `roles` claim to `ROLE_*`
- `groups` claim to `ROLE_*` using the mapping
- `scp` (scope) claim to `SCOPE_*`

## 6) Infrastructure and Deployment

**Terraform**
- Resource Group
- VNet + subnet
- AKS
- ACR
- Key Vault
- Log Analytics + App Insights
- Static Web App
- Azure AD app registrations

**Helm**
- Dedicated charts for `security-service` and `project-hub`
- Overlays for `dev`, `stage`, `prod`
- Release notes in `templates/NOTES.txt`

**CI/CD**
- GitHub Actions: build Docker images, push to ACR, deploy via Helm
- Angular builds deploy to Static Web Apps

## 7) Integration Flow (End-to-End)

1. User authenticates via Entra ID/B2C.
2. IdP issues JWT access token.
3. Angular calls `project-hub` with token.
4. `project-hub` validates token (issuer + audience).
5. Roles/groups/scopes are mapped to authorities.
6. `security-service` provides permission mapping when needed.
7. Service-to-service calls use Client Credentials or OBO.

## 8) Security Controls

- MFA and Conditional Access (IdP)
- Local JWT validation in each service
- Stateless authentication (no sessions)
- Least-privilege permissions
- Centralized audit trails via Azure monitoring
