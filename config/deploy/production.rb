# frozen_string_literal: true

server "34.147.171.215", user: "konkabetse24", roles: %w[app db web]

set :ssh_options, {
  keys: [ File.join(Dir.home, ".ssh", "womenemerging") ],
  keys_only: true,
  forward_agent: false,
  auth_methods: %w[publickey]
}
