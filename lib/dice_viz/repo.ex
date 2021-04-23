defmodule DiceViz.Repo do
  use Ecto.Repo,
    otp_app: :dice_viz,
    adapter: Ecto.Adapters.Postgres
end
