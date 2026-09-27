# 本機補丁

[janet-lsp-safe-def.patch](janet-lsp-safe-def.patch) 修正初始化式判斷誤用 `filter` 的問題。
基底 revision 與套用步驟由 [安裝腳本](../scripts/install-janet-lsp.sh) 維護；
原因與驗證見 [修復紀錄](../docs/janet-lsp.md)。
