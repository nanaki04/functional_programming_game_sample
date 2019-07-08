defmodule Actor do

  @type actor :: %{:buffs => term, :hp => number, :defense => number, :attack => number}

  @callback calculate_attack(actor) :: number
  @callback take_damage(actor, number) :: actor
  @callback add_buff(actor, term) :: actor
  @callback apply_buffs(actor) :: actor
  @callback reset_buffs(actor) :: actor

  defmacro __using__(_opts) do
    quote do
      @behaviour Actor

      @impl(Actor)
      def calculate_attack(actor) do
        actor = actor
                |> apply_buffs

        actor.attack
      end

      @impl(Actor)
      def take_damage(actor, dmg) do
        actor
        |> apply_buffs()
        |> apply_defense_and_reduce_hp(dmg)
        |> reset_buffs()
      end

      @impl(Actor)
      def add_buff(actor, buff) do
        Map.update(actor, :buffs, [], fn buffs -> [buff | buffs] end)
      end

      @impl(Actor)
      def apply_buffs(actor) do
        Enum.reduce(actor.buffs, actor, fn buff, actor -> Buff.apply(buff, actor) end)
      end

      @impl(Actor)
      def reset_buffs(actor) do
        Enum.reduce(actor.buffs, actor, fn buff, actor -> Buff.reset(buff, actor) end)
      end

      defp apply_defense_and_reduce_hp(actor, value) do
        reduce_hp(actor, value - actor.defense)
      end

      defp reduce_hp(actor, value) do
        Map.update(actor, :hp, 0, fn hp -> hp - value end)
      end

      defoverridable [add_buff: 2]
    end
  end
end
