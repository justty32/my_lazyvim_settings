# my_lazyvim_settings

個人使用的 [LazyVim](https://github.com/LazyVim/LazyVim) 設定。

## 安裝與套用

Neovim 實際載入的預設設定目錄是 `~/.config/nvim`。若此 repository 位於其他路徑，
需要將它連結或同步到該目錄；只修改 repository 不會自動影響目前使用中的 Neovim。

以 symbolic link 安裝：

```sh
mv ~/.config/nvim ~/.config/nvim.bak
ln -s /path/to/my_lazyvim_settings ~/.config/nvim
```

若不使用 symbolic link，更新設定後需自行將變更同步到 `~/.config/nvim`。

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
| `jk` | Insert | 離開 insert mode |

LazyGit（`<leader>gg`）、視窗大小調整（`<C-方向鍵>`）與存檔（`<C-s>`）由 LazyVim 內建鍵位提供，
不在此 repository 另行定義。

## 自訂命令

### C-Mera

| 命令 | 功能 |
| --- | --- |
| `:CmeraPreview [generator]` | 執行 `cm` 並預覽 stdout |
| `:CmeraWrite [generator]` | 執行 `cm` 並將 stdout 寫成產生檔 |
| `:CmeraOpen [generator]` | 寫出輸出並開啟產生的檔案 |

支援的 generator 包含 `c`、`c++`、`cxx`、`cuda`、`glsl`、`ocl`、`opencl`。
`:CmeraBuild [generator]` 保留為相容舊設定的別名，等同 `:CmeraPreview [generator]`。

重複執行 `:CmeraPreview` 會更新同一個 preview 視窗（關掉後 buffer 仍保留重用），不會疊出多個視窗。

### codegen

| 命令 | 功能 |
| --- | --- |
| `:CodegenRun [path...]` | 對指定路徑執行 codegen；未指定時使用目前檔案 |
| `:CodegenDryRun [path...]` | 以 dry-run 模式執行 codegen |
| `:CodegenRollbackList [path...]` | 列出 rollback 備份 |
| `:CodegenRollback [path...]` | 從 codegen 備份還原 |

codegen 整合會優先使用 `~/repo/codegen/src` 搭配 `~/repo/codegen/.venv/bin/python`，因此不需要把 `codegen` console script 安裝到全域環境。repo 位置可用環境變數 `CODEGEN_REPO` 覆蓋（未設定時 fallback 到 `~/repo/codegen`）。

## 語言環境

### Lisp 家族 REPL（Conjure）

`lua/plugins/` 下對下列 Lisp 方言設定了 [Conjure](https://github.com/Olical/conjure) REPL 與
[parinfer](https://github.com/eraserhd/parinfer-rust)（`smart` 模式自動維護括號）：

| 方言 | filetype | REPL 連線方式 | 需要先準備 |
| --- | --- | --- | --- |
| Common Lisp | `lisp` | Swank `127.0.0.1:4005` | SBCL、Quicklisp、Swank；本機以 systemd user service 常駐 |
| Fennel | `fennel` | stdio，呼叫 `fennel` | 系統需有 `fennel` 可執行檔 |
| Hy | `hy` | stdio，呼叫 `hy -iu` | 系統需有 `hy` 可執行檔 |
| Scheme（s7） | `scheme` | stdio，呼叫 s7 的 REPL | 見下方「Scheme（s7）」 |

#### Scheme（s7）

`lua/plugins/scheme.lua`。Conjure 內建的 scheme stdio client 預設指向 `mit-scheme`，這裡改指到
**s7**（`ai_core` 的 galtxt try_1 那條線用的就是 s7，開發哲學是「REPL 一直開、邊寫邊試」）。

s7 的 REPL 二進位**不在任何 repo 裡**（s7 原始碼不託管），先自己編出來：

```sh
cd ~/repo/pas/derived/s7-playground
bash setup.sh    # 從 ccrma 抓 s7.c / s7.h 與隨附庫
bash build.sh    # → ./s7
```

指令路徑的解析順序：`$S7_REPL` → `~/repo/pas/derived/s7-playground/s7` → PATH 上的 `s7`。
換機器或放別的地方，設 `S7_REPL` 環境變數即可（與 galtxt `try_1/build.sh` 找 s7 原始碼時
`$S7_DIR` 是同一套慣例）。prompt pattern 設成 `"> "`（s7 的提示字元，Conjure 預設那個是給
mit-scheme 的、對不上）。

- **用法**：`cd` 到 `try_1` 再開 nvim——Conjure 的 stdio client 是在 nvim 的 cwd 起 s7，
  腳本裡 `(load "llm.scm")` 這種相對路徑才對得上。然後 `,ee` 求值游標所在 form、`,ls` 開 REPL log。
- ⚠ **別去編 `libc_s7.so`**：有它的話 s7 的 REPL 會啟用終端控制碼的花俏模式，跳脫序列會汙染
  Conjure 的 stdio 管線。沒有它 s7 只是印一行 `load … failed` 的警告、退回純文字 REPL——那正是要的。

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

- **未安裝結構編輯 plugin**（vim-sexp 之類），所以 slurp/barf、括號跳轉等鍵不存在；括號平衡由 parinfer 自動處理（無鍵位）。
- Conjure 的 log HUD（右上角浮動視窗）已停用，避免求值時擋到程式碼；要看 log 用 `,ls` / `,lv` 開 log buffer。
- C-Mera 關鍵字（`function`、`decl`、`int` 等）的高亮由 `queries/commonlisp/highlights.scm` 的 treesitter query 提供。
- Lisp、Clojure、Scheme、Racket、Fennel、Hy 與 Janet 啟用 rainbow-delimiters，以不同顏色顯示巢狀括號。
- 縮排交給 parinfer（`smart` 模式），未開啟內建 `'lisp'` 選項，避免兩套縮排邏輯互相覆寫。
- `.cmera` 副檔名會被視為 `lisp` filetype（語法高亮、parinfer 都套用），但**不會** format-on-save。
- Common Lisp 不執行 format-on-save；縮排與括號結構完全交給 parinfer，避免 formatter
  重排整個 buffer 後與 parinfer 的結果互相覆寫。
- parinfer 需要 `cargo`（首次安裝會 `cargo build --release`）。

#### Common Lisp / Swank 工作流程

本機將 Swank 設為 systemd user service，開機後由 SBCL 載入 Quicklisp 與 Swank，並只在
loopback interface 的 `127.0.0.1:4005` 上監聽：

```text
systemd --user → SBCL → Quicklisp → Swank → 127.0.0.1:4005
```

相關的本機檔案（不屬於此 repository）：

```text
~/.config/common-lisp/swank-server.lisp
~/.config/systemd/user/swank.service
```

service 已透過以下設定啟用：

```bash
systemctl --user enable --now swank.service
loginctl enable-linger "$USER"
```

`enable-linger` 讓 user service 可在開機後、使用者尚未登入圖形桌面時啟動。常用管理指令：

```bash
systemctl --user status swank
systemctl --user restart swank
journalctl --user -u swank -f
```

Conjure 的 `client_on_load` 設為 `false`，所以開啟 `.lisp` 後不會自動連線。按 `,cc` 或執行
`:ConjureConnect` 連上 Swank；按 `,cd` 中斷連線。

這個全域常駐 Lisp image 適合學習、快速求值與個人工具。正式專案通常會各自啟動 SBCL、
載入該專案的 ASDF system，再啟動專案專用的 Swank；這能避免不同專案共用 package、
全域變數及已載入依賴。若同時開啟多個專案，應為各專案使用不同 port。

#### 為何 Lisp 不使用 format-on-save

parinfer 會在編輯過程中根據縮排維護括號結構，而整檔 formatter 會在存檔時重新排版。
兩者同時啟用可能造成縮排跳動、括號位置被再次改寫，或 buffer 與預期結構不一致。

因此 `lua/plugins/formatting.lua` 將 Lisp formatter 明確設為空清單：

```lua
formatters_by_ft = {
  lisp = {},
}
```

這不是停用 Conform 的其他語言格式化功能；只有 `lisp` filetype 不執行整檔 formatter。

### GDScript（Godot）

GDScript 走 Godot editor 內建的 LSP（`lua/plugins/gdscript.lua`），連到 `127.0.0.1:6005`。
**必須先開著 Godot editor**，補全與診斷才會生效；只開 Neovim 不會有 LSP。

除錯走 Godot editor 內建的 DAP（`127.0.0.1:6006`，同樣要求 editor 開著）。在 `.gd` 檔設好斷點後，
用 LazyVim 的 DAP 鍵位（`<leader>db` 設斷點、`<leader>dc` 啟動/繼續）即可透過 Godot 啟動場景除錯。

Treesitter 另外安裝了 `gdshader` parser，`.gdshader` 檔有語法高亮。

### 除錯：直接吃專案裡的 VSCode `launch.json`

`lua/plugins/dap.lua`。nvim-dap 會**自動、按需**讀取 cwd 底下的 `.vscode/launch.json`
（`dap.providers.configs["dap.launch.json"]`），所以**除錯設定不必為 nvim 另外維護一份**——
`cd` 到專案再開 nvim，`<leader>dc` 就會列出 launch.json 裡的設定。前提是 `"type"` 對得上
nvim 這邊註冊過的 adapter，這個檔就是在補那層對應：

| launch.json 的 `type` | 後端 | 怎麼來的 |
| --- | --- | --- |
| `cppdbg` | cpptools（gdb/MI） | mason-nvim-dap 的對應表本來就有 `cppdbg → cpptools`，只要把 `cpptools` 列進 mason 的 `ensure_installed` 即可 |
| `lua-local` | [local-lua-debugger-vscode](https://github.com/tomblind/local-lua-debugger-vscode)（純 Lua、不需原生模組） | **不在** mason-nvim-dap 的對應表裡，adapter 在 `dap.lua` 手動註冊 |

- **別把 `cppdbg` 別名到 codelldb**：mason-nvim-dap 開了 `automatic_installation`，它的 handler 會在
  你的 `opts` 之後跑、把別名蓋掉，白費工。讓 `cppdbg` 就是真的 cppdbg 還有個好處——launch.json 裡的
  `setupCommands`（gdb 整齊列印、UTF-8 字元集）原樣生效，與 Windows 同語意。
- **機器專屬路徑要放平台區塊**：launch.json 支援 `"windows"` / `"linux"` / `"osx"` 子物件，該平台的鍵
  會被合併到頂層（VSCode 與 nvim-dap 都支援）。所以像 `miDebuggerPath` 這種寫死 Windows gdb 路徑的欄位
  要塞進 `"windows": { … }`——Linux 側不給，cpptools 就用 PATH 上的 `gdb`。**一份 launch.json 兩台機器共用**
  的關鍵就在這。
- ⚠ **nvim 不會跑 `preLaunchTask`**（那是 VSCode `tasks.json` 的機制）——除錯前要自己先建置。
- ⚠ `lua-local` 需要 `node` 在 PATH 上（本機 node 由 fnm 管理，從桌面啟動器開的 nvim 可能沒有）。

### 已啟用的 LazyVim extras

C/C++（clangd + cmake）、Python、Rust、TypeScript、Java、.NET/C#、JSON、Markdown、TOML、YAML、
Git、DAP、Testing（neotest）、VS Code。清單見 `lazyvim.json`。

## 其他慣例

- `localleader` 設為 `,`（`lua/config/options.lua`）。注意這會覆蓋內建的反向重複 `f`/`t` 動作。
- C-Mera 與 codegen 的指令/autocmd 由 `lua/config/keymaps.lua` 透過 `require` 載入。
- 已移除 LazyVim 的 `lazyvim_wrap_spell` autocmd，因此 Markdown、純文字、Typst、TeX 與 Git commit
  buffer 預設不會啟用 Neovim 拼字檢查。可用 `:set spell` 暫時開啟，或用
  `<leader>us` 切換。
