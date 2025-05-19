# json5-ts-mode - Major mode for JSON5

*Author:* ZHANG Weiyi <dochang@gmail.com><br>
*Version:* 0.0.0<br>
*URL:* [https://github.com/dochang/json5-ts-mode](https://github.com/dochang/json5-ts-mode)<br>

This package provides a tree-sitter major mode for editing JSON5 files.

## Installation

Requirements:

- Git
- C/C++ compiler

If your compiler is not `cc`, `gcc`, `c99`, `c++` or `g++`, check out the
documentation of `treesit-language-source-alist`.

### Check the availability of `tree-sitter`

```elisp
(treesit-available-p) ; should return t
```

### Install grammar

```elisp
(require 'treesit)
(add-to-list 'treesit-language-source-alist
             '(json5 "https://github.com/Joakker/tree-sitter-json5"))
```

Then run <kbd>M-x treesit-install-language-grammar</kbd>

### Install `json5-ts-mode`

```elisp
(add-to-list 'load-path "/path/to/json5-ts-mode")
(require 'json5-ts-mode)
(add-to-list 'auto-mode-alist
             '("\\.json5\\'" . json5-ts-mode))
```

## Customizations

### `json5-ts-mode-indent-offset`

Number of spaces for each indentation step in `json5-ts-mode`.

## Limitations

Currently this mode doesn't support multi-line strings because the grammar
doesn't support it.

## License

GPLv3


---
Converted from `json5-ts-mode.el` by [*el2markdown*](https://github.com/Lindydancer/el2markdown).
