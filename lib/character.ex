defmodule Character do
  use Actor

  defstruct hp: 1000,
    defense: 20,
    attack: 100,
    buffs: []

end
