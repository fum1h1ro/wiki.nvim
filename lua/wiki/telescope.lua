local M = {}

local has_telescope, _ = pcall(require, "telescope")
if not has_telescope then
  return M
end

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local wiki = require("wiki")

--- バックリンク検索: 現在のファイル名を参照しているファイルを Telescope で表示
function M.backlinks(opts)
  opts = opts or {}
  local current = vim.fn.expand("%:t:r")
  local root = wiki.config.root_dir or vim.fn.getcwd()
  local cmd = string.format("grep -rn '\\[\\[%s\\]\\]' %s --include='*.md' 2>/dev/null",
    current, vim.fn.shellescape(root))
  local results = vim.fn.systemlist(cmd)

  if #results == 0 then
    vim.notify("wiki: バックリンクが見つかりません", vim.log.levels.INFO)
    return
  end

  local entries = {}
  for _, line in ipairs(results) do
    local file, lnum, text = line:match("^(.+):(%d+):(.*)$")
    if file then
      table.insert(entries, {
        filename = file,
        lnum = tonumber(lnum),
        text = text,
        display = vim.fn.fnamemodify(file, ":t:r") .. ":" .. lnum .. " " .. vim.trim(text),
      })
    end
  end

  pickers.new(opts, {
    prompt_title = "Backlinks: " .. current,
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.display,
          filename = entry.filename,
          lnum = entry.lnum,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
  }):find()
end

--- カレントバッファ内の全 [[link]] を Telescope で表示
function M.links(opts)
  opts = opts or {}
  local links = wiki.list_links()

  if #links == 0 then
    vim.notify("wiki: リンクが見つかりません", vim.log.levels.INFO)
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local bufname = vim.api.nvim_buf_get_name(bufnr)

  local entries = {}
  for _, l in ipairs(links) do
    local resolved = wiki.resolve_link(l.link)
    local exists = vim.fn.filereadable(resolved) == 1
    local status = exists and "" or " [新規]"
    table.insert(entries, {
      link = l.link,
      lnum = l.lnum,
      col = l.col,
      resolved = resolved,
      exists = exists,
      display = "[[" .. l.link .. "]]" .. status .. "  (行 " .. l.lnum .. ")",
    })
  end

  pickers.new(opts, {
    prompt_title = "Wiki Links",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.link,
          filename = bufname,
          lnum = entry.lnum,
          col = entry.col,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = previewers.new_buffer_previewer({
      title = "リンク先プレビュー",
      define_preview = function(self, entry)
        local e = entry.value
        if e.exists then
          conf.buffer_previewer_maker(e.resolved, self.state.bufnr, {
            bufname = e.resolved,
          })
        else
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
            "（ファイル未作成: " .. e.resolved .. "）",
          })
        end
      end,
    }),
    attach_mappings = function(prompt_bufnr)
      --- リンク先ファイルを必要なら作成してから開く
      local function open_link(open_cmd)
        actions.close(prompt_bufnr)
        local entry = action_state.get_selected_entry()
        if not entry then return end
        local filepath = entry.value.resolved
        if not entry.value.exists and wiki.config.create_if_missing then
          local dir = vim.fn.fnamemodify(filepath, ":h")
          vim.fn.mkdir(dir, "p")
          local title = entry.value.link:match("[^/]+$") or entry.value.link
          vim.fn.writefile({ "# " .. title, "", "" }, filepath)
          vim.notify("wiki: 新規作成 → " .. filepath, vim.log.levels.INFO)
        end
        if entry.value.exists or wiki.config.create_if_missing then
          vim.cmd(open_cmd .. " " .. vim.fn.fnameescape(filepath))
        end
      end
      actions.select_default:replace(function() open_link("edit") end)
      actions.select_horizontal:replace(function() open_link("split") end)
      actions.select_vertical:replace(function() open_link("vsplit") end)
      actions.select_tab:replace(function() open_link("tabedit") end)
      return true
    end,
  }):find()
end

--- Wiki ページ一覧を Telescope で fuzzy 検索
function M.pages(opts)
  opts = opts or {}
  local root = wiki.config.root_dir or vim.fn.getcwd()
  local ext = wiki.config.extension or ".md"

  -- root 配下の .md ファイルを収集
  root = root:gsub("/$", "")
  local glob_pattern = root .. "/**/*" .. ext
  local files = vim.fn.glob(glob_pattern, false, true)

  if #files == 0 then
    vim.notify("wiki: ページが見つかりません", vim.log.levels.INFO)
    return
  end

  local entries = {}
  for _, file in ipairs(files) do
    local rel = file:sub(#root + 2) -- root/ を除いた相対パス
    local name = rel:gsub(ext .. "$", "")
    table.insert(entries, {
      filename = file,
      name = name,
      display = name,
    })
  end

  pickers.new(opts, {
    prompt_title = "Wiki Pages",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.name,
          filename = entry.filename,
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
  }):find()
end

--- Wiki 内全文検索を Telescope の live_grep で実行
function M.grep(opts)
  opts = opts or {}
  local root = wiki.config.root_dir or vim.fn.getcwd()
  local ext = wiki.config.extension or ".md"

  opts = vim.tbl_deep_extend("force", {
    prompt_title = "Wiki Grep",
    cwd = root,
    glob_pattern = "*" .. ext,
  }, opts)

  require("telescope.builtin").live_grep(opts)
end

return M
