# my_lazyvim_settings

個人使用的 [LazyVim](https://github.com/LazyVim/LazyVim) 設定。

## 自訂快捷鍵

`<leader>` 是 LazyVim 的 leader key，通常是 `<Space>`；`<localleader>` 設為 `,`。

| 快捷鍵 | 模式 | 功能 |
| --- | --- | --- |
| `<localleader>cb` | Normal | 預覽 C-Mera 輸出到側邊視窗 |
| `<localleader>cw` | Normal | 將 C-Mera 輸出寫到原始檔旁邊 |
| `<localleader>co` | Normal | 寫出 C-Mera 輸出並開啟產生的檔案 |
| `<localleader>cgr` | Normal | 對目前檔案執行 `codegen` |
| `<localleader>cgd` | Normal | 對目前檔案執行 `codegen --dry-run` |
| `<localleader>cgl` | Normal | 列出可用的 `codegen` rollback 備份 |
| `<localleader>cgR` | Normal | 使用 `codegen rollback` 還原目前檔案 |
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

## 語言環境

### Lisp 家族 REPL（Conjure）

`lua/plugins/` 下對下列 Lisp 方言設定了 [Conjure](https://github.com/Olical/conjure) REPL 與
[parinfer](https://github.com/eraserhd/parinfer-rust)（`smart` 模式自動維護括號）：

| 方言 | filetype | REPL 連線方式 | 需要先準備 |
| --- | --- | --- | --- |
| Common Lisp | `lisp` | swank `127.0.0.1:4005` | 在 Lisp 端啟動 swank server（如 SBCL + `ql:quickload :swank`） |
| Fennel | `fennel` | stdio，呼叫 `fennel` | 系統需有 `fennel` 可執行檔 |
| Hy | `hy` | stdio，呼叫 `hy -iu` | 系統需有 `hy` 可執行檔 |

Conjure 的鍵位前綴也是 `<localleader>`（`,`），與 C-Mera 的 `<localleader>c…` 不衝突（Conjure 不用 `c` 開頭）。常用鍵：

| 鍵（接在 `<localleader>` 後） | 功能 |
| --- | --- |
| `ee` / `er` | 求值游標所在 form / 最外層 root form |
| `ew` / `eb` / `ef` | 求值 word / buffer / 檔案 |
| `E` | 求值 visual 選取 |
| `e!` / `em` / `ep` | 求值並取代 / marked form / 上一次求值 |
| `ec…` | 上述的「求值並把結果寫成註解」變體 |
| `ls` / `lv` / `lt` / `lg` / `lq` | REPL log buffer：水平/垂直/分頁開、toggle、關閉 |
| `gd` / `K` | 跳定義 / 查文件 |

- **結構編輯（vim-sexp）已停用**（`cmera.lua` 對 `guns/vim-sexp` 與 regular-people mappings 設 `enabled=false`），所以 slurp/barf、括號跳轉等鍵未綁定；括號平衡改由 parinfer 自動處理（無鍵位）。
- 縮排交給 parinfer（`smart` 模式），未開啟內建 `'lisp'` 選項，避免兩套縮排邏輯互相覆寫。
- `.cmera` 副檔名會被視為 `lisp` filetype（語法高亮、parinfer 都套用），但**不會** format-on-save。
- Common Lisp 的 `lisp_format` 格式化需另外安裝對應執行檔，否則對 `.lisp` 存檔時會報錯。
- parinfer 需要 `cargo`（首次安裝會 `cargo build --release`）。

### GDScript（Godot）

GDScript 走 Godot editor 內建的 LSP（`lua/plugins/gdscript.lua`），連到 `127.0.0.1:6005`。
**必須先開著 Godot editor**，補全與診斷才會生效；只開 Neovim 不會有 LSP。

### 已啟用的 LazyVim extras

C/C++（clangd + cmake）、Python、Rust、TypeScript、Java、.NET/C#、Git、DAP、VS Code。
語言清單見 `lazyvim.json`。

## 其他慣例

- `localleader` 設為 `,`（`lua/config/options.lua`）。注意這會覆蓋內建的反向重複 `f`/`t` 動作。
- C-Mera 與 codegen 的指令/autocmd 由 `lua/config/keymaps.lua` 透過 `require` 載入。
