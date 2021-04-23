defmodule DiceViz.DiceFormulaParser do
  import NimbleParsec

  dice_expression =
    integer(min: 1)
    |> ignore(string("d"))
    |> integer(min: 1)
    |> optional(string("!"))
    |> tag(:dice_expression)
    # |> post_traverse({:test, []})

  # def test(rest, args, context, line, offset) do
  #   IO.inspect(rest, label: :rest)
  #   IO.inspect(args, label: :args)
  #   IO.inspect(context, label: :context)
  #   IO.inspect(line, label: :line)
  #   IO.inspect(offset, label: :offset)

  #   {args, context}
  # end


  expression = choice([
    dice_expression,
    integer(min: 1)
  ])

  arithmetic =
    expression
    |> ignore(repeat(string(" ")))
    |> choice([
      string("+"),
      string("-"),
      string("*"),
      string("/"),
    ])
    |> ignore(repeat(string(" ")))
    |> concat(expression)
    |> tag(:arithmetic)

  function_arity2 =
    choice([
      string("max"),
      string("min"),
    ])
    |> ignore(string("("))
    |> choice([arithmetic, expression])
    |> ignore(repeat(string(" ")))
    |> ignore(string(","))
    |> ignore(repeat(string(" ")))
    |> choice([arithmetic, expression])
    |> ignore(string(")"))
    |> tag(:function_arity2)

  function_arity1 =
    choice([
      string("round"),
      string("ceil"),
      string("floor"),
    ])
    |> ignore(string("("))
    # |> ignore(repeat(string(" ")))
    |> choice([arithmetic, expression])
    # |> ignore(repeat(string(" ")))
    |> ignore(string(")"))
    |> tag(:function_arity1)

  function = choice([
    function_arity1,
    function_arity2,
  ])

  greater_than =
    choice([arithmetic, expression])
    |> ignore(repeat(string(" ")))
    |> ignore(string(">"))
    |> ignore(repeat(string(" ")))
    |> choice([arithmetic, expression])
    |> tag(:>)

  defparsec :formula, choice([
    arithmetic,
    function,
    greater_than,
    expression,
  ])

  def simulate(string) do
    case formula(string) do
      {:ok, result, _, _, _, _} -> value(result)
      other -> other
    end
  end

  def simulate_stream(string) do
    case formula(string) do
      {:ok, _, _, _, _, _} -> {:ok, Stream.unfold(nil, fn nil -> {simulate(string), nil} end)}
      other -> other
    end
  end

  def counts_for(values) do
    Enum.reduce(values, %{}, fn value, result ->
      Map.update(result, value, 1, & &1 + 1)
    end)
  end

  defp value([{tag, list}]) when is_list(list) do
    value({tag, list})
  end

  defp value({:arithmetic, [value1, "+", value2]}) do
    value(value1) + value(value2)
  end

  defp value({:arithmetic, [value1, "-", value2]}) do
    value(value1) - value(value2)
  end

  defp value({:arithmetic, [value1, "*", value2]}) do
    value(value1) * value(value2)
  end

  defp value({:arithmetic, [value1, "/", value2]}) do
    value(value1) / value(value2)
  end

  defp value({:function_arity2, ["max", value1, value2]}) do
    max(value(value1), value(value2))
  end

  defp value({:function_arity2, ["min", value1, value2]}) do
    min(value(value1), value(value2))
  end

  defp value({:function_arity1, ["round", value1]}) do
    round(value(value1))
  end

  defp value({:function_arity1, ["floor", value1]}) do
    floor(value(value1))
  end

  defp value({:function_arity1, ["ceil", value1]}) do
    ceil(value(value1))
  end

  defp value({:>, [value1, value2]}) do
    value(value1) > value(value2)
  end

  defp value({:dice_expression, [count, side_count]}) do
    Enum.reduce(1..count, 0, fn _, sum -> sum + roll(side_count) end)
  end

  defp value({:dice_expression, [count, side_count, "!"]}) do
    Enum.reduce(1..count, 0, fn _, sum -> sum + roll(side_count, & &1 == side_count) end)
  end

  defp roll(side_count, reroll_if \\ fn _ -> false end) do
    value = :rand.uniform(side_count)

    if reroll_if.(value) do
      value + roll(side_count, reroll_if)
    else
      value
    end
  end

  defp value(number), do: number
end
