defmodule Splendor.Game do
  use GenServer

  alias Splendor.Accounts.User
  alias Splendor.Game.Structs.{Attributes, State}
  alias Splendor.Game.Actions

  defp via_tuple(game_id), do: {:via, Registry, {Splendor.GameRegistry, game_id}}

  # API
  def start_link(_init) do
    game_id = Ecto.UUID.generate()
    {:ok, pid} = GenServer.start_link(__MODULE__, game_id, name: via_tuple(game_id))
    {:ok, pid, game_id}
  end

  def get_state(game_id) do
    via_tuple(game_id) |> GenServer.call(:get_state)
  end

  def join_game(game_id, %User{} = player_info) do
    via_tuple(game_id) |> GenServer.call({:join_game, player_info})
  end

  def leave_game(game_id, player_id) do
    via_tuple(game_id) |> GenServer.call({:leave_game, player_id})
  end

  def toggle_ready(game_id, player_id) do
    via_tuple(game_id) |> GenServer.call({:toggle_ready, player_id})
  end

  def start_game(game_id) do
    via_tuple(game_id) |> GenServer.call(:start_game)
  end

  def take_coins(game_id, player_id, %Attributes{} = coins) do
    via_tuple(game_id) |> GenServer.call({:take_coins, player_id, coins})
  end

  def return_coins(game_id, player_id, %Attributes{} = coins) do
    via_tuple(game_id) |> GenServer.call({:return_coins, player_id, coins})
  end

  def reserve_development(game_id, player_id, level, index)
      when level in [1, 2, 3] and index in [-1, 0, 1, 2, 3] do
    via_tuple(game_id) |> GenServer.call({:reserve_development, player_id, level, index})
  end

  def buy_development(game_id, player_id, level, index, %Attributes{} = payment)
      when level in [1, 2, 3] and index in [0, 1, 2, 3] do
    via_tuple(game_id) |> GenServer.call({:buy_development, player_id, level, index, payment})
  end

  def buy_reserved_development(game_id, player_id, index, %Attributes{} = payment)
      when is_integer(index) do
    via_tuple(game_id) |> GenServer.call({:buy_reserved_development, player_id, index, payment})
  end

  def select_noble(game_id, player_id, index) when is_integer(index) do
    via_tuple(game_id) |> GenServer.call({:select_noble, player_id, index})
  end

  @impl true
  def init(game_id) do
    {:ok, %State{game_id: game_id}}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:join_game, player_info}, _from, state) do
    case Actions.join_game(state, player_info) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, new_state} ->
        {:reply, :ok, new_state}
    end
  end

  def handle_call({:leave_game, player_id}, _from, state) do
    case Actions.leave_game(state, player_id) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, new_state} ->
        {:reply, :ok, new_state}
    end
  end

  def handle_call({:toggle_ready, player_id}, _from, state) do
    case Actions.toggle_ready(state, player_id) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, new_state} ->
        {:reply, :ok, new_state}
    end
  end

  def handle_call(:start_game, _from, state) do
    case Actions.start_game(state) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, new_state} ->
        {:reply, :ok, new_state}
    end
  end

  def handle_call({:take_coins, player_id, selection}, _from, state) do
    case Actions.take_coins(state, player_id, selection) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, new_state} ->
        {:reply, :ok, new_state}
    end
  end

  def handle_call({:return_coins, player_id, selection}, _from, state) do
    case Actions.return_coins(state, player_id, selection) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, new_state} ->
        {:reply, :ok, new_state}
    end
  end

  def handle_call({:reserve_development, player_id, level, index}, _from, state) do
    case Actions.reserve_development(state, player_id, level, index) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, new_state} ->
        {:reply, :ok, new_state}
    end
  end

  def handle_call({:buy_development, player_id, level, index, payment}, _from, state) do
    case Actions.buy_development(state, player_id, level, index, payment) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, new_state} ->
        {:reply, :ok, new_state}
    end
  end

  def handle_call({:buy_reserved_development, player_id, index, payment}, _from, state) do
    case Actions.buy_reserved_development(state, player_id, index, payment) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, new_state} ->
        {:reply, :ok, new_state}
    end
  end

  def handle_call({:select_noble, player_id, index}, _from, state) do
    case Actions.select_noble(state, player_id, index) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, new_state} ->
        {:reply, :ok, new_state}
    end
  end
end
