# Lesson 02 — ECS: Entities, Components, Systems (Lab 2)

> PIA week 3 · Branch `02-ECS` · Previous: `01-Pong`

```sh
love .
```

Same Pong as last class. Press **B** during play. Keep pressing it.

See the whole refactor:

```sh
git diff 01-Pong..02-ECS
```

## 1. Why change an architecture that worked?

Lesson 01 used the classic OO approach: a `Paddle` class, a `Ball` class, each
owning its data *and* its behavior. It worked great — at this size.

Now imagine our real game. A card that sits in your hand, a card flying to the
table, a date character that walks the overworld AND appears in dialogue
scenes, a menu cursor... With inheritance you end up with the famous **class
explosion**: `MovingDrawableClickableCard extends DrawableClickableCard
extends...` — and every new combination of abilities needs a new class.

**ECS flips the model**: instead of asking *"what IS this object?"* (its
class), we ask *"what does it HAVE?"* (its components).

- **Entity** — just a number. Entity 7. It has no data and no behavior; it
  only "exists" as a key inside the registry. There is no object to delete.
- **Component** — plain data attached to an entity: `position = {x, y}`,
  `velocity = {vx, vy}`, `paddle = {upKey, downKey, speed}`.
- **System** — logic that runs over every entity that has a certain set of
  components. The `MovementSystem` moves *anything* with `position` +
  `velocity`. It has no idea whether that thing is a ball, a card, or a love
  interest.

Behavior emerges from composition: an entity moves *because* it has a
velocity, collides *because* it has a size, is controllable *because* it has
a paddle component.

## 2. The architecture, in layers

```
Scene  ("pong")               one screen of the game
├── registry                  the DATA
│     position = { [2]={x,y}, [3]={x,y}, [4]={x,y} }
│     velocity = { [2]=..., [3]=..., [4]=... }
│     paddle   = { [2]=..., [3]=... }
│     ball     = { [4]={} }
│     match    = { [1]={left,right,winScore,state} }
└── systems                   the LOGIC, in frame order
      BallSpawnSystem, PaddleControlSystem, MovementSystem, ClampSystem,
      BounceWallsSystem, PaddleHitsSystem, ScoringSystem, RenderSystem
```

The **Registry** (`src/ecs/Registry.lua`) mirrors entt's registry from the
C++ course: pure component storage, no logic.

```lua
local entity = registry:spawn({ position = {x=0,y=0}, ball = {} })
registry:get(entity, "position")          -- read/write a component
registry:query("position", "velocity")    -- entities having ALL of these
registry:first("match")                   -- singleton lookup: entity, data
registry:destroy(entity)                  -- forget it in every store
```

Storage is **one table per component type**, indexed by entity — the
data-oriented layout from week 1. In C++ this is what makes ECS
cache-friendly; in Lua we keep the shape (and the mental model).

The **Scene** (`src/ecs/Scene.lua`) owns a registry plus an *ordered* list of
systems, and pumps them from `update`/`draw`. Right now the game has exactly
one scene; when scene switching arrives (menu → overworld → battle → date),
we'll add a Game layer that swaps scenes — the classes are already shaped
for it.

Systems receive the scene: `MovementSystem.update(scene, dt)` reaches the
data through `scene.registry` (and later, scene-level things like the camera).

A system is a plain table implementing any of **four lifecycle hooks**:

| Hook | When | Used here by |
|---|---|---|
| `setup(scene)` | once, when the scene starts | every system that owns something: `ScoringSystem` spawns the match, `PaddleControlSystem` the paddles, `BallSpawnSystem` the opening serve, `RenderSystem` its fonts |
| `update(scene, dt)` | every frame | the seven logic systems |
| `draw(scene)` | every frame | `RenderSystem` |
| `unload(scene)` | when the scene ends | `RenderSystem` drops its fonts (wired to `love.quit` for now) |

(Purist note: `setup`/`unload` aren't textbook ECS — but "each system creates
and cleans up what it owns" keeps main.lua from becoming a god-file, and it's
exactly the shape scene switching needs later.) The result: **main.lua spawns
zero entities.** It assembles the scene, forwards LÖVE's callbacks, and gets
out of the way.

## 3. Pong, decomposed

| Lesson 01 (OO) | Lesson 02 (ECS) |
|---|---|
| `Paddle` class | entity + `position, size, velocity, paddle, clamp` |
| `Ball` class | entity + `position, size, velocity, ball, bounceWalls` |
| `Ball.new()` / `Ball:reset()` | `BallSpawnSystem` + `serveRequest` events |
| `score` table in main.lua | entity + `match` (a **singleton component**) |
| `Paddle:update` | `PaddleControlSystem` + `MovementSystem` + `ClampSystem` |
| `Ball:update` | `MovementSystem` + `BounceWallsSystem` + `PaddleHitsSystem` |
| score check in `love.update` | `ScoringSystem` |
| the `draw` methods | one `RenderSystem` |
| object creation in `love.load` | each system's `setup()` creates what it owns |

Notice the systems are *tiny* — most are 15 lines. That's healthy ECS: many
small systems, each doing one thing to one query.

**System order is frame order** and it matters:

```
BallSpawnSystem      (consume serveRequest events, create balls)
PaddleControlSystem  (input -> velocity)
MovementSystem       (velocity -> position)
ClampSystem          (fix paddle positions)
BounceWallsSystem    (fix ball positions)
PaddleHitsSystem     (resolve collisions)
ScoringSystem        (react to what happened)
RenderSystem         (draw the final truth)
```

Swap `MovementSystem` and `ClampSystem` and paddles escape the screen for one
frame. Ordering bugs like this are an entire category of engine bugs — now
you know where to look for them.

## 4. How systems talk: events as entities

Systems never call each other, and they don't take parameters. They
communicate the ECS way: **by writing data into the registry**.

Watch a point being scored:

1. `ScoringSystem` sees a ball past the edge. It updates the score, destroys
   the ball, and spawns an entity with a single component:
   `serveRequest = { direction = -1 }`. That entity *is* the event.
2. Next frame, `BallSpawnSystem` queries `serveRequest`, destroys the request
   (consuming the event), and spawns a fresh ball toward that direction.

The B key and `love.load` request balls the exact same way — nobody knows how
balls are made except `BallSpawnSystem`. Later in the course this pattern
grows into damage events, dialogue triggers, and card effects. And note what
serving is now: the "ball" your paddle was hitting gets destroyed and a new
entity appears — nothing survived but data. Entities really are just numbers.

**Events have lifetimes — respect them.** The first version of this lesson
had a bug: scoring the *final* point emitted a `serveRequest`, but updates
stop on gameover, so nobody consumed it. It lingered in the registry and
hatched a ghost second ball in the next match. Deferred events are powerful,
but an event nobody consumes doesn't disappear — it waits. When you emit an
event, always ask: *who consumes this, and what if they never run?*

## 5. Naming conventions (course-wide from here on)

- Systems are `XxxSystem`, one per file, **file name = module name**
  (`src/systems/ScoringSystem.lua` returns `ScoringSystem`). Careful:
  Windows forgives wrong case in filenames, LÖVE's `require` does not —
  match them exactly or it breaks on someone else's machine.
- Entity variables: `entity` inside query loops, `ballEntity`-style when
  holding a specific one. Never call it `id` — say what it is.
- A table of components ready to spawn is a **prefab** (`matchPrefab`),
  never a `xxxEntity` — the entity is the *number* `spawn()` returns:
  `local matchEntity = registry:spawn(matchPrefab)`.
- Component names are lowercase nouns, unsuffixed: they only ever appear in
  registry contexts (`spawn` tables, `query`, `get`), where they can't be
  mistaken for anything else. Anything Uppercase is a module or a system.
- Modules and globals start uppercase; locals are `camelCase`.
- `require` everything once, at the top of the file.

## 6. The payoff: press B

Pressing B spawns a `serveRequest`, which becomes a ball entity with the same
components as the first one — and every system picks it up automatically.
Movement moves it, walls bounce it, paddles hit it, scoring scores it.
**Zero new logic.** Try adding a second ball to the lesson 01 code and count
how many places you must touch.

This is the property we'll lean on all semester: cards, characters, tiles,
dialogue portraits — all entities in the same registry, handled by systems
that don't know about each other.

## 7. What real ECS libraries add

Ours is deliberately minimal. Production ECS (entt, flecs, Bevy) adds:
archetype storage, cached queries, deferred spawn/despawn, richer event
plumbing, and parallel system scheduling. Same ideas, more engineering. If
you can read `Registry.lua`, you can read them.

## Exercises (for your own game repo)

1. Re-add lesson 01's `"serve"` state (ball frozen until SPACE). Where does
   that logic belong in this architecture?
2. Add a `lifetime` component and a system that despawns entities when it
   expires. Spawn a particle burst (a few tiny short-lived entities) when a
   point is scored.
3. `BallSpawnSystem` hard-codes the ball's components. Move them to a data
   table (a "prefab") so the system just instantiates it. We'll meet this
   idea again in the data-driven design week.
4. Our `query()` builds a new table every call, every frame. Measure it with
   1000 entities. How would you cache it? (Real ECS libraries do exactly this.)

## Next class

`03-RenderSystems-Camera` — system types, drawing images and backgrounds, and
a simple camera. The game starts looking like *our* game.
