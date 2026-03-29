vim.keymap.set("n", "<leader>gs", function()
  vim.cmd("Git")                     -- open fugitive status
  vim.cmd("resize " .. math.floor(vim.o.lines * 0.2))
end)
