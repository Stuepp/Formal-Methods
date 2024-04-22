module pokemon {
  import basicSpells.* from "../spells/basicSpells"
  import rareSpells.* from "../spells/rareSpells"

  type PokemonType = Water | Fire | Grass | Electric
  type DamageModifier = SuperEffective | NotVeryEffective | Normal

  type Pokemon = {
    name: str,
    hp: int,
    speed: int,
    team: str,
    pokemon_type: PokemonType
  }

  pure val POKEMONS = Set(
    { name: "Squirtle", hp: 44, speed: 43, team: "", pokemon_type: Water },
    { name: "Bulbasaur", hp: 45, speed: 45, team: "", pokemon_type: Grass },
    { name: "Charmander", hp: 39, speed: 65, team: "", pokemon_type: Fire },
    { name: "Pikachu", hp: 35, speed: 90, team: "", pokemon_type: Electric}
  )

  // Exercise 1
  var lastAttack : Option[{attacker: Pokemon, receiver: Pokemon, attack: str, dmg: int}] //{ attacker: Pokemon, receiver: Pokemon, attack: str, damage: int } ; {attacker, receiver, attack: str. (prevHP - receiver.hp)}
  // Exercise 2 a - check again
  val grassBeatsFire = {
    match lastAttack {
      | Some(last) => last.attacker.pokemon_type == Grass  and last.receiver.pokemon_type == Fire and pokemons.get(last.receiver.team).hp <= 0
      | None => false
    }
  }
  val fireBeatsGrass = not(grassBeatsFire)
  //Exercise 3 is found in lines 5, 20 and 44

  var pokemons: str -> Pokemon
  var next_team: str

  pure def other_team(team: str): str = if (team == "A") "B" else "A"

  pure def damage(p: Pokemon, d: int): Pokemon = {
    { ...p, hp: p.hp - d }
  }

  pure def damage_modifier(attacker: Pokemon, receiver: Pokemon): DamageModifier = {
    match attacker.pokemon_type {
        | Water => match receiver.pokemon_type {
          | Water => NotVeryEffective
          | Fire => SuperEffective
          | Grass => NotVeryEffective
          | Electric => Normal
        }
        | Fire => match receiver.pokemon_type {
          | Water => NotVeryEffective
          | Fire => NotVeryEffective
          | Grass => SuperEffective
          | Electric => Normal
        }
        | Grass => match receiver.pokemon_type {
          | Water => SuperEffective
          | Fire => NotVeryEffective
          | Grass => NotVeryEffective
          | Electric => Normal
        }
        | Electric => match receiver.pokemon_type{
          | Water => SuperEffective
          | Fire => Normal
          | Grass => NotVeryEffective
          | Electric => NotVeryEffective
        }
      }
  }

  action tackle(attacker: Pokemon,receiver: Pokemon): bool = all {
    pokemons' = pokemons.setBy(receiver.team, p => p.damage(10)),

    lastAttack' = Some({attacker: attacker, receiver: receiver, attack:"tackle", dmg:10})
  }

  action elemental_attack(attacker: Pokemon, receiver: Pokemon): bool = {
    val base_damage = 10
    val actual_damage = match damage_modifier(attacker, receiver) {
      | SuperEffective => base_damage * 2
      | NotVeryEffective => base_damage / 2
      | Normal => base_damage
    }
    all{
      pokemons' = pokemons.setBy(receiver.team, p => p.damage(actual_damage)),
      lastAttack' = Some({attacker: attacker, receiver: receiver, attack: "elemental_attack", dmg: actual_damage})
    }
  }

  action attack(attacker: Pokemon, receiver: Pokemon): bool = {
    all {
      attacker != receiver,
      attacker.hp > 0,
      receiver.hp > 0,
      pure val prevHP = receiver.hp
      
      match damage_modifier(attacker, receiver) {
        | SuperEffective => elemental_attack(attacker, receiver)
        | NotVeryEffective => tackle(attacker ,receiver)
        | Normal => any{ tackle(attacker ,receiver), elemental_attack(attacker, receiver) }
      }      
    }
  }

  action init = {
    nondet team_A_pokemon = POKEMONS.oneOf()
    nondet team_B_pokemon = POKEMONS.oneOf()
    all {
      pokemons' = Map(
        "A" -> { ...team_A_pokemon, team: "A" },
        "B" -> { ...team_B_pokemon, team: "B" }
      ),
      next_team' = if (team_A_pokemon.speed > team_B_pokemon.speed) "A" else "B",
      lastAttack' = None
    }
  }

  action step = {
    val attacker = pokemons.get(next_team)
    val receiver = pokemons.get(other_team(next_team))
    all {
      attack(attacker, receiver),
      next_team' = other_team(next_team),
    }
  }

  val inv = pokemons.values().forall(p => p.hp > 0)
}
