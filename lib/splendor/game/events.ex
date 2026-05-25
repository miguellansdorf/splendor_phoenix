defmodule Splendor.Game.Events do
  alias Splendor.Game.Structs.{Attributes, Player, State}

  def subscribe(game_id) do
    Phoenix.PubSub.subscribe(Splendor.PubSub, game_id)
  end

  def broadcast(events \\ [], game_id) do
    Phoenix.PubSub.broadcast(Splendor.PubSub, game_id, events)
  end

  def add(events \\ [], event_name, payload)

  def add(events, :player_joined, %Player{} = payload) do
    [{:player_joined, payload} | events]
  end

  def add(events, :player_left, payload) when is_binary(payload) do
    [{:player_left, payload} | events]
  end

  def add(events, :player_info_updated, {index, %Player{} = _player_info} = payload)
      when is_integer(index) do
    [{:player_info_updated, payload} | events]
  end

  def add(events, :game_started, %State{} = payload) do
    [{:game_started, payload} | events]
  end

  def add(events, :coins_updated, %Attributes{} = payload) do
    [{:coins_updated, payload} | events]
  end

  def add(events, :phase_updated, payload) when is_atom(payload) do
    [{:phase_updated, payload} | events]
  end

  def add(events, :current_player_updated, payload) when is_integer(payload) do
    [{:current_player_updated, payload} | events]
  end

  def add(events, :developments_updated, {group_key, {cards, deck}} = payload)
      when group_key in [:development_group_1, :development_group_2, :development_group_3] and
             is_list(deck) and is_list(cards) do
    [{:developments_updated, payload} | events]
  end

  def add(events, :nobles_updated, payload) when is_list(payload) do
    [{:nobles_updated, payload} | events]
  end

  def add(events, :is_final_round?, payload) when is_boolean(payload) do
    [{:is_final_round?, payload} | events]
  end
end
