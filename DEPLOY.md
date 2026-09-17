# Deploy WE Match (GCP + Capistrano)

Production: **https://match.womenemerging.org**  
VM: `we-match-web` · IP `34.147.171.215` · project We Connect  
Email: **Resend** (domain `womenemerging.org` verified)

Needs on the server: **Puma**, **Postgres**, **`bin/jobs`** (Solid Queue).

---

## 1. Server prep (already mostly done)

- VM + static IP + HTTP/HTTPS firewall
- GoDaddy A record `match` → `34.147.171.215`
- Packages: git, build tools, Postgres, Nginx, Certbot
- Ruby **3.2.2** via rbenv
- DB user/db `we_match` / `we_match_production`
- Dirs: `/var/www/we-match/{shared,releases}`

### Linked secrets on the server

```bash
# .env — see paste template in chat / env.example
nano /var/www/we-match/shared/.env

# master.key — same file as local/Docker (never commit)
nano /var/www/we-match/shared/config/master.key
# or:  scp config/master.key konkabetse24@34.147.171.215:/var/www/we-match/shared/config/master.key
chmod 600 /var/www/we-match/shared/.env /var/www/we-match/shared/config/master.key
```

### Passwordless sudo for Capistrano restarts

```bash
sudo tee /etc/sudoers.d/we-match <<'EOF'
konkabetse24 ALL=(ALL) NOPASSWD: /bin/systemctl restart we-match-puma, /bin/systemctl restart we-match-jobs, /bin/systemctl status we-match-puma, /bin/systemctl status we-match-jobs, /bin/systemctl is-active we-match-puma, /bin/systemctl is-active we-match-jobs
EOF
sudo chmod 440 /etc/sudoers.d/we-match
```

### GitHub deploy key (server must `git clone` the repo)

Add the server’s SSH public key as a GitHub deploy key on `muhammadahmed1310/we-match`, or use your personal key with agent forwarding.

```bash
ssh-keygen -t ed25519 -C "we-match-web" -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub
# Add that as a read-only deploy key on the GitHub repo
ssh -T git@github.com
```

---

## 2. Capistrano from your laptop

```bash
bundle install
# Commit + push Capistrano files and app changes to admin-cruds-ui-updates (or main)

# Laptop SSH to the VM must work:
ssh konkabetse24@34.147.171.215

bundle exec cap production deploy
```

First deploy creates `current/`. Then on the **server**:

```bash
bash /var/www/we-match/current/config/deploy/templates/install-server-services.sh
```

That installs Nginx site, systemd units, and Certbot for `match.womenemerging.org`.

Redeploy afterwards so services restart cleanly:

```bash
bundle exec cap production deploy
```

---

## 3. First admin + email check

On the server:

```bash
cd /var/www/we-match/current
bin/rails admin:create   # with ADMIN_EMAIL / ADMIN_PASSWORD set
bin/rails mail:test[you@example.com]
```

Visit https://match.womenemerging.org

---

## Environment variables

| Variable | Purpose |
|----------|---------|
| `APP_HOST` | `match.womenemerging.org` |
| `DATABASE_URL` | Postgres on localhost |
| `RAILS_MASTER_KEY` | Decrypt credentials |
| `SECRET_KEY_BASE` | Sessions |
| `EMAIL_DELIVERY_ENABLED` | `true` to send |
| `SHOW_MAILER_PREVIEWS` | `true` for open `/rails/mailers` (not linked in UI; share privately) |
| `MAIL_FROM` / `SMTP_*` | Resend SMTP |

Template: [`config/deploy/shared/env.example`](config/deploy/shared/env.example)  
Units / Nginx: [`config/deploy/templates/`](config/deploy/templates/)

### Do not seed the pilot database

`db:seed` deletes real data unless `ALLOW_DESTRUCTIVE_SEED=true`. Use **Import Excel**.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Capistrano can’t SSH | Add laptop key to VM `~/.ssh/authorized_keys` |
| Git clone fails on server | Deploy key / `ssh -T git@github.com` |
| Linked file missing | Create `shared/.env` and `shared/config/master.key` before deploy |
| Blocked hosts | `APP_HOST=match.womenemerging.org` |
| No scheduled cycles | `systemctl status we-match-jobs` |
| Email not sending | Resend key + `EMAIL_DELIVERY_ENABLED=true`; check dashboard `EmailDelivery` |
