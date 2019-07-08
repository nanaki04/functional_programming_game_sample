defmodule Enemy do
  use Actor

  defstruct hp: 10000,
    defense: 20,
    attack: 150,
    buffs: []

  # I don't want enemies to be able to receive buffs, so override!
  @impl(Actor)
  def add_buff(enemy, _), do: enemy

end
