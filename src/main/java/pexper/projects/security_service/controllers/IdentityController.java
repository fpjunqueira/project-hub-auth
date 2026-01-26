package pexper.projects.security_service.controllers;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import pexper.projects.security_service.services.PermissionService;

@RestController
public class IdentityController {

    private final PermissionService permissionService;

    public IdentityController(PermissionService permissionService) {
        this.permissionService = permissionService;
    }

    @GetMapping("/me")
    public ResponseEntity<Map<String, Object>> me(Authentication authentication) {
        Map<String, Object> response = new LinkedHashMap<>();
        response.put("authenticated", authentication != null && authentication.isAuthenticated());
        response.put("name", authentication != null ? authentication.getName() : null);
        response.put("authorities", authentication != null ? authentication.getAuthorities() : null);

        if (authentication instanceof JwtAuthenticationToken token) {
            Jwt jwt = token.getToken();
            response.put("subject", jwt.getSubject());
            response.put("issuer", jwt.getIssuer());
            response.put("audience", jwt.getAudience());
            response.put("claims", jwt.getClaims());
        }

        return ResponseEntity.ok(response);
    }

    @GetMapping("/permissions")
    public ResponseEntity<Set<String>> permissions(Authentication authentication) {
        return ResponseEntity.ok(permissionService.resolvePermissions(authentication));
    }
}
