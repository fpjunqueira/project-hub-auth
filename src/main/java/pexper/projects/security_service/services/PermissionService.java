package pexper.projects.security_service.services;

import java.util.LinkedHashSet;
import java.util.Set;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.stereotype.Service;

@Service
public class PermissionService {

    public Set<String> resolvePermissions(Authentication authentication) {
        Set<String> permissions = new LinkedHashSet<>();
        if (authentication == null) {
            return permissions;
        }

        for (GrantedAuthority authority : authentication.getAuthorities()) {
            String role = authority.getAuthority();
            permissions.addAll(mapRoleToPermissions(role));
        }

        return permissions;
    }

    private Set<String> mapRoleToPermissions(String role) {
        Set<String> permissions = new LinkedHashSet<>();
        if (role == null) {
            return permissions;
        }

        switch (role) {
            case "ROLE_ADMIN" -> {
                permissions.add("projects:read");
                permissions.add("projects:write");
                permissions.add("owners:read");
                permissions.add("owners:write");
                permissions.add("files:read");
                permissions.add("files:write");
            }
            case "ROLE_USER" -> {
                permissions.add("projects:read");
                permissions.add("owners:read");
                permissions.add("files:read");
            }
            default -> {
            }
        }

        return permissions;
    }
}
