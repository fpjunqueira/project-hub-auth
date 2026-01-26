# Security Service

This service provides centralized authorization policy and identity/claims mapping for a
microservices ecosystem. It integrates with a managed Identity Provider (Azure Entra ID / B2C)
and exposes authorization-friendly endpoints for clients and services.

## Why OAuth2 + OIDC

- **OAuth2 + OIDC** is the modern standard for web, mobile, terminal, and service clients.
- **Authorization Code + PKCE** is the safest interactive flow for browser and mobile apps.
- **Client Credentials** is the standard for service-to-service calls.
- **On-Behalf-Of (OBO)** supports downstream service calls using the user context.
- **JWT access tokens** allow resource servers to validate tokens locally with JWKS.

## Core Responsibilities

- Map IdP claims to internal roles/permissions.
- Provide centralized permission evaluation and optional policy decisions.
- Offer a consistent identity endpoint for internal clients and audit needs.

## Endpoints

- `GET /me` - returns the current authenticated principal and claims.
- `GET /permissions` - returns permission set derived from claims + mapping.

## Local Run

```powershell
.\mvnw.cmd spring-boot:run
```

## Configuration

Set your IdP issuer and audience in `application.yml`:

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://login.microsoftonline.com/{tenant}/v2.0
          audiences: api://security-service
```

## Notes

- For Azure Entra ID / B2C, prefer MSAL on clients.
- Protect secrets with Azure Key Vault in production.
