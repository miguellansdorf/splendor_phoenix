defmodule Splendor.Game.Structs do
  use TypedStruct

  typedstruct module: Attributes do
    field :gold, non_neg_integer(), default: 0
    field :diamond, non_neg_integer(), default: 0
    field :ruby, non_neg_integer(), default: 0
    field :emerald, non_neg_integer(), default: 0
    field :saphire, non_neg_integer(), default: 0
    field :amethyst, non_neg_integer(), default: 0
  end

  typedstruct module: Development do
    field :attribute, :diamond | :ruby | :emerald | :saphire | :amethyst, enforce: true
    field :cost, Splendor.Game.Structs.Attributes.t(), enforce: true
    field :points, non_neg_integer(), default: 0
  end

  typedstruct module: Noble do
    field :image, String.t(), enforce: true
    field :cost, Splendor.Game.Structs.Attributes.t(), enforce: true
    field :points, non_neg_integer(), default: 3
  end

  typedstruct module: Player do
    field :id, String.t(), enforce: true
    field :username, String.t(), enforce: true
    field :is_ready?, boolean(), default: false

    field :coins, Splendor.Game.Structs.Attributes.t(),
      default: %Splendor.Game.Structs.Attributes{}

    field :developments, list(Splendor.Game.Structs.Development.t()), default: []
    field :nobles, list(Splendor.Game.Structs.Noble.t()), default: []
    field :reservations, list(Splendor.Game.Structs.Development.t()), default: []
    field :points, non_neg_integer(), default: 0
  end

  typedstruct module: State do
    field :game_id, String.t(), enforce: true
    field :phase, :lobby | :select | :return | :noble | :game_over, default: :lobby
    field :players, list(Splendor.Game.Structs.Player.t()), default: []
    field :nobles, list(Splendor.Game.Structs.Noble.t()), default: []

    field :development_group_1,
          {
            [Splendor.Game.Structs.Development.t() | nil],
            [Splendor.Game.Structs.Development.t()]
          },
          default: {[], []}

    field :development_group_2,
          {
            [Splendor.Game.Structs.Development.t() | nil],
            [Splendor.Game.Structs.Development.t()]
          },
          default: {[], []}

    field :development_group_3,
          {
            [Splendor.Game.Structs.Development.t() | nil],
            [Splendor.Game.Structs.Development.t()]
          },
          default: {[], []}

    field :coins, Splendor.Game.Structs.Attributes.t(),
      default: %Splendor.Game.Structs.Attributes{}

    field :current_player_index, non_neg_integer(), default: 0
    field :is_final_round?, boolean(), default: false
  end
end
