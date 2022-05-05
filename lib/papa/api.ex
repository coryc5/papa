defmodule Papa.API do
  alias Papa.API

  @type tx_error :: {:error, failed_step :: atom(), failed_value :: any(), changes :: any()}

  @spec create_user(map()) ::
          {:ok, %{user: API.User.t(), account: API.Account.t()}} | tx_error()
  def create_user(%{} = params) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, fn _changes -> API.User.changeset(params) end)
    |> Ecto.Multi.insert(:account, fn %{user: user} -> API.Account.new_changeset(user) end)
    |> Papa.Repo.transaction()
  end

  @spec create_visit(API.User.t(), map()) ::
          {:ok, %{visit: API.Visit.t(), account: API.Account.t()}}
          | tx_error()
  def create_visit(%API.User{} = user, visit_params) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:visit, fn _changes ->
      API.Visit.requested_changeset(user, visit_params)
    end)
    |> Ecto.Multi.update(:account, fn %{visit: visit} ->
      get_user_account(user)
      |> API.Account.debit_visit_changeset(visit)
    end)
    |> Papa.Repo.transaction()
  end

  @spec cancel_visit(API.Visit.t()) ::
          {:ok, %{visit: API.Visit.t(), account: API.Account.t()}} | {:error, Ecto.Changeset.t()}
  def cancel_visit(%API.Visit{} = visit) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:visit, fn _changes ->
      API.Visit.canceled_changeset(visit)
    end)
    |> Ecto.Multi.update(:account, fn %{visit: visit} ->
      %{member: member} = Papa.Repo.preload(visit, :member)

      get_user_account(member)
      |> API.Account.refund_full_visit_changeset(visit)
    end)
    |> Papa.Repo.transaction()
  end

  @spec get_user_account(API.User.t()) :: API.Account.t() | nil
  def get_user_account(%API.User{} = user) do
    Papa.Repo.get_by(API.Account, user_id: user.id)
  end

  @spec list_requested_visits_for_date(Date.t()) :: [API.Visit.t()]
  def list_requested_visits_for_date(%Date{} = date) do
    API.Query.list_requested_visits_for_date(date)
    |> Papa.Repo.all()
  end

  @spec accept_requested_visit(API.Visit.t(), API.User.t()) ::
          {:ok, API.Visit.t()} | {:error, Ecto.Changeset.t()}
  def accept_requested_visit(%API.Visit{} = visit, %API.User{} = user) do
    API.Visit.accepted_changeset(visit, user)
    |> Papa.Repo.update()
  end

  @spec unaccept_visit(API.Visit.t()) :: {:ok, API.Visit.t()} | {:error, Ecto.Changeset.t()}
  def unaccept_visit(%API.Visit{} = visit) do
    API.Visit.unaccept_changeset(visit)
    |> Papa.Repo.update()
  end

  @spec fulfill_visit(API.Visit.t()) ::
          {:ok,
           %{visit: API.Visit.t(), account: API.Account.t(), transaction: API.Transaction.t()}}
          | {:error, Ecto.Changeset.t()}
  def fulfill_visit(%API.Visit{} = visit) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:visit, fn _ ->
      API.Visit.fulfilled_changeset(visit)
    end)
    |> Ecto.Multi.update(:pal_account, fn %{visit: updated_visit} ->
      %{pal: pal} = Papa.Repo.preload(visit, :pal)

      get_user_account(pal)
      |> API.Account.credit_pal_visit_changeset(updated_visit)
    end)
    |> Ecto.Multi.insert(:transaction, fn %{visit: updated_visit} ->
      API.Transaction.changeset(%{
        member_id: updated_visit.member_id,
        pal_id: updated_visit.pal_id,
        visit_id: updated_visit.id
      })
    end)
    |> Papa.Repo.transaction()
  end
end
