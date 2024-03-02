# fixquick.nvim ⚡💻

> *Gain control of the contents of your quickfix list. Modify it, use it, save it.*

> [!IMPORTANT]
> This is a work in progress.


## The problem

You open the quickfix list with a bunch of files (from Telescope... diagnostics... wherever)
and you want to exclude some of those files from the list. You can't. Quickfix is not modifiable.

But lets say you're crazy enough to run `:set modifiable` and you make some changes (`:g/tests/d`).
It works! **But not really**. Even though you can indeed modify it, it will remain useless. You press
enter on a file and it will open the one it was in that line before, ignoring your changes.

## The solution

*fixquick.nvim* makes your quickfix list modifiable like any file buffer and when you save it
it will make the changes permanent. Filtering

## Installation

Using *lazy.nvim*:

```lua
{
  "pablopunk/fixquick.nvim",
  event = "BufEnter"
}
```
