-- File: lua/project_navigator/init.lua
local M = {}

-- Default configuration
local config = {
	projects_root = vim.env.HOME .. "/Projects",
	allowed_exts = { "c", "ts", "rs", "cpp", "vue", "py", "lua", "dart", "js", "cs", "vim", "kt", "qml", "cu", "sh", "s" },
	ignore_dirs = { "probe", "third_party" },
	-- Optional mappings for additional project roots.
	extra_mappings = {}, -- e.g. { probe = vim.env.HOME .. "/Projects/probe", third_party = vim.env.HOME .. "/Projects/third_party" }
}

-- Utility: merge user config with defaults.
local function merge_config(user_config)
	if not user_config then
		return
	end
	for key, value in pairs(user_config) do
		config[key] = value
	end
end

-- This function uses `git ls-files` to determine the most common file extension in a repo.
local function find_mc_ext(path, allowed_exts)
	-- Build the command: change to the target directory then list non-ignored files.
	local cmd = string.format("cd %q && git ls-files --exclude-standard -co", path)
	local files = vim.fn.systemlist(cmd)
	if vim.v.shell_error ~= 0 then
		-- The folder is not a git repository. Get all files in the folder.
		local ncmd = string.format('cd %q && find . -type f', path)
		files = vim.fn.systemlist(ncmd)
		if vim.v.shell_error ~= 0 then
			vim.notify("Failed to list files in " .. path, vim.log.levels.ERROR)
			return
		end
	end

	local ext_counts = {}
	for _, file in ipairs(files) do
		-- Extract extension: everything after the last dot.
		local ext = file:match("%.([^%.]+)$")
		for _, allowed_ext in ipairs(allowed_exts) do
			if ext == allowed_ext then
				ext_counts[ext] = (ext_counts[ext] or 0) + 1
				break
			end
		end
	end

	local most_common, highest = nil, 0
	for ext, count in pairs(ext_counts) do
		if count > highest then
			most_common = ext
			highest = count
		end
	end
	return most_common
end

local function get_language_icon(language)
	local webdevicons = require("nvim-web-devicons")
	if not language then
		return { "", "TelescopeResultsDefaultIcon" }
	else
		local icon, color = webdevicons.get_icon("dummy." .. language, language)
		return { icon, color }
	end
end

-- Main function to open the projects picker.
local function open_projects_picker(root_path)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values

	-- Get names of all folders in the projects directory
	local projects_dir_content = vim.split(vim.fn.glob(root_path .. "/*"), "\n", { trimempty = true })
	local project_entries = {} -- { preview_file, display_name, icon }
	local project_paths = {} -- parallel table with project full paths

	for _, project_dir in ipairs(projects_dir_content) do
		-- Get just the folder name.
		local name = project_dir:sub(#root_path + 2)
		-- Skip directories that are in the ignore list.
		local ignore = false
		for _, ignore_dir in ipairs(config.ignore_dirs) do
			if name == ignore_dir then
				ignore = true
				break
			end
		end
		if ignore then
			goto continue
		end

		local ext = find_mc_ext(project_dir, config.allowed_exts)
		local icon = get_language_icon(ext)
		-- Try to preview README.md if it exists.
		local readme_path = project_dir .. "/README.md"
		if vim.fn.filereadable(readme_path) == 0 then
			readme_path = project_dir
		end

		table.insert(project_entries, { readme_path, name, icon })
		table.insert(project_paths, project_dir)
		::continue::
	end

	pickers.new({}, {
		prompt_title = "Projects",
		finder = finders.new_table {
			results = project_entries,
			entry_maker = function(entry)
				local entry_display = require("telescope.pickers.entry_display")
				return {
					value = entry[1],
					display = function()
						local displayer = entry_display.create({
							separator = " ",
							items = {
								{ width = 2 },
								{ remaining = true },
							},
						})
						return displayer({
							{ entry[3][1], entry[3][2] },
							{ entry[2],    "TelescopeResultsDescription" },
						})
					end,
					ordinal = entry[2],
				}
			end,
		},
		sorter = conf.generic_sorter({}),
		previewer = conf.file_previewer({}),
		attach_mappings = function(prompt_bufnr, map)
			local actions = require("telescope.actions")
			local state = require("telescope.actions.state")
			local open_proj = function()
				local selection = state.get_selected_entry()
				local idx = state.get_current_picker(prompt_bufnr).finder.results[selection.ordinal] and selection.index or
					selection.idx
				vim.cmd("cd " .. project_paths[idx])
				vim.cmd("e .")
				actions.close(prompt_bufnr)
			end
			map("i", "<CR>", open_proj)
			map("n", "<CR>", open_proj)
			return true
		end,
	}):find()
end

-- Public function to open projects from the configured root.
M.open_projects = function()
	open_projects_picker(config.projects_root)
end

-- Allow users to map extra project roots if they like.
M.open_project_by_key = function(key)
	local extra = config.extra_mappings
	if extra and extra[key] then
		open_projects_picker(extra[key])
	else
		vim.api.nvim_err_writeln("No project mapping for key: " .. key)
	end
end

-- Setup function for user configuration.
M.setup = function(user_config)
	merge_config(user_config)
	-- You might want to add your keymaps here. For example:
	--
	-- vim.keymap.set("n", "<leader>p", M.open_projects, { desc = "Open Projects" })
	--
	-- And if the user has extra_mappings, they could set keybindings like:
	-- for key, path in pairs(config.extra_mappings) do
	--   vim.keymap.set("n", "<leader>p" .. key, function() M.open_project_by_key(key) end,
	--     { desc = "Open Project: " .. key })
	-- end
end

return M
