# Deploy WE Match (live demo)

Deploy for **$0** on **[Render](https://render.com)** — free web + Postgres. The app **sleeps when idle** (~15 min); the first visit after sleep may take 30–60 seconds to wake. Fine for sharing with reviewers.

Config: [`render.yaml`](render.yaml) + [`bin/render-build.sh`](bin/render-build.sh)

## Other free options (optional)

| Platform | Cost | Idle sleep? |
|----------|------|-------------|
| **Render** (use this) | $0 | Yes — recommended |
| **Fly.io** | Free allowance* | Yes (`auto_stop`) — [`fly.toml`](fly.toml) |
| **Koyeb** | Limited free hours | Varies |
| **Neon + Render** | DB free on Neon | Depends on Render |

\*Card often required; allowances change.

---

## Render (recommended — free, sleeps when idle)

### Prerequisites

- GitHub account
- [Render](https://render.com) account
- This repo pushed to GitHub
- Your `config/master.key` value (local file; **never commit it**)

### Steps

1. **Push to GitHub** (if you have not already):
   ```bash
   git remote add origin git@github.com:YOUR_USER/we-match.git
   git push -u origin main
   ```

2. **Create Blueprint on Render**
   - [dashboard.render.com](https://dashboard.render.com) → **New +** → **Blueprint**
   - Connect the `we-match` repository
   - Render reads [`render.yaml`](render.yaml) and creates:
     - PostgreSQL database (`we-match-db`)
     - Web service (`we-match`)

3. **Set `RAILS_MASTER_KEY`**
   - When prompted, paste the contents of your local `config/master.key`
   - Or in the web service → **Environment** → add `RAILS_MASTER_KEY`

4. **Deploy**
   - First deploy runs migrations and seeds demo data (`SEED_DEMO=true` in `render.yaml`)
   - Wait until status is **Live**
   - Open the URL, e.g. `https://we-match-xxxx.onrender.com`

5. **Share the link** with testers. Suggested flow:
   - Dashboard → **Match Cycles** → **Expedition Alumni**
   - **Run Matching** → **View matches**
   - Mailer previews: `https://YOUR-APP.onrender.com/rails/mailers` (enabled via `SHOW_MAILER_PREVIEWS=true`)

### Notes for Render free tier

- App **sleeps after ~15 min** of no traffic; first visit may take 30–60 seconds to wake.
- Emails are **not really sent** in production (`delivery_method = :test`); matching still runs and pairs are saved.
- To **re-seed** demo data: Shell → `bundle exec rails db:seed`
- To disable auto-seed on rebuild: set env `SEED_DEMO` to `false`

---

## Fly.io (optional — Docker)

Uses [`Dockerfile`](Dockerfile) and [`fly.toml`](fly.toml).

1. Install [flyctl](https://fly.io/docs/hands-on/install-flyctl/) and sign up.
2. From the project folder:
   ```bash
   fly auth login
   fly launch          # accept defaults; don't deploy yet if asked
   fly postgres create --name we-match-db --region iad
   fly postgres attach we-match-db
   fly secrets set RAILS_MASTER_KEY="$(cat config/master.key)"
   fly secrets set APP_HOST="$(fly info -j | jq -r .Hostname)"   # or set manually after first deploy
   fly deploy
   fly ssh console -C "/rails/bin/rails db:prepare db:seed"
   ```
3. Open `https://YOUR-APP.fly.dev`

Machines can **auto-stop** when idle (like Render). Set `min_machines_running = 1` in `fly.toml` if you upgrade to stay warm (uses more free credits).

---

## Koyeb (optional — limited free hours)

1. [koyeb.com](https://www.koyeb.com) → Create app → **GitHub** → this repo  
2. **Runtime**: Docker (use repo `Dockerfile`) or buildpack  
3. Add **PostgreSQL** from Koyeb dashboard (free instance has **~5 compute hours/month** — fine for a short review window)  
4. Set env: `DATABASE_URL`, `RAILS_MASTER_KEY`, `RAILS_ENV=production`, `APP_HOST`, `PORT=3000`  
5. Deploy; run `db:prepare` and `db:seed` from console  

Check [Koyeb pricing](https://www.koyeb.com/pricing) before relying on it long-term.

---

## Neon (optional — free Postgres) + Render

Use **free database only**, deploy the app on Render:

1. [neon.tech](https://neon.tech) → create project → copy **connection string**  
2. On Render, set `DATABASE_URL` to Neon’s URL (instead of bundled Postgres)  
3. Deploy app as usual; run `db:prepare db:seed` once  

Neon free tier is generous for DB size; good if Render’s free Postgres expires or you hit limits.

---

## Environment variables

| Variable | Required | Purpose |
|----------|----------|---------|
| `DATABASE_URL` | Yes (hosted) | PostgreSQL connection |
| `RAILS_MASTER_KEY` | Yes | Decrypt credentials |
| `SECRET_KEY_BASE` | Yes | Sessions (Render can auto-generate) |
| `RAILS_ENV` | Yes | `production` |
| `APP_HOST` | Yes | Host for URLs in emails, e.g. `we-match.onrender.com` |
| `SEED_DEMO` | No | `true` to run `db:seed` on build |

---

## Production vs local differences

| Feature | Local | Production |
|---------|-------|------------|
| Emails | Logged / test adapter | Test adapter (not delivered to real inboxes) |
| Mailer previews | `/rails/mailers` | Same URL (fine for demo) |
| Auth | None | None (anyone with URL can use app) |
| HTTPS | No | Yes (`force_ssl`) |

For a **public demo**, the lack of login is acceptable; add authentication before a real launch.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Blocked hosts` | Set `APP_HOST` to your exact hostname (no `https://`) |
| Database error on boot | Check `DATABASE_URL`; run `db:prepare` in shell |
| Assets 404 | Ensure `assets:precompile` ran in build |
| Empty app | Run `bin/rails db:seed` in Render shell |
| Slow first load | Free tier cold start — wait and refresh |
