;; extends

;; C-Mera 關鍵字高亮。原本在 config/cmera.lua 用 `syntax keyword` 上色，
;; 但 treesitter highlight 啟用時傳統 syntax 會被停用，所以統一收在這裡。

((sym_lit) @keyword.directive
 (#any-of? @keyword.directive
   "include" "cpp" "pragma" "comment"))

((sym_lit) @keyword.function
 (#any-of? @keyword.function
   "function" "decl" "main" "for" "while" "if" "when" "cond"
   "switch" "return" "break" "continue"
   "class" "struct" "enum" "union" "typedef" "typename"
   "namespace" "using-namespace" "from-namespace"
   "template" "instantiate" "constructor" "destructor"))

((sym_lit) @keyword.modifier
 (#any-of? @keyword.modifier
   "const" "static" "inline" "virtual" "volatile" "pure"
   "private" "protected" "public" "signed" "unsigned"))

((sym_lit) @type.builtin
 (#any-of? @type.builtin
   "int" "char" "void" "float" "double" "long" "short"
   "bool" "size_t" "auto"))

((sym_lit) @function.builtin
 (#any-of? @function.builtin
   "printf" "cout" "endl" "sizeof"))

((sym_lit) @boolean
 (#any-of? @boolean
   "true" "false"))
