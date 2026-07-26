defmodule SplendorWeb.GameComponents do
  use Phoenix.Component

  alias Splendor.Game.Structs.{Development, Noble, Player}

  attr :player, Player, required: true

  def player(assigns) do
    ~H"""
    <div class="w-62 p-2 flex flex-col gap-2 rounded-lg border-2 items-center select-none">
      <span class="text-3xl">{@player.username}</span>
      <span class="text-2xl border-2 rounded-full size-10 flex items-center justify-center">
        {@player.points}
      </span>
      <div class="flex gap-2 items-center">
        <div
          :for={attribute <- [:gold, :diamond, :ruby, :emerald, :saphire, :amethyst]}
          class={[
            "rounded-full px-2 size-8 flex items-center justify-center text-lg font-bold text-black",
            attribute_bg(attribute)
          ]}
        >
          {Map.get(@player.coins, attribute, 0)}
        </div>
      </div>
      <div class="flex gap-2 items-center">
        <div
          :for={attribute <- [:diamond, :ruby, :emerald, :saphire, :amethyst]}
          class={[
            "rounded-lg px-2 w-8 h-10 flex items-center justify-center text-lg font-bold text-black",
            attribute_bg(attribute)
          ]}
        >
          {Map.get(@player.coins, attribute, 0)}
        </div>
      </div>
      <div class="flex gap-2 items-center">
        <div :for={reservation <- @player.reservations} class="rounded-lg w-8 h-10 bg-amber-500">
        </div>
        <div
          :for={_ <- Range.new(1, 3 - length(@player.reservations), 1)}
          class="rounded-lg w-8 h-10 border-2 border-dotted border-amber-500"
        >
        </div>
      </div>
    </div>
    """
  end

  attr :noble, Noble, required: true

  def noble(assigns) do
    ~H"""
    <div class="size-44 border-4 border-amber-800 rounded-lg overflow-hidden flex flex-col-reverse items-center relative select-none">
      <img
        src={@noble.image}
        class="absolute bg-cover -z-1"
        alt={String.split(@noble.image, "/") |> List.last()}
      />
      <div class="flex gap-2">
        <div
          :for={attribute <- [:diamond, :ruby, :emerald, :saphire, :amethyst]}
          :if={Map.get(@noble.cost, attribute, 0) > 0}
          class="flex flex-col gap-1 items-center"
        >
          <div class={[
            "w-6 h-8 rounded-lg flex items-center justify-center text-black font-bold text-lg",
            attribute_bg(attribute)
          ]}>
          </div>
          <span class="text-xl text-white font-bold">{Map.get(@noble.cost, attribute)}</span>
        </div>
      </div>
    </div>
    """
  end

  attr :count, :integer, required: true
  attr :level, :integer, required: true, values: [1, 2, 3]

  def deck(assigns) do
    ~H"""
    <div class="relative w-44 h-50 rounded-lg flex flex-col justify-center items-center select-none border-4 border-amber-800">
      <div class="absolute w-full h-full flex flex-col justify-center items-center">
        <SplendorWeb.CoreComponents.icon name="hero-rectangle-group" class="size-10 text-amber-800" />
        <div class="flex gap-1 items-center">
          <span :for={_ <- Range.new(1, @level, 1)} class="bg-amber-800 size-4 rounded-full"></span>
        </div>
      </div>
      <div
        :for={i <- Range.new(1, @count, 1)}
        style={"transform: translateX(#{(i - 1) * -0.125}rem)"}
        class={[
          "absolute w-44 h-50 rounded-lg flex flex-col justify-center items-center border-4 border-amber-800",
          @level == 1 && "bg-gray-700",
          @level == 2 && "bg-gray-800",
          @level == 3 && "bg-gray-900"
        ]}
      >
        <SplendorWeb.CoreComponents.icon name="hero-rectangle-group" class="size-10 text-primary" />
        <div class="flex gap-1 items-center">
          <span :for={_ <- Range.new(1, @level, 1)} class="bg-primary size-4 rounded-full"></span>
        </div>
      </div>
    </div>
    """
  end

  attr :development, Development, default: nil
  attr :index, :integer, required: true, values: [0, 1, 2, 3]

  def development(%{development: nil} = assigns) do
    ~H"""
    <div class="w-44 h-50 rounded-lg flex flex-col justify-center items-center select-none border-4 border-amber-800">
      <SplendorWeb.CoreComponents.icon name="hero-rectangle-group" class="size-10 text-amber-800" />
    </div>
    """
  end

  def development(assigns) do
    ~H"""
    <div class={[
      "w-44 h-50 rounded-lg overflow-hidden flex flex-col justify-between select-none relative border-4 border-amber-800"
    ]}>
      <img
        src={"/images/developments/#{@development.attribute}.png"}
        alt={@development.attribute}
        class="-z-10 bg-cover absolute"
      />
      <div class="flex justify-between items-center p-2">
        <div class={["size-9 rounded-full", attribute_bg(@development.attribute)]}></div>
        <span class={["text-3xl font-bold text-white", @development.points == 0 && "hidden"]}>
          {@development.points}
        </span>
      </div>
      <div class="flex flex-col p-2">
        <div
          :for={attribute <- [:diamond, :ruby, :emerald, :saphire, :amethyst]}
          :if={Map.get(@development.cost, attribute, 0) > 0}
          class="flex gap-2 items-center"
        >
          <div class={["size-5 rounded-full", attribute_bg(attribute)]}></div>
          <span class="text-lg font-bold text-white">{Map.get(@development.cost, attribute)}</span>
        </div>
      </div>
    </div>
    """
  end

  attr :attribute, :atom,
    required: true,
    values: [:gold, :diamond, :ruby, :emerald, :saphire, :amethyst]

  attr :count, :integer, default: 0

  def coins(assigns) do
    ~H"""
    <div class={[
      "size-28 rounded-full border-5 border-dashed relative flex justify-center items-center",
      attribute_border(@attribute)
    ]}>
      <div
        :for={i <- Range.new(1, @count, 1)}
        style={"transform: translate(#{(i - 1) * -0.45}rem, #{(i - 1) * 0.55}rem);"}
        class={[
          "absolute size-28 rounded-full border-6 flex justify-center items-center bg-gray-900",
          attribute_border(@attribute)
        ]}
      >
        <div class={["size-20 rounded-full", attribute_bg(@attribute)]}></div>
      </div>
    </div>
    """
  end

  defp attribute_bg(:gold), do: "bg-amber-500"
  defp attribute_bg(:diamond), do: "bg-neutral-300"
  defp attribute_bg(:ruby), do: "bg-red-600"
  defp attribute_bg(:emerald), do: "bg-green-600"
  defp attribute_bg(:saphire), do: "bg-cyan-600"
  defp attribute_bg(:amethyst), do: "bg-purple-600"

  defp attribute_border(:gold), do: "border-amber-500"
  defp attribute_border(:diamond), do: "border-neutral-300"
  defp attribute_border(:ruby), do: "border-red-600"
  defp attribute_border(:emerald), do: "border-green-600"
  defp attribute_border(:saphire), do: "border-cyan-600"
  defp attribute_border(:amethyst), do: "border-purple-600"
end
