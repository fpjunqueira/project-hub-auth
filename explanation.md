# Security Service - Deep Explanation

## 1) Business Purpose

This service is the centralized identity and authorization adapter for the system. It sits
between the Identity Provider (Azure Entra ID / B2C) and the internal microservices and
clients. Its responsibilities are:

- Validate JWT access tokens issued by the IdP.
- Convert IdP claims (roles, groups, scopes) into internal Spring Security authorities.
- Map roles to concrete permissions that the rest of the system can understand.
- Provide identity/permission introspection endpoints for clients and audit tooling.

The result is a single, consistent source of truth for "who is the user" and "what can they do".

## 2) High-Level Architecture

This is a Spring Boot OAuth2 Resource Server with a thin API surface and a focused security
layer:

- **Entry point**: `SecurityServiceApplication` starts the Spring Boot app.
- **Security config**: `SecurityConfig` defines JWT validation and the security filter chain.
- **Claims mapping**: `SecurityClaimProperties` reads group-to-role mappings from config.
- **JWT conversion**: `JwtAuthoritiesConverter` builds Spring authorities from JWT claims.
- **Permissions**: `PermissionService` maps roles to application permissions.
- **API**: `IdentityController` exposes `/me` and `/permissions`.

## 3) Authentication and Authorization Flow

### 3.1 JWT Validation

The service is configured as a resource server:

- The token issuer and audience are configured in `application.yml`.
- Spring Security fetches JWKS from the issuer and validates the token signature and claims.

Key config:

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: ${OIDC_ISSUER_URI:https://login.microsoftonline.com/your-tenant-id/v2.0}
          audiences: ${OIDC_AUDIENCE:api://security-service}
```

### 3.2 Claims to Authorities

`JwtAuthoritiesConverter` converts JWT claims into Spring `GrantedAuthority` values:

- `roles` claim (array) -> `ROLE_<value>`
- `groups` claim (array) -> mapped via `security.claims.group-role-mappings`
- `scp` claim (space-delimited) -> `SCOPE_<scope>`

This gives the rest of the system a consistent authority model regardless of the IdP's raw
claim shape.

### 3.3 Authorities to Permissions

`PermissionService` converts roles into explicit permissions:

- `ROLE_ADMIN` -> read/write permissions for projects, owners, files
- `ROLE_USER` -> read-only permissions for those domains

This isolates permission logic in one place and makes it easy to grow into a richer policy
system later.

## 4) API Endpoints

### `GET /me`

Returns identity details for the current request:

- Authentication status
- User name
- Authorities
- When using JWT: subject, issuer, audience, and full claims payload

This is useful for debugging, auditing, and verifying IdP claims.

### `GET /permissions`

Returns the resolved permission set for the authenticated user based on roles/authorities.

## 5) Configuration and External Integration

### 5.1 Group-to-Role Mappings

The service supports mapping IdP group IDs to internal role names:

```yaml
security:
  claims:
    group-role-mappings:
      "00000000-0000-0000-0000-000000000000": "ADMIN"
```

This allows admins to change role mappings without code changes.

### 5.2 Operational Endpoints

Only health and info endpoints are exposed by default:

- `/actuator/health`
- `/actuator/info`

These are publicly accessible per security configuration and intended for monitoring.

## 6) Business Use Cases

- **Centralized permission resolution**: other services can call `/permissions` to determine
  what a user can do.
- **Identity introspection**: clients and internal tools can call `/me` to view claims and
  authorities, simplifying debugging.
- **Consistent authorization model**: roles and permissions are normalized regardless of
  IdP-specific claim formats.

## 7) Extensibility and Future Growth

This architecture is intentionally small but extensible:

- Add new roles and permission sets by updating `PermissionService`.
- Add new claim mappings or different claim sources in `JwtAuthoritiesConverter`.
- Externalize mappings to config or database if needed.
- Add new authorization endpoints without changing core security flow.

## 8) Integration With the Other Projects

This service integrates via **HTTP + JWT** and is designed to be called by both the Angular UI
and any backend service that needs identity or permission lookup:

- **Angular frontend**: sends authenticated requests to `/security/me` or `/security/permissions`
  (proxied or configured base URL). MSAL attaches an access token for the
  `api://security-service` resource.
- **Project Hub backend**: does not call this service directly in the current code, but could
  use it to resolve permissions if you want centralized authorization decisions.

Operationally, the contract is:

1. User authenticates with the IdP and receives a JWT access token.
2. Client calls security-service with `Authorization: Bearer <token>`.
3. Security-service validates the token, maps claims, and returns identity/permissions.

## 9) Key Source References

- `src/main/java/pexper/projects/security_service/config/SecurityConfig.java`
- `src/main/java/pexper/projects/security_service/security/JwtAuthoritiesConverter.java`
- `src/main/java/pexper/projects/security_service/services/PermissionService.java`
- `src/main/java/pexper/projects/security_service/controllers/IdentityController.java`
- `src/main/resources/application.yml`
