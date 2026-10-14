<h1 align="center">
  <br>
<img src=".assets/readme/heading.png" alt="neovim" width="600"></a>
  <br>
</h1>

<h4 align="center">
<a href="https://www.robbow.land" target="_blank">My</a> <a href="https://github.com/neovim/neovim" target="_blank">neovim</a> configuration for simplicity, consistency & functionality.<br>Standing on the shoulders of <a href="https://github.com/LazyVim/LazyVim" target="_blank">LazyVim</a>💤.
</h4>

## Themes

The default is the local `micrographics` colorscheme, which uses pure-invert surfaces, grayscale scaffolding, and canonical success and danger accents for compact state signals. Diffview keeps the source body identical to a normal file and marks changed lines with narrow add/remove gutters. The previous `github_dark_default` theme remains installed as a fallback.

Use `:set background=light | colorscheme micrographics` for positive polarity, or switch back at any time with `:colorscheme github_dark_default`.

`:MicrographicsPunctuation` toggles punctuation between the default faint treatment and full ink. Use `:MicrographicsPunctuation faint` or `:MicrographicsPunctuation ink` to select a mode explicitly.

## Git diffs

[diffview-plus](https://github.com/dlyongemallo/diffview-plus.nvim), the maintained fork of Diffview, owns the side-by-side review mappings while LazyVim keeps `<leader>gf` for its file-history picker. With weaver installed, the working-tree, full-branch and PR views share one review tab: pressing a mapping again from elsewhere returns to its view, pressing it inside the view closes it, and another mapping replaces it. Without weaver they open plain Diffview tabs.

| Mapping | View |
| --- | --- |
| `<leader>gd` | Working tree and index |
| `<leader>gD` | Full branch against the remote's default branch, including local changes |
| `<leader>gA` | Full branch grouped by commit, with local changes |
| `<leader>gV` | Current pull-request layer against its GitHub base |
| `<leader>gF` | Current-file history, including local changes |
| `<leader>gR` | Current-file history following renames, including local changes |
| `<leader>gH` | All-file history |
| `<leader>gm` | Previous commit against the working tree |
| `<leader>gM` | Previous commit against `HEAD` |
| `<leader>gq` | Close Diffview |

The full-branch base is the `upstream` or `origin` default branch (where its `HEAD` points, else `main` or `master`), else a local `main` or `master`; without weaver it is `origin/HEAD`. With weaver, `gf` in any Diffview opens the file at the same line in the tab of its own worktree. PR-layer diffs and PR numbers in the status line require an authenticated GitHub CLI. In the file panel, `-` or `s` toggles staging and `S` stages everything; unresolved conflict markers require confirmation. `<leader>cw` saves the resolved merge file. Closed unchanged sections appear as full-width labelled dividers showing the hidden count and file-line range; `zO` expands one, `zR` expands all, and `zM` collapses all. Large diff buffers disable expensive editor services, while the existing right-hand file panel and Micrographics gutter-only change highlighting remain unchanged.

<p align="center">
  <a>sections</a> •
  <a>to</a> •
  <a>come</a> •
  <a>later</a>
</p>
