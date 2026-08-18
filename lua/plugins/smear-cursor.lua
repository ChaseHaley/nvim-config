vim.pack.add({ "https://github.com/sphamba/smear-cursor.nvim" })
require("smear_cursor").setup(
	---@module "smear_cursor.config"
	{
		-- Smear cursor when switching buffers or windows.
		smear_between_buffers = true,

		-- Smear cursor when moving within line or to neighbor lines.
		-- Use `min_horizontal_distance_smear` and `min_vertical_distance_smear` for finer control
		smear_between_neighbor_lines = true,

		-- Draw the smear in buffer space instead of screen space when scrolling
		scroll_buffer_space = false,

		-- Set to `true` if your font supports legacy computing symbols (block unicode symbols).
		-- Smears and particles will look a lot less blocky.
		legacy_computing_symbols_support = true,

		-- Smear cursor in insert mode.
		-- See also `vertical_bar_cursor_insert_mode` and `distance_stop_animating_vertical_bar`.
		smear_insert_mode = true,

		-- Only smear cursor when moving at least these distances
		min_horizontal_distance_smear = 0,
		min_vertical_distance_smear = 0,

		-- Stop animating when the smear's tail is within this distance (in characters) from the target.
		distance_stop_animating = 1,

		-- Can be decreased (e.g. to 0.1) if using legacy computing symbols
		distance_stop_animating_vertical_bar = 0,

		-- Velocity reduction over time. O: no reduction, 1: full reduction
		damping = 1,

		-- How fast the smear's head moves towards the target.
		-- 0: no movement, 1: instantaneous
		stiffness = 1,

		-- Controls if middle points are closer to the head or the tail.
		-- < 1: closer to the tail, > 1: closer to the head
		trailing_exponent = 3,

		-- How fast the smear's tail moves towards the target.
		-- 0: no movement, 1: instantaneous
		trailing_stiffness = 0.2,
	}
)
