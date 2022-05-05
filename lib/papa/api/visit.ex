defmodule Papa.API.Visit do
  use Ecto.Schema

  @type t :: %__MODULE__{
          date: Date.t(),
          minutes: pos_integer(),
          status: String.t(),
          lock_version: integer(),
          member: Papa.API.User.t(),
          member_id: integer(),
          pal: Papa.API.User.t(),
          pal_id: integer(),
          visit_tasks: [Papa.API.VisitTask.t()]
        }

  @requested "requested"
  @accepted "accepted"
  @fulfilled "fulfilled"
  @canceled "canceled"
  @status_options [@requested, @accepted, @fulfilled, @canceled]

  schema "visits" do
    field(:date, :date)
    field(:minutes, :integer)
    field(:status, :string, default: @requested)
    field(:lock_version, :integer, default: 1)
    belongs_to(:member, Papa.API.User)
    belongs_to(:pal, Papa.API.User)

    has_many(:visit_tasks, Papa.API.VisitTask)

    timestamps()
  end

  @required_fields ~w(date minutes status member_id)a
  @optional_fields ~w(pal_id)a

  def requested_changeset(%Papa.API.User{} = user, params) do
    Ecto.build_assoc(user, :member_visits)
    |> changeset(params)
    |> Ecto.Changeset.validate_change(:member_id, fn :member_id, _member_id ->
      case Papa.API.User.member?(user) do
        true -> []
        false -> [member_id: "is not member"]
      end
    end)
    |> Ecto.Changeset.cast_assoc(:visit_tasks, with: &Papa.API.VisitTask.changeset/2)
  end

  def accepted_changeset(%__MODULE__{} = visit, %Papa.API.User{} = user) do
    changeset(visit, %{pal_id: user.id, status: @accepted})
    |> validate_status(fn ->
      case requested?(visit) do
        true -> []
        false -> [status: "is not requested"]
      end
    end)
    |> Ecto.Changeset.validate_change(:pal_id, fn :pal_id, pal_id ->
      case pal_id == visit.member_id do
        true -> [pal_id: "cannot match member"]
        false -> []
      end
    end)
    |> Ecto.Changeset.validate_change(:pal_id, fn :pal_id, _pal_id ->
      case Papa.API.User.pal?(user) do
        true -> []
        false -> [pal_id: "is not pal"]
      end
    end)
  end

  def unaccept_changeset(%__MODULE__{} = visit) do
    changeset(visit, %{pal_id: nil, status: @requested})
    |> validate_status(fn ->
      case accepted?(visit) do
        true -> []
        false -> [status: "is not accepted"]
      end
    end)
  end

  def canceled_changeset(%__MODULE__{} = visit) do
    changeset(visit, %{status: @canceled})
    |> validate_status(fn ->
      case accepted?(visit) or requested?(visit) do
        true -> []
        false -> [status: "cannot be canceled"]
      end
    end)
  end

  def fulfilled_changeset(%__MODULE__{} = visit) do
    changeset(visit, %{status: @fulfilled})
    |> validate_status(fn ->
      case accepted?(visit) do
        true -> []
        false -> [status: "cannot be fulfilled"]
      end
    end)
  end

  def requested_status, do: @requested
  def requested?(%__MODULE__{status: status}), do: status == @requested
  def accepted?(%__MODULE__{status: status}), do: status == @accepted
  def fulfilled?(%__MODULE__{status: status}), do: status == @fulfilled

  def changeset(schema \\ %__MODULE__{}, params) do
    Ecto.Changeset.cast(schema, params, @required_fields ++ @optional_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.validate_inclusion(:status, @status_options)
    |> Ecto.Changeset.validate_number(:minutes, greater_than: 0)
    |> Ecto.Changeset.assoc_constraint(:member)
    |> Ecto.Changeset.assoc_constraint(:pal)
    |> Ecto.Changeset.optimistic_lock(:lock_version)
  end

  defp validate_status(changeset, error_fun) do
    errors = error_fun.()

    Enum.reduce(errors, changeset, fn {key, val}, acc ->
      Ecto.Changeset.add_error(acc, key, val)
    end)
  end
end
