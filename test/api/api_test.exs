defmodule Papa.APITest do
  use Papa.RepoCase

  describe "create_user/1" do
    test "creates user and account" do
      params = %{
        first_name: "Jane",
        last_name: "Doe",
        email: "janedoe@example.org",
        role: Papa.API.User.member()
      }

      {:ok, result} = Papa.API.create_user(params)

      Enum.each(params, fn {k, v} ->
        assert Map.fetch!(result.user, k) == v
      end)

      assert result.account.user_id == result.user.id
    end

    test "fails if missing required fields" do
      params = %{}

      assert {:error, :user, _changeset, _data} = Papa.API.create_user(params)
    end
  end

  describe "visits" do
    test "full successful visit pipeline" do
      {:ok, %{user: member, account: member_account}} =
        Papa.API.create_user(%{
          first_name: "Jane",
          last_name: "Doe",
          email: "janedoe@example.org",
          role: Papa.API.User.member()
        })

      {:ok, %{user: pal, account: pal_account}} =
        Papa.API.create_user(%{
          first_name: "Bob",
          last_name: "Smith",
          email: "bob@example.org",
          role: Papa.API.User.pal()
        })

      visit_params = %{
        minutes: 5,
        date: Date.utc_today(),
        visit_tasks: []
      }

      {:ok, %{visit: requested_visit, account: post_request_member_account}} =
        Papa.API.create_visit(member, visit_params)

      # requesting visit debits member account
      assert post_request_member_account.seconds ==
               member_account.seconds - visit_params.minutes * 60

      {:ok, accepted_visit} = Papa.API.accept_requested_visit(requested_visit, pal)
      {:ok, result} = Papa.API.fulfill_visit(accepted_visit)

      assert Papa.API.Visit.fulfilled?(result.visit)

      # pal account credited time minus the overhead fee
      assert result.pal_account.seconds ==
               pal_account.seconds +
                 visit_params.minutes * (60 - Papa.API.Account.overhead_fee_seconds())

      assert result.transaction.member_id == member.id
      assert result.transaction.pal_id == pal.id
      assert result.transaction.visit_id == requested_visit.id
    end

    test "restrict visit requests by time credits in account" do
      {:ok, %{user: member_pal, account: member_account}} =
        Papa.API.create_user(%{
          first_name: "Jane",
          last_name: "Doe",
          email: "janedoe@example.org",
          role: Papa.API.User.member_pal()
        })

      too_many_minutes = div(member_account.seconds, 60) + 1

      visit_params = %{
        minutes: too_many_minutes,
        date: Date.utc_today(),
        visit_tasks: []
      }

      {:error, :account, changeset, _data} = Papa.API.create_visit(member_pal, visit_params)

      assert format_changeset_error(changeset) == %{
               seconds: ["must be greater than or equal to 0"]
             }

      # fulfilling another visit enables the previous request
      {:ok, %{user: member}} =
        Papa.API.create_user(%{
          first_name: "Bob",
          last_name: "Smith",
          email: "bob@example.org",
          role: Papa.API.User.member()
        })

      # add extra minute to account for overhead
      minutes = 2
      second_visit_params = %{minutes: minutes, date: Date.utc_today(), visit_tasks: []}
      {:ok, %{visit: second_visit}} = Papa.API.create_visit(member, second_visit_params)
      {:ok, accepted_visit} = Papa.API.accept_requested_visit(second_visit, member_pal)
      {:ok, _} = Papa.API.fulfill_visit(accepted_visit)

      # original request now succeeds
      assert {:ok, _result} = Papa.API.create_visit(member_pal, visit_params)
    end

    test "visit cannot be accepted twice" do
      {:ok, %{user: member}} =
        Papa.API.create_user(%{
          first_name: "Jane",
          last_name: "Doe",
          email: "janedoe@example.org",
          role: Papa.API.User.member()
        })

      {:ok, %{user: pal}} =
        Papa.API.create_user(%{
          first_name: "Bob",
          last_name: "Smith",
          email: "bob@example.org",
          role: Papa.API.User.pal()
        })

      visit_params = %{
        minutes: 5,
        date: Date.utc_today(),
        visit_tasks: []
      }

      {:ok, %{visit: requested_visit}} = Papa.API.create_visit(member, visit_params)

      # first accept succeeds
      {:ok, accepted_visit} = Papa.API.accept_requested_visit(requested_visit, pal)

      # competing request for the initial result fails
      assert_raise Ecto.StaleEntryError, fn ->
        Papa.API.accept_requested_visit(requested_visit, pal)
      end

      # subsequent requests for a non-stale entry also fail
      {:error, changeset} = Papa.API.accept_requested_visit(accepted_visit, pal)
      assert format_changeset_error(changeset) == %{status: ["is not requested"]}
    end
  end

  defp format_changeset_error(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
