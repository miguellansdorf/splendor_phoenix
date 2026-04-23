defmodule Splendor.Repo do
  use Ecto.Repo,
    otp_app: :splendor,
    adapter: Ecto.Adapters.Postgres
end
