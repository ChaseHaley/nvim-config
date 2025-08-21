-- lua/regioner/init.lua
local M = {}

local defaults = {
  -- Use '//' by default; override per-filetype if needed.
  comment_leader = "//",
  -- Keep a blank line after the opening comment and before the closing.
  blank_line = true,
  -- Optional preset choices (will be offered if non-empty).
  presets = {}, -- e.g., { "Constructors", "Public Methods", "Internal Methods" }
  -- Keymaps
  set_keymaps = true,
  key_wrap = "<leader>r",  -- visual: prompt for a name
  key_pick = "<leader>R",  -- visual: choose from presets (plus "Custom…")
}

M.cfg = vim.deepcopy(defaults)

local function get_visual_line_range()
  -- Always expand to full lines, regardless of 'v' vs 'V'
  local srow = vim.fn.getpos("'<")[2]
  local erow = vim.fn.getpos("'>")[2]
  if srow > erow then srow, erow = erow, srow end
  -- Convert to 0-indexed [start, end-exclusive] for nvim_buf_* APIs
  return srow - 1, erow
end

local function compute_indent(line)
  return (line:match("^%s*")) or ""
end

local function wrap_lines_with_region(lines, name, leader, with_blank)
  if #lines == 0 then
    return lines
  end
  local indent = compute_indent(lines[1])
  local start_line = string.format("%s%s #region %s", indent, leader, name)
  local end_line   = string.format("%s%s #endregion", indent, leader)

  local new = { start_line }
  if with_blank then table.insert(new, "") end
  vim.list_extend(new, lines)
  if with_blank then table.insert(new, "") end
  table.insert(new, end_line)
  return new
end

function M.wrap_with_name(name)
  if not name or name == "" then
    return
  end

  local sr, er = get_visual_line_range()
  local buf = 0
  local old = vim.api.nvim_buf_get_lines(buf, sr, er, false)
  if #old == 0 then return end

  local new = wrap_lines_with_region(old, name, M.cfg.comment_leader, M.cfg.blank_line)
  vim.api.nvim_buf_set_lines(buf, sr, er, false, new)

  -- Put cursor back at start of the region (nice UX)
  vim.api.nvim_win_set_cursor(0, { sr + 1, 0 })
end

function M.prompt_and_wrap()
  vim.ui.input({ prompt = "Region name: " }, function(input)
    if input and input ~= "" then
      M.wrap_with_name(input)
    end
  end)
end

function M.choose_and_wrap()
  local presets = M.cfg.presets or {}
  if #presets == 0 then
    return M.prompt_and_wrap()
  end
  local choices = vim.deepcopy(presets)
  table.insert(choices, 1, "Custom…")
  vim.ui.select(choices, { prompt = "Select region name" }, function(choice)
    if not choice then return end
    if choice == "Custom…" then
      M.prompt_and_wrap()
    else
      M.wrap_with_name(choice)
    end
  end)
end

function M.setup(opts)
  M.cfg = vim.tbl_deep_extend("force", defaults, opts or {})

  if M.cfg.set_keymaps then
    -- Visual mode mappings only; we operate on the selection.
    vim.keymap.set("x", M.cfg.key_wrap, function() M.prompt_and_wrap() end,
      { desc = "Regioner: wrap selection with named region" })

    -- Only map the picker if presets are provided
    if M.cfg.presets and #M.cfg.presets > 0 then
      vim.keymap.set("x", M.cfg.key_pick, function() M.choose_and_wrap() end,
        { desc = "Regioner: wrap selection with preset region" })
    end
  end
end

return M

