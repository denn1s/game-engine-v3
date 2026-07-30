# Lesson 05 — Game state: resources, serialization, the save file

> PIA week 6 · Branch `05-GameState` · Previous: `04.5-GameViewport`
>
> A small lesson on purpose. Before the card game starts generating
> state worth keeping (twelve weeks of stats, a whole card collection),
> pong donates its score one last time so we can build the machinery on
> something we already understand: a value escapes the entity world,
> becomes text, survives quitting the game, and greets you on the title
> screen.

```sh
love .             # win a match, quit, relaunch: the menu remembers
love . --debug     # watch the highscore resource appear in the inspector
```

```sh
git diff 04.5-GameViewport..05-GameState
```

## 1. The limit of "everything is an entity"

Since lesson 02 the answer to "where does data live?" has been *on an
entity*. The match score already cheated: `ScoringSystem` spawns an
entity whose only job is to carry the `match` component, and everyone
finds it with `registry:first("match")`. It works, but look at what
we're pretending: a score has no position, is never queried alongside
anything, and there is exactly one. That's not an entity — that's a
**global with an alibi**.

Real ECS engines admit this and give singletons their own concept. Bevy
calls them **resources**; ours is ten lines in `src/ecs/Registry.lua`:

```lua
registry:setResource("highscore", { winner = 5, loser = 2 })
local highscore = registry:resource("highscore")
```

Under the hood it *is* still a hidden singleton entity — which means the
debug inspector shows every resource for free, no new tooling. The point
of the API isn't the implementation, it's the **declaration**: code that
says `resource("finalScore")` tells the reader "there is one of these,
and it isn't a thing in the world."

The gameover scene's `finalScore` is the first convert. The `match`
component stays as-is — migrating it is exercise 1.

## 2. Serialization: code is data

To outlive a quit, a table has to become text. Lua ships no serializer,
and it doesn't apologize for it, because it has something better: **a
Lua table is already valid Lua syntax**. So `src/state/serialize.lua`
doesn't invent a format — it prints the table as Lua source, and
deserializing is just *running that text*:

```lua
serialize.encode({ bestVictory = { winner = 5, loser = 2 } })
-- "return {\n    bestVictory = {\n        loser = 2,\n        winner = 5,\n    },\n}"

local chunk = loadstring(text)   -- compile the string into a function
local data = chunk()             -- run it; the table comes back
```

Thirty lines of recursion, three decisions worth reading:

- **Plain data only.** Numbers, strings, booleans, tables of those. A
  function or an Image can't be written down as source, so hitting one
  is an `error()`, not a shrug — a save you can't write is a bug in
  *what you tried to save*. This rule is why the GDD's `RunState` will
  hold no functions, no images, no scene references: state that follows
  the rule serializes for free, forever.
- **Sorted keys.** `pairs()` order is undefined; sorting makes the same
  table always print the same file. Stable output means save files diff
  cleanly — you can `git diff` your own save while tuning.
- **`decode` never throws.** `loadstring` + `pcall`, and anything
  suspicious returns `nil`. A corrupt file is the *caller's* decision
  (start fresh), not a crash five layers down.

And one warning for later: `loadstring` on a file **executes** that
file. For your own save directory that's fine; for anything a stranger
can hand you (downloaded saves, network data) it's an arbitrary-code
vulnerability, and you'd reach for a data-only format instead. Know
which one you're holding.

## 3. `love.filesystem`, or: never write next to the executable

`src/state/SaveFile.lua` owns the file itself, through `love.filesystem`
— never `io.open`. LÖVE gives every game a per-user **save directory**
(named by the new `t.identity` in `conf.lua`) and writes there and
nowhere else. Why not just write `./save.lua`? Because on a machine that
isn't yours, the game's folder is read-only (`/usr/bin`, `Program
Files`), shared between users, and wiped by every update. Every engine
draws this line; LÖVE just refuses to let you cross it.

The other habit worth forming on day one:

```lua
{ version = 1, bestVictory = { winner = 5, loser = 2 } }
```

Every save carries a **version**. The day the data changes shape, old
files announce what they are and can be migrated — or at worst detected
and discarded — instead of exploding somewhere deep in a scene.
`SaveFile.load()` returns `nil` for first-run, corrupt, *and*
wrong-version files alike: to the caller, all three mean "start fresh."

## 4. The wiring: nothing on screen is remembered

`src/systems/HighscoreSystem.lua` runs in the gameover scene — and only
in `setup`, because the match is already history by the time the scene
exists; there is nothing to do per-frame. It reads the `finalScore`
resource, compares the winning *margin* against the file (5–0 beats
5–2), writes a new best, and publishes a `highscore` resource for the
render system (`isNew` decides between "a new best victory!" and the
plain line).

The title screen closes the loop, and one sentence in `MenuScene.lua`
is the actual lesson:

> The save file is the only thing that survives between scenes. The
> title screen reads it fresh every time it's built — nothing on screen
> is ever "remembered", it's all rebuilt from data.

Scene factories build from scratch (lesson 03), the Game carries no
payload here, and yet the menu knows. That's the architecture the GDD
demands — "the save file **is** the run state" — running at pong scale.

One guard worth noticing: the debug scene switcher can jump straight to
gameover with no payload, so a 0–0 "match" must not become a highscore.
A scene you can enter directly is a scene that gets entered with
garbage; defaults are not enough, the *logic* has to survive them too.

## Exercises (for your own game repo)

1. **Migrate `match`.** `ScoringSystem` still hand-rolls its singleton.
   Move it to `setResource`/`resource` and delete the prefab comment —
   does anything else break? (The debug inspector shouldn't even
   notice.)
2. **Corrupt it on purpose.** Find your save file
   (`print(love.filesystem.getSaveDirectory())`), open it, and vandalize
   it — delete a brace, change `version` to 99, replace the whole thing
   with a poem. The game must start fresh every time, never crash.
3. **A settings resource.** Add a persistent `settings` table (say,
   paddle speed) that saves alongside `bestVictory` in the *same* file.
   What does `SaveFile.save` need so the two owners don't overwrite each
   other's keys?
4. **Version 2.** Change the highscore to store the *last five*
   victories instead of one. Bump `VERSION`, then write a real
   migration: a v1 file should convert, not be discarded. When is
   discarding actually the right call?
5. **The serializer's blind spot.** Our encoder ignores the array part
   mixed with holes and cycles (`t.self = t` recurses forever). Make
   cycles an `error("cycle detected")` instead of a stack overflow.

## Next class

`06` — the card game begins for real: the 640×400 canvas from the GDD,
the real title screen, and the Week scene's first layout. The `RunState`
you'll build there is this lesson's save file with more fields.
