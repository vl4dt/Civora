defmodule Mix.Tasks.Civora.Accounts.CreateUser do
  use Mix.Task

  @shortdoc "Creates a confirmed internal Civora user"

  @impl Mix.Task
  def run([email, password]) do
    Mix.Task.run("app.start")

    case Civora.Accounts.create_internal_user(%{email: email, password: password}) do
      {:ok, user} ->
        Mix.shell().info("Created internal user #{user.email}")

      {:error, changeset} ->
        errors =
          Ecto.Changeset.traverse_errors(changeset, fn {message, options} ->
            Enum.reduce(options, message, fn {key, value}, text ->
              String.replace(text, "%{#{key}}", to_string(value))
            end)
          end)

        Mix.raise("Could not create internal user: #{inspect(errors)}")
    end
  end

  def run(_args) do
    Mix.raise(~s(mix civora.accounts.create_user EMAIL "PASSWORD"))
  end
end
