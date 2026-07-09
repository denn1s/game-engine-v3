# Game Engine Architecture — v3 (2026)

Course repository for **CC3096 — Game Engine Architecture**.

This year's stack, chosen by the class: **Lua + [LÖVE](https://love2d.org) 11.5**.

This year's game, voted by the class: a **card game with dating-sim elements**,
connected by a small explorable overworld. (Yes, really. It's going to be great.)

## How this repository works

I build one game from scratch during the semester, live in class. Students build
their own game in parallel, with their own twist, following the same lessons.

Each lesson lives in its own numbered **git branch**, and every branch builds on
top of the previous one:

```
main → 00-GameLoops → 01-Pong → 02-ECS → ...
```

- The **code on a branch** is the state of the game at the end of that class.
- The **README on a branch** contains that lesson's notes.
- The **diff between two branches** is exactly what we write together in class:

```sh
git diff 01-Pong..02-ECS
```

## Branches

| Branch | PIA week | Topic |
|---|---|---|
| `00-GameLoops` | 2 | Game loops with no engine at all, frame control, `dt` |
| `01-Pong` | 2–3 | **Lab 1:** Pong from scratch |
| `02-ECS` | 3 | **Lab 2:** Pong on a hand-written ECS: Registry, Scene, Systems, events |
| `03-Scenes` | 4 | The Game layer: scene factories, deferred switching, payloads |

More branches appear as the semester advances.

## Running

Install [LÖVE 11.5](https://love2d.org), then from the repo root:

```sh
love .
```

On Windows you can also drag the folder onto `love.exe`.
