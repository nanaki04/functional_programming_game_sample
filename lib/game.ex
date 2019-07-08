defmodule Game do
  @behaviour GenServer

  @id {:global, :game}

  defstruct characters: %{},
    enemy: %Enemy{},
    state: :in_progress

  defguardp is_not_alive(actor) when :erlang.map_get(:hp, actor) <= 0

  defguardp has_joined(characters, player_id) when :erlang.is_map_key(player_id, characters)

  def start_server() do
    GenServer.start_link(__MODULE__, %Game{}, name: @id)
  end

  def join() do
    GenServer.call(@id, :join)
  end

  def play_turn() do
    GenServer.call(@id, :play_turn)
  end

  def restart() do
    GenServer.call(@id, :restart)
  end

  @impl(GenServer)
  def init(state), do: {:ok, state}

  @impl(GenServer)
  def handle_call(:restart, _from, _game_state) do
    game_state = %Game{}
    {:reply, game_state, game_state}
  end

  def handle_call(:join, {player_id, _ref}, %{characters: characters} = game_state) when has_joined(characters, player_id) do
    {:reply, "Oops! You have already joined the game!", game_state}
  end

  def handle_call(:join, {player_id, _ref}, game_state) do
    game_state = Map.update!(game_state, :characters, fn characters ->
      # add character
      Map.put(characters, player_id, %Character{})
      # add buffs to all characters in the game
      |> Enum.map(fn {player_id, character} ->
        character = character
                    |> Character.add_buff(%Buff{type: :defense_up, value: 40})
                    |> Character.add_buff(%Buff{type: :attack_up, value: 450})

        {player_id, character}
      end)
      |> Enum.into(%{})
    end)

    {:reply, game_state, game_state}
  end

  def handle_call(:play_turn, _from, %{state: :victory} = game_state) do
    {:reply, "VICTORY!!!", game_state}
  end

  def handle_call(:play_turn, _from, %{state: :defeat} = game_state) do
    {:reply, "DEFEAT!!!", game_state}
  end

  def handle_call(:play_turn, {player_id, _ref}, game_state) do
    case validate_turn(game_state, player_id) do
      :ok ->
        game_state = game_state
                     |> attack_enemies(player_id)
                     |> attack_players

        {:reply, game_state, game_state}

      {:error, message} ->
        {:reply, message, game_state}
    end
  end

  defp validate_turn(game_state, player_id) do
    with %{hp: hp} when hp > 0 <- Map.get(game_state.characters, player_id) do
      :ok
    else
      nil -> {:error, "Oops! You have not joined the game yet!"}
      _ -> {:error, "Oh no! Your character is down!"}
    end
  end

  defp attack_enemies(game_state, player_id) do
    character = Map.get(game_state.characters, player_id)
    dmg = Character.calculate_attack(character)
    enemy = Enemy.take_damage(game_state.enemy, dmg)

    Map.put(game_state, :enemy, enemy)
    |> judge_victory_or_defeat()
  end

  defp attack_players(game_state) do
    dmg = Enemy.calculate_attack(game_state.enemy)

    {target_name, _} = find_alive_characters(game_state)
                       |> Enum.random()

    characters = Map.update!(game_state.characters, target_name, fn target ->
      Character.take_damage(target, dmg)
    end)

    Map.put(game_state, :characters, characters)
    |> judge_victory_or_defeat()
  end

  defp judge_victory_or_defeat(%{enemy: enemy} = game_state) when is_not_alive(enemy) do
    Map.put(game_state, :state, :victory)
  end

  defp judge_victory_or_defeat(game_state) do
    case Enum.to_list(find_alive_characters(game_state)) do
      [] -> Map.put(game_state, :state, :defeat)
      _ -> Map.put(game_state, :state, :in_progress)
    end
  end

  defp find_alive_characters(%{characters: characters}) do
    Enum.filter(characters, fn {_key, character} -> character.hp > 0 end)
    |> Enum.into(%{})
  end

end
