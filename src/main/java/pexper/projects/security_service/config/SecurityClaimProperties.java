package pexper.projects.security_service.config;

import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "security.claims")
public class SecurityClaimProperties {

    private final Map<String, String> groupRoleMappings = new LinkedHashMap<>();

    public Map<String, String> getGroupRoleMappings() {
        return groupRoleMappings;
    }
}
