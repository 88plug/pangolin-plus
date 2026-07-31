**Workaround using Traefik Proxy Cookie plugin**

This bug bricked my first Pangolin install - added a resource with "Accept Clients" enabled and immediately got locked into a redirect loop. Couldn't access the dashboard at all, had to nuke the config and start fresh.

The root cause: `p_session_token` cookie is scoped to the exact hostname (`Domain=example.com`) instead of the wildcard (`Domain=.example.com`), so subdomain resources with Badger auth can't see the session cookie → infinite redirect. This affects any deployment, not specific to any proxy/CDN setup.

Fixed it with [traefik-plugin-proxy-cookie](https://plugins.traefik.io/plugins/63f635069454451553c1c914/proxy-cookie) to rewrite cookie domains at the Traefik layer:

**traefik.yml:**
```yaml
experimental:
  plugins:
    proxyCookie:
      moduleName: "github.com/SchmitzDan/traefik-plugin-proxy-cookie"
      version: "v0.0.2"
```

**dynamic_config.yml:**
```yaml
http:
  middlewares:
    cookie-domain-fix:
      plugin:
        proxyCookie:
          domain:
            rewrites:
              - regex: "^(example\\.com)$"
                replacement: ".example.com"

  routers:
    # apply to pangolin dashboard/api routers
    next-router:
      rule: "Host(`example.com`)"
      middlewares: ["cookie-domain-fix"]
      # ... rest of config
```

This intercepts `Set-Cookie` responses and rewrites the domain to include the leading dot, making the session cookie valid across all subdomains. Works for both regular auth and OIDC flows.
