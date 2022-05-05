defmodule Papa.API.VisitTask do
  use Ecto.Schema

  @type t :: %__MODULE__{
          id: integer(),
          note: String.t(),
          visit: Papa.API.Visit.t(),
          task: Papa.API.Task.t(),
          visit_id: integer(),
          task_id: integer()
        }

  schema "visit_tasks" do
    field(:note)
    belongs_to(:visit, Papa.API.Visit)
    belongs_to(:task, Papa.API.Task)
  end

  @required_fields ~w(note visit_id task_id)a

  def new_changeset(%Papa.API.Visit{} = visit, params) do
    Ecto.build_assoc(visit, :visit_tasks)
    |> changeset(params)
  end

  @max_note_length 500
  def changeset(schema \\ %__MODULE__{}, params) do
    Ecto.Changeset.cast(schema, params, @required_fields)
    |> Ecto.Changeset.validate_required(@required_fields)
    |> Ecto.Changeset.validate_length(:note, @max_note_length)
    |> Ecto.Changeset.assoc_constraint(:visit)
    |> Ecto.Changeset.assoc_constraint(:task)
  end
end
