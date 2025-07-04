[![Release Build](https://github.com/FG-Unofficial-Developers-Guild/FG-Aura-Effect/actions/workflows/release.yml/badge.svg)](https://github.com/FG-Unofficial-Developers-Guild/FG-Aura-Effect/actions/workflows/release.yml)
[![Check Lua Code](https://github.com/FG-Unofficial-Developers-Guild/FG-Aura-Effect/actions/workflows/lua.yml/badge.svg)](https://github.com/FG-Unofficial-Developers-Guild/FG-Aura-Effect/actions/workflows/lua.yml)

# Aura Effect Extension

This extension enables auras and area-of-effect buffs/debuffs by adding/removing effects on other actors based on proximity.

## Compatibility

This extension is compatible with the following rulesets:

- **Fantasy Grounds Unity** v4.6.6 (2025-03-09)
- **Supported Rulesets**:
  - 3.5E
  - 4E
  - 5E
  - PFRPG
  - PFRPG2
  - SFRPG

Additionally, Mattekure's [Complete Offensive Package Aura Extension](https://forge.fantasygrounds.com/shop/items/620/view) allows you to see the auras generated by this extension. It is a paid extension.

---

## How to Use

To create an aura, two clauses are required, separated by a semicolon (`;`). The first clause defines the area of effect (modifier: `AURA`), and the second clause defines the applied effect for tokens within the aura.


| Modifier | Value | Descriptors | Notes |
| --- | --- | --- | --- |
| AURA | (N) | [faction]\*, [behavior]\*, [alignment]\*, [size]\*, [type]\*, point, dying | Effect is applied to all tokens in the defined area that match the descriptor filtering|

- **(N)**: = Only numbers supported for value attribute.
- **\***: = Multiple entries of this descriptor type allowed.
- **!** or **~**: Use to negate a descriptor.

### Basic Aura Effect

```Aura of Protection; AURA: 10 ally; Aura of Protection AoE; SAVE: 5```

- This will create a 10-foot aura around the character with the effect.
- Allies within 10' will receive the effect: "Aura of Protection AoE; SAVE: 5".

> **Note:** While a label (like 'Aura of Protection', 'Aura of Protection AoE') is not mandatory, it is highly recommended to reference where effects are sourced from.

You can use **IF/IFT** conditions to control when an aura is applied or removed:

- **Before** the "AURA" effect: Enables or disables parsing of the aura (e.g., for conditional auras).
- **After** the "AURA" effect: Conditions will be copied to the recipients of the aura.

By default, the bearer of the aura effect will also receive its benefits. If this is not desired, use the `FACTION()` conditional operator.

### Descriptor Types

The following descriptors determine whether an aura applies to an actor. All conditions must be true for the aura to apply.

You can reverse the results of any descriptor by using the `!` or `~` operator (e.g., `!friend`, `~ally`).

#### Faction

- **all**: Applies aura to all actors (default).
- **ally**: Applies aura to actors whose faction matches the effect source's faction.
- **enemy**: Applies aura to actors whose faction is "foe" if the effect source's faction is "friend" (or vice versa).
- **foe**: Applies aura to actors whose faction is "foe".
- **friend**: Applies aura to actors whose faction is "friend".
- **neutral**: Applies aura to actors whose faction is "neutral".
- **none**: Applies aura to actors whose faction is "none" or blank.

#### Behavior

These modify the default behavior of auras. You can combine multiple special types to create unique effects.

| Descriptor | Notes | Example |
|------------|-------|---------|
| **cube** | Changes the aura shape to a cube instead of a sphere. The cube's side length is defined by the aura value. | `Example; AURA: 10 all,cube;Example E AoE; ATK: -5` |
| **single** | Applies the aura only when the target enters the area for the first time or starts their turn there. It won't be reapplied if the target leaves and returns on the same turn. | `Example; AURA: 10 !ally,single; Example AoE; IF: FACTION(!self); ATK: -5` |
| **sticky** | Aura effects persist on the actor even if they move out of the aura. | `Example; AURA: 10 all,sticky; Example AoE; IF: FACTION(!self); Poisoned` |
| **once** | The aura is applied only once per turn, regardless of whether the actor leaves and re-enters the area. | `Example; AURA: 10 all,once; Example AoE; ATK: -5` |

#### Point

By default, aura distances are calculated from the outside of the token. Use the `point` descriptor to calculate distance from the center of the token instead.

```Example; AURA: 10 all,point; Example AoE; ATK: -5```

#### Alignment

Supported alignments for each ruleset:

- **5E, 4E, PFRPG, PFRPG2, SFRPG**:  lawful, chaotic, good, evil, l, c, g, e, n, lg, ln, le, ng, ne, cg, cn, ce.

> **Note:** Neutral alignment should be represented as `n` when specifying in conditions.

#### Size

Supported sizes for each ruleset:

- **5E & 4E**: tiny, small, medium, large, huge, gargantuan
- **3.5E, PFRPG, PFRPG2, & SFRPG**: fine, diminutive, tiny, small, medium, large, huge, gargantuan, colossal

#### Type

Available creature types:

- **5E**: aberration, beast, celestial, construct, dragon, elemental, fey, fiend, giant, humanoid, monstrosity, ooze, plant, undead, living construct, aarakocra, bullywug, demon, devil, dragonborn, dwarf, elf, gith, gnoll, gnome, goblinoid, grimlock, halfling, human, kenku, kuo-toa, kobold, lizardfolk, merfolk, orc, quaggoth, sahuagin, shapechanger, thri-kreen, titan, troglodyte, yuan-ti, yugoloth
- **4E**: magical beast, animate, beast, humanoid, living construct, air, angel, aquatic, cold, construct, demon, devil, dragon, earth, fire, giant, homunculus, mount, ooze, plant, reptile, shapechanger, spider, swarm, undead, water
- **3.5E/PFRPG**:  magical beast, monstrous humanoid, aberration, animal, construct, dragon, elemental, fey, giant, humanoid, ooze, outsider, plant, undead, vermin, living construct, air, angel, aquatic, archon, augmented, cold, demon, devil, earth, extraplanar, fire, incorporeal, native, psionic, shapechanger, swarm, water, dwarf, elf, gnoll, gnome, goblinoid, gnoll, halfling, human, orc, reptilian
- **PFRPG2**:  aberration, animal, beast, celestial, construct, dragon, elemental, fey, fiend, fungus, humanoid, monitor, ooze, plant, undead, adlet, aeon, agathion, air, angel, aquatic, archon, asura, augmented, azata, behemoth, catfolk, clockwork, cold, colossus, daemon, dark folk, demodand, demon, devil, div, dwarf, earth, elemental, elf, extraplanar, fire, giant, gnome, goblinoid, godspawn, great old one, halfling, herald, human, incorporeal, inevitable, kaiju, kami, kasatha, kitsune, kyton, leshy, living construct, mythic, native, nightshade, oni, orc, protean, psychopomp, qlippoth, rakshasa, ratfolk, reptilian, robot, samsaran, sasquatch, shapechanger, swarm, troop, udaeus, unbreathing, vanara, vishkanya, water
- **SFRPG**: magical beast, monstrous humanoid, aberration, animal, companion, construct, dragon, fey, giant, humanoid, ooze, outsider, plant, undead, vermin,living construct, aeon, agathion, air, angel, aquatic, archon, augmented, cold, demon, devil, earth, extraplanar, fire, incorporeal, native, psionic, shapechanger, swarm, water, dwarf, elf, gnoll, gnome, goblinoid, halfling, human, orc, reptilian

#### Dying

- **dying**: Applies aura when the source actor is at 0 HP or in a dying state.
- **!dying**: Applies aura when the source actor is not dying (HP > 0).

> **Note:** Auras with the "dying" descriptor will only trigger if the actor is in a dying state.

#### Exceptions

- If a resulting aura effect is set to **"off"** in the combat tracker, the effect will not be removed based on token movement. This is useful for managing automatic effects like those for saved or immune creatures.
- The factional relationship of **ally** or **enemy** is evaluated from the source of the aura effect.

---

### 5E Concentration (C)

For **concentration** effects, place the `(C)` modifier before or within the "AURA" clause, but **not after** it.

**Correct Usage:**

```Example; (C); AURA: 10 all; Example AoE; Do something```
```Example; AURA: 10 all (C); Example AoE; Do something```

**Incorrect Usage:**

```Example; AURA: 10 all; Example; Do something (C)```

---

## FACTION() Conditional Operator

This operator expands the functionality of **IF/IFT** conditions by evaluating factional relationships.

- **ally**: True if the source and target factions match.
- **enemy**: True if the source faction is "foe" and the target faction is "friend" (or vice versa).
- **foe**: True if the faction is "foe".
- **friend**: True if the faction is "friend".
- **neutral**: True if the faction is "neutral".
- **none**: True if the faction is "none".
- **self**: True if the actor is the source of the effect.
- **notself**: Legacy, same as `!self`, True if the actor is not the source.

Use `!` or `~` to negate the result (e.g., `!self`, `~ally`).

---

## GM Holding Shift

When the GM holds **Shift**, aura calculations are temporarily disabled. This allows the GM to move a token through an aura without triggering the aura effect.

---

## Special Condition: **Object**

Actors with the **Object** condition will not be affected by auras.

---

## Optional Settings

### Disabling Aura Effect Chat Messages

You can suppress aura apply/removal notifications for specific factions or all factions by adjusting the "Silence Notifications for Aura Types" setting.

### Diagonal Distance Multiplier

You can control how diagonal distances are calculated between tokens:

- **Raw**: Uses the Pythagorean Theorem for diagonals.
- **Ruleset**: Diagonal distances are calculated according to the specific ruleset's definition.

---

## Effect Sharing Threads

- **5E**: [5E Aura Effects Coding Thread](https://www.fantasygrounds.com/forums/showthread.php?69965-5E-Aura-Effects-Coding)

---

## Video Demonstration

[![Video Thumbnail](https://i.ytimg.com/vi_webp/e2JQzf5HI6I/hqdefault.webp)](https://www.youtube.com/watch?v=e2JQzf5HI6I)

---

## API Documentation

For developers who want to interact with this extension, an API is available. Documentation is provided in the code.

- **[Aura API Documentation](https://github.com/FG-Unofficial-Developers-Guild/FG-Aura-Effect/blob/main/scripts/manager_aura_api.lua)**
