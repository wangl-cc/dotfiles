; Based on the-mikedavis/tree-sitter-git-config/queries/highlights.scm
; Based on revision with git hash a01b498b25003d97a5f93b0da0e6f28307454347
; License: MIT
; URL: https://github.com/the-mikedavis/tree-sitter-git-config/blob/main/LICENSE

((section_name) @function.builtin
 (#eq? @function.builtin "include"))

((section_header
   (section_name) @function.builtin
   (subsection_name))
 (#eq? @function.builtin "includeIf"))

[ (true) (false) ] @boolean
(integer) @number
(string) @string
(comment) @comment @spell

(section_name) @tag
(section_header "\"" @string)
(subsection_name) @string
(name) @property

"=" @operator
[
 "["
 "]"
] @punctuation.bracket

