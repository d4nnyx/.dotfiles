-- Ansible language server

vim.lsp.config.ansiblels = {
  settings = {
    ansible = {
      ansible = {
        useFullyQualifiedCollectionNames = false
      }
    }
  }
}

vim.filetype.add({
  pattern = {
    ['.*/ansible/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/roles/.*%.ya?ml'] = 'yaml.ansible',
    ['.*/playbooks/.*%.ya?ml'] = 'yaml.ansible',
  },
})

-- Gitlab CI LspAttach

vim.filetype.add({
  pattern = {
    ['%.?gitlab%-ci%.ya?ml'] = 'yaml.gitlab',
    ['.*/%.gitlab/.*%.ya?ml'] = 'yaml.gitlab',
  },
})

-- General settings

vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float)


-- Inline diagnostic

vim.diagnostic.config({
  virtual_text = {
    prefix = "●",  -- or “▎”, “■”, etc
    spacing = 2,
  },
  signs = true,        -- show sign column markers
  underline = true,     -- underline problematic text
  update_in_insert = false,
})

-- Autocompletion settings

vim.o.completeopt = "menuone,noinsert,popup,fuzzy,menuone"
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    if client:supports_method('textDocument/implementation') then
      -- Create a keymap for vim.lsp.buf.implementation ...
    end
    -- Enable auto-completion. Note: Use CTRL-Y to select an item. |complete_CTRL-Y|
    if client:supports_method('textDocument/completion') then
      -- Optional: trigger autocompletion on EVERY keypress. May be slow!
      local chars = {}; for i = 32, 126 do table.insert(chars, string.char(i)) end
      client.server_capabilities.completionProvider.triggerCharacters = chars
      vim.lsp.completion.enable(true, client.id, args.buf, {autotrigger = true})
    end
  end,
})

