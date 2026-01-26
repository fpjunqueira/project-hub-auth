package pexper.projects.security_service.security;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.springframework.core.convert.converter.Converter;
import org.springframework.lang.NonNull;
import org.springframework.lang.Nullable;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;

public class JwtAuthoritiesConverter implements Converter<Jwt, Collection<GrantedAuthority>> {

    private final Map<String, String> groupRoleMappings;

    public JwtAuthoritiesConverter(Map<String, String> groupRoleMappings) {
        this.groupRoleMappings = groupRoleMappings == null
                ? Collections.emptyMap()
                : Map.copyOf(groupRoleMappings);
    }

    @Override
    @SuppressWarnings("java:S2638")
    @Nullable
    public Collection<GrantedAuthority> convert(@NonNull Jwt jwt) {
        List<String> roles = new ArrayList<>();
        Object rolesClaim = jwt.getClaims().get("roles");
        if (rolesClaim instanceof List<?> list) {
            for (Object role : list) {
                if (role != null) {
                    roles.add(role.toString());
                }
            }
        }

        addGroupMappings(jwt, roles);

        String scopeClaim = jwt.getClaimAsString("scp");
        if (scopeClaim != null && !scopeClaim.isBlank()) {
            for (String scope : scopeClaim.split(" ")) {
                roles.add("SCOPE_" + scope);
            }
        }

        return roles.stream()
                .distinct()
                .map(role -> role.startsWith("SCOPE_") ? role : "ROLE_" + role)
                .map(SimpleGrantedAuthority::new)
                .collect(Collectors.toList());
    }

    private void addGroupMappings(Jwt jwt, List<String> target) {
        Object groupsClaim = jwt.getClaims().get("groups");
        if (!(groupsClaim instanceof List<?> list)) {
            return;
        }
        for (Object group : list) {
            if (group == null) {
                continue;
            }
            String groupId = group.toString();
            String mappedRole = groupRoleMappings.get(groupId);
            if (mappedRole != null && !mappedRole.isBlank()) {
                target.add(mappedRole.trim());
            } else {
                target.add(groupId);
            }
        }
    }
}
