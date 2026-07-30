# CLAUDE.md

## What this repo is

Course repository for **CC3096 — Game Engine Architecture** (UVG). The instructor builds one game from scratch, live in class, in **Lua + LÖVE 11.5**; students follow along building their own games with the same lessons.

The game proper is **"Small Talk"**, a raising sim + card battler with dating-sim elements (Tokimeki Memorial shrunk to jam size): 12 in-game weeks of training hidden stats (Int/Charm/Sense) → weekly booster packs of conversation-topic cards → dates fought as card battles on a complement-don't-compete rock-paper-scissors triangle. Full design in `docs/GDD.md`; schedule in `docs/LESSON_PLAN.md`.

## Branch organization

Each lesson is a numbered git branch, each building on the previous:
`main → 00-GameLoops → 01-Pong → 02-ECS → 03-Scenes → 04-DebugTools → 04.5-GameViewport → 05-GameState → ...`

- The **code on a branch** is the state of the game at the end of that class.
- The **README.md on a branch** is that lesson's notes (so the README changes per branch; `main`'s README describes the repo itself).
- The **diff between consecutive branches** is exactly what gets written in class: `git diff 01-Pong..02-ECS`.

Early branches use pong as the teaching vehicle; the card game begins around lesson 06.

## Design principle: atomic systems

For the development of the game proper (not the pong demo — that one doesn't matter), keep ECS systems as atomic as possible. Instead of a catch-all system (e.g. one big "render" system), prefer many small, dedicated systems with a single responsibility (e.g. separate systems for sprites, text, debug shapes, etc.).

The reason is pedagogical: each system should be easy to explain and buildable one by one with students. When adding a feature, ask whether it can be its own small system before extending an existing one.
