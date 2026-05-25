defmodule Splendor.Game.ActionsTest do
  alias Splendor.Game.{Actions, Coins, Events}
  alias Splendor.Game.Structs.{Attributes, Development, Noble, State, Player}

  use ExUnit.Case

  setup context do
    Events.subscribe(context.state.game_id)
    %{state: context.state}
  end

  describe "join_game/2" do
    @tag state: %State{game_id: "join_game"}
    test "successfully join game", %{state: state} do
      {:ok, state} = Actions.join_game(state, %{id: "player1", username: "player1"})
      assert state.players == [%Player{id: "player1", username: "player1"}]

      assert_received([{:player_joined, %Player{id: "player1", username: "player1"}}])

      {:ok, state} =
        Actions.join_game(state, %{id: "player2", username: "player2"})

      assert state.players == [
               %Player{id: "player2", username: "player2"},
               %Player{id: "player1", username: "player1"}
             ]

      assert_received([{:player_joined, %Player{id: "player2", username: "player2"}}])
    end

    @tag state: %State{game_id: "join_game", phase: :select}
    test "fail to join game if not lobby phase", %{state: state} do
      assert Actions.join_game(state, %{id: "player1", username: "player1"}) ==
               {:error, :game_already_started}
    end

    @tag state: %State{
           game_id: "join_game",
           players: [
             %Player{id: "player1", username: "player1"},
             %Player{id: "player2", username: "player2"},
             %Player{id: "player3", username: "player3"},
             %Player{id: "player4", username: "player4"}
           ]
         }
    test "fail to join game if full", %{state: state} do
      assert Actions.join_game(state, %{id: "player1", username: "player1"}) ==
               {:error, :game_full}
    end

    @tag state: %State{
           game_id: "join_game",
           players: [%Player{id: "player1", username: "player1"}]
         }
    test "fail to join game if already joined", %{state: state} do
      assert Actions.join_game(state, %{id: "player1", username: "player1"}) ==
               {:error, :already_joined}
    end
  end

  describe "leave_game/2" do
    @tag state: %State{
           game_id: "leave_game",
           players: [
             %Player{id: "player2", username: "player2"},
             %Player{id: "player1", username: "player1"}
           ]
         }
    test "successfully leave game", %{state: state} do
      {:ok, state} = Actions.leave_game(state, "player2")
      assert state.players == [%Player{id: "player1", username: "player1"}]

      assert_received([{:player_left, "player2"}])

      {:ok, state} = Actions.leave_game(state, "player1")
      assert state.players == []

      assert_received([{:player_left, "player1"}])
    end

    @tag state: %State{
           game_id: "leave_game",
           phase: :select,
           players: [
             %Player{id: "player2", username: "player2"},
             %Player{id: "player1", username: "player1"}
           ]
         }
    test "fail to leave game if not lobby phase", %{state: state} do
      assert Actions.leave_game(state, "player1") == {:error, :game_already_started}
    end

    @tag state: %State{
           game_id: "leave_game",
           players: [
             %Player{id: "player1", username: "player1"}
           ]
         }
    test "fail to leave game if not joined", %{state: state} do
      assert Actions.leave_game(state, "player2") == {:error, :player_not_found}
    end
  end

  describe "toggle_ready/2" do
    @tag state: %State{
           game_id: "toggle_ready",
           players: [%Player{id: "player1", username: "player1"}]
         }
    test "successfully toggle ready", %{state: state} do
      {:ok, state} = Actions.toggle_ready(state, "player1")

      assert state.players == [
               %Player{id: "player1", username: "player1", is_ready?: true}
             ]

      assert_received([
        {:player_info_updated, {0, %Player{id: "player1", username: "player1", is_ready?: true}}}
      ])

      {:ok, state} = Actions.toggle_ready(state, "player1")

      assert state.players == [
               %Player{id: "player1", username: "player1", is_ready?: false}
             ]

      assert_received([
        {:player_info_updated, {0, %Player{id: "player1", username: "player1", is_ready?: false}}}
      ])
    end

    @tag state: %State{
           game_id: "toggle_ready",
           phase: :select,
           players: [%Player{id: "player1", username: "player1"}]
         }
    test "fail to toggle ready if not lobby phase", %{state: state} do
      assert Actions.toggle_ready(state, "player1") == {:error, :game_already_started}
    end

    @tag state: %State{
           game_id: "toggle_ready",
           players: [%Player{id: "player1", username: "player1"}]
         }
    test "fail to toggle ready if not joined", %{state: state} do
      assert Actions.toggle_ready(state, "player2") == {:error, :player_not_found}
    end
  end

  describe "start_game/1" do
    @tag state: %State{
           game_id: "start_game",
           players: [
             %Player{id: "player1", username: "player1", is_ready?: true},
             %Player{id: "player2", username: "player2", is_ready?: true}
           ]
         }
    test "successfully start game with 2 players", %{state: state} do
      {:ok, %State{} = state} = Actions.start_game(state)
      assert state.phase == :select

      assert state.coins == %Attributes{
               diamond: 4,
               ruby: 4,
               emerald: 4,
               saphire: 4,
               amethyst: 4,
               gold: 5
             }

      assert length(state.nobles) == 3

      {cards1, deck1} = state.development_group_1
      assert length(cards1) == 4
      assert length(deck1) == 36

      {cards2, deck2} = state.development_group_2
      assert length(cards2) == 4
      assert length(deck2) == 26

      {cards3, deck3} = state.development_group_3
      assert length(cards3) == 4
      assert length(deck3) == 16

      assert_received([{:game_started, ^state}])
    end

    @tag state: %State{
           game_id: "start_game",
           players: [
             %Player{id: "player1", username: "player1", is_ready?: true},
             %Player{id: "player2", username: "player2", is_ready?: true},
             %Player{id: "player3", username: "player3", is_ready?: true}
           ]
         }
    test "successfully start game with 3 players", %{state: state} do
      {:ok, %State{} = state} = Actions.start_game(state)
      assert state.phase == :select

      assert state.coins == %Attributes{
               diamond: 5,
               ruby: 5,
               emerald: 5,
               saphire: 5,
               amethyst: 5,
               gold: 5
             }

      assert length(state.nobles) == 4

      {cards1, deck1} = state.development_group_1
      assert length(cards1) == 4
      assert length(deck1) == 36

      {cards2, deck2} = state.development_group_2
      assert length(cards2) == 4
      assert length(deck2) == 26

      {cards3, deck3} = state.development_group_3
      assert length(cards3) == 4
      assert length(deck3) == 16

      assert_received([{:game_started, ^state}])
    end

    @tag state: %State{
           game_id: "start_game",
           players: [
             %Player{id: "player1", username: "player1", is_ready?: true},
             %Player{id: "player2", username: "player2", is_ready?: true},
             %Player{id: "player3", username: "player3", is_ready?: true},
             %Player{id: "player4", username: "player4", is_ready?: true}
           ]
         }
    test "successfully start game with 4 players", %{state: state} do
      {:ok, %State{} = state} = Actions.start_game(state)
      assert state.phase == :select

      assert state.coins == %Attributes{
               diamond: 7,
               ruby: 7,
               emerald: 7,
               saphire: 7,
               amethyst: 7,
               gold: 5
             }

      assert length(state.nobles) == 5

      {cards1, deck1} = state.development_group_1
      assert length(cards1) == 4
      assert length(deck1) == 36

      {cards2, deck2} = state.development_group_2
      assert length(cards2) == 4
      assert length(deck2) == 26

      {cards3, deck3} = state.development_group_3
      assert length(cards3) == 4
      assert length(deck3) == 16

      assert_received([{:game_started, ^state}])
    end

    @tag state: %State{
           game_id: "start_game",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1", is_ready?: true},
             %Player{id: "player2", username: "player2", is_ready?: true}
           ]
         }
    test "fail to start game if not lobby phase", %{state: state} do
      assert Actions.start_game(state) == {:error, :game_already_started}
    end

    @tag state: %State{
           game_id: "start_game",
           players: [
             %Player{id: "player1", username: "player1", is_ready?: true}
           ]
         }
    test "fail to start game if not enough players", %{state: state} do
      assert Actions.start_game(state) == {:error, :not_enough_players}
    end

    @tag state: %State{
           game_id: "start_game",
           players: [
             %Player{id: "player1", username: "player1", is_ready?: true},
             %Player{id: "player2", username: "player2", is_ready?: false}
           ]
         }
    test "fail to start game if not all players ready", %{state: state} do
      assert Actions.start_game(state) == {:error, :not_all_players_ready}
    end
  end

  describe "take_coins/3" do
    @tag state: %State{
           game_id: "take_coins",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1"},
             %Player{id: "player2", username: "player2"}
           ],
           coins: Coins.init(2)
         }
    test "successfully take coins and go to next player", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 3,
        ruby: 3,
        emerald: 3,
        saphire: 4,
        amethyst: 4,
        gold: 5
      }

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        coins: %Attributes{diamond: 1, ruby: 1, emerald: 1}
      }

      {:ok, %State{} = state} =
        Actions.take_coins(state, "player1", %Attributes{diamond: 1, emerald: 1, ruby: 1})

      assert state.coins == expected_game_coins

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 1
      assert state.phase == :select

      assert_received([
        {:player_info_updated, {0, ^expected_player_info}},
        {:coins_updated,
         %Attributes{
           diamond: 3,
           ruby: 3,
           emerald: 3,
           saphire: 4,
           amethyst: 4,
           gold: 5
         }},
        {:current_player_updated, 1},
        {:phase_updated, :select}
      ])
    end

    @tag state: %State{
           game_id: "take_coins",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{diamond: 2, ruby: 2, emerald: 2, saphire: 2}
             },
             %Player{id: "player2", username: "player2"}
           ],
           coins: Coins.init(2)
         }
    test "successfully take coins and go to return phase", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 3,
        ruby: 3,
        emerald: 3,
        saphire: 4,
        amethyst: 4,
        gold: 5
      }

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        coins: %Attributes{diamond: 3, ruby: 3, emerald: 3, saphire: 2}
      }

      {:ok, %State{} = state} =
        Actions.take_coins(state, "player1", %Attributes{diamond: 1, emerald: 1, ruby: 1})

      assert state.coins == expected_game_coins

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 0
      assert state.phase == :return

      assert_received([
        {:player_info_updated, {0, ^expected_player_info}},
        {:coins_updated,
         %Attributes{
           diamond: 3,
           ruby: 3,
           emerald: 3,
           saphire: 4,
           amethyst: 4,
           gold: 5
         }},
        {:current_player_updated, 0},
        {:phase_updated, :return}
      ])
    end

    @tag state: %State{
           game_id: "take_coins",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               developments: [
                 %Development{attribute: :diamond, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}},
                 %Development{attribute: :emerald, cost: %Attributes{}},
                 %Development{attribute: :emerald, cost: %Attributes{}},
                 %Development{attribute: :emerald, cost: %Attributes{}},
                 %Development{attribute: :emerald, cost: %Attributes{}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ],
           coins: Coins.init(2),
           nobles: [%Noble{image: "", cost: %Attributes{diamond: 4, emerald: 4}}]
         }
    test "successfully take coins and go to noble phase", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 3,
        ruby: 3,
        emerald: 3,
        saphire: 4,
        amethyst: 4,
        gold: 5
      }

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        coins: %Attributes{diamond: 1, ruby: 1, emerald: 1},
        developments: [
          %Development{attribute: :diamond, cost: %Attributes{}},
          %Development{attribute: :diamond, cost: %Attributes{}},
          %Development{attribute: :diamond, cost: %Attributes{}},
          %Development{attribute: :diamond, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}}
        ]
      }

      {:ok, %State{} = state} =
        Actions.take_coins(state, "player1", %Attributes{diamond: 1, emerald: 1, ruby: 1})

      assert state.coins == expected_game_coins

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 0
      assert state.phase == :noble

      assert_received([
        {:player_info_updated, {0, ^expected_player_info}},
        {:coins_updated,
         %Attributes{
           diamond: 3,
           ruby: 3,
           emerald: 3,
           saphire: 4,
           amethyst: 4,
           gold: 5
         }},
        {:current_player_updated, 0},
        {:phase_updated, :noble}
      ])
    end

    @tag state: %State{
           game_id: "take_coins",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1", points: 15},
             %Player{id: "player2", username: "player2", points: 13}
           ],
           coins: Coins.init(2),
           is_final_round?: true,
           current_player_index: 1
         }
    test "successfully take coins and end the game", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 3,
        ruby: 3,
        emerald: 3,
        saphire: 4,
        amethyst: 4,
        gold: 5
      }

      expected_player_info = %Player{
        id: "player2",
        username: "player2",
        points: 13,
        coins: %Attributes{diamond: 1, ruby: 1, emerald: 1}
      }

      {:ok, %State{} = state} =
        Actions.take_coins(state, "player2", %Attributes{diamond: 1, emerald: 1, ruby: 1})

      assert state.coins == expected_game_coins

      assert state.players == [
               %Player{id: "player1", username: "player1", points: 15},
               expected_player_info
             ]

      assert state.current_player_index == 0
      assert state.phase == :game_over

      assert_received([
        {:player_info_updated, {1, ^expected_player_info}},
        {:coins_updated,
         %Attributes{
           diamond: 3,
           ruby: 3,
           emerald: 3,
           saphire: 4,
           amethyst: 4,
           gold: 5
         }},
        {:current_player_updated, 0},
        {:phase_updated, :game_over}
      ])
    end

    # FAILURES
    @tag state: %State{
           game_id: "take_coins",
           phase: :return,
           players: [
             %Player{id: "player1", username: "player1"},
             %Player{id: "player2", username: "player2"}
           ]
         }
    test "fail to take coins if not select phase", %{state: state} do
      assert Actions.take_coins(state, "player1", %Attributes{}) == {:error, :not_select_phase}
    end

    @tag state: %State{
           game_id: "take_coins",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1"},
             %Player{id: "player2", username: "player2"}
           ]
         }
    test "fail to take coins if not current player", %{state: state} do
      assert Actions.take_coins(state, "player2", %Attributes{}) == {:error, :not_current_player}
    end

    @tag state: %State{
           game_id: "take_coins",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1"},
             %Player{id: "player2", username: "player2"}
           ],
           coins: Coins.init(2)
         }
    test "fail to take coins if taking gold", %{state: state} do
      assert Actions.take_coins(state, "player1", %Attributes{gold: 1, diamond: 1, amethyst: 1}) ==
               {:error, :cannot_select_gold}
    end

    @tag state: %State{
           game_id: "take_coins",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1"},
             %Player{id: "player2", username: "player2"}
           ],
           coins: Coins.init(2)
         }
    test "fail to take coins if taking more than 3", %{state: state} do
      assert Actions.take_coins(state, "player1", %Attributes{
               diamond: 1,
               ruby: 1,
               amethyst: 1,
               emerald: 1
             }) == {:error, :max_three_coins}
    end

    @tag state: %State{
           game_id: "take_coins",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1"},
             %Player{id: "player2", username: "player2"}
           ],
           coins: Coins.init(2)
         }
    test "fail to take coins if taking more than 1 coin of an attribute while taking multiple attributes",
         %{state: state} do
      assert Actions.take_coins(state, "player1", %Attributes{
               diamond: 2,
               ruby: 1,
               amethyst: 1
             }) == {:error, :only_one_of_each_attribute}
    end

    @tag state: %State{
           game_id: "take_coins",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1"},
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{Coins.init(2) | diamond: 3}
         }
    test "fail to take coins if taking 2 of same attribute while less than 4 available",
         %{state: state} do
      assert Actions.take_coins(state, "player1", %Attributes{
               diamond: 2
             }) == {:error, :insufficient_coins_for_double}
    end

    @tag state: %State{
           game_id: "take_coins",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1"},
             %Player{id: "player2", username: "player2"}
           ],
           coins: Coins.init(2)
         }
    test "fail to take coins if taking more than 2 of same attribute",
         %{state: state} do
      assert Actions.take_coins(state, "player1", %Attributes{
               diamond: 3
             }) == {:error, :no_more_than_two}
    end

    @tag state: %State{
           game_id: "take_coins",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1"},
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{Coins.init(2) | diamond: 0}
         }
    test "fail to take coins if taking more than available",
         %{state: state} do
      assert Actions.take_coins(state, "player1", %Attributes{
               diamond: 1,
               emerald: 1,
               ruby: 1
             }) == {:error, :insufficient_coins}
    end
  end

  describe "return_coins/3" do
    @tag state: %State{
           game_id: "return_coins",
           phase: :return,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{diamond: 3, emerald: 3, ruby: 3, saphire: 3}
             },
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{diamond: 1, emerald: 1, ruby: 1, saphire: 1, amethyst: 4, gold: 5}
         }
    test "successfully return coins and go to next player", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 1,
        emerald: 1,
        ruby: 2,
        saphire: 2,
        amethyst: 4,
        gold: 5
      }

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        coins: %Attributes{diamond: 3, emerald: 3, ruby: 2, saphire: 2}
      }

      {:ok, %State{} = state} =
        Actions.return_coins(state, "player1", %Attributes{ruby: 1, saphire: 1})

      assert state.coins == expected_game_coins

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 1
      assert state.phase == :select

      assert_received([
        {:player_info_updated, {0, ^expected_player_info}},
        {:coins_updated, ^expected_game_coins},
        {:current_player_updated, 1},
        {:phase_updated, :select}
      ])
    end

    @tag state: %State{
           game_id: "return_coins",
           phase: :return,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{diamond: 3, emerald: 3, ruby: 3, saphire: 3},
               developments: [
                 %Development{attribute: :diamond, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}},
                 %Development{attribute: :emerald, cost: %Attributes{}},
                 %Development{attribute: :emerald, cost: %Attributes{}},
                 %Development{attribute: :emerald, cost: %Attributes{}},
                 %Development{attribute: :emerald, cost: %Attributes{}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{diamond: 1, emerald: 1, ruby: 1, saphire: 1, amethyst: 4, gold: 5},
           nobles: [%Noble{image: "", cost: %Attributes{diamond: 4, emerald: 4}}]
         }
    test "successfully return coins and go to noble phase", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 1,
        emerald: 1,
        ruby: 2,
        saphire: 2,
        amethyst: 4,
        gold: 5
      }

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        coins: %Attributes{diamond: 3, emerald: 3, ruby: 2, saphire: 2},
        developments: [
          %Development{attribute: :diamond, cost: %Attributes{}},
          %Development{attribute: :diamond, cost: %Attributes{}},
          %Development{attribute: :diamond, cost: %Attributes{}},
          %Development{attribute: :diamond, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}}
        ]
      }

      {:ok, %State{} = state} =
        Actions.return_coins(state, "player1", %Attributes{ruby: 1, saphire: 1})

      assert state.coins == expected_game_coins

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 0
      assert state.phase == :noble

      assert_received([
        {:player_info_updated, {0, ^expected_player_info}},
        {:coins_updated, ^expected_game_coins},
        {:current_player_updated, 0},
        {:phase_updated, :noble}
      ])
    end

    @tag state: %State{
           game_id: "return_coins",
           phase: :return,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               points: 14
             },
             %Player{
               id: "player2",
               username: "player2",
               points: 16,
               coins: %Attributes{diamond: 3, emerald: 3, ruby: 3, saphire: 3}
             }
           ],
           coins: %Attributes{diamond: 1, emerald: 1, ruby: 1, saphire: 1, amethyst: 4, gold: 5},
           current_player_index: 1,
           is_final_round?: true
         }
    test "successfully return coins and end the game", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 1,
        emerald: 1,
        ruby: 2,
        saphire: 2,
        amethyst: 4,
        gold: 5
      }

      expected_player_info = %Player{
        id: "player2",
        username: "player2",
        points: 16,
        coins: %Attributes{diamond: 3, emerald: 3, ruby: 2, saphire: 2}
      }

      {:ok, %State{} = state} =
        Actions.return_coins(state, "player2", %Attributes{ruby: 1, saphire: 1})

      assert state.coins == expected_game_coins

      assert state.players == [
               %Player{id: "player1", username: "player1", points: 14},
               expected_player_info
             ]

      assert state.current_player_index == 1
      assert state.phase == :game_over

      assert_received([
        {:player_info_updated, {1, ^expected_player_info}},
        {:coins_updated, ^expected_game_coins},
        {:current_player_updated, 1},
        {:phase_updated, :game_over}
      ])
    end

    @tag state: %State{
           game_id: "return_coins",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{diamond: 3, emerald: 3, ruby: 3, saphire: 3}
             },
             %Player{
               id: "player2",
               username: "player2"
             }
           ],
           coins: %Attributes{diamond: 1, emerald: 1, ruby: 1, saphire: 1, amethyst: 4, gold: 5}
         }
    test "fail to return coins if not return phase", %{state: state} do
      assert Actions.return_coins(state, "player1", %Attributes{diamond: 1, emerald: 1}) ==
               {:error, :not_return_phase}
    end

    @tag state: %State{
           game_id: "return_coins",
           phase: :return,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{diamond: 3, emerald: 3, ruby: 3, saphire: 3}
             },
             %Player{
               id: "player2",
               username: "player2"
             }
           ],
           coins: %Attributes{diamond: 1, emerald: 1, ruby: 1, saphire: 1, amethyst: 4, gold: 5}
         }
    test "fail to return coins if not current player", %{state: state} do
      assert Actions.return_coins(state, "player2", %Attributes{diamond: 1, emerald: 1}) ==
               {:error, :not_current_player}
    end

    @tag state: %State{
           game_id: "return_coins",
           phase: :return,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{diamond: 3, emerald: 3, ruby: 3, saphire: 3}
             },
             %Player{
               id: "player2",
               username: "player2"
             }
           ],
           coins: %Attributes{diamond: 1, emerald: 1, ruby: 1, saphire: 1, amethyst: 4, gold: 5}
         }
    test "fail to return coins if returning more than available", %{state: state} do
      assert Actions.return_coins(state, "player1", %Attributes{diamond: 1, amethyst: 1}) ==
               {:error, :insufficient_coins}
    end

    @tag state: %State{
           game_id: "return_coins",
           phase: :return,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{diamond: 3, emerald: 3, ruby: 3, saphire: 3}
             },
             %Player{
               id: "player2",
               username: "player2"
             }
           ],
           coins: %Attributes{diamond: 1, emerald: 1, ruby: 1, saphire: 1, amethyst: 4, gold: 5}
         }
    test "fail to return coins if not returning enough", %{state: state} do
      assert Actions.return_coins(state, "player1", %Attributes{diamond: 1}) ==
               {:error, :still_too_many_coins}
    end
  end

  describe "reserve_development/4" do
    @tag state: %State{
           game_id: "reserve_development",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1"},
             %Player{id: "player2", username: "player2"}
           ],
           coins: Coins.init(2),
           development_group_1:
             {[
                %Development{attribute: :ruby, cost: %Attributes{}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], [%Development{attribute: :diamond, cost: %Attributes{}}]}
         }
    test "successfully reserve development and go to next player", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 4,
        ruby: 4,
        emerald: 4,
        saphire: 4,
        amethyst: 4,
        gold: 4
      }

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        reservations: [%Development{attribute: :ruby, cost: %Attributes{}}],
        coins: %Attributes{gold: 1}
      }

      expected_development_group = {
        [
          %Development{attribute: :diamond, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :saphire, cost: %Attributes{}},
          %Development{attribute: :amethyst, cost: %Attributes{}}
        ],
        []
      }

      {:ok, %State{} = state} =
        Actions.reserve_development(state, "player1", 1, 0)

      assert state.coins == expected_game_coins
      assert state.development_group_1 == expected_development_group

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 1
      assert state.phase == :select

      assert_received([
        {:current_player_updated, 1},
        {:developments_updated, {:development_group_1, ^expected_development_group}},
        {:coins_updated, ^expected_game_coins},
        {:player_info_updated, {0, ^expected_player_info}},
        {:phase_updated, :select}
      ])
    end

    @tag state: %State{
           game_id: "reserve_development",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1"},
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{Coins.init(2) | gold: 0},
           development_group_2:
             {[
                %Development{attribute: :ruby, cost: %Attributes{}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], []}
         }
    test "successfully reserve development with no gold remaining and go to next player", %{
      state: state
    } do
      expected_game_coins = %Attributes{
        diamond: 4,
        ruby: 4,
        emerald: 4,
        saphire: 4,
        amethyst: 4,
        gold: 0
      }

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        reservations: [%Development{attribute: :emerald, cost: %Attributes{}}]
      }

      expected_development_group = {
        [
          %Development{attribute: :ruby, cost: %Attributes{}},
          nil,
          %Development{attribute: :saphire, cost: %Attributes{}},
          %Development{attribute: :amethyst, cost: %Attributes{}}
        ],
        []
      }

      {:ok, %State{} = state} =
        Actions.reserve_development(state, "player1", 2, 1)

      assert state.coins == expected_game_coins
      assert state.development_group_2 == expected_development_group

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 1
      assert state.phase == :select

      assert_received([
        {:current_player_updated, 1},
        {:developments_updated, {:development_group_2, ^expected_development_group}},
        {:coins_updated, ^expected_game_coins},
        {:player_info_updated, {0, ^expected_player_info}},
        {:phase_updated, :select}
      ])
    end

    @tag state: %State{
           game_id: "reserve_development",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{diamond: 2, emerald: 2, ruby: 2, saphire: 2, amethyst: 2}
             },
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{diamond: 2, emerald: 2, ruby: 2, saphire: 2, amethyst: 2, gold: 5},
           development_group_3:
             {[
                %Development{attribute: :ruby, cost: %Attributes{}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], [%Development{attribute: :diamond, cost: %Attributes{}}]}
         }
    test "successfully reserve development and go to return phase", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 2,
        ruby: 2,
        emerald: 2,
        saphire: 2,
        amethyst: 2,
        gold: 4
      }

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        reservations: [%Development{attribute: :saphire, cost: %Attributes{}}],
        coins: %Attributes{diamond: 2, emerald: 2, ruby: 2, saphire: 2, amethyst: 2, gold: 1}
      }

      expected_development_group = {
        [
          %Development{attribute: :ruby, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :diamond, cost: %Attributes{}},
          %Development{attribute: :amethyst, cost: %Attributes{}}
        ],
        []
      }

      {:ok, %State{} = state} =
        Actions.reserve_development(state, "player1", 3, 2)

      assert state.coins == expected_game_coins
      assert state.development_group_3 == expected_development_group

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 0
      assert state.phase == :return

      assert_received([
        {:current_player_updated, 0},
        {:developments_updated, {:development_group_3, ^expected_development_group}},
        {:coins_updated, ^expected_game_coins},
        {:player_info_updated, {0, ^expected_player_info}},
        {:phase_updated, :return}
      ])
    end

    @tag state: %State{
           game_id: "reserve_development",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               developments: [
                 %Development{attribute: :diamond, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}},
                 %Development{attribute: :emerald, cost: %Attributes{}},
                 %Development{attribute: :emerald, cost: %Attributes{}},
                 %Development{attribute: :emerald, cost: %Attributes{}},
                 %Development{attribute: :emerald, cost: %Attributes{}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ],
           coins: Coins.init(2),
           nobles: [%Noble{image: "", cost: %Attributes{diamond: 4, emerald: 4}}],
           development_group_1:
             {[
                %Development{attribute: :ruby, cost: %Attributes{}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], [%Development{attribute: :diamond, cost: %Attributes{}}]}
         }
    test "successfully reserve development and go to noble phase", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 4,
        ruby: 4,
        emerald: 4,
        saphire: 4,
        amethyst: 4,
        gold: 4
      }

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        reservations: [%Development{attribute: :amethyst, cost: %Attributes{}}],
        coins: %Attributes{gold: 1},
        developments: [
          %Development{attribute: :diamond, cost: %Attributes{}},
          %Development{attribute: :diamond, cost: %Attributes{}},
          %Development{attribute: :diamond, cost: %Attributes{}},
          %Development{attribute: :diamond, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}}
        ]
      }

      expected_development_group = {
        [
          %Development{attribute: :ruby, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :saphire, cost: %Attributes{}},
          %Development{attribute: :diamond, cost: %Attributes{}}
        ],
        []
      }

      {:ok, %State{} = state} =
        Actions.reserve_development(state, "player1", 1, 3)

      assert state.coins == expected_game_coins
      assert state.development_group_1 == expected_development_group

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 0
      assert state.phase == :noble

      assert_received([
        {:current_player_updated, 0},
        {:developments_updated, {:development_group_1, ^expected_development_group}},
        {:coins_updated, ^expected_game_coins},
        {:player_info_updated, {0, ^expected_player_info}},
        {:phase_updated, :noble}
      ])
    end

    @tag state: %State{
           game_id: "reserve_development",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1", points: 15},
             %Player{id: "player2", username: "player2", points: 13}
           ],
           coins: Coins.init(2),
           development_group_1:
             {[
                %Development{attribute: :ruby, cost: %Attributes{}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], [%Development{attribute: :diamond, cost: %Attributes{}}]},
           current_player_index: 1,
           is_final_round?: true
         }
    test "successfully reserve development and end the game", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 4,
        ruby: 4,
        emerald: 4,
        saphire: 4,
        amethyst: 4,
        gold: 4
      }

      expected_player_info = %Player{
        id: "player2",
        username: "player2",
        points: 13,
        reservations: [%Development{attribute: :diamond, cost: %Attributes{}}],
        coins: %Attributes{gold: 1}
      }

      expected_development_group = {
        [
          %Development{attribute: :ruby, cost: %Attributes{}},
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :saphire, cost: %Attributes{}},
          %Development{attribute: :amethyst, cost: %Attributes{}}
        ],
        []
      }

      {:ok, %State{} = state} =
        Actions.reserve_development(state, "player2", 1, -1)

      assert state.coins == expected_game_coins
      assert state.development_group_1 == expected_development_group

      assert state.players == [
               %Player{id: "player1", username: "player1", points: 15},
               expected_player_info
             ]

      assert state.current_player_index == 0
      assert state.phase == :game_over

      assert_received([
        {:current_player_updated, 0},
        {:developments_updated, {:development_group_1, ^expected_development_group}},
        {:coins_updated, ^expected_game_coins},
        {:player_info_updated, {1, ^expected_player_info}},
        {:phase_updated, :game_over}
      ])
    end

    @tag state: %State{
           game_id: "reserve_development",
           phase: :return,
           players: [
             %Player{id: "player1", username: "player1"},
             %Player{id: "player2", username: "player2"}
           ],
           development_group_1:
             {[
                %Development{attribute: :ruby, cost: %Attributes{}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], []}
         }
    test "fail to reserve development if not select phase", %{state: state} do
      assert Actions.reserve_development(state, "player1", 1, 0) == {:error, :not_select_phase}
    end

    @tag state: %State{
           game_id: "reserve_development",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1"},
             %Player{id: "player2", username: "player2"}
           ],
           development_group_1:
             {[
                %Development{attribute: :ruby, cost: %Attributes{}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], []}
         }
    test "fail to reserve development if not current player", %{state: state} do
      assert Actions.reserve_development(state, "player2", 1, 1) == {:error, :not_current_player}
    end

    @tag state: %State{
           game_id: "reserve_development",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               reservations: [
                 %Development{attribute: :diamond, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ],
           development_group_1:
             {[
                %Development{attribute: :ruby, cost: %Attributes{}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], []}
         }
    test "fail to reserve development if at reservation limit", %{state: state} do
      assert Actions.reserve_development(state, "player1", 1, 0) ==
               {:error, :reservation_limit_reached}
    end

    @tag state: %State{
           game_id: "reserve_development",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1"},
             %Player{id: "player2", username: "player2"}
           ],
           development_group_1:
             {[
                nil,
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], []}
         }
    test "fail to reserve development if invalid selection", %{state: state} do
      assert Actions.reserve_development(state, "player1", 1, 0) == {:error, :invalid_selection}
    end
  end

  describe "buy_development/5" do
    @tag state: %State{
           game_id: "buy_development",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1", coins: %Attributes{ruby: 4}},
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{diamond: 4, ruby: 0, emerald: 4, saphire: 4, amethyst: 4, gold: 5},
           development_group_1:
             {[
                %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], []}
         }
    test "successfully buy development and go to next player", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 4,
        ruby: 4,
        emerald: 4,
        saphire: 4,
        amethyst: 4,
        gold: 5
      }

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        points: 1,
        coins: %Attributes{},
        developments: [%Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}]
      }

      expected_development_group = {
        [
          nil,
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :saphire, cost: %Attributes{}},
          %Development{attribute: :amethyst, cost: %Attributes{}}
        ],
        []
      }

      {:ok, %State{} = state} =
        Actions.buy_development(state, "player1", 1, 0, %Attributes{ruby: 4})

      assert state.coins == expected_game_coins
      assert state.development_group_1 == expected_development_group

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 1
      assert state.phase == :select

      assert_received([
        {:is_final_round?, false},
        {:current_player_updated, 1},
        {:developments_updated, {:development_group_1, ^expected_development_group}},
        {:coins_updated, ^expected_game_coins},
        {:player_info_updated, {0, ^expected_player_info}},
        {:phase_updated, :select}
      ])
    end

    @tag state: %State{
           game_id: "buy_development",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1", coins: %Attributes{ruby: 4}},
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{diamond: 4, ruby: 0, emerald: 4, saphire: 4, amethyst: 4, gold: 5},
           development_group_2:
             {[
                %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], []},
           nobles: [%Noble{image: "", cost: %Attributes{diamond: 1}}]
         }
    test "successfully buy development and go to noble phase", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 4,
        ruby: 4,
        emerald: 4,
        saphire: 4,
        amethyst: 4,
        gold: 5
      }

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        points: 1,
        coins: %Attributes{},
        developments: [%Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}]
      }

      expected_development_group = {
        [
          nil,
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :saphire, cost: %Attributes{}},
          %Development{attribute: :amethyst, cost: %Attributes{}}
        ],
        []
      }

      {:ok, %State{} = state} =
        Actions.buy_development(state, "player1", 2, 0, %Attributes{ruby: 4})

      assert state.coins == expected_game_coins
      assert state.development_group_2 == expected_development_group

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 0
      assert state.phase == :noble

      assert_received([
        {:is_final_round?, false},
        {:current_player_updated, 0},
        {:developments_updated, {:development_group_2, ^expected_development_group}},
        {:coins_updated, ^expected_game_coins},
        {:player_info_updated, {0, ^expected_player_info}},
        {:phase_updated, :noble}
      ])
    end

    @tag state: %State{
           game_id: "buy_development",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{ruby: 4, gold: 1},
               points: 14
             },
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{diamond: 4, ruby: 0, emerald: 4, saphire: 4, amethyst: 4, gold: 4},
           development_group_3:
             {[
                %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], []}
         }
    test "successfully buy development and start final round", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 4,
        ruby: 3,
        emerald: 4,
        saphire: 4,
        amethyst: 4,
        gold: 5
      }

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        points: 15,
        coins: %Attributes{ruby: 1},
        developments: [%Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}]
      }

      expected_development_group = {
        [
          nil,
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :saphire, cost: %Attributes{}},
          %Development{attribute: :amethyst, cost: %Attributes{}}
        ],
        []
      }

      {:ok, %State{} = state} =
        Actions.buy_development(state, "player1", 3, 0, %Attributes{ruby: 3, gold: 1})

      assert state.coins == expected_game_coins
      assert state.development_group_3 == expected_development_group
      assert state.is_final_round? == true

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 1
      assert state.phase == :select

      assert_received([
        {:is_final_round?, true},
        {:current_player_updated, 1},
        {:developments_updated, {:development_group_3, ^expected_development_group}},
        {:coins_updated, ^expected_game_coins},
        {:player_info_updated, {0, ^expected_player_info}},
        {:phase_updated, :select}
      ])
    end

    @tag state: %State{
           game_id: "buy_development",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               points: 15
             },
             %Player{
               id: "player2",
               username: "player2",
               points: 14,
               coins: %Attributes{ruby: 4}
             }
           ],
           coins: %Attributes{diamond: 4, ruby: 0, emerald: 4, saphire: 4, amethyst: 4, gold: 5},
           development_group_1:
             {[
                %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], []},
           is_final_round?: true,
           current_player_index: 1
         }
    test "successfully buy development and end the game", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 4,
        ruby: 4,
        emerald: 4,
        saphire: 4,
        amethyst: 4,
        gold: 5
      }

      expected_player_info = %Player{
        id: "player2",
        username: "player2",
        points: 15,
        coins: %Attributes{},
        developments: [%Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}]
      }

      expected_development_group = {
        [
          nil,
          %Development{attribute: :emerald, cost: %Attributes{}},
          %Development{attribute: :saphire, cost: %Attributes{}},
          %Development{attribute: :amethyst, cost: %Attributes{}}
        ],
        []
      }

      {:ok, %State{} = state} =
        Actions.buy_development(state, "player2", 1, 0, %Attributes{ruby: 4})

      assert state.coins == expected_game_coins
      assert state.development_group_1 == expected_development_group

      assert state.players == [
               %Player{id: "player1", username: "player1", points: 15},
               expected_player_info
             ]

      assert state.current_player_index == 0
      assert state.phase == :game_over

      assert_received([
        {:is_final_round?, true},
        {:current_player_updated, 0},
        {:developments_updated, {:development_group_1, ^expected_development_group}},
        {:coins_updated, ^expected_game_coins},
        {:player_info_updated, {1, ^expected_player_info}},
        {:phase_updated, :game_over}
      ])
    end

    @tag state: %State{
           game_id: "buy_development",
           phase: :lobby,
           players: [
             %Player{id: "player1", username: "player1", coins: %Attributes{ruby: 4}},
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{diamond: 4, ruby: 0, emerald: 4, saphire: 4, amethyst: 4, gold: 5},
           development_group_1:
             {[
                %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], []}
         }
    test "fail to buy development if not select phase", %{state: state} do
      assert Actions.buy_development(state, "player1", 1, 0, %Attributes{ruby: 4}) ==
               {:error, :not_select_phase}
    end

    @tag state: %State{
           game_id: "buy_development",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1", coins: %Attributes{ruby: 4}},
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{diamond: 4, ruby: 0, emerald: 4, saphire: 4, amethyst: 4, gold: 5},
           development_group_1:
             {[
                %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], []}
         }
    test "fail to buy development if not current player", %{state: state} do
      assert Actions.buy_development(state, "player2", 1, 0, %Attributes{ruby: 4}) ==
               {:error, :not_current_player}
    end

    @tag state: %State{
           game_id: "buy_development",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1", coins: %Attributes{ruby: 4}},
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{diamond: 4, ruby: 0, emerald: 4, saphire: 4, amethyst: 4, gold: 5},
           development_group_1:
             {[
                %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}},
                nil,
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], []}
         }
    test "fail to buy development if invalid selection", %{state: state} do
      assert Actions.buy_development(state, "player1", 1, 1, %Attributes{ruby: 4}) ==
               {:error, :invalid_selection}
    end

    @tag state: %State{
           game_id: "buy_development",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1", coins: %Attributes{ruby: 3}},
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{diamond: 4, ruby: 1, emerald: 4, saphire: 4, amethyst: 4, gold: 5},
           development_group_1:
             {[
                %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], []}
         }
    test "fail to buy development if insufficient coins", %{state: state} do
      assert Actions.buy_development(state, "player1", 1, 0, %Attributes{ruby: 4}) ==
               {:error, :insufficient_coins}
    end

    @tag state: %State{
           game_id: "buy_development",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1", coins: %Attributes{ruby: 4, diamond: 1}},
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{diamond: 4, ruby: 1, emerald: 4, saphire: 4, amethyst: 4, gold: 5},
           development_group_1:
             {[
                %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], []}
         }
    test "fail to buy development if overpaying", %{state: state} do
      assert Actions.buy_development(state, "player1", 1, 0, %Attributes{ruby: 4, diamond: 1}) ==
               {:error, :overpaying}
    end

    @tag state: %State{
           game_id: "buy_development",
           phase: :select,
           players: [
             %Player{id: "player1", username: "player1", coins: %Attributes{ruby: 3, gold: 1}},
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{diamond: 4, ruby: 1, emerald: 4, saphire: 4, amethyst: 4, gold: 4},
           development_group_1:
             {[
                %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}},
                %Development{attribute: :emerald, cost: %Attributes{}},
                %Development{attribute: :saphire, cost: %Attributes{}},
                %Development{attribute: :amethyst, cost: %Attributes{}}
              ], []}
         }
    test "fail to buy development if incorrect gold amount", %{state: state} do
      assert Actions.buy_development(state, "player1", 1, 0, %Attributes{ruby: 3}) ==
               {:error, :incorrect_gold_amount}
    end
  end

  describe "buy_reserved_development/4" do
    @tag state: %State{
           game_id: "buy_reserved_development",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{ruby: 4},
               reservations: [
                 %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{diamond: 4, ruby: 0, emerald: 4, saphire: 4, amethyst: 4, gold: 5}
         }
    test "successfully buy reserved development and go to next player", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 4,
        ruby: 4,
        emerald: 4,
        saphire: 4,
        amethyst: 4,
        gold: 5
      }

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        points: 1,
        coins: %Attributes{},
        developments: [%Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}],
        reservations: []
      }

      {:ok, %State{} = state} =
        Actions.buy_reserved_development(state, "player1", 0, %Attributes{ruby: 4})

      assert state.coins == expected_game_coins

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 1
      assert state.phase == :select

      assert_received([
        {:is_final_round?, false},
        {:current_player_updated, 1},
        {:coins_updated, ^expected_game_coins},
        {:player_info_updated, {0, ^expected_player_info}},
        {:phase_updated, :select}
      ])
    end

    @tag state: %State{
           game_id: "buy_reserved_development",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{ruby: 4, gold: 1},
               reservations: [
                 %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{diamond: 4, ruby: 0, emerald: 4, saphire: 4, amethyst: 4, gold: 4},
           nobles: [%Noble{image: "", cost: %Attributes{diamond: 1}}]
         }
    test "successfully buy reserved development and go noble phase", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 4,
        ruby: 3,
        emerald: 4,
        saphire: 4,
        amethyst: 4,
        gold: 5
      }

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        points: 1,
        coins: %Attributes{ruby: 1},
        developments: [%Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}],
        reservations: []
      }

      {:ok, %State{} = state} =
        Actions.buy_reserved_development(state, "player1", 0, %Attributes{ruby: 3, gold: 1})

      assert state.coins == expected_game_coins

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 0
      assert state.phase == :noble

      assert_received([
        {:is_final_round?, false},
        {:current_player_updated, 0},
        {:coins_updated, ^expected_game_coins},
        {:player_info_updated, {0, ^expected_player_info}},
        {:phase_updated, :noble}
      ])
    end

    @tag state: %State{
           game_id: "buy_reserved_development",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{ruby: 4},
               reservations: [
                 %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}
               ],
               points: 14
             },
             %Player{id: "player2", username: "player2"}
           ],
           coins: %Attributes{diamond: 4, ruby: 0, emerald: 4, saphire: 4, amethyst: 4, gold: 5}
         }
    test "successfully buy reserved development and start final round", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 4,
        ruby: 4,
        emerald: 4,
        saphire: 4,
        amethyst: 4,
        gold: 5
      }

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        points: 15,
        developments: [%Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}]
      }

      {:ok, %State{} = state} =
        Actions.buy_reserved_development(state, "player1", 0, %Attributes{ruby: 4})

      assert state.coins == expected_game_coins

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 1
      assert state.phase == :select
      assert state.is_final_round? == true

      assert_received([
        {:is_final_round?, true},
        {:current_player_updated, 1},
        {:coins_updated, ^expected_game_coins},
        {:player_info_updated, {0, ^expected_player_info}},
        {:phase_updated, :select}
      ])
    end

    @tag state: %State{
           game_id: "buy_reserved_development",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               points: 16
             },
             %Player{
               id: "player2",
               username: "player2",
               coins: %Attributes{ruby: 4},
               points: 14,
               reservations: [
                 %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}
               ]
             }
           ],
           coins: %Attributes{diamond: 4, ruby: 0, emerald: 4, saphire: 4, amethyst: 4, gold: 5},
           is_final_round?: true,
           current_player_index: 1
         }
    test "successfully buy reserved development and end the game", %{state: state} do
      expected_game_coins = %Attributes{
        diamond: 4,
        ruby: 4,
        emerald: 4,
        saphire: 4,
        amethyst: 4,
        gold: 5
      }

      expected_player_info = %Player{
        id: "player2",
        username: "player2",
        points: 15,
        developments: [%Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}]
      }

      {:ok, %State{} = state} =
        Actions.buy_reserved_development(state, "player2", 0, %Attributes{ruby: 4})

      assert state.coins == expected_game_coins

      assert state.players == [
               %Player{id: "player1", username: "player1", points: 16},
               expected_player_info
             ]

      assert state.current_player_index == 0
      assert state.phase == :game_over

      assert_received([
        {:is_final_round?, true},
        {:current_player_updated, 0},
        {:coins_updated, ^expected_game_coins},
        {:player_info_updated, {1, ^expected_player_info}},
        {:phase_updated, :game_over}
      ])
    end

    @tag state: %State{
           game_id: "buy_reserved_development",
           phase: :lobby,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{ruby: 4},
               reservations: [
                 %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ]
         }
    test "fail to buy reserved development if not select phase", %{state: state} do
      assert Actions.buy_reserved_development(state, "player1", 0, %Attributes{ruby: 4}) ==
               {:error, :not_select_phase}
    end

    @tag state: %State{
           game_id: "buy_reserved_development",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{ruby: 4},
               reservations: [
                 %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ],
           current_player_index: 1
         }
    test "fail to buy reserved development if not current player", %{state: state} do
      assert Actions.buy_reserved_development(state, "player1", 0, %Attributes{ruby: 4}) ==
               {:error, :not_current_player}
    end

    @tag state: %State{
           game_id: "buy_reserved_development",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{ruby: 4},
               reservations: []
             },
             %Player{id: "player2", username: "player2"}
           ]
         }
    test "fail to buy reserved development if invalid selection", %{state: state} do
      assert Actions.buy_reserved_development(state, "player1", 0, %Attributes{ruby: 4}) ==
               {:error, :invalid_selection}
    end

    @tag state: %State{
           game_id: "buy_reserved_development",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{ruby: 3},
               reservations: [
                 %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ]
         }
    test "fail to buy reserved development if insufficient coins", %{state: state} do
      assert Actions.buy_reserved_development(state, "player1", 0, %Attributes{ruby: 4}) ==
               {:error, :insufficient_coins}
    end

    @tag state: %State{
           game_id: "buy_reserved_development",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{ruby: 4},
               reservations: [
                 %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 3}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ]
         }
    test "fail to buy reserved development if overpaying", %{state: state} do
      assert Actions.buy_reserved_development(state, "player1", 0, %Attributes{ruby: 4}) ==
               {:error, :overpaying}
    end

    @tag state: %State{
           game_id: "buy_reserved_development",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               coins: %Attributes{ruby: 3, gold: 0},
               reservations: [
                 %Development{attribute: :diamond, points: 1, cost: %Attributes{ruby: 4}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ]
         }
    test "fail to buy reserved development if incorrect gold amount", %{state: state} do
      assert Actions.buy_reserved_development(state, "player1", 0, %Attributes{ruby: 3}) ==
               {:error, :incorrect_gold_amount}
    end
  end

  describe "select_noble/3" do
    @tag state: %State{
           game_id: "select_noble",
           phase: :noble,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               developments: [
                 %Development{attribute: :ruby, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ],
           nobles: [
             %Noble{image: "", cost: %Attributes{diamond: 1}},
             %Noble{image: "", cost: %Attributes{ruby: 2}}
           ]
         }
    test "successfully select noble and go to next player", %{state: state} do
      expected_game_nobles = [
        %Noble{image: "", cost: %Attributes{ruby: 2}}
      ]

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        points: 3,
        developments: [
          %Development{attribute: :ruby, cost: %Attributes{}},
          %Development{attribute: :diamond, cost: %Attributes{}}
        ],
        nobles: [%Noble{image: "", cost: %Attributes{diamond: 1}}]
      }

      {:ok, %State{} = state} =
        Actions.select_noble(state, "player1", 0)

      assert state.nobles == expected_game_nobles

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 1
      assert state.phase == :select

      assert_received([
        {:is_final_round?, false},
        {:nobles_updated, ^expected_game_nobles},
        {:current_player_updated, 1},
        {:player_info_updated, {0, ^expected_player_info}},
        {:phase_updated, :select}
      ])
    end

    @tag state: %State{
           game_id: "select_noble",
           phase: :noble,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               points: 12,
               developments: [
                 %Development{attribute: :ruby, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ],
           nobles: [
             %Noble{image: "", cost: %Attributes{diamond: 1}},
             %Noble{image: "", cost: %Attributes{ruby: 2}}
           ]
         }
    test "successfully select noble and start to final round", %{state: state} do
      expected_game_nobles = [
        %Noble{image: "", cost: %Attributes{ruby: 2}}
      ]

      expected_player_info = %Player{
        id: "player1",
        username: "player1",
        points: 15,
        developments: [
          %Development{attribute: :ruby, cost: %Attributes{}},
          %Development{attribute: :diamond, cost: %Attributes{}}
        ],
        nobles: [%Noble{image: "", cost: %Attributes{diamond: 1}}]
      }

      {:ok, %State{} = state} =
        Actions.select_noble(state, "player1", 0)

      assert state.nobles == expected_game_nobles
      assert state.is_final_round? == true

      assert state.players == [
               expected_player_info,
               %Player{id: "player2", username: "player2"}
             ]

      assert state.current_player_index == 1
      assert state.phase == :select

      assert_received([
        {:is_final_round?, true},
        {:nobles_updated, ^expected_game_nobles},
        {:current_player_updated, 1},
        {:player_info_updated, {0, ^expected_player_info}},
        {:phase_updated, :select}
      ])
    end

    @tag state: %State{
           game_id: "select_noble",
           phase: :noble,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               points: 15,
               developments: [
                 %Development{attribute: :ruby, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}}
               ]
             },
             %Player{
               id: "player2",
               username: "player2",
               points: 12,
               developments: [%Development{attribute: :diamond, cost: %Attributes{}}]
             }
           ],
           nobles: [
             %Noble{image: "", cost: %Attributes{diamond: 1}},
             %Noble{image: "", cost: %Attributes{ruby: 2}}
           ],
           is_final_round?: true,
           current_player_index: 1
         }
    test "successfully select noble and end the game", %{state: state} do
      expected_game_nobles = [
        %Noble{image: "", cost: %Attributes{ruby: 2}}
      ]

      expected_player_info = %Player{
        id: "player2",
        username: "player2",
        points: 15,
        developments: [
          %Development{attribute: :diamond, cost: %Attributes{}}
        ],
        nobles: [%Noble{image: "", cost: %Attributes{diamond: 1}}]
      }

      {:ok, %State{} = state} =
        Actions.select_noble(state, "player2", 0)

      assert state.nobles == expected_game_nobles

      assert state.players == [
               %Player{
                 id: "player1",
                 username: "player1",
                 points: 15,
                 developments: [
                   %Development{attribute: :ruby, cost: %Attributes{}},
                   %Development{attribute: :diamond, cost: %Attributes{}}
                 ]
               },
               expected_player_info
             ]

      assert state.current_player_index == 1
      assert state.phase == :game_over

      assert_received([
        {:is_final_round?, true},
        {:nobles_updated, ^expected_game_nobles},
        {:current_player_updated, 1},
        {:player_info_updated, {1, ^expected_player_info}},
        {:phase_updated, :game_over}
      ])
    end

    @tag state: %State{
           game_id: "select_noble",
           phase: :select,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               developments: [
                 %Development{attribute: :ruby, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ],
           nobles: [
             %Noble{image: "", cost: %Attributes{diamond: 1}},
             %Noble{image: "", cost: %Attributes{ruby: 2}}
           ]
         }
    test "fail to select noble if not noble phase", %{state: state} do
      assert Actions.select_noble(state, "player1", 0) == {:error, :not_noble_phase}
    end

    @tag state: %State{
           game_id: "select_noble",
           phase: :noble,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               developments: [
                 %Development{attribute: :ruby, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ],
           nobles: [
             %Noble{image: "", cost: %Attributes{diamond: 1}},
             %Noble{image: "", cost: %Attributes{ruby: 2}}
           ]
         }
    test "fail to select noble if not current player", %{state: state} do
      assert Actions.select_noble(state, "player2", 0) == {:error, :not_current_player}
    end

    @tag state: %State{
           game_id: "select_noble",
           phase: :noble,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               developments: [
                 %Development{attribute: :ruby, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ],
           nobles: [
             %Noble{image: "", cost: %Attributes{diamond: 1}},
             %Noble{image: "", cost: %Attributes{ruby: 2}}
           ]
         }
    test "fail to select noble if invalid selection", %{state: state} do
      assert Actions.select_noble(state, "player1", 2) == {:error, :invalid_selection}
    end

    @tag state: %State{
           game_id: "select_noble",
           phase: :noble,
           players: [
             %Player{
               id: "player1",
               username: "player1",
               developments: [
                 %Development{attribute: :ruby, cost: %Attributes{}},
                 %Development{attribute: :diamond, cost: %Attributes{}}
               ]
             },
             %Player{id: "player2", username: "player2"}
           ],
           nobles: [
             %Noble{image: "", cost: %Attributes{diamond: 1}},
             %Noble{image: "", cost: %Attributes{ruby: 2}}
           ]
         }
    test "fail to select noble if requirements not met", %{state: state} do
      assert Actions.select_noble(state, "player1", 1) == {:error, :invalid_selection}
    end
  end
end
