import Config

config :papa, Papa.Repo,
  database: "papa_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :papa,
  ecto_repos: [Papa.Repo]

config :papa, :account_promo_minute_credits, 15
config :papa, :overhead_fee, "0.15"

import_config "#{Mix.env()}.exs"
