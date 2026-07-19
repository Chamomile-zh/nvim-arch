; extends

(function_call
  name: (identifier) @_name
  (#eq? @_name "cmd")
  arguments: (arguments
    (string
      content: (string_content) @injection.content))
  (#set! injection.language "vim"))
