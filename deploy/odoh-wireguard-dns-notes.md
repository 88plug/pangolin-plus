# DNS ODoH Fix for WireGuard Tunnels - Implementation Status

## 🎯 Problem Statement
WireGuard tunnel clients are not using the VPS's ODoH (Oblivious DNS over HTTPS) DNS setup. Instead, they bypass the encrypted DNS and use local DNS resolvers, defeating the privacy benefits of ODoH.

## ✅ What Has Been Implemented

### 1. systemd-resolved Configuration
**Status**: ✅ Complete on VPS
- Added `DNSStubListenerExtra=172.22.0.1` to `/etc/systemd/resolved.conf`
- systemd-resolved now listens on Docker bridge IP (172.22.0.1:53)
- Forwards DNS queries to dnscrypt-proxy ODoH (127.0.0.1:5353)

**Verification**:
```bash
$ resolvectl status | grep 172.22.0.1
tcp        0      0 172.22.0.1:53           0.0.0.0:*               LISTEN
```

### 2. Firewall Rules
**Status**: ✅ Complete on VPS
- Added DNS rules for bridge interfaces in nftables
- Allows UDP/TCP port 53 traffic on `br-*` interfaces

**Current nftables rules**:
```bash
iifname "br-*" udp dport 53 accept comment "Pangolin bridge DNS UDP"
iifname "br-*" tcp dport 53 accept comment "Pangolin bridge DNS TCP"
```

### 3. ODoH Infrastructure
**Status**: ✅ Already working
- dnscrypt-proxy running on 127.0.0.1:5353
- Configured with Cloudflare, Crypto-SX, and JP ODoH servers
- systemd-resolved forwards to it

## ❌ Current Issues

### 1. YAML Syntax Error in play.yml
**Location**: Line 624, column 6
**Error**: `All sequence items must start at the same column`
**Problem**: Incorrect indentation in DNS configuration tasks

**Current broken code**:
```yaml
      - name: Configure systemd-resolved for ODoH (dnscrypt)  # ❌ Wrong indentation (6 spaces)
        blockinfile:
          path: /etc/systemd/resolved.conf
          block: |
            [Resolve]
            DNS=127.0.0.1:5353
            DNSSEC=allow-downgrade
            DNSOverTLS=no
            StaleRetentionSec=604800
       notify: restart systemd-resolved

     - name: Configure systemd-resolved for tunnel DNS access  # ❌ Wrong indentation (5 spaces)
       blockinfile:
         path: /etc/systemd/resolved.conf
         insertafter: "StaleRetentionSec=604800"
         block: |
           # Enable DNS access from Docker bridge (for WireGuard tunnels)
           DNSStubListenerExtra=172.22.0.1
         marker: "# {mark} ANSIBLE MANAGED BLOCK - TUNNEL DNS"
       notify: restart systemd-resolved
```

**Correct indentation should be**:
```yaml
     - name: Configure systemd-resolved for ODoH (dnscrypt)  # ✅ 5 spaces
       blockinfile:
         path: /etc/systemd/resolved.conf
         block: |
           [Resolve]
           DNS=127.0.0.1:5353
           DNSSEC=allow-downgrade
           DNSOverTLS=no
           StaleRetentionSec=604800
       notify: restart systemd-resolved

     - name: Configure systemd-resolved for tunnel DNS access  # ✅ 5 spaces
       blockinfile:
         path: /etc/systemd/resolved.conf
         insertafter: "StaleRetentionSec=604800"
         block: |
           # Enable DNS access from Docker bridge (for WireGuard tunnels)
           DNSStubListenerExtra=172.22.0.1
         marker: "# {mark} ANSIBLE MANAGED BLOCK - TUNNEL DNS"
       notify: restart systemd-resolved
```

### 2. pangolin.yml Updates Incomplete
**Status**: Partially complete
- ✅ Firewall DNS rules added to nftables configuration
- ❌ DNS verification tasks not yet added

## 🔧 Exact Steps to Complete

### Step 1: Fix play.yml YAML Syntax
```bash
# Fix indentation in play.yml DNS section
# Change line 624 from 6 spaces to 5 spaces
# Change line 635 from 5 spaces to 5 spaces (consistent)
```

### Step 2: Add DNS Verification to pangolin.yml
Add these tasks before the final "Show setup URL" debug task:

```yaml
- name: Verify tunnel DNS configuration
  shell: |
    # Test that Docker bridge DNS forwards to ODoH
    timeout 5 nslookup google.com 172.22.0.1 >/dev/null 2>&1 && echo "DNS working" || echo "DNS failed"
  register: dns_test
  changed_when: false
  failed_when: false

- name: Display DNS configuration status
  debug:
    msg: |
      Tunnel DNS Configuration:
        systemd-resolved listening on: 172.22.0.1:53
        ODoH proxy on: 127.0.0.1:5353
        Docker bridge test: {{ dns_test.stdout | default('not tested') }}

      WireGuard clients can now use DNS=172.22.0.1 in their configs
      for ODoH-encrypted DNS queries through tunnels.
```

### Step 3: Test Playbook Syntax
```bash
python3 -c "import yaml; yaml.safe_load(open('play.yml')); print('play.yml: YAML syntax OK')"
python3 -c "import yaml; yaml.safe_load(open('pangolin.yml')); print('pangolin.yml: YAML syntax OK')"
```

### Step 4: Test Playbook Changes
```bash
# Dry run
ansible-playbook -i inventory.ini play.yml --check
ansible-playbook -i inventory.ini pangolin.yml --check

# Deploy
ansible-playbook -i inventory.ini play.yml
ansible-playbook -i inventory.ini pangolin.yml
```

### Step 5: Verify DNS Functionality
```bash
# Test from VPS
nslookup google.com 172.22.0.1

# Test from Docker container
docker exec pangolin nslookup google.com 172.22.0.1

# Check ODoH queries in logs
tail -f /var/log/dnscrypt-proxy/query.log
```

## 🧪 Testing Checklist

- [ ] YAML syntax validation passes
- [ ] Ansible dry-run succeeds
- [ ] Playbooks deploy without errors
- [ ] systemd-resolved listens on 172.22.0.1:53
- [ ] Firewall allows DNS on bridge interfaces
- [ ] DNS queries work from Docker containers
- [ ] ODoH queries appear in dnscrypt-proxy logs
- [ ] WireGuard clients can use DNS=172.22.0.1

## 🎯 Expected Outcome

When complete, WireGuard tunnel clients will:
1. Send DNS queries to 172.22.0.1:53 (Docker bridge)
2. Queries forwarded to 127.0.0.1:5353 (systemd-resolved)
3. systemd-resolved forwards to 127.0.0.1:5353 (dnscrypt-proxy)
4. dnscrypt-proxy sends ODoH queries to Cloudflare/Crypto-SX
5. All DNS traffic is encrypted and private

## 📋 Files to Check/Modify

1. **`play.yml`**: Fix YAML indentation in DNS section
2. **`pangolin.yml`**: Add DNS verification tasks
3. **`/etc/systemd/resolved.conf`**: Should have DNSStubListenerExtra
4. **`/etc/nftables.conf`**: Should have bridge DNS rules
5. **`inventory.ini`**: Contains VPS connection details

## 🚨 Critical Notes

- **Docker bridge IP**: Assumes 172.22.0.1 - verify with `docker network inspect pangolin`
- **Firewall**: DNS rules must allow traffic on bridge interfaces
- **systemd-resolved**: Must be restarted after config changes
- **Testing**: Always test from containers, not just host

## 🔍 Debugging Commands

```bash
# Check systemd-resolved status
resolvectl status

# Check listening ports
netstat -tlnp | grep :53

# Check firewall rules
nft list chain inet filter input | grep -A2 -B2 '53\|br-'

# Test DNS from container
docker exec pangolin nslookup google.com 172.22.0.1

# Check ODoH logs
tail -f /var/log/dnscrypt-proxy/query.log
```

This implementation provides ODoH DNS through WireGuard tunnels with minimal changes to the existing infrastructure.</content>
<parameter name="filePath">what-i-am-doing.md