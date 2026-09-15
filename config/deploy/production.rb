# frozen_string_literal: true

server "34.147.171.215", user: "konkabetse24", roles: %w[app db web]

set :ssh_options, {
  forward_agent: true,
  auth_methods: %w[publickey]
}
