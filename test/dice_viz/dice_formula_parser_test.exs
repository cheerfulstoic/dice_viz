defmodule DiceViz.DiceFormulaParserTest do
  use ExUnit.Case, async: true

  alias DiceViz.DiceFormulaParser

  @roll_count 100_000

  test "basic d6 roll" do
    {:ok, stream} = DiceFormulaParser.simulate_stream("1d6")
    values = Stream.take(stream, @roll_count)

    assert MapSet.new(values) == MapSet.new(1..6)

    counts = DiceViz.DiceFormulaParser.counts_for(values)

    for value <- 1..6 do
      assert_in_delta counts[value] / @roll_count, 0.1666, 0.01
    end
  end

  test "a 2d6 roll" do
    {:ok, stream} = DiceFormulaParser.simulate_stream("2d6")
    values = Stream.take(stream, @roll_count)

    assert MapSet.new(values) == MapSet.new(2..12)

    counts = DiceViz.DiceFormulaParser.counts_for(values)

    assert_in_delta counts[2] / @roll_count, 0.0277, 0.01
    assert_in_delta counts[4] / @roll_count, 0.0833, 0.01
    assert_in_delta counts[7] / @roll_count, 0.1666, 0.01
    assert_in_delta counts[10] / @roll_count, 0.0833, 0.01
    assert_in_delta counts[12] / @roll_count, 0.0277, 0.01
  end

  test "2d6 + 2" do
    {:ok, stream} = DiceFormulaParser.simulate_stream("2d6 + 2")
    values = Stream.take(stream, @roll_count)

    assert MapSet.new(values) == MapSet.new(4..14)

    counts = DiceViz.DiceFormulaParser.counts_for(values)

    assert_in_delta counts[4] / @roll_count, 0.0277, 0.01
    assert_in_delta counts[6] / @roll_count, 0.0833, 0.01
    assert_in_delta counts[9] / @roll_count, 0.1666, 0.01
    assert_in_delta counts[12] / @roll_count, 0.0833, 0.01
    assert_in_delta counts[14] / @roll_count, 0.0277, 0.01
  end

  test "Exploding dice: 1d6!" do
    {:ok, stream} = DiceFormulaParser.simulate_stream("1d6!")
    values = Stream.take(stream, @roll_count)

    MapSet.new(values)
    |> Enum.all?(& rem(&1, 6) != 0)
    |> assert()

    counts = DiceViz.DiceFormulaParser.counts_for(values)

    # 1 in 6 chance
    for i <- 1..5 do
      assert_in_delta counts[i] / @roll_count, 0.1666, 0.01
    end
    # 1 in 36 chance
    for i <- 7..11 do
      assert_in_delta counts[i] / @roll_count, 0.0277, 0.01
    end
    # 1 in 216 chance
    for i <- 13..17 do
      assert_in_delta counts[i] / @roll_count, 0.004629, 0.01
    end


    # Enum.each(1..50, fn (i) ->
    #   if counts[i] do
    #     IO.puts("#{i},#{:erlang.float_to_binary(counts[i] / @roll_count, [:compact, { :decimals, 20 }])}")
    #   end
    # end)
  end

  test "max(1d6 - 1, 1)" do
    {:ok, stream} = DiceFormulaParser.simulate_stream("max(1d6 - 1, 1)")
    values = Stream.take(stream, @roll_count)

    assert MapSet.new(values) == MapSet.new(1..5)

    counts = DiceViz.DiceFormulaParser.counts_for(values)

    assert_in_delta counts[1] / @roll_count, 0.3333, 0.01
    assert_in_delta counts[2] / @roll_count, 0.1666, 0.01
    assert_in_delta counts[3] / @roll_count, 0.1666, 0.01
    assert_in_delta counts[4] / @roll_count, 0.1666, 0.01
    assert_in_delta counts[5] / @roll_count, 0.1666, 0.01
  end

  test "min(1d6 + 1, 4)" do
    {:ok, stream} = DiceFormulaParser.simulate_stream("min(1d6 + 1, 4)")
    values = Stream.take(stream, @roll_count)

    assert MapSet.new(values) == MapSet.new(2..4)

    counts = DiceViz.DiceFormulaParser.counts_for(values)

    assert_in_delta counts[2] / @roll_count, 0.1666, 0.01
    assert_in_delta counts[3] / @roll_count, 0.1666, 0.01
    assert_in_delta counts[4] / @roll_count, 0.6666, 0.01
  end

  test "round(2d6 / 3)" do
    {:ok, stream} = DiceFormulaParser.simulate_stream("round(2d6 / 3)")
    values = Stream.take(stream, @roll_count)

    assert MapSet.new(values) == MapSet.new(1..4)

    counts = DiceViz.DiceFormulaParser.counts_for(values)

    assert_in_delta counts[1] / @roll_count, 0.1666, 0.01
    assert_in_delta counts[2] / @roll_count, 0.4166, 0.01
    assert_in_delta counts[3] / @roll_count, 0.3333, 0.01
    assert_in_delta counts[4] / @roll_count, 0.0833, 0.01
  end
end
