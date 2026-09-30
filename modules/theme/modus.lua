require("modus-themes").setup({
	style = "modus_vivendi",
	transparent = vim.g.theme_transparent,
	line_nr_column_background = false,
	sign_column_background = false,
	on_highlights = function(highlights)
		highlights.NormalFloat.bg = "NONE"
		highlights.FloatBorder.bg = "NONE"
		highlights.Pmenu.bg = "NONE"
	end,
})
vim.cmd.colorscheme("modus")
