defmodule Papa.Repo do
  use Ecto.Repo,
    otp_app: :papa,
    adapter: Ecto.Adapters.Postgres
end
