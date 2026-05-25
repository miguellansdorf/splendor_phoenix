defmodule Splendor.Game.Coins do
  alias Splendor.Game.Structs.Attributes

  @spec init(2 | 3 | 4) :: Attributes.t()
  def init(player_count) when player_count in [2, 3, 4] do
    count =
      case player_count do
        4 -> 7
        _ -> player_count + 2
      end

    %Attributes{
      diamond: count,
      ruby: count,
      saphire: count,
      emerald: count,
      amethyst: count,
      gold: 5
    }
  end

  @spec validate_selection(Attributes.t(), Attributes.t()) :: :ok | {:error, atom()}
  def validate_selection(%Attributes{} = available, %Attributes{} = selection) do
    selection_list =
      Map.from_struct(selection) |> Enum.filter(fn {_attribute, amount} -> amount > 0 end)

    cond do
      Map.get(selection, :gold, 0) > 0 ->
        {:error, :cannot_select_gold}

      length(selection_list) > 3 ->
        {:error, :max_three_coins}

      length(selection_list) != 1 &&
          Enum.any?(selection_list, fn {_attribute, amount} -> amount > 1 end) ->
        {:error, :only_one_of_each_attribute}

      length(selection_list) == 1 &&
          Enum.any?(selection_list, fn {attribute, amount} ->
            amount == 2 && Map.get(available, attribute, 0) < 4
          end) ->
        {:error, :insufficient_coins_for_double}

      length(selection_list) == 1 &&
          Enum.any?(selection_list, fn {_attribute, amount} -> amount > 2 end) ->
        {:error, :no_more_than_two}

      Enum.any?(selection_list, fn {attribute, amount} ->
        Map.get(available, attribute, 0) < amount
      end) ->
        {:error, :insufficient_coins}

      true ->
        :ok
    end
  end

  @spec calculate_costs(Attributes.t(), Attributes.t()) :: Attributes.t()
  def calculate_costs(%Attributes{} = original_cost, %Attributes{} = discount) do
    subtract(original_cost, discount)
    |> Map.from_struct()
    |> Enum.reduce(%Attributes{}, fn {attribute, amount}, acc ->
      if amount > 0 do
        Map.put(acc, attribute, amount)
      else
        acc
      end
    end)
  end

  @spec verify_payment(Attributes.t(), Attributes.t()) ::
          :ok | {:error, :incorrect_gold_amount | :overpaying}
  def verify_payment(%Attributes{} = cost, %Attributes{} = payment) do
    remainder =
      Enum.reduce([:diamond, :ruby, :emerald, :saphire, :amethyst], %{}, fn attribute, acc ->
        cost_amount = Map.get(cost, attribute)
        payment_amount = Map.get(payment, attribute)
        Map.put(acc, attribute, cost_amount - payment_amount)
      end)

    cond do
      Enum.any?(remainder, fn {_attribute, amount} -> amount < 0 end) ->
        {:error, :overpaying}

      Enum.sum_by(remainder, fn {_attribute, amount} -> amount end) != Map.get(payment, :gold) ->
        {:error, :incorrect_gold_amount}

      true ->
        :ok
    end
  end

  @spec add(Attributes.t(), Attributes.t()) :: Attributes.t()
  def add(%Attributes{} = current, %Attributes{} = addition) do
    addition
    |> Map.from_struct()
    |> Enum.reduce(current, fn {attribute, amount}, acc ->
      Map.update!(acc, attribute, &(&1 + amount))
    end)
  end

  @spec subtract(Attributes.t(), Attributes.t()) :: Attributes.t()
  def subtract(%Attributes{} = current, %Attributes{} = subtraction) do
    subtraction
    |> Map.from_struct()
    |> Enum.reduce(current, fn {attribute, amount}, acc ->
      Map.update!(acc, attribute, &(&1 - amount))
    end)
  end
end
