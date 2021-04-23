defmodule DiceVizWeb.PageLive do
  use DiceVizWeb, :live_view

  @default_roll_count 10_000

  @impl true
  def mount(_params, _session, socket) do
    formula = "1d6"
    {:ok, stream} = DiceViz.DiceFormulaParser.simulate_stream(formula)
    counts =
      stream
      |> Stream.take(@default_roll_count)
      |> DiceViz.DiceFormulaParser.counts_for()
      |> Enum.sort_by(fn {value, count} -> value end)

    {:ok, assign(socket, formula: formula, counts: counts, error: nil, roll_count: @default_roll_count)}
  end

  @impl true
  def handle_event("calculate", %{"formula" => ""}, socket) do
    {:noreply,
     socket
     |> assign(formula: "", counts: nil, error: nil)}
  end
  def handle_event("calculate", %{"formula" => formula, "roll_count" => roll_count}, socket) do
    IO.inspect(formula, label: :formula)
    case DiceViz.DiceFormulaParser.simulate_stream(formula) do
      {:ok, stream} ->
        IO.inspect("got it!")
        {roll_count, _} = Integer.parse(roll_count)
        roll_count = min(roll_count, 10_000)

        counts =
          stream
          |> Stream.take(roll_count)
          |> DiceViz.DiceFormulaParser.counts_for()
          |> Enum.sort_by(fn {value, count} -> value end)

        {:noreply,
         socket
         |> assign(
           formula: formula,
           counts: counts,
           roll_count: roll_count,
           error: nil)}

      {:error, message, _, _, _, _} -> 
        {roll_count, _} = Integer.parse(roll_count)
        roll_count = min(roll_count, 10_000)

        {:noreply,
         socket
         |> assign(
           formula: formula,
           roll_count: roll_count,
           error: "Invalid formula")}
    end
  end
end
