defmodule Papa.API.Task do
  use Ecto.Schema

  @type t :: %__MODULE__{
          id: integer(),
          type: String.t(),
          visit_tasks: [Papa.API.VisitTask.t()]
        }

  schema "tasks" do
    field(:type)
    has_many(:visit_tasks, Papa.API.VisitTask)

    timestamps()
  end
end
