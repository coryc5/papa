defmodule Papa.API.Query do
  import Ecto.Query

  def list_requested_visits_for_date(%Date{} = date) do
    requested_status = Papa.API.Visit.requested_status()

    from(v in Papa.API.Visit, where: v.status == ^requested_status, where: v.date == ^date)
  end
end
