# Lesson 11 — Procedural card identity

Last class, randomness decided **which card exists**. Today, randomness decides
**what that card looks like**. Those jobs need opposite behavior:

```text
gameplay RNG       surprise me
presentation RNG   remember me
```

A generated pack should be uncertain. Once a card exists, however, its picture
must survive a redraw, a scene change, and a restart. The same card data must
always become the same visual identity.

This class also introduces the collection browser, but its navigation, paging,
layout, and detail panel arrive as scaffold. They are not today's intellectual
work. The class designs and implements the transformation from three numbers to
one recognizable picture.

## Run it

```bash
love .
luajit tests/card_art.lua
luajit tests/generation.lua
```

The game opens in the collection browser. Use the arrow keys to move, and
Home/End to jump to the first or last card. Run with `love . --debug` to switch
back to the Pack Lab; generate and replay a pack to see that replayed data also
replays its pictures.

## Instructor preparation

This branch has two deliberately separate code commits:

| Commit | Purpose |
|---|---|
| `4abdabb` | Pre-made collection browser: input, selection, paging, layout, detail panel |
| `bb32523` | Reference solution: procedural recipe, renderer integration, tests |

Begin the class from `4abdabb`. Do not live-type the collection scene. Show its
systems for five minutes so students know what they received, then leave it
alone.

The completed `CardRenderer.lua` is also suitable as instructor-provided
plumbing. Its job is to turn a finished visual recipe into LÖVE draw calls. The
three useful live-code targets are in `CardArt.lua`:

1. `seed` — card values become stable identity;
2. `rankedStats` and symbol sizing — data becomes visual hierarchy;
3. `describe` — local randomness and HSL color become a drawing recipe.

Do not try to type both files from an empty screen in ninety minutes. Either
provide `CardRenderer.lua` before class or reveal it after the room has designed
the rules. Walk through one shape function and the clipping boundary; summarize
the other drawing calls as implementation of the agreed contract.

## Learning goals

By the end, students should be able to explain:

- why procedural visuals need deterministic randomness;
- why render-time randomness must not touch gameplay's global RNG;
- how one value can be encoded redundantly with color and shape;
- why proportional **area** requires a square root when calculating width;
- why hue interpolation preserves identity better than RGB averaging;
- why `CardArt` is a transformation while collection rendering is an ECS
  system.

The code is done when any card can render at any rectangle and equal card data
produces equal pictures.

## The 90-minute class

### 0–8 min — Cold read

Screen-share the completed collection for about ten seconds, then hide the
detail panel or simply ask students not to read it.

Ask in Discord chat:

```text
Pick one visible card.
1. What is its strongest stat?
2. What is probably second?
3. What visual evidence did you use?
```

Everybody posts at once. Simultaneous chat answers prevent the first confident
voice from becoming the room's answer.

Do not correct anyone immediately. If people disagree, that is evidence about
the visual language, not a student mistake.

### 8–16 min — Two jobs for randomness

Return to the previous lesson's replay seed:

1. Generate a pack in the Pack Lab.
2. Record the cards and their pictures.
3. Replay the seed.
4. Confirm both the data and pictures return.

Then ask what would happen if rendering called `love.math.random()` every
frame. The card would crawl, flicker, and consume random values that gameplay
expected to use later.

State today's invariant:

> Drawing is allowed to look random. It is not allowed to change history.

### 16–29 min — Six-seat design review

There are only three decisions. Assign two students to each one in the main
Discord channel; no breakout rooms are needed.

Post these cards:

```lua
A = { primary = "int",   stats = { int = 10, charm = 2,  sense = 0 } }
B = { primary = "charm", stats = { int = 4,  charm = 10, sense = 8 } }
C = { primary = "sense", stats = { int = 1,  charm = 1,  sense = 1 } }
```

Assign:

| Seats | One decision | Forced choices |
|---|---|---|
| 1–2 | Size | Relative within each card, or absolute across the whole run? What does zero draw? |
| 3–4 | Placement | Fixed slots, or seeded positions? Can symbols overlap? |
| 5–6 | Color | Primary only, or primary tinted by secondary? Should weak and strong versions share a palette? |

Give everyone ninety silent seconds. Each student posts exactly this:

```text
Choice:
One reason:
One failure case:
```

Spend another five minutes resolving the three decisions as a room. When the
room is split, use the GDD's intended reading test: the picture communicates a
card's **build**, while the detail panel communicates exact strength.

If fewer than six students attend, give one student a whole row. If discussion
is slow, use the shipped decisions below and ask students to attack them rather
than invent alternatives from nothing.

### 29–37 min — Freeze the contract

Write the chosen rules before opening the editor. The reference implementation
uses:

- Intelligence: blue square;
- Charm: red circle;
- Sense: green triangle;
- values normalized against the largest value on that card;
- zero draws no symbol;
- symbol area grows with value;
- largest symbols draw first so smaller ones remain visible above them;
- positions come from a card-local seeded RNG;
- overlap is allowed;
- background starts at the primary hue and moves at most 45% toward the
  strongest off-stat;
- saturation and lightness remain fixed;
- exact phrase and numbers live in the detail panel.

This is the design spec. From this point onward, code is judged against it.

### 37–44 min — Tour the scaffold

Show the pre-made systems in their execution order:

```text
CollectionInputSystem
        key press -> move request

CollectionSelectionSystem
        move request -> selected index and visible page

CollectionChromeRenderSystem
        background, title, count and controls

CollectionGridRenderSystem
        page of cards and cursor

CardDetailRenderSystem
        selected phrase and exact numbers
```

Point out what is deliberately absent: input does not clamp a cursor, selection
does not draw, the grid does not know the exact-value layout, and no one owns a
catch-all collection system.

The scene temporarily generates a deterministic twelve-card gallery when the
save has no collection. This is a classroom fixture, not the Saturday flow.
Lesson 12 will remove it when Week → pack → browse exists.

### 44–59 min — Stable visual identity

Start with the card seed. A seed is derived only from serializable card data:

```lua
function CardArt.seed(card)
    local stats = card.stats
    local primary = PRIMARY_INDEX[card.primary]
    return (stats.int * 73856093
        + stats.charm * 19349663
        + stats.sense * 83492791
        + primary * 26544357) % 2147483646 + 1
end
```

The constants are merely large, distinct mixing constants. They are not secret
and this is not cryptography. The promise matters more than the particular
numbers: equal input gives equal seed.

The renderer builds a private generator:

```lua
local rng = love.math.newRandomGenerator(CardArt.seed(card))
local random = function(...) return rng:random(...) end
```

Contrast it with both dangerous alternatives:

```lua
love.math.random()             -- consumes gameplay's shared sequence
love.math.setRandomSeed(seed)  -- rewinds gameplay's shared sequence
```

The local generator may be consumed freely without changing the next pack or
hand.

### 59–70 min — Value becomes size

Sort the three stats by value, retaining a stable stat order for ties. Skip
zeros. Normalize every non-zero value against the largest value on that card.

If diameter were directly proportional to value, a value of 10 would have one
hundred times the area of a value of 1. Use a square root:

```lua
local proportion = entry.value / maximum
local size = math.max(0.15, 0.46 * math.sqrt(proportion))
```

The `0.15` floor is a presentation compromise: a real non-zero off-stat should
remain visible on an 86×116 thumbnail. It means very small values are no longer
perfectly area-proportional. Name that compromise instead of hiding it.

Ask whether `A` and `{ int = 20, charm = 4, sense = 0 }` should share a
silhouette. In this design they do: the image says “specialist,” while the
detail panel distinguishes strength.

### 70–78 min — Primary plus secondary color

RGB interpolation changes red and green by lowering and raising three channels;
the midpoint often loses the vividness that made either endpoint legible. Here,
the variables have clearer jobs:

```text
hue          which stat family?
saturation   how colorful?       fixed
lightness    how bright?          fixed
```

Interpolate hue on a circle, taking the shortest direction. Red near 360° and
blue near 218° must not take an accidental long trip through unrelated hues.

The secondary influence is capped below half:

```lua
local influence = math.min(
    secondaryValue / (primaryValue + secondaryValue),
    0.45)
```

That cap is a design claim: a hybrid should be visible, but its pack category
should remain readable.

### 78–85 min — Render and challenge it

Run the collection. Use the cold-read questions again. Then inspect these edge
cases:

- one non-zero stat;
- three equal stats;
- a primary whose rolled value is not the largest value;
- a value of zero;
- two cards with identical values;
- an 86×116 grid card versus a differently sized card.

Do not ask merely whether the scene “looks good.” Ask whether it fulfills the
written visual contract.

### 85–90 min — Test and exit ticket

Run:

```bash
luajit tests/card_art.lua
```

The test checks promises, not a screenshot:

- equal data produces the same seed and positions;
- zero-valued stats disappear;
- the largest value produces the largest symbol;
- the strongest off-stat supplies the secondary hue;
- secondary influence cannot steal primary identity;
- generated RGB channels remain valid.

Exit ticket, posted in Discord:

1. Which randomness in today's code must be unpredictable?
2. Which randomness must be reproducible?
3. Name one visual ambiguity the current generator still has.

## Architecture underneath the picture

```text
card plain data
     |
     v
CardArt.describe       pure visual policy
     |
     v
visual recipe          background + ordered normalized symbols
     |
     v
CardRenderer.draw      LÖVE drawing primitive
     |
     +----------+----------------+
     v          v                v
collection   pack lab       future date hand
```

`CardArt` is not an ECS system. It transforms one value into another and needs
no registry, scene, entity, or graphics window. That is why its test runs under
plain LuaJIT.

`CardRenderer` is also not a screen-level system. It is the reusable primitive
for drawing one card at a requested rectangle. Systems decide which cards are
visible, where they go, and what interaction surrounds them.

This is the same boundary used last class: generators are transformations;
systems adapt transformations to the running world.

## Deliberate limitations

- The visual seed does not include the phrase. Equal primary/stat data produces
  the same composition even if the phrases differ. Add a stable phrase hash if
  prose should be part of identity.
- Overlap is permitted but not optimized. A later polish pass could reject
  placements that hide too much of a smaller symbol.
- Shapes encode color redundantly, but the current palette still needs testing
  with actual color-vision simulations.
- The collection uses pages rather than smooth scrolling. That interaction and
  pack reveal animation belong to lesson 12.
- The lesson gallery is not saved and does not represent a free pack.

## Next class

Turn the browser into the Saturday scene with two entry modes:

```text
pack mode:        SLIDE_IN -> FLIPPING -> BROWSING
collection mode:                         BROWSING
```

The card renderer is finished, so the next lesson can concentrate on UI state,
tweening, staggered reveals, new-card highlighting, and the transition from the
Week scene instead of drawing the same card again.
