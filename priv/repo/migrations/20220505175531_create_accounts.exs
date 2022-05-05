defmodule Papa.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table "accounts" do
      add(:seconds, :decimal, null: false)
      add(:lock_version, :integer, null: false)
      add(:user_id, references("users"), null: false)

      timestamps()
    end

    create unique_index("accounts", [:user_id])
  end
end
