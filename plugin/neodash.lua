if vim.g.loaded_neodash == 1 then
  return
end
vim.g.loaded_neodash = 1

vim.api.nvim_create_user_command("Neodash", function()
  require("neodash").open()
end, { desc = "Open the neodash dashboard" })

vim.api.nvim_create_user_command("NeodashClose", function()
  require("neodash").close()
end, { desc = "Close the neodash dashboard" })

vim.api.nvim_create_user_command("NeodashRefresh", function()
  require("neodash").refresh()
end, { desc = "Refresh the neodash dashboard" })

vim.api.nvim_create_user_command("NeodashTheme", function(args)
  require("neodash").set_theme(args.args)
end, {
  nargs = 1,
  desc = "Change the neodash theme",
  complete = function()
    return require("neodash.theme").names()
  end,
})
