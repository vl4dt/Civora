defmodule Civora.RepoTest do
  use Civora.DataCase, async: true

  test "executes a query through the PostgreSQL repository" do
    assert {:ok, %{rows: [[1]]}} = Repo.query("SELECT 1")
  end
end
