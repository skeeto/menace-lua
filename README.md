# MENACE (Tic-Tac-Toe) in Lua

This is a software implementation of the [Machine Educable Noughts And
Crosses Engine][video] (MENACE) in **Lua 5.3**. It can play against
itself or against a human opponent. Either way it learns from each game
it plays.

The "brain" is persisted between sessions in a Lua source file named
`brain.lua` by default. In interactive mode (`-i`) it saves the brain
after each game, so it's save to <kbd>C-c</kbd> out of it when you're
done.

While this program only currently has an implementation for Tic-Tac-Toe,
its MENACE implementation can play any game that provides an appropriate
"state" interface (documented in the source).

## Creating a usable brain

Unfortunately it doesn't seem to learn much just playing against itself
and needs some help. I've had the most success *seeding* the brain by
playing some games against it first, being careful to exercise different
game states. When it starts to get the hang of the game, I then pit it
against itself. I've never gotten it to the point of perfect play.

```
# Play against it repeatedly until it starts to show some smarts
$ lua menace.lua -i

# Then play a million games against itself
# lua menace.lua -n 1000000

# Finally see if it got any smarter
$ lua menace.lua -i
```

The learning rate for the brain is reduced when it plays itself — the
initial number of beads is increaed — and this change is permanent. It's
a waste of time to attempt train the brain manually after it's been
playing against itself.

[video]: https://www.youtube.com/watch?v=R9c-_neaxeU
