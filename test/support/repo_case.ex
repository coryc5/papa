defmodule Papa.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Papa.Repo

      import Ecto
      import Ecto.Query
      import Papa.RepoCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Papa.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Papa.Repo, {:shared, self()})
    end

    :ok
  end
end
