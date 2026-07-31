# Pangolin-plus troubleshooting notes

## Integration API returns 404 on `/api/v1/*` (issue #3334)

Pangolin serves the **dashboard API** and the **integration API** on different
ports/paths depending on config.

In `config.yml`:

```yaml
server:
  # Integration API (for external automation / API keys)
  enable_integration_api: true
  # integration_api_port: 3003   # check docs for your version
```

Hitting the dashboard port with `/api/v1/...` will 404 even when the integration
API is "enabled". Use the integration API bind address/port from the running
compose, or Traefik routes that point at that service.

## Custom response headers (PR #3172)

Resource HTTP settings now have **request** and **response** headers separately.
Existing `headers` column is renamed to `requestHeaders` by migration `1.21.3`.
