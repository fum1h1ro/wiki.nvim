# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

wiki.nvim は Neovim 用のローカル Markdown Wiki プラグイン。`[[link]]` 記法で Markdown ファイル間をジャンプできる Obsidian 風のシンプルな Wiki 機能を提供する。

## Project Structure

- `init.lua` — プラグイン本体（設定、リンク解析、ナビゲーション、コマンド登録すべてを含む単一モジュール）
- `markdown.lua` — `[[link]]` のシンタックスハイライト定義

ビルドシステム・テストスイート・リンター設定は存在しない。純粋な Lua プラグインのため、Neovim の runtimepath に追加するだけで動作する。

## Architecture

単一の Lua モジュール (`M`) が全機能をエクスポートするシンプルな設計:

- **設定**: `M.config` テーブルに deep merge（`vim.tbl_deep_extend`）で適用
- **Autocmd 駆動**: `FileType markdown` でバッファローカルキーマップを自動設定
- **リンク解析**: Lua パターンマッチ (`%[%[(.-)%]%]`) でカーソル位置の `[[link]]` を抽出
- **バックリンク検索**: 外部コマンド `grep -rl` を使用（`vim.fn.systemlist`）
- **結果表示**: quickfix リストに集約して `copen`

## Development Notes

- ドキュメント・コメント・通知メッセージはすべて日本語
- スペースはハイフンに変換してファイルパスを解決（`resolve_link`）
- `create_if_missing = true` の場合、リンク先が存在しなければ `# title` 付きで自動作成
