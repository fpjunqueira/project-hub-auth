# Security Platform Architecture

## Auth Patterns and Flows

**Primary choice: OAuth2 + OpenID Connect (OIDC)**

- **Authorization Code + PKCE** for web/mobile/terminal clients.
- **Client Credentials** for service-to-service calls.
- **On-Behalf-Of (OBO)** when a service calls another service under user context.

**Why not SAML for APIs?**

- SAML is optimized for browser-based SSO and enterprise portals.
- It is heavier for mobile/SPA and not ideal for API authorization.
- OIDC is the current best practice for modern APIs and microservices.

## Token Strategy

- **JWT access tokens** signed by the IdP.
- Services validate tokens locally via **JWKS** to avoid per-request IdP calls.
- Short-lived access tokens + refresh tokens for interactive clients.

## Roles and Permissions

- Roles from IdP claims (e.g., `roles`, `groups`, `scp`).
- Mapped into app permissions (RBAC, with optional ABAC later).

## Azure Identity Provider

**Managed IdP**: Azure Entra ID or Azure AD B2C

- MFA and Conditional Access built-in.
- Tight integration with Azure hosting and monitoring.

## High-Level Flow

1. Client authenticates with IdP.
2. IdP issues JWT access token.
3. Client calls APIs with bearer token.
4. Each service validates JWT and enforces permissions.
5. Optional: security-service supplies centralized permission logic and audit endpoints.
