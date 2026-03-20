# wiki.nvim

ローカル Markdown Wiki プラグイン for Neovim

`[[hoge]]` と書くと `hoge.md` にジャンプできる、Obsidian 風のシンプルな Wiki 機能。

## インストール

### lazy.nvim

```lua
{
  "your-name/wiki.nvim",
  ft = "markdown",
  opts = {
    root_dir = vim.fn.expand("~/wiki"), -- Wiki ファイルの場所
  },
}
```

### ローカルで試す

```lua
-- init.lua に追記
vim.opt.runtimepath:prepend("~/path/to/wiki.nvim")
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

| コマンド | 説明 |
|----------|------|
| `:WikiFollow` | `[[link]]` をたどる |
| `:WikiBack` | 前のファイルに戻る |
| `:WikiBacklinks` | 現在のファイルへのバックリンクを quickfix に表示 |
| `:WikiLinks` | バッファ内の全リンクを quickfix に表示 |

## 設定

```lua
require("wiki").setup({
  root_dir = vim.fn.expand("~/wiki"),  -- Wiki ルート (default: cwd)
  extension = ".md",                    -- ファイル拡張子
  create_if_missing = true,             -- 存在しないファイルは自動作成
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
- **シンタックスハイライト**: `[[link]]` が下線付きリンク色で表示
- **戻る**: `<BS>` で前のバッファに戻る（ブラウザの戻るボタン的な）
