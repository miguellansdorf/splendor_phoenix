defmodule Splendor.Game.Nobles do
  alias Splendor.Game.Structs.{Attributes, Noble}

  @nobles [
    %Noble{
      image: "/images/nobles/noble_01.png",
      cost: %Attributes{amethyst: 3, ruby: 3, emerald: 3}
    },
    %Noble{image: "/images/nobles/noble_02.png", cost: %Attributes{ruby: 4, emerald: 4}},
    %Noble{image: "/images/nobles/noble_03.png", cost: %Attributes{diamond: 4, saphire: 4}},
    %Noble{
      image: "/images/nobles/noble_04.png",
      cost: %Attributes{diamond: 3, amethyst: 3, emerald: 3}
    },
    %Noble{
      image: "/images/nobles/noble_05.png",
      cost: %Attributes{diamond: 3, saphire: 3, ruby: 3}
    },
    %Noble{image: "/images/nobles/noble_06.png", cost: %Attributes{saphire: 4, emerald: 4}},
    %Noble{
      image: "/images/nobles/noble_07.png",
      cost: %Attributes{diamond: 3, amethyst: 3, ruby: 3}
    },
    %Noble{
      image: "/images/nobles/noble_08.png",
      cost: %Attributes{diamond: 3, saphire: 3, amethyst: 3}
    },
    %Noble{
      image: "/images/nobles/noble_09.png",
      cost: %Attributes{saphire: 3, amethyst: 3, ruby: 3}
    },
    %Noble{image: "/images/nobles/noble_10.png", cost: %Attributes{amethyst: 4, ruby: 4}},
    %Noble{
      image: "/images/nobles/noble_11.png",
      cost: %Attributes{saphire: 3, ruby: 3, emerald: 3}
    },
    %Noble{image: "/images/nobles/noble_12.png", cost: %Attributes{diamond: 4, amethyst: 4}},
    %Noble{image: "/images/nobles/noble_13.png", cost: %Attributes{amethyst: 4, emerald: 4}},
    %Noble{image: "/images/nobles/noble_14.png", cost: %Attributes{diamond: 4, ruby: 4}},
    %Noble{
      image: "/images/nobles/noble_15.png",
      cost: %Attributes{diamond: 3, saphire: 3, emerald: 3}
    }
  ]

  def init(player_count) when player_count in [2, 3, 4] do
    @nobles |> Enum.shuffle() |> Enum.take(player_count + 1)
  end

  @spec can_select_nobles?(list(Noble.t()), Attributes.t()) :: boolean()
  def can_select_nobles?([], _player_developments), do: false

  def can_select_nobles?(nobles, %Attributes{} = player_developments) do
    Enum.any?(nobles, fn %Noble{cost: cost} ->
      Enum.all?(Map.from_struct(cost), fn {attribute, amount} ->
        Map.get(player_developments, attribute, 0) >= amount
      end)
    end)
  end
end
