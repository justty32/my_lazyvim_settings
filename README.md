# my_lazyvim_settings

Personal [LazyVim](https://github.com/LazyVim/LazyVim) settings.

## Custom Keymaps

`<leader>` is the LazyVim leader key, normally `<Space>`.

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>cb` | Normal | Preview C-Mera output in a side window |
| `<leader>cp` | Normal | Preview C-Mera output in a side window |
| `<leader>cw` | Normal | Write C-Mera output next to the source file |
| `<leader>co` | Normal | Write C-Mera output and open the generated file |
| `<leader>cgr` | Normal | Run `codegen` on the current file |
| `<leader>cgd` | Normal | Run `codegen --dry-run` on the current file |
| `<leader>cgl` | Normal | List available `codegen` rollback backups |
| `<leader>cgR` | Normal | Roll back the current file with `codegen rollback` |
| `<leader>gg` | Normal | Open LazyGit |
| `<C-Up>` | Normal | Increase window height |
| `<C-Down>` | Normal | Decrease window height |
| `<C-Left>` | Normal | Decrease window width |
| `<C-Right>` | Normal | Increase window width |
| `jk` | Insert | Exit insert mode |
| `<C-s>` | Normal / Insert / Visual | Save current file |

## Custom Commands

### C-Mera

| Command | Purpose |
| --- | --- |
| `:CmeraPreview [generator]` | Run `cm` and preview stdout |
| `:CmeraWrite [generator]` | Run `cm -o` and write the generated output file |
| `:CmeraOpen [generator]` | Write output and open the generated file |
| `:CmeraBuild [generator]` | Backward-compatible alias for `:CmeraPreview` |

Supported generators include `c`, `c++`, `cxx`, `cuda`, `glsl`, `ocl`, and `opencl`.

### codegen

| Command | Purpose |
| --- | --- |
| `:CodegenRun [path...]` | Run codegen on paths, or the current file when no path is given |
| `:CodegenDryRun [path...]` | Run codegen in dry-run mode |
| `:CodegenRollbackList [path...]` | List rollback backups |
| `:CodegenRollback [path...]` | Restore from a codegen backup |

The codegen integration uses `~/repo/codegen/src` with `~/repo/codegen/.venv/bin/python` when available, so the `codegen` console script does not need to be installed globally.
