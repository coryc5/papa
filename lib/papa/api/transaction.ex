defmodule Papa.API.Transaction do
  use Ecto.Schema

  @type t :: %__MODULE__{
          member: Papa.API.User.t(),
          member_id: integer(),
          pal: Papa.API.User.t(),
          pal_id: integer(),
          visit: Papa.API.Visit.t()
        }

  schema "transactions" do
    belongs_to(:member, Papa.API.User)
    belongs_to(:pal, Papa.API.User)
    belongs_to(:visit, Papa.API.Visit)

    timestamps()
  end

  @required_fields ~w(member_id pal_id visit_id)a

  def changeset(schema \\ %__MODULE__{}, params) do
    Ecto.Changeset.cast(schema, params, @required_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.assoc_constraint(:pal)
    |> Ecto.Changeset.assoc_constraint(:member)
    |> Ecto.Changeset.assoc_constraint(:visit)
  end
end
