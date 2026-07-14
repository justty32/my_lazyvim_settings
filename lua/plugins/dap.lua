-- DAP：讓專案裡現成的 VSCode `.vscode/launch.json` 在 nvim 這邊也直接可用。
--
-- nvim-dap 會**自動、按需**讀取 cwd 底下的 `.vscode/launch.json`
-- （`dap.providers.configs["dap.launch.json"]`；舊的 `load_launchjs()` 已 deprecated），
-- 所以除錯設定不需要為 nvim 另外維護一份——前提是 launch.json 裡的 `"type"` 對得上
-- nvim 這邊註冊過的 adapter 名字。這個檔就是在補那層對應：
--
--   · cppdbg    ── VSCode 上是 cpptools（微軟的 C/C++ 擴充，走 gdb/MI）。Linux 這邊**改接
--                  codelldb**（LazyVim 的 clangd extra 已經裝好、接好），理由見下方「為什麼不用
--                  cpptools」。launch.json 的 `type` 一個字都不用改。
--
--   · lua-local ── tomblind/local-lua-debugger-vscode，純 Lua 除錯器、不需原生模組。
--                  ai_core 的 galtxt try_2 用它除錯 Lua 腳本（跑標準的 build/lua.exe，
--                  不是內嵌 Lua 的 host.exe——後者不吃除錯器要注入的 -e 引導）。
--
-- ★★ 為什麼不用 cpptools（踩過的坑，別再走回頭路）
--   mason 的對應表有 `cppdbg → cpptools`（mappings/source.lua），看起來「讓 cppdbg 就是真 cppdbg」
--   最漂亮——但 cpptools 是微軟那包 **~90MB 的 VSCode 擴充**，mason 從 GitHub release 抓它極慢且常斷。
--   而 codelldb 早就在（clangd extra 帶的）、功能完全夠用。取捨很清楚：不值得為了「type 名稱名副其實」
--   去扛一個 90MB 的下載。
--
--   ⚠ **但註冊 `cppdbg` 這個名字會招來 cpptools 的自動下載**：mason-nvim-dap 的
--     `automatic_installation` 掃的是 `dap.adapters` 的 **key**（見其 automatic_installation.lua），
--     看到 `cppdbg` 就去解析成 cpptools 套件、然後開始下載。所以下面必須用 `exclude` 明講別碰它，
--     否則每次開 nvim 都會在背景偷偷抓那 90MB。
--
--   ℹ 反過來說，`setup_handlers` 只對**已安裝**的套件動作——cpptools 沒裝，就不會有 handler 跑來
--     覆蓋我們自己註冊的 `cppdbg`。所以「別名會被蓋掉」這個顧慮只在 cpptools 真的裝了時才成立。
--
--   代價：codelldb（LLDB）不認得 launch.json 裡 cpptools/gdb 專屬的欄位——`MIMode`、
--   `miDebuggerPath`、`setupCommands`（`-enable-pretty-printing`、`set charset UTF-8`）會被忽略。
--   實務上沒差：LLDB 內建 STL 的整齊列印、UTF-8 也正常。那些欄位留著給 Windows 的 VSCode 用即可
--   （機器專屬路徑記得放進 launch.json 的 `"windows": { … }` 平台區塊——VSCode 與 nvim-dap 都支援
--   平台區塊，這是「一份 launch.json 兩台機器共用」的關鍵）。
--
-- ⚠ **nvim 不會跑 launch.json 的 `preLaunchTask`**（那是 VSCode tasks.json 的東西）。
--    所以在 nvim 裡除錯前要自己先建置（`./build.sh` 或 `cmake --build --preset …`）。
--
-- ⚠ node 要在 PATH 上，lua-local 這個 DA 才起得來（本機 node 由 fnm 管理——若從桌面啟動器開 nvim
--    而非從 shell，PATH 上可能沒有 node）。

local function mason_pkg(name)
  return vim.fn.stdpath("data") .. "/mason/packages/" .. name
end

-- ★★ Lua 5.5 相容性修補：local-lua-debugger-vscode（0.3.3）在 Lua 5.5 上根本載入不了。
--
-- 它注入被除錯行程的 `lldebugger.lua` 有這一段：
--     for path in scriptRootsStr:gmatch("[^;]+") do
--         path = Path.format(path) .. Path.separator      ← 對 for 的控制變數賦值
-- **Lua 5.5 把 generic for 的控制變數改成唯讀（const）**，所以這在 5.5 是**編譯期**錯誤——
-- 整個 lldebugger 模組載入失敗（`attempt to assign to const variable 'path'`），除錯器起不來。
-- 症狀很難懂：DAP session 起得來、中斷點還顯示 verified，然後程式就直接跑完結束，什麼都沒停。
-- （ai_core 的 galtxt try_2 vendored 的正是 Lua 5.5，所以一定中鏢。）
--
-- 這是上游還沒跟上 Lua 5.5，不是設定問題。修法只有一行（換個變數名），但檔案在 mason 的套件目錄下，
-- **mason 更新套件就會被覆蓋回去**——所以做成每次啟動時的**冪等修補**：比對到壞的樣子才改，
-- 已經修過、或哪天上游修好了，就是 no-op。
local function patch_lldebugger_for_lua55()
  local file = mason_pkg("local-lua-debugger-vscode") .. "/extension/debugger/lldebugger.lua"
  local fd = io.open(file, "r")
  if not fd then
    return
  end
  local src = fd:read("*a")
  fd:close()

  local bad = 'for path in scriptRootsStr:gmatch("[^;]+") do\n'
    .. "                    path = Path.format(path) .. Path.separator"
  local i, j = src:find(bad, 1, true)
  if not i then
    return -- 已修補，或上游已經修好
  end

  local good = 'for rawPath in scriptRootsStr:gmatch("[^;]+") do\n'
    .. "                    local path = Path.format(rawPath) .. Path.separator"
  local out = io.open(file, "w")
  if not out then
    return
  end
  out:write(src:sub(1, i - 1) .. good .. src:sub(j + 1))
  out:close()
  vim.notify("[dap] 已為 Lua 5.5 修補 lldebugger.lua（for 控制變數在 5.5 是唯讀的）", vim.log.levels.INFO)
end

return {
  {
    -- 叫 mason-nvim-dap 別因為我們註冊了 `cppdbg` 就跑去下載 cpptools（見檔頭）。
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = {
      automatic_installation = { exclude = { "cppdbg" } },
    },
  },
  {
    "mfussenegger/nvim-dap",
    optional = true,
    dependencies = {
      "mason-org/mason.nvim",
      -- lua-local 的後端。（cppdbg 走 codelldb，由 clangd extra 帶進來，不必列在這。）
      opts = { ensure_installed = { "local-lua-debugger-vscode" } },
    },
    opts = function()
      local dap = require("dap")

      -- ── cppdbg → codelldb
      -- 用 **function adapter**（nvim-dap 支援 adapter 是 function(callback, config)）——
      -- 好處是「要跑的當下」才去拿 codelldb 的設定，不必去猜 lazy.nvim 的 opts 誰先誰後。
      -- ⚠ 別在這裡直接抄一份 codelldb 的 table：
      --   ① opts 執行順序不保證——實測本檔的 opts 比 clangd extra 早跑，抄的時候 codelldb 還是 nil，
      --      只會抄到自己寫的 fallback。
      --   ② LazyVim clangd extra 那份設定帶 `host = "localhost"`，而 **codelldb 只監聽 127.0.0.1
      --      （純 IPv4）**；本機 getaddrinfo 先回 IPv6 的 ::1 → 連過去 ECONNREFUSED、除錯起不來。
      --      mason-nvim-dap 註冊的那份**不帶 host**（nvim-dap 預設 127.0.0.1），是對的，直接沿用它。
      if not dap.adapters["cppdbg"] then
        dap.adapters["cppdbg"] = function(callback, config)
          local codelldb = dap.adapters["codelldb"]
          if not codelldb then
            vim.notify("[dap] 找不到 codelldb adapter（cppdbg 靠它）", vim.log.levels.ERROR)
            return
          end
          if type(codelldb) == "function" then
            return codelldb(callback, config)
          end
          callback(codelldb)
        end
      end

      -- ── lua-local（local-lua-debugger-vscode）
      patch_lldebugger_for_lua55() -- 見檔案上方：不修的話它在 Lua 5.5 上載入不了
      if not dap.adapters["lua-local"] then
        -- 注意路徑真的有兩層 extension/：<pkg>/extension/extension/debugAdapter.js
        local ext_root = mason_pkg("local-lua-debugger-vscode") .. "/extension"
        dap.adapters["lua-local"] = {
          type = "executable",
          command = "node",
          args = { ext_root .. "/extension/debugAdapter.js" },
          -- 除錯器要知道自己的 extension 根目錄，才找得到它注入被除錯行程的那些 Lua 腳本。
          -- launch.json 裡不必寫 extensionPath，這裡補上。
          enrich_config = function(config, on_config)
            if not config["extensionPath"] then
              local c = vim.deepcopy(config)
              c.extensionPath = ext_root
              on_config(c)
            else
              on_config(config)
            end
          end,
        }
      end
    end,
  },
}
