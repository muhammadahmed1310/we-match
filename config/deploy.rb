# frozen_string_literal: true

lock "~> 3.19"

set :application, "we-match"
set :repo_url, "git@github.com:muhammadahmed1310/we-match.git"

# Deploy from main. Override with:
#   DEPLOY_BRANCH=some-branch bundle exec cap production deploy
set :branch, ENV.fetch("DEPLOY_BRANCH", "main")


set :deploy_to, "/var/www/we-match"
set :keep_releases, 5

set :rbenv_type, :user
set :rbenv_ruby, File.read(".ruby-version").strip

append :linked_files, ".env", "config/master.key"
append :linked_dirs, "log", "tmp/pids", "tmp/sockets", "tmp/cache", "storage", "public/assets"

namespace :deploy do
  desc "Restart Puma and Solid Queue via systemd (no-op until units are installed)"
  task :restart_app do
    on roles(:app) do
      if test("[ -f /etc/systemd/system/we-match-puma.service ]")
        execute :sudo, :systemctl, :restart, "we-match-puma"
      else
        info "we-match-puma.service not installed yet — skip restart"
      end

      if test("[ -f /etc/systemd/system/we-match-jobs.service ]")
        execute :sudo, :systemctl, :restart, "we-match-jobs"
      else
        info "we-match-jobs.service not installed yet — skip restart"
      end
    end
  end

  after :publishing, :restart_app
end
