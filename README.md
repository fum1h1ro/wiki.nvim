# wiki.nvim

ローカル Markdown Wiki プラグイン for Neovim

`[[hoge]]` と書くと `hoge.md` にジャンプできる、Obsidian 風のシンプルな Wiki 機能。

## インストール

### lazy.nvim

```lua
{
  "fum1h1ro/wiki.nvim",
  ft = "markdown",
  dependencies = {
    "nvim-telescope/telescope.nvim", -- オプション
  },
  opts = {
    root_dir = vim.fn.expand("~/wiki"), -- Wiki ファイルの場所
  },
}
```

### ローカルで試す

```lua
-- init.lua に追記
vim.opt.runtimepath:prepend(vim.fn.expand("~/path/to/wiki.nvim"))
require("wiki").setup({
  root_dir = vim.fn.expand("~/wiki"),
})
```

## 使い方

| キー | モード | 動作 |
|------|--------|------|
| `<CR>` | Normal | カーソル下の `[[link]]` を開く |
| `<BS>` | Normal | 前のファイルに戻る |
| `<Leader>wl` | Visual | 選択テキストを `[[link]]` で囲む |

## コマンド

| コマンド | 説明 | Telescope なし |
|----------|------|----------------|
| `:WikiFollow` | `[[link]]` をたどる | — |
| `:WikiBack` | 前のファイルに戻る | — |
| `:WikiFrontPage` | FrontPage を開く | — |
| `:WikiBacklinks` | 現在のファイルへのバックリンク検索 | quickfix にフォールバック |
| `:WikiLinks` | バッファ内の全リンク一覧 | quickfix にフォールバック |
| `:WikiPages` | Wiki ページ fuzzy 検索 | Telescope 必須 |
| `:WikiGrep` | Wiki 内全文検索 | Telescope 必須 |

## Telescope 連携

[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) がインストールされている場合、`:WikiBacklinks` / `:WikiLinks` / `:WikiPages` / `:WikiGrep` は自動的に Telescope picker を使用します。Telescope がなければ従来の quickfix にフォールバックします（`WikiPages` / `WikiGrep` は Telescope 必須）。

Telescope 拡張としても利用可能です:

```vim
:Telescope wiki backlinks
:Telescope wiki links
:Telescope wiki pages
:Telescope wiki grep
```

拡張を明示的にロードする場合:

```lua
require("telescope").load_extension("wiki")
```

## 設定

```lua
require("wiki").setup({
  root_dir = vim.fn.expand("~/wiki"),  -- Wiki ルート (default: cwd)
  extension = ".md",                    -- ファイル拡張子
  create_if_missing = true,             -- 存在しないファイルは自動作成
  use_telescope = true,                 -- Telescope が利用可能なら使用 (default: true)
  mappings = {
    follow_link = "<CR>",
    go_back = "<BS>",
    create_link = "<Leader>wl",
  },
})
```

## 機能

- **リンクジャンプ**: `[[hoge]]` にカーソルを置いて Enter → `hoge.md` を開く
- **自動作成**: リンク先が存在しなければ `# hoge` 付きで新規作成
- **サブディレクトリ対応**: `[[dir/page]]` → `dir/page.md`
- **バックリンク**: `:WikiBacklinks` で現在のファイルを参照している他ファイルを一覧
- **ページ検索**: `:WikiPages` で Wiki 内のページを fuzzy 検索
- **全文検索**: `:WikiGrep` で Wiki 内をリアルタイム全文検索
- **シンタックスハイライト**: `[[link]]` が下線付きリンク色で表示
- **戻る**: `<BS>` で前のバッファに戻る（ブラウザの戻るボタン的な）
