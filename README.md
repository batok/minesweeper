# Minesweeper

** Rest API Server in Elixir for a Minesweeper Mobile Client **

## Installation

This is an elixir rest api server, built with Plug and Cowboy.

You need elixir 1.4+ and erlang 19 installed in your computer.

Instructions to install both ( elixir and erlang ) depends on your computer OS.

```bash
$ git clone https://github.com/batok/minesweeper
$ cd minesweeper
$ mix deps.get
$ mix compile
```

If you want to start interactively this app do...

```bash
$ iex -S mix
```

Into iex REPL type
```
  Minesweeper.start(nil)
``` 

To stop the Api Server ctrl-c twice


