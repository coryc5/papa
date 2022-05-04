import Config

config :papa, Papa.Repo,
  username: "postgres",
  password: "postgres",
  database: "papa_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
