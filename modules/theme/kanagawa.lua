require("kanagawa").setup({
	transparent = vim.g.theme_transparent,
	colors = {
		theme = {
			all = {
				ui = {
					bg_gutter = "none",
					float = {
						bg = "none",
						bg_border = "none",
					},
				},
			},
		},
	},
})
vim.cmd.colorscheme("kanagawa-dragon")
