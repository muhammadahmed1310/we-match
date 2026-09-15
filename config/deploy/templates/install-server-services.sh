#!/usr/bin/env bash
# Run on we-match-web after the first Capistrano deploy has created current/.
# Copies Nginx + systemd unit templates from the release into place.
set -euo pipefail

APP_ROOT="${APP_ROOT:-/var/www/we-match/current}"
TEMPLATES="$APP_ROOT/config/deploy/templates"

if [[ ! -d "$TEMPLATES" ]]; then
  echo "Missing $TEMPLATES — deploy the app first."
  exit 1
fi

sudo cp "$TEMPLATES/nginx-we-match.conf" /etc/nginx/sites-available/we-match
sudo ln -sfn /etc/nginx/sites-available/we-match /etc/nginx/sites-enabled/we-match
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx

sudo cp "$TEMPLATES/we-match-puma.service" /etc/systemd/system/we-match-puma.service
sudo cp "$TEMPLATES/we-match-jobs.service" /etc/systemd/system/we-match-jobs.service
sudo systemctl daemon-reload
sudo systemctl enable --now we-match-puma we-match-jobs

# TLS (needs DNS for match.womenemerging.org already pointing here)
sudo certbot --nginx -d match.womenemerging.org --non-interactive --agree-tos \
  -m info@womenemerging.org --redirect || {
  echo "Certbot failed — run manually: sudo certbot --nginx -d match.womenemerging.org"
}

echo "Done. Check: sudo systemctl status we-match-puma we-match-jobs"
