# Small Talk — Game Design Document

> Working title. The cards you collect are *conversation topics*; the battles
> are dates. Rename freely once the game finds its voice.
>
> Genre: **raising sim + card battler** (voted by the class).
> Reference point: *Tokimeki Memorial*, shrunk to game-jam size.

## 1. Pitch

You are a third-year high-school student in your **final semester before
graduation**. Twelve weeks remain. How you spend your weekdays quietly shapes
who you become; every Saturday you get to find out who that is — first as a
booster pack of conversation topics, then on a date where you have to actually
*use* them.

On graduation day, someone might be waiting for you under the old tree behind
the school. Or no one.

## 2. The core loop

One in-game **week** is one full loop:

```
┌─────────────────────────────────────────────────────────┐
│  MON–FRI   Raising sim: pick an activity each day.      │
│            Hidden stats grow (Int / Charm / Sense).     │
│                          ↓                              │
│  SAT AM    Pack opening: 5 random cards, rolled from    │
│            your hidden stats. Collection grows.         │
│                          ↓                              │
│  SAT PM    World map: walk to one of 3 places, meet     │
│            the person who hangs out there.              │
│                          ↓                              │
│  THE DATE  Card battle: 5 exchanges, hand of 5 drawn    │
│            from your whole collection. Affection moves. │
│                          ↓                              │
│  SUN       Recap screen, autosave. Next week.           │
└─────────────────────────────────────────────────────────┘
      × 12 weeks  →  GRADUATION DAY (endings)
```

The two genres feed each other: training determines what packs you open, and
the dates create demand for stats you haven't trained. Neither half is
optional.

## 3. Setting & premise

Deliberately generic on purpose — a nameless high school in a nameless town,
one semester, three people you might fall for. All flavor text should be
archetypal enough that students can reskin characters, places, and topics
without touching mechanics.

- **Protagonist:** silent-protagonist third-year. Defined entirely by stats
  and cards; no portrait needed for v1.
- **Timeframe:** 12 weeks (one semester), ending on graduation day.
- **Tone:** light, warm, a little self-aware about being a dating sim.

## 4. Stats & the triangle

Three hidden stats, starting at **1 / 1 / 1**:

| Stat | Trained by | Flavor |
|------|-----------|--------|
| **Intelligence** (Int) | Study | Books, trivia, being right |
| **Charm** (Cha) | Socialize | Warmth, humor, being liked |
| **Sense** (Sen) | Hobbies | Intuition, taste, being interesting |

The battle system runs on one rule, a rock-paper-scissors triangle. You never
match a topic with the *same* stat — you **complement** it:

```
        Int
       ↗    ↘
   answers    is answered by
     Cha  ←   Sen
```

- She plays **Int** → answer with **Sense** (don't out-nerd her; be interesting)
- She plays **Sense** → answer with **Charm** (don't compete on taste; be warm)
- She plays **Charm** → answer with **Int** (don't try to out-charm her; impress her)

The thesis of the game, stated as a mechanic: **complement, don't compete.**
Implementation-wise the whole triangle is one lookup table.

## 5. The weekday phase (raising sim)

Monday to Friday, one choice per day from three activities:

| Activity | Effect |
|----------|--------|
| Study | +1 Int |
| Socialize | +1 Cha |
| Hobbies | +1 Sen |

That's it for v1. Stats are **hidden** — the player sees flavor feedback
("you feel sharper"), not numbers. The pack opening *is* the stat screen:
you learn what you've become by seeing what you can talk about.

*Tuning hooks (later, not v1):* rest days, random events, diminishing
returns, activities that give +2/−1 splits.

## 6. Pack generation (Saturday morning)

Every Saturday the player opens a **pack of 5 cards**. Each card is a
conversation topic with three numbers (e.g. `Zodiac Signs — 1 Int / 2 Cha /
10 Sen`).

Generation, per card:

1. Pick the card's **primary stat**, weighted by the player's hidden stat
   distribution (a 20/5/10 player mostly pulls Int-primary cards).
2. Roll the primary value between **50–100%** of that hidden stat.
3. Roll the two off-stats between **0–50%** of their hidden stats.
4. Pick a topic name from that stat's name pool (pure flavor).

Properties this buys us:

- Cards never exceed what you've trained — no lottery wins.
- Higher stats raise the *ceiling and the floor*: training improves your
  **chances**, it never guarantees the perfect hand.
- Multi-stat cards fall out naturally (that 10 Cha / 2 Int rare that you
  *could* waste on an easy exchange…).

Exact curves are tuning; the invariant is *rolls are bounded by hidden stats*.

## 7. Saturday afternoon: the world map

A small walkable map (top-down, tile-based) with **three locations**. Time
allows **one visit** per Saturday.

| Place | Who's there | She plays | You need |
|-------|-------------|-----------|----------|
| Library | **The Bookworm** | Int | Sense |
| Sports field | **The Ace** | Sense | Charm |
| Arcade | **The Gamer** | Charm | Int |

Each love interest is keyed to the stat she *plays*, which means each one
creates demand for a *different* stat than the obvious one — the player who
wants the Bookworm discovers they should have been doing Hobbies, not
Studying. That discovery is a designed moment; don't tutorialize it away.

Character archetypes (placeholder names welcome):

- **The Bookworm** — quotes novels at you, secretly loves when you say
  something she's never read anywhere. Talks Int; melts for Sense.
- **The Ace** — all instinct and momentum, allergic to lectures. Talks
  Sense; melts for Charm.
- **The Gamer** — playful trash-talker, unimpressed by flattery. Talks
  Charm; melts for Int (outsmart her and she'll never admit she liked it).

As **affection rises, each girl starts mixing in her off-stats** — she opens
up and shows other sides of herself. This is both the anti-mono-build
mechanic and genuinely nice characterization.

## 8. The date (card battle)

The heart of the game. A date is **5 exchanges**, one card each per exchange.

**Setup**

- She has a small scripted-plus-random deck; difficulty (card values) scales
  with her current affection level.
- You draw a **hand of 5** from your **entire collection**. Cards are never
  destroyed — a card played is out *for this date only* ("you already told
  her that story today"). The collection only ever grows.

**One exchange**

1. She plays a topic face-up: a stat and a value (e.g. `Sense 7`).
2. You play one card from your hand. The game resolves it as a cascade — the
   player just throws the card, the fiction decides what happened:

| Check (in order) | Result | Effect |
|---|---|---|
| Your **counter stat** > her value | **Hit it off!** | Affection **+1**. |
| Your **matching stat** ≥ her value | **Stall** | "Haha, yeah, totally." No affection, but **draw a replacement card**. |
| Neither | **Fumble** | Awkward silence. Affection **−1**. |

3. Your played card goes to this date's discard.

**The mulligan.** Once per date you may redraw your whole hand — but it
**consumes an exchange** and reads as a fumble in the fiction (you zoned out
mid-conversation). One expensive escape hatch; think before you use it.

**Date end.** After 5 exchanges the date is over. Net affection is applied.
Running out of strong cards mid-date should *feel* like running out of things
to say — that feeling is the design target for all tuning.

Why the stall rule matters strategically: stalling digs one card deeper into
your collection at zero risk (if your matching stat clears the bar). Reading
whether to dig or to spend is most of the skill.

## 9. Affection, calendar & endings

- Affection per girl is an integer, displayed fuzzily as hearts (Tokimeki
  hides truth behind vibes; so do we).
- Thresholds unlock: new dialogue pools → her mixing off-stats → a scripted
  event date (stretch).
- **Week 12 → Graduation day.** The girl with the highest affection above a
  confession threshold confesses under the tree. Below threshold: the
  friendly-but-alone ending. That ending should sting a little.

A 12-week run is short **on purpose**: a full playthrough in ~20–30 minutes,
replayable to chase a different girl with a different build.

## 10. Scenes

| Scene | Purpose | Teaches |
|-------|---------|---------|
| Week (raising sim) | Pick daily activities | UI, game state, calendar/save data |
| Pack opening | Reveal 5 new cards | Weighted RNG, animation & juice |
| World map | Walk to a location | Tilemaps, movement, collision, transitions |
| Date (battle) | The card game | Turn state machines, data-driven design |
| Collection viewer | Browse your cards | Scrolling UI, data presentation |
| Recap / Sunday | Week summary, autosave | Serialization |
| Title / Ending | Frame the run | Scene flow, endings |

## 11. Scope

**v1 (the jam-sized game)** — everything above with placeholder art: 3 stats,
3 activities, 3 girls, 3 locations, 5-card packs, 5-exchange dates, 12 weeks,
2 ending types.

**Stretch, in rough priority order:**

1. **Deck builder** — pick a 15-card "weekend deck" from the collection
   before Saturday. This is the planned fix for *deck dilution* (by week 10
   the collection is ~50+ cards and early junk waters down every draw). V1
   accepts mild dilution; if it hurts, this is the cure, and it gives the
   collection viewer a mechanical reason to exist.
2. Scripted event dates at affection thresholds.
3. Weekday random events ("she was at the library on a Tuesday?!").
4. Card rarity tiers & pack-opening fanfare by rarity.
5. Rival / time pressure mechanics.

## 12. Open questions & tuning knobs

- Affection numbers: is ±1 per exchange enough resolution, or do big margins
  deserve bonus affection?
- Her deck contents per affection level: scripted list vs. weighted pool.
- Pack roll curves (§6): uniform vs. bell-shaped rolls.
- Should stalls be visible as a distinct animation from hits? (Yes, probably
  — the three outcomes are the game's vocabulary.)
- Does the mulligan cost an exchange (current design) or affection instead?
