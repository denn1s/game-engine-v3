# Lesson 03 — Scenes and the Game layer

> PIA week 4 · Branch `03-Scenes` · Previous: `02-ECS`

```sh
love .
```

Pong is now a complete product: title screen → match → results → back to the
title. Same mechanics; the whole diff is architecture:

```sh
git diff 02-ECS..03-Scenes
```

## 1. The state machine grows up

Lesson 01 had a `state` variable (`"serve" | "play" | "gameover"`) and every
function branched on it. The README back then called it "the embryo of the
scene system". This is the payoff: each state is now a **Scene** — a full
screen of the game with its own registry and its own systems — and a **Game**
layer that owns them and switches between them.

```
Game
├── factories: menu, play, gameover     (how to BUILD each scene)
└── current scene                       (the one running right now)
```

Look at what got *deleted*: `match.state` is gone, the
`if state == "play"` gate in `love.update` is gone, the restart logic in
`keypressed` is gone. Nothing tracks "where we are" — being in a scene IS the
state. main.lua shrank to: register scenes, start, forward callbacks.

## 2. Scenes are factories, recreated fresh every entry

Each scene lives in its own file (`src/scenes/`) and exports a **factory** —
a function that builds the scene from scratch:

```lua
return function(payload)
    local scene = Scene.new("play")
    scene:addSystem(BallSpawnSystem)
    ...
    return scene
end
```

The Game never reuses a scene instance. Entering = `factory(payload)` then
`scene:setup()`; leaving = `scene:unload()`. A rematch isn't "reset all the
fields we can remember" — it's a brand-new scene where every system's
`setup()` runs again. **No stale state can survive a visit**, by
construction. (What *should* survive — decks, affection, progress, once the
real game arrives — will live in data outside the scenes, not in entities.
That's a coming lesson.)

## 3. Switching is requested through data — never called

No system calls `Game.switch()`. There is no such function to call. To
change scenes, a system spawns an event entity, same pattern as
`serveRequest`:

```lua
registry:spawn({
    switchRequest = {
        to = "gameover",
        payload = { left = match.left, right = match.right },
    },
})
```

`Game.update` runs the scene's frame **first**, and only then looks for a
request and performs the switch. Why deferred? Imagine switching in the
middle of an update: the current scene gets unloaded while its own systems
are still iterating its registry — logic running over a world that's being
demolished around it. Real engines defer scene transitions for exactly this
reason; ours does it in four lines.

The **payload** is how a dying scene sends data to the next one. The
gameover factory turns it into registry data (`finalScore`), and its render
system queries it like any other component. Payloads carry *transition*
data; they are not storage.

## 4. The bug that became impossible

Last lesson, scoring the final point left a stale `serveRequest` that
hatched a ghost ball in the next match. We patched it with a guard and a
restart sweep. **Both patches are deleted in this diff** — look for them.
The win now switches scenes, the play scene's registry is destroyed, and
the stale request dies with it. That's what good architecture does: it
doesn't fix bugs, it makes them *unrepresentable*. (The `match.state`
component also vanished — the scene graph absorbed it.)

## 5. New system hook: `keypressed`

Menus are *discrete* input — lesson 01's polling-vs-events distinction,
now with teeth: polling `isDown("space")` in the menu would fire again
next frame *inside the play scene*, because the key is still held while
the world changes underneath it. So input events flow
`love.keypressed → Game → scene:keypressed(key) → systems` and a system
opts in by implementing the hook:

- `MenuSystem.keypressed` — SPACE requests the play scene
- `GameOverSystem.keypressed` — SPACE requests the menu
- `DebugSystem.keypressed` — B requests an extra ball (main.lua's last
  entity-touching code, now a proper system)
- ESC lives in `Game.keypressed`: quitting is a Game concern, not a scene's

A system is now a table with up to five hooks:
`setup / update / draw / keypressed / unload`.

## 6. New responsibility, new system: WinCheckSystem

`ScoringSystem` awards points. Deciding what a finished match *means* —
leave the scene, carry the score out — is a different consequence, so it's
a different system, running right after. This split matters beyond
cleanliness: win conditions change per game mode (our card battles win by
HP, dates "win" by affection), while scoring-like bookkeeping stays stable.
Small systems with one consequence each are cheap to swap.

## 7. The smell we're keeping (on purpose)

Three render systems each create their own fonts in `setup` and drop
them in `unload`. It works, and the lifecycle is honest — but the
duplication smells, and loading the same asset every time a scene is
entered won't survive contact with real sprite sheets. Sit with the smell:
the **asset cache** lesson is coming, and now you know why it exists.

## Exercises (for your own game repo)

1. Add a "How to play" scene: reachable from the menu with H, returns with
   SPACE. Count how many existing files you had to touch (it should be: one
   new scene file, one new system, one `registerScene` line).
2. On the gameover screen, add R for an instant rematch (straight to play,
   skipping the menu). One line — which one, and in which system?
3. Add a 3-2-1 serve countdown to the play scene: a `countdown` component,
   a system that ticks it with `dt`, and balls that only move once it hits
   zero. (Last lesson's "serve state" exercise, scene-flavored.)
4. Two systems spawn a `switchRequest` on the same frame. What does our
   Game do? What *should* it do? (Read `Registry:first` before answering.)

## Next class

`04` — the card game begins: the real title screen, drawing images from
files, and the asset cache that kills the font smell.
