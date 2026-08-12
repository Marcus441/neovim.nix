require("kanagawa").setup({
	transparent = vim.g.theme_transparent,
	colors = {
		theme = {
			all = {
				ui = {
					bg_gutter = "none",
					float = {
						bg = "none",
					},
				},
				-- load-bearing: docs/decisions/theme.md#diag-error
				diag = {
					error = "#e46876",
				},
			},
		},
	},
	overrides = function(colors)
		local theme = colors.theme
		local makeDiagnosticColor = function(color)
			local c = require("kanagawa.lib.color")
			return { fg = color, bg = c(color):blend(theme.ui.bg, 0.95):to_hex() }
		end
		local block = function(bg)
			return {
				normal = { bg = bg },
				border = { fg = bg, bg = bg },
				title = { fg = theme.ui.special, bg = bg, bold = true },
			}
		end
		local prompt, results, preview = block(theme.ui.bg_p1), block(theme.ui.bg_m1), block(theme.ui.bg_dim)
		local overrides = {
			-- Tint diagnostic virtual text with their foreground color (tokyonight style)
			DiagnosticVirtualTextHint = makeDiagnosticColor(theme.diag.hint),
			DiagnosticVirtualTextInfo = makeDiagnosticColor(theme.diag.info),
			DiagnosticVirtualTextWarn = makeDiagnosticColor(theme.diag.warning),
			DiagnosticVirtualTextError = makeDiagnosticColor(theme.diag.error),

			-- Dark on red, since diag.error is read as a background here
			["@comment.error"] = { fg = theme.ui.bg, bg = theme.diag.error, bold = true },

			-------------------
			-- Floating windows
			-------------------
			NormalFloat = { bg = "none" },
			FloatBorder = { bg = "none" },
			FloatTitle = { bg = "none" },

			-------------------
			-- Status Line
			-------------------
			MiniStatuslineFilename = { fg = theme.ui.fg },
			MiniStatuslineFileinfo = { fg = theme.ui.fg },
			MiniStatuslineDevinfo = { fg = theme.ui.fg },
			-------------------
			-- Blink-cmp
			-------------------
			-- The native menu stays transparent; blink's own windows are blocks
			Pmenu = { bg = "none" },
			PmenuSel = { bg = theme.ui.bg_p2 },
			PmenuSbar = { bg = "none" },
			PmenuThumb = { bg = theme.ui.bg_p2 },

			BlinkCmpMenu = results.normal,
			BlinkCmpMenuBorder = results.border,

			-- Individual row elements
			BlinkCmpLabel = { bg = "none", fg = theme.ui.fg },
			BlinkCmpLabelDescription = { bg = "none", fg = theme.ui.fg_dim },
			BlinkCmpLabelDetail = { bg = "none", fg = theme.ui.fg_dim },
			BlinkCmpKind = { bg = "none", fg = theme.ui.fg_dim },
			BlinkCmpSource = { bg = "none", fg = theme.ui.fg_dim },
			BlinkCmpLabelMatch = { bg = "none", fg = theme.diag.info, bold = true },

			-- The selection bar inside the menu
			BlinkCmpMenuSelection = { bg = theme.ui.bg_p2, fg = theme.ui.fg },

			-- Documentation & Signature Help
			BlinkCmpDoc = preview.normal,
			BlinkCmpDocBorder = preview.border,
			BlinkCmpDocSeparator = preview.normal,
			BlinkCmpSignatureHelp = preview.normal,
			BlinkCmpSignatureHelpBorder = preview.border,

			-------------------
			-- Snacks picker
			-------------------
			-- load-bearing: docs/decisions/theme.md#picker-blocks
			SnacksPicker = results.normal,
			SnacksPickerBorder = results.border,
			SnacksPickerTitle = results.title,
			SnacksPickerFooter = results.title,
			SnacksPickerBox = results.normal,
			SnacksPickerBoxBorder = results.border,
			SnacksPickerBoxTitle = results.title,

			SnacksPickerInput = prompt.normal,
			SnacksPickerInputBorder = prompt.border,
			SnacksPickerInputTitle = prompt.title,
			SnacksPickerInputSearch = { fg = theme.syn.special1 },

			SnacksPickerList = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
			SnacksPickerListBorder = results.border,
			SnacksPickerListTitle = results.title,
			SnacksPickerListCursorLine = { bg = theme.ui.bg_p2 },

			SnacksPickerPreview = preview.normal,
			SnacksPickerPreviewBorder = preview.border,
			SnacksPickerPreviewTitle = preview.title,
			SnacksPickerPreviewCursorLine = { bg = theme.ui.bg_p1 },

			-------------------
			-- Snacks input
			-------------------
			SnacksInputNormal = prompt.normal,
			SnacksInputBorder = prompt.border,
			SnacksInputTitle = prompt.title,

			-------------------
			-- Noice cmdline and LSP hover
			-------------------
			NoicePopup = preview.normal,
			NoicePopupBorder = preview.border,
			NoiceCmdlinePopup = prompt.normal,
			NoiceCmdlinePopupBorder = prompt.border,
			NoiceCmdlinePopupTitle = prompt.title,
			NoicePopupmenu = results.normal,
			NoicePopupmenuBorder = results.border,
			NoicePopupmenuSelected = { bg = theme.ui.bg_p2 },
		}

		-- The notifier border keeps its per-level colour and gains the block's bg,
		-- so the fancy style's rule stays visible while the frame reads as padding
		for level, color in pairs({
			Trace = theme.ui.nontext,
			Debug = theme.ui.nontext,
			Info = theme.diag.info,
			Warn = theme.diag.warning,
			Error = theme.diag.error,
		}) do
			overrides["SnacksNotifier" .. level] = results.normal
			overrides["SnacksNotifierBorder" .. level] = { fg = color, bg = theme.ui.bg_m1 }
			overrides["SnacksNotifierTitle" .. level] = { fg = color, bg = theme.ui.bg_m1 }
			overrides["SnacksNotifierFooter" .. level] = { fg = color, bg = theme.ui.bg_m1 }
		end

		return overrides
	end,
})
vim.cmd([[colorscheme kanagawa-dragon]])
