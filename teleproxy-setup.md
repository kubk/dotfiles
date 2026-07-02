# Teleproxy Setup Notes

Target server: `ssh tencent-bangkok`  
Current public IP: `43.133.98.242`  
Current private IP seen by the VM: `10.15.0.6`

This is not a full tutorial. It is the handoff for the parts that were easy to get wrong.

## Key Gotchas

- Tencent Lighthouse has its own firewall. Opening `443/tcp` on the VM is not enough; add an inbound Tencent firewall rule for TCP `443`.
- Do not use Teleproxy `direct = true` for parents. Text may work, but media can fail for non-Premium Telegram users. Use normal relay mode.
- Relay mode needs Telegram relay files:

```bash
sudo curl -fsSL https://core.telegram.org/getProxySecret -o /etc/teleproxy/proxy-secret
sudo curl -fsSL https://core.telegram.org/getProxyConfig -o /etc/teleproxy/proxy-multi.conf
sudo chown root:teleproxy /etc/teleproxy/proxy-secret /etc/teleproxy/proxy-multi.conf
sudo chmod 0640 /etc/teleproxy/proxy-secret /etc/teleproxy/proxy-multi.conf
```

- Tencent NAT was the main blocker. Without `--nat-info`, Teleproxy started but had `ready_targets 0`, dropped Telegram queries, and Telegram showed the proxy as unavailable. The systemd `ExecStart` must include private-to-public NAT mapping:

```ini
ExecStart=/usr/local/bin/teleproxy --nat-info 10.15.0.6:43.133.98.242 --config /etc/teleproxy/config.toml --aes-pwd /etc/teleproxy/proxy-secret /etc/teleproxy/proxy-multi.conf
```

- After changing the unit:

```bash
sudo systemctl daemon-reload
sudo systemctl restart teleproxy
```

## Config Shape

Keep live secrets out of notes. Read them from the server if needed.

```toml
port = 443
stats_port = 8888
http_stats = true
user = "teleproxy"
direct = false
workers = 0
domain = "www.google.com" # better: replace with a real custom domain

[[secret]]
key = "<32_hex_secret>"
label = "family"

[[secret]]
key = "<32_hex_secret>"
label = "egor-test"
```

Use separate secrets for family and testing so stats are distinguishable and one link can be revoked without breaking the other.

## Domain Advice

A custom domain is useful, but it does not hide the IP. If a censor learns the domain, they can resolve it and block the IP.

The benefit is consistency: current fake TLS uses `www.google.com` while connecting to a Tencent IP, which is detectable as an SNI/IP mismatch. Better setup:

- Point a boring subdomain like `cdn.example.com` to `43.133.98.242`.
- Configure real HTTPS fallback for that domain.
- Set Teleproxy `domain = "cdn.example.com"`.
- Regenerate Telegram links with the domain hex suffix.

For 2-5 private family users, do this if a domain is already available. Do not squander on rotating infrastructure unless the IP is blocked or a link leaks.

## Link Format

Telegram link:

```text
https://t.me/proxy?server=<public_ip_or_domain>&port=443&secret=ee<32_hex_secret><hex_of_fake_tls_domain>
```

Example domain suffix:

```bash
printf '%s' 'cdn.example.com' | xxd -ps -c 256
```

Do not publish the link. If it leaks, rotate that specific secret. Secret rotation does not help after the IP is blocked.

## Verification

Port reachability from local machine:

```bash
nc -vz -w 8 43.133.98.242 443
```

Fake TLS fallback should look like normal TLS for the configured domain:

```bash
printf '' | openssl s_client -connect 43.133.98.242:443 -servername www.google.com -tls1_3 -brief
```

Stats are local-only on the VM:

```bash
curl -fsS http://127.0.0.1:8888/stats | grep -E '^(ready_targets|total_ready_targets|direct_mode|secret_.*_connections_created|dropped_queries|tot_forwarded_queries|tot_forwarded_responses|transport_errors_received)'
```

Healthy relay-mode signs:

- `ready_targets` is greater than `0`; current working setup showed `19`.
- `direct_mode` is `0`.
- `dropped_queries` does not climb when testing from Telegram.
- The relevant `secret_<label>_connections_created` counter increases after opening the Telegram link.

Logs:

```bash
sudo journalctl -u teleproxy --since '15 minutes ago' --no-pager -o short-iso
sudo systemctl status teleproxy --no-pager -l
```

