# Project Manager.nvim

[![License: BSD-2-Clause](https://img.shields.io/badge/License-BSD%202--Clause-blue.svg)](LICENSE)

Project Navigator.nvim is a Neovim plugin that helps you quickly browse and open your projects. It uses [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for a smooth fuzzy-finding interface and [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) to display icons based on the dominant file type in each project.

## Features

- **Configurable File Extensions:** Users supply their own list of allowed file extensions.
- **Customizable Ignored Directories:** Choose which directories to ignore when scanning for projects.
- **Multiple Project Roots:** Easily map additional project roots to keybindings.
- **Telescope Integration:** Browse projects using Telescope’s interface.
- **Dynamic Icons:** Each project displays an icon based on its most common file extension.

## Prerequisites

- Neovim 0.5 or higher
- [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons)
- Git (for scanning your projects)

## Installation

### Using [Lazy.nvim](https://github.com/folke/lazy.nvim)

Add the following to your Lazy configuration (e.g., in your `lazy.lua`):

```lua
return {
  {
    "Dr-42/project-manager.nvim",
    name = "project-manager",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("project_navigator").setup({
        projects_root = vim.env.HOME .. "/Projects",  -- Your projects directory
        allowed_exts = { "lua", "py", "js", "ts", "cpp" },  -- Customize your allowed file extensions
        ignore_dirs = { "probe", "third_party" },            -- Directories to ignore
        extra_mappings = {                                    -- Optional extra mappings
          probe = vim.env.HOME .. "/Projects/probe",
          third_party = vim.env.HOME .. "/Projects/third_party",
        },
      })
      vim.keymap.set("n", "<leader>p", require("project_navigator").open_projects, { desc = "Open Projects" })
      vim.keymap.set("n", "<leader>pp",
        function()
            require("project_navigator").open_project_by_key('probe')
        end,
        { desc = "Open Probe Projects" })
    end,
  },
}
```

## Usage

Once installed, you can open the projects picker with the keybindings you set

    Press <leader>p in normal mode to open the project browser.
    Press <leader>pp in normal mode to open the project browser for a specific project.

## How It Works

- Scanning Projects: The plugin scans the specified projects_root directory. For each subdirectory, it uses Git to list files and determines the most common file extension based on your allowed list. If not a git repo, It scans all files.
- Icons: It then uses nvim-web-devicons to fetch an icon corresponding to that file extension.
- Telescope Picker: Finally, a Telescope picker displays your projects with their icons and names. When you select a project, it changes the working directory to the project folder and opens it.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests. Please follow the repository’s guidelines.
License

This project is licensed under the BSD-2-Clause License. See the LICENSE file for details.
