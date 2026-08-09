# Deploy WE Match

The pilot needs three things: a web process, a Postgres database, and a worker process for
the biweekly automation. [`render.yaml`](render.yaml) describes all three.

**Free plans cover the web process and the database, but not a worker.** Without a worker
the app is fully usable — a CM presses **Send invitations**, **Close responses**, and **Run
matching** on the cycle page — but nothing happens on a schedule. Budget the smallest paid
instance if you want the automation.

## Render

### Prerequisites

- The repo on GitHub, and a [Render](https://render.com) account
- The value of your local `config/master.key` (never commit it)

### Steps

1. **Dashboard → New + → Blueprint**, connect the repo. Render reads
   [`render.yaml`](render.yaml) and creates the database, the web service, and the worker.
2. **Set `RAILS_MASTER_KEY`** when prompted, on both the web and worker services.
3. **Set `APP_HOST`** to the final hostname once you know it — the subdomain if you have
   one, otherwise the `*.onrender.com` name. Email links are built from it.
4. **Deploy.** The build runs `assets:precompile` and `db:prepare`.
5. **Create the first admin.** Web service → Shell:

   ```bash
   ADMIN_EMAIL=you@womenemerging.org ADMIN_PASSWORD=a-long-passphrase bin/rails admin:create
   ```

6. **Sign in** and check the dashboard. It flags anything still missing, such as no groups,
   no topics, or email delivery being off.

### Custom subdomain

Point a CNAME for `wematch.womenemerging.org` at the Render hostname, add the domain in
Render, then set `APP_HOST` to it. Render issues the certificate.

## Switching on email

Nothing is sent until `EMAIL_DELIVERY_ENABLED` is set. Before setting it, WE IT needs SPF,
DKIM, and DMARC records for the sending domain on `womenemerging.org`, and the domain wants
a week or two of low volume before real sends. Until then, invitations are recorded and
handed out as the CSV of links from the cycle page.

When the records exist, set these on **both** the web and worker services:

| Variable | Example |
|----------|---------|
| `EMAIL_DELIVERY_ENABLED` | `true` |
| `MAIL_FROM` | `WE Match <no-reply@womenemerging.org>` |
| `SMTP_ADDRESS` | your provider's host |
| `SMTP_PORT` | `587` |
| `SMTP_USERNAME` / `SMTP_PASSWORD` | from the provider |

Send one cycle to yourself first. `EmailDelivery` rows record every attempt and its error,
so failures are visible on the dashboard rather than silent.

## Environment variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `DATABASE_URL` | Yes | Postgres connection |
| `RAILS_MASTER_KEY` | Yes | Decrypt credentials |
| `SECRET_KEY_BASE` | Yes | Sessions. Render generates it |
| `RAILS_ENV` | Yes | `production` |
| `APP_HOST` | Yes | Host used in email links, no scheme |
| `EMAIL_DELIVERY_ENABLED` | No | Unset means nothing is sent, only recorded |
| `MAIL_FROM`, `SMTP_*` | With email on | Provider credentials |
| `WE_MATCH_API_TOKEN` | No | Only if something outside the app calls the JSON API |
| `SHOW_MAILER_PREVIEWS` | No | `true` exposes `/rails/mailers`. Leave off in production |
| `SEED_DEMO` | No | `true` seeds demo data on build. See the warning below |

### Do not seed the pilot database

`db:seed` **deletes every group, person, cycle, and response** before inserting demo data.
It refuses to run in production unless `ALLOW_DESTRUCTIVE_SEED=true`, and `SEED_DEMO` is
`false` in the blueprint. Real data arrives through **Import CSV**, not seeds.

## Before handing the URL to the WE team

- Sign in works, and signing out then visiting `/groups` sends you back to sign-in
- An admin account exists for each CM, with a passphrase sent separately
- `APP_HOST` matches the URL you are sharing, so links in emails are right
- A test cycle end to end: invitations, one response through a private link, close, match
- `SHOW_MAILER_PREVIEWS` is off
- If the worker is running, `bin/jobs` shows the recurring tasks registered

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Blocked hosts` | Set `APP_HOST` to the exact hostname, no `https://` |
| Links in emails point at the wrong host | Same — `APP_HOST` on both web and worker |
| Signed in but immediately signed out | `SECRET_KEY_BASE` changed between deploys |
| Nothing on a schedule | Worker not running, or the group does not have auto-cycling on |
| Emails recorded but never sent | `EMAIL_DELIVERY_ENABLED` not set, which is the default |
| Database error on boot | Check `DATABASE_URL`, run `bin/rails db:prepare` in the shell |
| Assets 404 | `assets:precompile` did not run in the build |

## Other platforms

The [`Dockerfile`](Dockerfile) and [`fly.toml`](fly.toml) work for Fly.io. Same
requirements: a web process, Postgres, and a second process running `bin/jobs` if you want
the automation.

```bash
fly launch
fly postgres create --name we-match-db && fly postgres attach we-match-db
fly secrets set RAILS_MASTER_KEY="$(cat config/master.key)" APP_HOST=your-app.fly.dev
fly deploy
fly ssh console -C "/rails/bin/rails db:prepare"
fly ssh console -C "/rails/bin/rails admin:create"   # with ADMIN_EMAIL and ADMIN_PASSWORD set
```
