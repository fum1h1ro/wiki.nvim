local M = {}

M.config = {
  -- wiki ファイルのルートディレクトリ（nil なら現在の cwd を使用）
  root_dir = nil,
  -- リンク先ファイルの拡張子
  extension = ".md",
  -- ファイルが存在しない場合に自動作成するか
  create_if_missing = true,
  -- Telescope が利用可能なら使用する（false で常に quickfix）
  use_telescope = true,
  -- キーマップ
  mappings = {
    follow_link = "<CR>",   -- リンクをたどる
    go_back = "<BS>",       -- 前のファイルに戻る
    create_link = "<Leader>wl", -- ビジュアル選択からリンク作成
  },
}

--- Telescope が利用可能かチェック
local function has_telescope()
  if not M.config.use_telescope then return false end
  local ok = pcall(require, "telescope")
  return ok
end

--- wiki ルートディレクトリを返す
local function get_root()
  return M.config.root_dir or vim.fn.getcwd()
end

--- カーソル位置の [[link]] を取得
--- @return string|nil リンクテキスト（ブラケット除く）
function M.get_link_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed

  -- カーソル位置を含む [[...]] を探す
  local start = 1
  while start do
    local s, e, link = line:find("%[%[(.-)%]%]", start)
    if not s then break end
    if col >= s and col <= e then
      return link
    end
    start = e + 1
  end
  return nil
end

--- リンク先のファイルパスを返す
--- @param link string リンクテキスト
--- @return string ファイルパス
function M.resolve_link(link)
  -- サブディレクトリ対応: [[dir/page]] → dir/page.md
  local path = link:gsub("%s+", "-") -- スペースをハイフンに
  if not path:match("%.[^/]+$") then
    path = path .. M.config.extension
  end
  return get_root() .. "/" .. path
end

--- [[link]] をたどって対象ファイルを開く
function M.follow_link()
  local link = M.get_link_under_cursor()
  if not link then
    vim.notify("wiki: カーソル位置に [[link]] がありません", vim.log.levels.WARN)
    return
  end

  local filepath = M.resolve_link(link)
  local dir = vim.fn.fnamemodify(filepath, ":h")

  if vim.fn.filereadable(filepath) == 0 then
    if M.config.create_if_missing then
      vim.fn.mkdir(dir, "p")
      -- 新規ファイルにタイトルを挿入
      local title = link:match("[^/]+$") or link
      vim.fn.writefile({ "# " .. title, "", "" }, filepath)
      vim.notify("wiki: 新規作成 → " .. filepath, vim.log.levels.INFO)
    else
      vim.notify("wiki: ファイルが見つかりません → " .. filepath, vim.log.levels.WARN)
      return
    end
  end

  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end

--- FrontPage.md を開く
function M.front_page()
  local filepath = get_root() .. "/FrontPage" .. M.config.extension
  if vim.fn.filereadable(filepath) == 0 then
    if M.config.create_if_missing then
      vim.fn.mkdir(get_root(), "p")
      vim.fn.writefile({ "# FrontPage", "", "" }, filepath)
      vim.notify("wiki: 新規作成 → " .. filepath, vim.log.levels.INFO)
    else
      vim.notify("wiki: FrontPage が見つかりません → " .. filepath, vim.log.levels.WARN)
      return
    end
  end
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
end

--- 前のファイルに戻る（バッファ履歴）
function M.go_back()
  if vim.fn.bufnr("#") ~= -1 then
    vim.cmd("edit #")
  else
    vim.notify("wiki: 戻り先がありません", vim.log.levels.WARN)
  end
end

--- ビジュアル選択テキストを [[link]] で囲む
function M.create_link()
  -- 最後のビジュアル選択範囲を取得
  local s = vim.fn.getpos("'<")
  local e = vim.fn.getpos("'>")
  local line = vim.api.nvim_get_current_line()
  local selected = line:sub(s[3], e[3])
  if selected == "" then return end

  local new_line = line:sub(1, s[3] - 1) .. "[[" .. selected .. "]]" .. line:sub(e[3] + 1)
  vim.api.nvim_set_current_line(new_line)
end

--- カレントバッファ内の全 [[link]] を収集
--- @return table[] { link: string, lnum: number, col: number }
function M.list_links()
  local links = {}
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    for s, link in line:gmatch("()%[%[(.-)%]%]") do
      table.insert(links, { link = link, lnum = i, col = s })
    end
  end
  return links
end

--- バックリンク検索: 現在のファイル名を参照しているファイル一覧
function M.backlinks()
  if has_telescope() then
    require("wiki.telescope").backlinks()
    return
  end

  local current = vim.fn.expand("%:t:r") -- 拡張子なしのファイル名
  local root = get_root()
  local cmd = string.format("grep -rl '\\[\\[%s\\]\\]' %s --include='*.md' 2>/dev/null", current, root)
  local results = vim.fn.systemlist(cmd)

  if #results == 0 then
    vim.notify("wiki: バックリンクが見つかりません", vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, file in ipairs(results) do
    table.insert(items, {
      filename = file,
      text = "→ [[" .. current .. "]]",
    })
  end

  vim.fn.setqflist(items, "r")
  vim.fn.setqflist({}, "a", { title = "Backlinks: " .. current })
  vim.cmd("copen")
end

--- キーマップ設定
local function setup_mappings(bufnr)
  local map = M.config.mappings
  local opts = { buffer = bufnr, silent = true }

  vim.keymap.set("n", map.follow_link, M.follow_link, vim.tbl_extend("force", opts, { desc = "Wiki: follow link" }))
  vim.keymap.set("n", map.go_back, M.go_back, vim.tbl_extend("force", opts, { desc = "Wiki: go back" }))
  vim.keymap.set("v", map.create_link, M.create_link, vim.tbl_extend("force", opts, { desc = "Wiki: create link" }))
end

--- セットアップ
--- @param opts table|nil
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Markdown ファイルでキーマップを自動設定
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function(ev)
      setup_mappings(ev.buf)
    end,
    group = vim.api.nvim_create_augroup("WikiNvim", { clear = true }),
  })

  -- コマンド登録
  vim.api.nvim_create_user_command("WikiFollow", M.follow_link, { desc = "Follow [[link]] under cursor" })
  vim.api.nvim_create_user_command("WikiBack", M.go_back, { desc = "Go back to previous file" })
  vim.api.nvim_create_user_command("WikiFrontPage", M.front_page, { desc = "Open FrontPage" })
  vim.api.nvim_create_user_command("WikiBacklinks", M.backlinks, { desc = "Find backlinks to current file" })
  vim.api.nvim_create_user_command("WikiLinks", function()
    if has_telescope() then
      require("wiki.telescope").links()
      return
    end
    local links = M.list_links()
    if #links == 0 then
      vim.notify("wiki: リンクが見つかりません", vim.log.levels.INFO)
      return
    end
    local items = {}
    for _, l in ipairs(links) do
      table.insert(items, {
        bufnr = vim.api.nvim_get_current_buf(),
        lnum = l.lnum,
        col = l.col,
        text = "[[" .. l.link .. "]]",
      })
    end
    vim.fn.setqflist(items, "r")
    vim.fn.setqflist({}, "a", { title = "Wiki Links" })
    vim.cmd("copen")
  end, { desc = "List all [[links]] in current buffer" })
  vim.api.nvim_create_user_command("WikiPages", function()
    if has_telescope() then
      require("wiki.telescope").pages()
    else
      vim.notify("wiki: WikiPages は Telescope が必要です", vim.log.levels.WARN)
    end
  end, { desc = "Fuzzy search wiki pages" })
  vim.api.nvim_create_user_command("WikiGrep", function()
    if has_telescope() then
      require("wiki.telescope").grep()
    else
      vim.notify("wiki: WikiGrep は Telescope が必要です", vim.log.levels.WARN)
    end
  end, { desc = "Live grep in wiki" })
end

return M
