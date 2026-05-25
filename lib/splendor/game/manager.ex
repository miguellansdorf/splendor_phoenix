defmodule Splendor.Game.Manager do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def list_games do
    Registry.select(Splendor.GameRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  def create_game() do
    case DynamicSupervisor.start_child(__MODULE__, {Splendor.Game, []}) do
      {:ok, _pid, game_id} ->
        {:ok, game_id}

      {:error, :max_children} ->
        {:error, "Too many games"}
    end
  end

  def end_game(game_id) do
    case get_game_pid(game_id) do
      nil ->
        {:error, :game_not_found}

      pid ->
        :ok = DynamicSupervisor.terminate_child(__MODULE__, pid)
        {:ok, :game_ended}
    end
  end

  def game_exists?(game_id) do
    case get_game_pid(game_id) do
      nil -> false
      _ -> true
    end
  end

  defp get_game_pid(game_id) do
    case Registry.lookup(Splendor.GameRegistry, game_id) do
      [] ->
        nil

      [{pid, _}] ->
        pid
    end
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
