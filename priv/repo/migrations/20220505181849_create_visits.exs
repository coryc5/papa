defmodule Papa.Repo.Migrations.CreateVisits do
  use Ecto.Migration

  def change do
    create table "visits" do
      add(:date, :date, null: false)
      add(:minutes, :integer, null: false)
      add(:status, :string, null: false)
      add(:lock_version, :integer, null: false)
      add(:member_id, references("users"), null: false)
      add(:pal_id, references("users"))

      timestamps()
    end

    create index("visits", [:member_id])
    create index("visits", [:pal_id])
    create index("visits", [:status])
  end
end
