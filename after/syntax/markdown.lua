-- [[wiki link]] のハイライト
vim.fn.matchadd("WikiLink", "\\[\\[[^\\]]*\\]\\]")

-- WikiLink のハイライトカラー（リンクっぽく下線+青）
if vim.fn.hlexists("WikiLink") == 0 or vim.fn.synIDattr(vim.fn.hlID("WikiLink"), "fg") == "" then
  vim.api.nvim_set_hl(0, "WikiLink", { link = "Underlined" })
end
