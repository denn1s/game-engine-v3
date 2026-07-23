# Game Engine Architectures

One question, six answers: **where does behavior live?**

- `index.html` — Part 1: the six paradigms. Open in any browser
  (no server needed, both pages are self-contained).
- `part2.html` — Part 2: Unity, Unreal and Godot as *hybrids* of the
  six, the Rosetta stone table, and Pokémon architected per subsystem.
- `pong/01-procedural` … `pong/07-hybrid` — the same Pong, rebuilt
  seven times. Identical gameplay, identical constants, heavily-commented;
  the **only** variable is the architecture.

```sh
love lesson/pong/01-procedural
love lesson/pong/02-inheritance
love lesson/pong/03-components   # Unity's model — NOT ECS
love lesson/pong/04-events       # watch the flash; read the beeps
love lesson/pong/05-scenegraph   # hit the ball: the court shakes, the UI doesn't
love lesson/pong/06-ecs          # press B. keep pressing B.
love lesson/pong/07-hybrid       # ECS + events + a state machine, coexisting
```

Controls everywhere: `W/S` and `↑/↓`, first to 5, `SPACE` restarts,
`ESC` quits.

Read the demos side by side (`diff` two folders!). Each file's header
comment says what to notice and what question to bring to class.

Assigned material (linked from the pages): the Overwatch GDC talk and
Godot's "Why isn't Godot an ECS-based game engine?" article.
