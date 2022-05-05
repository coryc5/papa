defmodule Papa.API.User do
  use Ecto.Schema

  @type t :: %__MODULE__{
          id: integer(),
          first_name: String.t(),
          last_name: String.t(),
          email: String.t(),
          role: String.t()
        }

  schema "users" do
    field(:first_name)
    field(:last_name)
    field(:email)
    field(:role)

    has_many(:member_visits, Papa.API.Visit, foreign_key: :member_id)
    has_many(:pal_visits, Papa.API.Visit, foreign_key: :pal_id)

    timestamps()
  end

  @required_fields ~w(first_name last_name email role)a

  @member "member"
  @member_pal "member-pal"
  @pal "pal"
  @roles [@member, @member_pal, @pal]

  def changeset(schema \\ %__MODULE__{}, params) do
    Ecto.Changeset.cast(schema, params, @required_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.validate_inclusion(:role, @roles)
    |> validate_email()
  end

  def member, do: @member
  def pal, do: @pal
  def member_pal, do: @member_pal

  def member?(%__MODULE__{role: role}), do: role in [@member, @member_pal]
  def pal?(%__MODULE__{role: role}), do: role in [@pal, @member_pal]

  defp validate_email(changeset) do
    changeset
    |> validate_email_format()
    |> Ecto.Changeset.validate_length(:email, max: 160)
    |> Ecto.Changeset.unsafe_validate_unique(:email, Papa.Repo)
    |> Ecto.Changeset.unique_constraint(:email)
  end

  defp validate_email_format(changeset) do
    Ecto.Changeset.validate_format(changeset, :email, ~r/^[^\s]+@[^\s]+$/,
      message: "must have the @ sign and no spaces"
    )
  end
end
