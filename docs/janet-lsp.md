# Janet LSP 初始化式修復

[回學習筆記](README.md)｜[操作說明](../README.md#janet-開發)

## 問題與修正

2026-09-27，本機原版 Janet LSP 在開檔分析時執行了 `def` 初始化式，可能觸發模型請求。
上游 `is-safe-def` 使用 `(filter ...)` 判斷是否含允許分析的標記；Janet 的空陣列也是真值，
所以 `or` 的第一項永遠放行。修正為 `(some ...)`，沒有標記時才能進入後面的安全性判斷。

[patch](../patches/janet-lsp-safe-def.patch) 只改這一個判斷。Janet 編譯器會先建立宣告的
binding／source map，因此不執行初始化式仍能保留變數名稱、函式補全和診斷。
動態計算出的實際值不會為了補全而執行，相關推論自然可能不完整。

本機使用與原版相同的上游基底版本；完整 revision 只維護在
[安裝腳本](../scripts/install-janet-lsp.sh)，不跟著 upstream HEAD 漂移。
原始碼來自 [CFiggers/janet-lsp](https://github.com/CFiggers/janet-lsp)，修復尚未提交上游。

## Neovim 使用獨立版本

- `scripts/install-janet-lsp.sh` 取得指定 revision、套用 patch、執行 evaluator 測試，再建置 image。
- 產物預設放在 `~/.local/share/nvim/janet-lsp-fixed/`，也支援 XDG_DATA_HOME／NVIM_APPNAME。
- [janet.lua](../lua/plugins/janet.lua) 只使用這個 image，缺少 image／依賴時保持停用，沒有原版 fallback。
- 不覆蓋 `~/.local/bin/janet-lsp` 或全域 Janet 套件，也不更動 VS Code。

建置需要既有的 Janet、jpm、git、bubblewrap，以及 Janet 模組 judge、cmd、spork。
腳本會檢查這些相依；不會暗中安裝或升級全域 Janet 模組。

```sh
cd ~/.config/nvim
scripts/install-janet-lsp.sh
python3 tests/janet-lsp-protocol.py
nvim --headless -i NONE '+luafile tests/conjure.lua'
```

第一次建置需要網路下載原始碼；平常啟動 LSP 不需要下載。
建置成功後重開 Neovim 即可；這次也已明確更新使用者當時開著的行程。
Janet runtime 升級後，如果舊 image 不相容，重新執行安裝腳本建置。

## 為什麼還有隔離啟動器

修掉初始化式判斷，不代表 Lisp 編譯永遠不執行程式：巨集展開、模組載入與
`.janet-lsp/startup.janet` 仍可能執行程式碼。
[啟動器](../scripts/janet-lsp) 因此使用 bubblewrap：

- 檔案系統唯讀，分析程序不能修改專案或使用者檔案。
- 獨立的網路 namespace，不可透過主機的 TCP/IP 網路呼叫本機模型服務或外部 API。
- 獨立 PID namespace；關閉父行程時一起結束。

這是 Linux 專用設定。編譯期要寫快取或連網的巨集可能收到診斷錯誤；不會為了讓它通過
而放寬限制。這也不是用來執行任意惡意程式的完整安全保證：程序仍可讀取檔案、消耗 CPU。
Conjure 的 Janet REPL 不走這個啟動器，使用者明確求值的程式仍可照常執行。

## 驗證證據

| 測試 | 核對什麼 |
| --- | --- |
| [evaluator 測試](../tests/janet-lsp-eval.janet) | 不靠隔離，確認 def／var／私有宣告、巢狀容器、解構初始化式不寫檔；保留 binding、函式和診斷 |
| [協定測試](../tests/janet-lsp-protocol.py) | 真實 initialize／didOpen／didChange、補全、hover、語法及未知符號診斷；巨集寫檔被拒，本機 HTTP 測試服務收到零次請求 |
| [Neovim 整合測試](../tests/conjure.lua) | 載入修正版啟動器，LSP hover、REPL、log 視窗與既有快捷鍵回歸 |

三層測試均通過。另在 `~/code/janet-try/la-1` 開啟實際檔案核對根目錄、啟動器和診斷，
結果為零診斷。這輪沒有對該檔案執行 Conjure 整檔求值。

先前「不少錯誤」的回報沒有保留原始訊息，仍不能把它全部歸因於這個問題。
