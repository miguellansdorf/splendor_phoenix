defmodule Splendor.Game.Developments do
  alias Splendor.Game.Structs.{Attributes, Development}

  @developments_1 [
    %Development{
      attribute: :diamond,
      cost: %Attributes{ruby: 2, amethyst: 1}
    },
    %Development{
      attribute: :diamond,
      cost: %Attributes{emerald: 2, saphire: 1, ruby: 1, amethyst: 1}
    },
    %Development{
      attribute: :diamond,
      points: 1,
      cost: %Attributes{emerald: 4}
    },
    %Development{
      attribute: :diamond,
      cost: %Attributes{diamond: 3, saphire: 1, amethyst: 1}
    },
    %Development{
      attribute: :diamond,
      cost: %Attributes{saphire: 3}
    },
    %Development{
      attribute: :diamond,
      cost: %Attributes{emerald: 2, saphire: 2, amethyst: 1}
    },
    %Development{
      attribute: :diamond,
      cost: %Attributes{emerald: 1, saphire: 1, ruby: 1, amethyst: 1}
    },
    %Development{
      attribute: :diamond,
      cost: %Attributes{saphire: 2, amethyst: 2}
    },
    %Development{
      attribute: :ruby,
      cost: %Attributes{diamond: 1, ruby: 1, amethyst: 3}
    },
    %Development{
      attribute: :ruby,
      cost: %Attributes{emerald: 1, saphire: 2}
    },
    %Development{
      attribute: :ruby,
      cost: %Attributes{diamond: 2, emerald: 1, amethyst: 2}
    },
    %Development{
      attribute: :ruby,
      points: 1,
      cost: %Attributes{diamond: 4}
    },
    %Development{
      attribute: :ruby,
      cost: %Attributes{diamond: 2, ruby: 2}
    },
    %Development{
      attribute: :ruby,
      cost: %Attributes{diamond: 2, emerald: 1, saphire: 1, amethyst: 1}
    },
    %Development{
      attribute: :ruby,
      cost: %Attributes{diamond: 1, emerald: 1, saphire: 1, amethyst: 1}
    },
    %Development{
      attribute: :ruby,
      cost: %Attributes{diamond: 3}
    },
    %Development{
      attribute: :saphire,
      cost: %Attributes{amethyst: 3}
    },
    %Development{
      attribute: :saphire,
      cost: %Attributes{diamond: 1, emerald: 2, ruby: 2}
    },
    %Development{
      attribute: :saphire,
      cost: %Attributes{diamond: 1, emerald: 1, ruby: 1, amethyst: 1}
    },
    %Development{
      attribute: :saphire,
      cost: %Attributes{emerald: 2, amethyst: 2}
    },
    %Development{
      attribute: :saphire,
      cost: %Attributes{diamond: 1, emerald: 1, ruby: 2, amethyst: 1}
    },
    %Development{
      attribute: :saphire,
      points: 1,
      cost: %Attributes{ruby: 4}
    },
    %Development{
      attribute: :saphire,
      cost: %Attributes{diamond: 1, emerald: 3, saphire: 1, ruby: 1}
    },
    %Development{
      attribute: :saphire,
      cost: %Attributes{diamond: 1, amethyst: 2}
    },
    %Development{
      attribute: :emerald,
      cost: %Attributes{diamond: 1, saphire: 1, ruby: 1, amethyst: 1}
    },
    %Development{
      attribute: :emerald,
      cost: %Attributes{saphire: 1, ruby: 2, amethyst: 2}
    },
    %Development{
      attribute: :emerald,
      cost: %Attributes{diamond: 1, saphire: 1, ruby: 1, amethyst: 2}
    },
    %Development{
      attribute: :emerald,
      cost: %Attributes{saphire: 2, ruby: 2}
    },
    %Development{
      attribute: :emerald,
      cost: %Attributes{ruby: 3}
    },
    %Development{
      attribute: :emerald,
      cost: %Attributes{diamond: 1, emerald: 1, saphire: 3}
    },
    %Development{
      attribute: :emerald,
      cost: %Attributes{diamond: 2, saphire: 1}
    },
    %Development{
      attribute: :emerald,
      points: 1,
      cost: %Attributes{amethyst: 4}
    },
    %Development{
      attribute: :amethyst,
      cost: %Attributes{emerald: 3}
    },
    %Development{
      attribute: :amethyst,
      points: 1,
      cost: %Attributes{saphire: 4}
    },
    %Development{
      attribute: :amethyst,
      cost: %Attributes{diamond: 1, emerald: 1, saphire: 1, ruby: 1}
    },
    %Development{
      attribute: :amethyst,
      cost: %Attributes{diamond: 2, saphire: 2, ruby: 1}
    },
    %Development{
      attribute: :amethyst,
      cost: %Attributes{emerald: 1, ruby: 3, amethyst: 1}
    },
    %Development{
      attribute: :amethyst,
      cost: %Attributes{diamond: 2, emerald: 2}
    },
    %Development{
      attribute: :amethyst,
      cost: %Attributes{emerald: 2, ruby: 1}
    },
    %Development{
      attribute: :amethyst,
      cost: %Attributes{diamond: 1, emerald: 1, saphire: 2, ruby: 1}
    }
  ]

  @developments_2 [
    %Development{
      attribute: :diamond,
      points: 3,
      cost: %Attributes{diamond: 6}
    },
    %Development{
      attribute: :diamond,
      points: 2,
      cost: %Attributes{ruby: 4, emerald: 1, amethyst: 2}
    },
    %Development{
      attribute: :diamond,
      points: 1,
      cost: %Attributes{ruby: 2, emerald: 3, amethyst: 2}
    },
    %Development{
      attribute: :diamond,
      points: 1,
      cost: %Attributes{diamond: 2, ruby: 3, saphire: 3}
    },
    %Development{
      attribute: :diamond,
      points: 2,
      cost: %Attributes{ruby: 5, amethyst: 3}
    },
    %Development{
      attribute: :diamond,
      points: 2,
      cost: %Attributes{ruby: 5}
    },
    %Development{
      attribute: :ruby,
      points: 1,
      cost: %Attributes{ruby: 2, saphire: 3, amethyst: 3}
    },
    %Development{
      attribute: :ruby,
      points: 2,
      cost: %Attributes{diamond: 3, amethyst: 5}
    },
    %Development{
      attribute: :ruby,
      points: 1,
      cost: %Attributes{diamond: 2, ruby: 2, amethyst: 3}
    },
    %Development{
      attribute: :ruby,
      points: 2,
      cost: %Attributes{diamond: 1, saphire: 4, emerald: 2}
    },
    %Development{
      attribute: :ruby,
      points: 2,
      cost: %Attributes{amethyst: 5}
    },
    %Development{
      attribute: :ruby,
      points: 3,
      cost: %Attributes{ruby: 6}
    },
    %Development{
      attribute: :saphire,
      points: 1,
      cost: %Attributes{saphire: 2, emerald: 3, amethyst: 3}
    },
    %Development{
      attribute: :saphire,
      points: 2,
      cost: %Attributes{diamond: 2, ruby: 1, amethyst: 4}
    },
    %Development{
      attribute: :saphire,
      points: 2,
      cost: %Attributes{saphire: 5}
    },
    %Development{
      attribute: :saphire,
      points: 2,
      cost: %Attributes{diamond: 5, saphire: 3}
    },
    %Development{
      attribute: :saphire,
      points: 1,
      cost: %Attributes{ruby: 3, saphire: 2, emerald: 2}
    },
    %Development{
      attribute: :saphire,
      points: 3,
      cost: %Attributes{saphire: 6}
    },
    %Development{
      attribute: :emerald,
      points: 3,
      cost: %Attributes{emerald: 6}
    },
    %Development{
      attribute: :emerald,
      points: 2,
      cost: %Attributes{emerald: 5}
    },
    %Development{
      attribute: :emerald,
      points: 1,
      cost: %Attributes{diamond: 2, saphire: 3, amethyst: 2}
    },
    %Development{
      attribute: :emerald,
      points: 1,
      cost: %Attributes{diamond: 3, ruby: 3, emerald: 2}
    },
    %Development{
      attribute: :emerald,
      points: 2,
      cost: %Attributes{saphire: 5, emerald: 3}
    },
    %Development{
      attribute: :emerald,
      points: 2,
      cost: %Attributes{diamond: 4, saphire: 2, amethyst: 1}
    },
    %Development{
      attribute: :amethyst,
      points: 2,
      cost: %Attributes{ruby: 2, saphire: 1, emerald: 4}
    },
    %Development{
      attribute: :amethyst,
      points: 1,
      cost: %Attributes{diamond: 3, saphire: 2, emerald: 2}
    },
    %Development{
      attribute: :amethyst,
      points: 2,
      cost: %Attributes{ruby: 3, emerald: 5}
    },
    %Development{
      attribute: :amethyst,
      points: 3,
      cost: %Attributes{amethyst: 6}
    },
    %Development{
      attribute: :amethyst,
      points: 1,
      cost: %Attributes{diamond: 3, emerald: 3, amethyst: 2}
    },
    %Development{
      attribute: :amethyst,
      points: 2,
      cost: %Attributes{diamond: 5}
    }
  ]

  @developments_3 [
    %Development{
      attribute: :diamond,
      points: 3,
      cost: %Attributes{emerald: 3, saphire: 3, ruby: 5, amethyst: 3}
    },
    %Development{
      attribute: :diamond,
      points: 4,
      cost: %Attributes{diamond: 3, ruby: 3, amethyst: 6}
    },
    %Development{
      attribute: :diamond,
      points: 4,
      cost: %Attributes{amethyst: 7}
    },
    %Development{
      attribute: :diamond,
      points: 5,
      cost: %Attributes{diamond: 3, amethyst: 7}
    },
    %Development{
      attribute: :ruby,
      points: 4,
      cost: %Attributes{emerald: 7}
    },
    %Development{
      attribute: :ruby,
      points: 3,
      cost: %Attributes{diamond: 3, emerald: 3, saphire: 5, amethyst: 3}
    },
    %Development{
      attribute: :ruby,
      points: 5,
      cost: %Attributes{emerald: 7, ruby: 3}
    },
    %Development{
      attribute: :ruby,
      points: 4,
      cost: %Attributes{emerald: 6, saphire: 3, ruby: 3}
    },
    %Development{
      attribute: :saphire,
      points: 3,
      cost: %Attributes{diamond: 3, emerald: 3, ruby: 3, amethyst: 5}
    },
    %Development{
      attribute: :saphire,
      points: 4,
      cost: %Attributes{diamond: 7}
    },
    %Development{
      attribute: :saphire,
      points: 4,
      cost: %Attributes{diamond: 6, saphire: 3, amethyst: 3}
    },
    %Development{
      attribute: :saphire,
      points: 5,
      cost: %Attributes{diamond: 7, saphire: 3}
    },
    %Development{
      attribute: :emerald,
      points: 4,
      cost: %Attributes{diamond: 3, emerald: 3, saphire: 6}
    },
    %Development{
      attribute: :emerald,
      points: 3,
      cost: %Attributes{diamond: 5, saphire: 3, ruby: 3, amethyst: 3}
    },
    %Development{
      attribute: :emerald,
      points: 5,
      cost: %Attributes{emerald: 3, saphire: 7}
    },
    %Development{
      attribute: :emerald,
      points: 4,
      cost: %Attributes{emerald: 7}
    },
    %Development{
      attribute: :amethyst,
      points: 5,
      cost: %Attributes{ruby: 7, amethyst: 3}
    },
    %Development{
      attribute: :amethyst,
      points: 4,
      cost: %Attributes{emerald: 3, ruby: 6, amethyst: 3}
    },
    %Development{
      attribute: :amethyst,
      points: 3,
      cost: %Attributes{diamond: 3, emerald: 3, amethyst: 5}
    },
    %Development{
      attribute: :amethyst,
      points: 5,
      cost: %Attributes{diamond: 7, amethyst: 3}
    }
  ]

  def init(level) when level in [1, 2, 3] do
    developments =
      case level do
        1 -> @developments_1
        2 -> @developments_2
        _ -> @developments_3
      end

    developments
    |> Enum.shuffle()
    |> Enum.split(4)
  end

  def update_group({cards, deck}, index)
      when is_list(cards) and is_list(deck) and index in [-1, 0, 1, 2, 3] do
    {new_development, new_deck} = List.pop_at(deck, 0)

    case index do
      -1 ->
        {cards, new_deck}

      _ ->
        {List.replace_at(cards, index, new_development), new_deck}
    end
  end
end
