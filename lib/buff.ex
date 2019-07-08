defmodule Buff do

  defstruct type: :defense_up,
    value: 1

  def apply(%{type: :defense_up, value: value}, actor) do
    Map.update(actor, :defense, 0, fn defense -> defense + value end)
  end

  def apply(%{type: :attack_up, value: value}, actor) do
    Map.update(actor, :attack, 0, fn attack -> attack + value end)
  end

  def apply(_, actor) do
    IO.warn("unsupported buff")
    actor
  end

  def reset(%{type: :defense_up, value: value}, actor) do
    Map.update(actor, :defense, 0, fn defense -> defense - value end)
  end

  def reset(%{type: :attack_up, value: value}, actor) do
    Map.update(actor, :attack, 0, fn attack -> attack - value end)
  end

  def reset(_, actor) do
    IO.warn("unsupported buff")
    actor
  end

end
