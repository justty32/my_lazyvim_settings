# my_lazyvim_settings

個人使用的 [LazyVim](https://github.com/LazyVim/LazyVim) 設定。

## 自訂快捷鍵

`<leader>` 是 LazyVim 的 leader key，通常是 `<Space>`。

| 快捷鍵 | 模式 | 功能 |
| --- | --- | --- |
| `<leader>cb` | Normal | 預覽 C-Mera 輸出到側邊視窗 |
| `<leader>cw` | Normal | 將 C-Mera 輸出寫到原始檔旁邊 |
| `<leader>co` | Normal | 寫出 C-Mera 輸出並開啟產生的檔案 |
| `<leader>cgr` | Normal | 對目前檔案執行 `codegen` |
| `<leader>cgd` | Normal | 對目前檔案執行 `codegen --dry-run` |
| `<leader>cgl` | Normal | 列出可用的 `codegen` rollback 備份 |
| `<leader>cgR` | Normal | 使用 `codegen rollback` 還原目前檔案 |
| `<leader>gg` | Normal | 開啟 LazyGit |
| `<C-Up>` | Normal | 增加視窗高度 |
| `<C-Down>` | Normal | 減少視窗高度 |
| `<C-Left>` | Normal | 減少視窗寬度 |
| `<C-Right>` | Normal | 增加視窗寬度 |
| `jk` | Insert | 離開 insert mode |
| `<C-s>` | Normal / Insert / Visual | 儲存目前檔案 |

## 自訂命令

### C-Mera

| 命令 | 功能 |
| --- | --- |
| `:CmeraPreview [generator]` | 執行 `cm` 並預覽 stdout |
| `:CmeraWrite [generator]` | 執行 `cm` 並將 stdout 寫成產生檔 |
| `:CmeraOpen [generator]` | 寫出輸出並開啟產生的檔案 |

支援的 generator 包含 `c`、`c++`、`cxx`、`cuda`、`glsl`、`ocl`、`opencl`。
`:CmeraBuild [generator]` 保留為相容舊設定的別名，等同 `:CmeraPreview [generator]`。

### codegen

| 命令 | 功能 |
| --- | --- |
| `:CodegenRun [path...]` | 對指定路徑執行 codegen；未指定時使用目前檔案 |
| `:CodegenDryRun [path...]` | 以 dry-run 模式執行 codegen |
| `:CodegenRollbackList [path...]` | 列出 rollback 備份 |
| `:CodegenRollback [path...]` | 從 codegen 備份還原 |

codegen 整合會優先使用 `~/repo/codegen/src` 搭配 `~/repo/codegen/.venv/bin/python`，因此不需要把 `codegen` console script 安裝到全域環境。
