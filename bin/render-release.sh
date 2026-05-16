#!/usr/bin/env bash
set -o errexit

bundle exec rails db:prepare

if [ "${SEED_DEMO}" = "true" ]; then
  bundle exec rails db:seed
fi
