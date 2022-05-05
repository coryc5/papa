defmodule Papa.API.Account do
  use Ecto.Schema

  @type t :: %__MODULE__{
          id: integer(),
          seconds: Decimal.t(),
          user: Pap.API.User.t(),
          user_id: integer(),
          lock_version: pos_integer()
        }

  schema "accounts" do
    field(:seconds, :decimal)
    field(:lock_version, :integer, default: 1)
    belongs_to(:user, Papa.API.User)

    timestamps()
  end

  @seconds_per_minute 60
  @required_fields ~w(seconds user_id)a

  def new_changeset(%Papa.API.User{} = user) do
    %{user_id: user.id, seconds: new_account_promo_second_credits()}
    |> changeset()
  end

  def debit_visit_changeset(%__MODULE__{} = account, %Papa.API.Visit{} = visit) do
    charged_seconds = Decimal.mult(visit.minutes, @seconds_per_minute)

    changeset(account, %{seconds: Decimal.sub(account.seconds, charged_seconds)})
  end

  def refund_full_visit_changeset(%__MODULE__{} = account, %Papa.API.Visit{} = visit) do
    charged_seconds = Decimal.mult(visit.minutes, @seconds_per_minute)

    changeset(account, %{seconds: Decimal.add(account.seconds, charged_seconds)})
  end

  def credit_pal_visit_changeset(%__MODULE__{} = account, %Papa.API.Visit{} = visit) do
    credited_seconds = Decimal.mult(visit.minutes, @seconds_per_minute)
    overhead_seconds = Decimal.mult(credited_seconds, overhead_fee())

    changeset(account, %{
      seconds: Decimal.add(account.seconds, credited_seconds) |> Decimal.sub(overhead_seconds)
    })
  end

  def changeset(schema \\ %__MODULE__{}, params) do
    Ecto.Changeset.cast(schema, params, @required_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.validate_number(:seconds, greater_than_or_equal_to: 0)
    |> Ecto.Changeset.assoc_constraint(:user)
    |> Ecto.Changeset.optimistic_lock(:lock_version)
  end

  def new_account_promo_second_credits do
    Application.fetch_env!(:papa, :account_promo_minute_credits) * @seconds_per_minute
  end

  def overhead_fee do
    Application.fetch_env!(:papa, :overhead_fee)
  end
end
