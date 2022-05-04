import Config

config :papa, Papa.Repo,
  database: "papa_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :papa,
  ecto_repos: [Papa.Repo]

import_config "#{Mix.env()}.exs"
