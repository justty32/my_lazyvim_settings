;; extends

((sym_lit) @keyword.directive
 (#any-of? @keyword.directive
   "include" "cpp" "pragma"))

((sym_lit) @keyword.function
 (#any-of? @keyword.function
   "function" "decl" "for" "while" "if" "when" "cond"
   "switch" "return" "break" "continue"
   "class" "namespace" "template" "instantiate" "constructor" "destructor"))

((sym_lit) @type.builtin
 (#any-of? @type.builtin
   "int" "char" "void" "float" "double" "long" "short"
   "unsigned" "signed" "bool" "size_t" "auto" "const" "static"))
