local Popup = require("nui.popup")
local Text = require("nui.text")
local helper = require("tests.nui")

local eq, tbl_pick = helper.eq, helper.tbl_pick

describe("nui.popup", function()
  local popup_options = {}

  before_each(function()
    popup_options = {
      ns_id = vim.api.nvim_create_namespace("NuiTest"),
      position = "50%",
      size = {
        height = 2,
        width = 8,
      },
    }
  end)

  describe("border.style", function()
    local function get_border_style_list()
      return { "╭", "─", "╮", "│", "╯", "─", "╰", "│" }
    end

    local function get_border_style_map()
      return {
        top_left = "╭",
        top = "─",
        top_right = "╮",
        left = "│",
        right = "│",
        bottom_left = "╰",
        bottom = "─",
        bottom_right = "╯",
      }
    end

    local function get_borer_style_map_with_nui_text(hl_group)
      local style = get_border_style_map()
      for k, v in pairs(style) do
        style[k] = Text(v, hl_group .. "_" .. k)
      end
      return style
    end

    local function get_borer_style_map_with_tuple(hl_group)
      local style = get_border_style_map()
      for k, v in pairs(style) do
        style[k] = { v, hl_group .. "_" .. k }
      end
      return style
    end

    it("supports string name", function()
      popup_options = vim.tbl_deep_extend("force", popup_options, {
        border = {
          style = "rounded",
          padding = { 0 },
        },
      })

      local popup = Popup(popup_options)

      popup:mount()

      eq(vim.api.nvim_buf_get_lines(popup.border.bufnr, 0, -1, false), {
        "╭────────╮",
        "│        │",
        "│        │",
        "╰────────╯",
      })
    end)

    it("supports list table", function()
      local style = get_border_style_list()

      popup_options = vim.tbl_deep_extend("force", popup_options, {
        border = {
          style = style,
          padding = { 0 },
        },
      })

      local popup = Popup(popup_options)

      popup:mount()

      eq(vim.api.nvim_buf_get_lines(popup.border.bufnr, 0, -1, false), {
        "╭────────╮",
        "│        │",
        "│        │",
        "╰────────╯",
      })
    end)

    it("supports map table", function()
      local style = get_border_style_map()

      popup_options = vim.tbl_deep_extend("force", popup_options, {
        border = {
          style = style,
          padding = { 0 },
        },
      })

      local popup = Popup(popup_options)

      popup:mount()

      eq(vim.api.nvim_buf_get_lines(popup.border.bufnr, 0, -1, false), {
        "╭────────╮",
        "│        │",
        "│        │",
        "╰────────╯",
      })
    end)

    describe("supports highlight", function()
      local function assert_highlight(popup, hl_group)
        local size = popup_options.size

        eq(vim.api.nvim_buf_get_lines(popup.border.bufnr, 0, -1, false), {
          "╭────────╮",
          "│        │",
          "│        │",
          "╰────────╯",
        })

        for linenr = 1, size.height + 2 do
          local is_top_line = linenr == 1
          local is_bottom_line = linenr == size.height + 2

          local extmarks = vim.api.nvim_buf_get_extmarks(
            popup.border.bufnr,
            popup_options.ns_id,
            { linenr - 1, 0 },
            { linenr - 1, -1 },
            { details = true }
          )

          eq(#extmarks, (is_top_line or is_bottom_line) and 4 or 2)

          eq(extmarks[1][2], linenr - 1)
          eq(tbl_pick(extmarks[1][4], { "end_row", "hl_group" }), {
            end_row = linenr - 1,
            hl_group = hl_group .. (is_top_line and "_top_left" or is_bottom_line and "_bottom_left" or "_left"),
          })

          if is_top_line or is_bottom_line then
            eq(extmarks[2][2], linenr - 1)
            eq(tbl_pick(extmarks[2][4], { "end_row", "hl_group" }), {
              end_row = linenr - 1,
              hl_group = hl_group .. (is_top_line and "_top" or "_bottom"),
            })

            eq(extmarks[3][2], linenr - 1)
            eq(tbl_pick(extmarks[3][4], { "end_row", "hl_group" }), {
              end_row = linenr - 1,
              hl_group = hl_group .. (is_top_line and "_top" or "_bottom"),
            })
          end

          eq(extmarks[#extmarks][2], linenr - 1)
          eq(tbl_pick(extmarks[#extmarks][4], { "end_row", "hl_group" }), {
            end_row = linenr - 1,
            hl_group = hl_group .. (is_top_line and "_top_right" or is_bottom_line and "_bottom_right" or "_right"),
          })
        end
      end

      it("as (char, hl_group) tuple in map table", function()
        local hl_group = "NuiPopupTest"
        local style = get_borer_style_map_with_tuple(hl_group)

        popup_options = vim.tbl_deep_extend("force", popup_options, {
          border = {
            style = style,
            padding = { 0 },
          },
        })

        local popup = Popup(popup_options)

        popup:mount()

        assert_highlight(popup, hl_group)
      end)

      it("as nui.text in map table", function()
        local hl_group = "NuiPopupTest"
        local style = get_borer_style_map_with_nui_text(hl_group)

        popup_options = vim.tbl_deep_extend("force", popup_options, {
          border = {
            style = style,
            padding = { 0 },
          },
        })

        local popup = Popup(popup_options)

        popup:mount()

        assert_highlight(popup, hl_group)
      end)
    end)
  end)

  describe("border.text", function()
    it("supports simple text", function()
      local text = "popup"

      popup_options = vim.tbl_deep_extend("force", popup_options, {
        border = {
          style = "single",
          text = {
            top = text,
          },
        },
      })

      local popup = Popup(popup_options)

      popup:mount()

      local linenr = 1
      local line = vim.api.nvim_buf_get_lines(popup.border.bufnr, linenr - 1, linenr, false)[linenr]
      local byte_start = string.find(line, text)

      popup:unmount()

      eq(type(byte_start), "number")
    end)

    it("supports nui.text", function()
      local text = "popup"
      local hl_group = "NuiPopupTest"

      popup_options = vim.tbl_deep_extend("force", popup_options, {
        border = {
          style = "single",
          text = {
            top = Text(text, hl_group),
          },
        },
      })

      local popup = Popup(popup_options)

      popup:mount()

      local linenr = 1
      local line = vim.api.nvim_buf_get_lines(popup.border.bufnr, linenr - 1, linenr, false)[linenr]
      local byte_start = string.find(line, text)

      local extmarks = vim.api.nvim_buf_get_extmarks(
        popup.border.bufnr,
        popup_options.ns_id,
        { linenr - 1, byte_start },
        { linenr - 1, #text },
        { details = true }
      )

      popup:unmount()

      eq(type(byte_start), "number")

      eq(#extmarks, 1)
      eq(extmarks[1][2], linenr - 1)
      eq(extmarks[1][4].end_col - extmarks[1][3], #text)
      eq(tbl_pick(extmarks[1][4], { "end_row", "hl_group" }), {
        end_row = linenr - 1,
        hl_group = hl_group,
      })
    end)
  end)
end)
