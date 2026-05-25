defmodule Splendor.Game.Actions do
  alias Splendor.Game.Structs.{Attributes, Development, Player, State, Noble}
  alias Splendor.Game.{Coins, Developments, Events, Nobles}

  @max_players 4
  @max_player_coins 10
  @game_points 15
  @max_reservations 3

  defp get_next_player_index(last_player_index, current_player_index, is_final_round) do
    if current_player_index == last_player_index do
      (is_final_round && -1) || 0
    else
      current_player_index + 1
    end
  end

  defp get_winner_index(players) do
    points_sorted_players = Enum.sort_by(players, & &1.points, :desc)
    highest_points = List.first(points_sorted_players).points

    points_filtered_players =
      Enum.filter(points_sorted_players, fn player -> player.points == highest_points end)

    winner =
      cond do
        length(points_filtered_players) > 1 ->
          developments_sorted_players =
            Enum.sort_by(
              points_filtered_players,
              fn %Player{} = player ->
                length(player.developments)
              end,
              :asc
            )

          List.first(developments_sorted_players)

        true ->
          List.first(points_filtered_players)
      end

    Enum.find_index(players, fn player -> player.id == winner.id end)
  end

  defp developments_list_to_attributes(developments) do
    Enum.reduce(developments, %Attributes{}, fn %Development{} = development, acc ->
      Map.update!(acc, development.attribute, &(&1 + 1))
    end)
  end

  defp get_development_by_index({cards, deck}, index) do
    cond do
      index == -1 ->
        List.first(deck)

      true ->
        Enum.at(cards, index)
    end
  end

  def join_game(%State{} = state, %{id: player_id, username: username}) do
    cond do
      state.phase != :lobby ->
        {:error, :game_already_started}

      length(state.players) == @max_players ->
        {:error, :game_full}

      Enum.any?(state.players, fn %{id: p} -> p == player_id end) ->
        {:error, :already_joined}

      true ->
        player = %Player{
          id: player_id,
          username: username
        }

        state = %State{state | players: [player | state.players]}

        Events.add(:player_joined, player)
        |> Events.broadcast(state.game_id)

        {:ok, state}
    end
  end

  def leave_game(%State{} = state, player_id) do
    cond do
      state.phase != :lobby ->
        {:error, :game_already_started}

      Enum.all?(state.players, fn %{id: id} -> id != player_id end) ->
        {:error, :player_not_found}

      true ->
        players =
          for player <- state.players, player.id != player_id do
            %{player | is_ready?: false}
          end

        state = %State{state | players: players}

        Events.add(:player_left, player_id)
        |> Events.broadcast(state.game_id)

        {:ok, state}
    end
  end

  def toggle_ready(%State{} = state, player_id) do
    player_index =
      Enum.find_index(state.players, fn %Player{} = player -> player.id == player_id end)

    cond do
      state.phase != :lobby ->
        {:error, :game_already_started}

      player_index == nil ->
        {:error, :player_not_found}

      true ->
        player_info = %Player{} = Enum.at(state.players, player_index)
        new_player_info = %Player{player_info | is_ready?: !player_info.is_ready?}

        players = List.replace_at(state.players, player_index, new_player_info)

        state = %State{state | players: players}

        Events.add(:player_info_updated, {player_index, new_player_info})
        |> Events.broadcast(state.game_id)

        {:ok, state}
    end
  end

  def start_game(%State{} = state) do
    player_count = length(state.players)

    player_ready_count =
      Enum.reduce(state.players, 0, fn %Player{} = player, acc ->
        if player.is_ready?, do: acc + 1, else: acc
      end)

    cond do
      state.phase != :lobby ->
        {:error, :game_already_started}

      player_count < 2 ->
        {:error, :not_enough_players}

      player_ready_count < player_count ->
        {:error, :not_all_players_ready}

      true ->
        players = Enum.shuffle(state.players)

        state = %State{
          state
          | phase: :select,
            coins: Coins.init(player_count),
            development_group_1: Developments.init(1),
            development_group_2: Developments.init(2),
            development_group_3: Developments.init(3),
            nobles: Nobles.init(player_count),
            players: players
        }

        Events.add(:game_started, state)
        |> Events.broadcast(state.game_id)

        {:ok, state}
    end
  end

  def take_coins(%State{} = state, player_id, %Attributes{} = selection) do
    player_info = %Player{} = Enum.at(state.players, state.current_player_index)

    cond do
      state.phase != :select ->
        {:error, :not_select_phase}

      player_info.id != player_id ->
        {:error, :not_current_player}

      true ->
        case Coins.validate_selection(state.coins, selection) do
          {:error, reason} ->
            {:error, reason}

          :ok ->
            new_game_coins = Coins.subtract(state.coins, selection)

            new_player_info = %Player{
              player_info
              | coins: Coins.add(player_info.coins, selection)
            }

            new_players =
              List.replace_at(state.players, state.current_player_index, new_player_info)

            player_coins_count =
              new_player_info.coins
              |> Map.from_struct()
              |> Enum.reduce(0, fn {_attribute, amount}, acc -> acc + amount end)

            next_player_index =
              get_next_player_index(
                length(state.players) - 1,
                state.current_player_index,
                state.is_final_round?
              )

            can_select_nobles =
              Nobles.can_select_nobles?(
                state.nobles,
                developments_list_to_attributes(new_player_info.developments)
              )

            {next_player_index, game_over} =
              cond do
                player_coins_count > @max_player_coins ->
                  {state.current_player_index, false}

                can_select_nobles ->
                  {state.current_player_index, false}

                next_player_index == -1 ->
                  {next_player_index, true}

                true ->
                  {next_player_index, false}
              end

            new_phase =
              cond do
                player_coins_count > @max_player_coins -> :return
                can_select_nobles -> :noble
                game_over -> :game_over
                true -> :select
              end

            next_player_index = (game_over && get_winner_index(new_players)) || next_player_index

            Events.add(:phase_updated, new_phase)
            |> Events.add(:current_player_updated, next_player_index)
            |> Events.add(:coins_updated, new_game_coins)
            |> Events.add(:player_info_updated, {state.current_player_index, new_player_info})
            |> Events.broadcast(state.game_id)

            state = %State{
              state
              | phase: new_phase,
                current_player_index: next_player_index,
                coins: new_game_coins,
                players: new_players
            }

            {:ok, state}
        end
    end
  end

  def return_coins(%State{} = state, player_id, %Attributes{} = selection) do
    player_info = %Player{} = Enum.at(state.players, state.current_player_index)

    insufficient_coins =
      Map.from_struct(selection)
      |> Enum.any?(fn {attribute, amount} ->
        Map.get(player_info.coins, attribute) < amount
      end)

    updated_player_coins_count =
      Coins.subtract(player_info.coins, selection)
      |> Map.from_struct()
      |> Enum.reduce(0, fn {_attribute, amount}, acc -> acc + amount end)

    cond do
      state.phase != :return ->
        {:error, :not_return_phase}

      player_info.id != player_id ->
        {:error, :not_current_player}

      insufficient_coins == true ->
        {:error, :insufficient_coins}

      updated_player_coins_count > @max_player_coins ->
        {:error, :still_too_many_coins}

      true ->
        new_game_coins = Coins.add(state.coins, selection)

        new_player_info = %Player{
          player_info
          | coins: Coins.subtract(player_info.coins, selection)
        }

        new_players = List.replace_at(state.players, state.current_player_index, new_player_info)

        next_player_index =
          get_next_player_index(
            length(state.players) - 1,
            state.current_player_index,
            state.is_final_round?
          )

        can_select_nobles =
          Nobles.can_select_nobles?(
            state.nobles,
            developments_list_to_attributes(new_player_info.developments)
          )

        {next_player_index, game_over} =
          cond do
            can_select_nobles ->
              {state.current_player_index, false}

            next_player_index == -1 ->
              {next_player_index, true}

            true ->
              {next_player_index, false}
          end

        new_phase =
          cond do
            can_select_nobles -> :noble
            game_over -> :game_over
            true -> :select
          end

        next_player_index = (game_over && get_winner_index(new_players)) || next_player_index

        Events.add(:phase_updated, new_phase)
        |> Events.add(:current_player_updated, next_player_index)
        |> Events.add(:coins_updated, new_game_coins)
        |> Events.add(:player_info_updated, {state.current_player_index, new_player_info})
        |> Events.broadcast(state.game_id)

        state = %State{
          state
          | phase: new_phase,
            current_player_index: next_player_index,
            coins: new_game_coins,
            players: new_players
        }

        {:ok, state}
    end
  end

  def reserve_development(%State{} = state, player_id, level, index)
      when level in [1, 2, 3] and index in [-1, 0, 1, 2, 3] do
    player_info = %Player{} = Enum.at(state.players, state.current_player_index)

    {development_group_key, selection} =
      case level do
        1 -> {:development_group_1, get_development_by_index(state.development_group_1, index)}
        2 -> {:development_group_2, get_development_by_index(state.development_group_2, index)}
        3 -> {:development_group_3, get_development_by_index(state.development_group_3, index)}
      end

    cond do
      state.phase != :select ->
        {:error, :not_select_phase}

      player_info.id != player_id ->
        {:error, :not_current_player}

      length(player_info.reservations) == @max_reservations ->
        {:error, :reservation_limit_reached}

      selection == nil ->
        {:error, :invalid_selection}

      true ->
        gold_available? = Map.get(state.coins, :gold, 0) > 0

        new_player_info = %Player{
          player_info
          | reservations: [selection | player_info.reservations],
            coins:
              if(gold_available?,
                do: Coins.add(player_info.coins, %Attributes{gold: 1}),
                else: player_info.coins
              )
        }

        new_game_coins =
          if(gold_available?,
            do: Coins.subtract(state.coins, %Attributes{gold: 1}),
            else: state.coins
          )

        new_players = List.replace_at(state.players, state.current_player_index, new_player_info)

        new_development_group =
          Developments.update_group(Map.get(state, development_group_key), index)

        can_select_nobles =
          Nobles.can_select_nobles?(
            state.nobles,
            developments_list_to_attributes(new_player_info.developments)
          )

        player_coins_count =
          new_player_info.coins
          |> Map.from_struct()
          |> Enum.reduce(0, fn {_attribute, amount}, acc -> acc + amount end)

        next_player_index =
          get_next_player_index(
            length(state.players) - 1,
            state.current_player_index,
            state.is_final_round?
          )

        {next_player_index, game_over} =
          cond do
            player_coins_count > @max_player_coins ->
              {state.current_player_index, false}

            can_select_nobles ->
              {state.current_player_index, false}

            next_player_index == -1 ->
              {next_player_index, true}

            true ->
              {next_player_index, false}
          end

        new_phase =
          cond do
            player_coins_count > @max_player_coins -> :return
            can_select_nobles -> :noble
            game_over -> :game_over
            true -> :select
          end

        next_player_index = (game_over && get_winner_index(new_players)) || next_player_index

        Events.add(:phase_updated, new_phase)
        |> Events.add(:player_info_updated, {state.current_player_index, new_player_info})
        |> Events.add(:coins_updated, new_game_coins)
        |> Events.add(:developments_updated, {development_group_key, new_development_group})
        |> Events.add(:current_player_updated, next_player_index)
        |> Events.broadcast(state.game_id)

        state =
          state
          |> Map.put(:phase, new_phase)
          |> Map.put(:coins, new_game_coins)
          |> Map.put(:players, new_players)
          |> Map.put(:current_player_index, next_player_index)
          |> Map.put(development_group_key, new_development_group)

        {:ok, state}
    end
  end

  def buy_development(%State{} = state, player_id, level, index, %Attributes{} = payment)
      when level in [1, 2, 3] and index in [0, 1, 2, 3] do
    player_info = %Player{} = Enum.at(state.players, state.current_player_index)

    {development_group_key, selection} =
      case level do
        1 -> {:development_group_1, get_development_by_index(state.development_group_1, index)}
        2 -> {:development_group_2, get_development_by_index(state.development_group_2, index)}
        3 -> {:development_group_3, get_development_by_index(state.development_group_3, index)}
      end

    cost =
      case selection do
        nil ->
          nil

        %Development{} = selection ->
          Coins.calculate_costs(
            selection.cost,
            developments_list_to_attributes(player_info.developments)
          )
      end

    cond do
      state.phase != :select ->
        {:error, :not_select_phase}

      player_info.id != player_id ->
        {:error, :not_current_player}

      selection == nil ->
        {:error, :invalid_selection}

      Map.from_struct(payment)
      |> Enum.any?(fn {attribute, amount} ->
        Map.get(player_info.coins, attribute, 0) < amount
      end) ->
        {:error, :insufficient_coins}

      (response = Coins.verify_payment(cost, payment)) != :ok ->
        response

      true ->
        new_player_info = %Player{
          player_info
          | coins: Coins.subtract(player_info.coins, payment),
            developments: [selection | player_info.developments],
            points: player_info.points + selection.points
        }

        new_game_coins = Coins.add(state.coins, payment)

        new_players = List.replace_at(state.players, state.current_player_index, new_player_info)

        new_development_group =
          Developments.update_group(Map.get(state, development_group_key), index)

        can_select_nobles =
          Nobles.can_select_nobles?(
            state.nobles,
            developments_list_to_attributes(new_player_info.developments)
          )

        is_final_round? = state.is_final_round? || new_player_info.points >= @game_points

        next_player_index =
          (can_select_nobles && state.current_player_index) ||
            get_next_player_index(
              length(state.players) - 1,
              state.current_player_index,
              is_final_round?
            )

        game_over = next_player_index == -1

        next_player_index = (game_over && get_winner_index(new_players)) || next_player_index

        new_phase =
          cond do
            can_select_nobles -> :noble
            game_over -> :game_over
            true -> :select
          end

        Events.add(:phase_updated, new_phase)
        |> Events.add(:player_info_updated, {state.current_player_index, new_player_info})
        |> Events.add(:coins_updated, new_game_coins)
        |> Events.add(:developments_updated, {development_group_key, new_development_group})
        |> Events.add(:current_player_updated, next_player_index)
        |> Events.add(:is_final_round?, is_final_round?)
        |> Events.broadcast(state.game_id)

        state =
          state
          |> Map.put(:phase, new_phase)
          |> Map.put(:players, new_players)
          |> Map.put(:coins, new_game_coins)
          |> Map.put(development_group_key, new_development_group)
          |> Map.put(:current_player_index, next_player_index)
          |> Map.put(:is_final_round?, is_final_round?)

        {:ok, state}
    end
  end

  def buy_reserved_development(%State{} = state, player_id, index, payment)
      when is_integer(index) do
    player_info = %Player{} = Enum.at(state.players, state.current_player_index)

    {selection, new_reservations} = List.pop_at(player_info.reservations, index)

    cost =
      case selection do
        nil ->
          nil

        %Development{} = selection ->
          Coins.calculate_costs(
            selection.cost,
            developments_list_to_attributes(player_info.developments)
          )
      end

    cond do
      state.phase != :select ->
        {:error, :not_select_phase}

      player_info.id != player_id ->
        {:error, :not_current_player}

      selection == nil ->
        {:error, :invalid_selection}

      Map.from_struct(payment)
      |> Enum.any?(fn {attribute, amount} ->
        Map.get(player_info.coins, attribute, 0) < amount
      end) ->
        {:error, :insufficient_coins}

      (response = Coins.verify_payment(cost, payment)) != :ok ->
        response

      true ->
        new_player_info = %Player{
          player_info
          | coins: Coins.subtract(player_info.coins, payment),
            developments: [selection | player_info.developments],
            points: player_info.points + selection.points,
            reservations: new_reservations
        }

        new_game_coins = Coins.add(state.coins, payment)

        new_players = List.replace_at(state.players, state.current_player_index, new_player_info)

        can_select_nobles =
          Nobles.can_select_nobles?(
            state.nobles,
            developments_list_to_attributes(new_player_info.developments)
          )

        is_final_round? = state.is_final_round? || new_player_info.points >= @game_points

        next_player_index =
          (can_select_nobles && state.current_player_index) ||
            get_next_player_index(
              length(state.players) - 1,
              state.current_player_index,
              is_final_round?
            )

        game_over = next_player_index == -1

        next_player_index = (game_over && get_winner_index(new_players)) || next_player_index

        new_phase =
          cond do
            can_select_nobles -> :noble
            game_over -> :game_over
            true -> :select
          end

        Events.add(:phase_updated, new_phase)
        |> Events.add(:player_info_updated, {state.current_player_index, new_player_info})
        |> Events.add(:coins_updated, new_game_coins)
        |> Events.add(:current_player_updated, next_player_index)
        |> Events.add(:is_final_round?, is_final_round?)
        |> Events.broadcast(state.game_id)

        state = %State{
          state
          | phase: new_phase,
            coins: new_game_coins,
            players: new_players,
            current_player_index: next_player_index,
            is_final_round?: is_final_round?
        }

        {:ok, state}
    end
  end

  def select_noble(%State{} = state, player_id, index) when is_integer(index) do
    player_info = %Player{} = Enum.at(state.players, state.current_player_index)

    {selection, new_nobles} = List.pop_at(state.nobles, index)

    valid_selection =
      case selection do
        nil ->
          false

        %Noble{} = selection ->
          player_development_attributes =
            developments_list_to_attributes(player_info.developments)

          Map.from_struct(selection.cost)
          |> Enum.all?(fn {attribute, amount} ->
            Map.get(player_development_attributes, attribute, 0) >=
              amount
          end)
      end

    cond do
      state.phase != :noble ->
        {:error, :not_noble_phase}

      player_info.id != player_id ->
        {:error, :not_current_player}

      valid_selection == false ->
        {:error, :invalid_selection}

      true ->
        new_player_info = %Player{
          player_info
          | nobles: [selection | player_info.nobles],
            points: player_info.points + selection.points
        }

        new_players = List.replace_at(state.players, state.current_player_index, new_player_info)

        is_final_round? = state.is_final_round? || new_player_info.points >= @game_points

        next_player_index =
          get_next_player_index(
            length(state.players) - 1,
            state.current_player_index,
            is_final_round?
          )

        game_over = next_player_index == -1

        next_player_index = (game_over && get_winner_index(new_players)) || next_player_index

        new_phase = (game_over && :game_over) || :select

        Events.add(:phase_updated, new_phase)
        |> Events.add(:player_info_updated, {state.current_player_index, new_player_info})
        |> Events.add(:current_player_updated, next_player_index)
        |> Events.add(:nobles_updated, new_nobles)
        |> Events.add(:is_final_round?, is_final_round?)
        |> Events.broadcast(state.game_id)

        state = %State{
          state
          | phase: new_phase,
            current_player_index: next_player_index,
            players: new_players,
            nobles: new_nobles,
            is_final_round?: is_final_round?
        }

        {:ok, state}
    end
  end
end
