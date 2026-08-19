{
  description = "Isolated NixVim environment for beans.nvim development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixvim, ... }:
    let
      # Plain-nix multi-system: iterate an explicit list, no flake-utils.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      pkgsFor = system: nixpkgs.legacyPackages.${system};

      beansPluginPath = self;

      nixvimModule = pkgs: {
        # Make the `beans` CLI available to the editor (the plugin shells out to
        # it via vim.system) as well as the tools the reference flake ships.
        extraPackages = [
          pkgs.beans
        ];

        extraPlugins = [
          pkgs.vimPlugins.plenary-nvim
          pkgs.vimPlugins.nvim-treesitter.withAllGrammars
        ];

        extraConfigLua = ''
          -- Add beans.nvim source to runtimepath (use env var set by shellHook,
          -- falling back to the flake's own path).
          local beans_dev_path = vim.fn.getenv("BEANS_NVIM_DEV_PATH")
          if beans_dev_path and beans_dev_path ~= vim.NIL then
            vim.opt.runtimepath:prepend(beans_dev_path)
          else
            vim.opt.runtimepath:prepend("${beansPluginPath}")
          end

          vim.g.mapleader = " "

          -- Activate the plugin in the dev editor (a real user calls this from
          -- their own config). Guarded so a load error never breaks nvim.
          pcall(function()
            require("beans").setup()
          end)

          -- Quick reload function for development.
          _G.reload_beans = function()
            for name, _ in pairs(package.loaded) do
              if name:match("^beans") then
                package.loaded[name] = nil
              end
            end
            vim.cmd("runtime! plugin/*.lua")
            vim.cmd("runtime! plugin/*.vim")
            vim.cmd("runtime! after/plugin/*.lua")
            pcall(function()
              require("beans").setup()
            end)
            local path = vim.fn.getenv("BEANS_NVIM_DEV_PATH") or "${beansPluginPath}"
            print("beans.nvim reloaded from: " .. path)
          end

          vim.keymap.set("n", "<leader>rr", reload_beans, { desc = "Reload beans.nvim" })

          -- Run plenary tests.
          vim.keymap.set("n", "<leader>rt", function()
            vim.cmd("PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}")
          end, { desc = "Run tests" })
        '';

        opts = {
          number = true;
          relativenumber = true;
          expandtab = true;
          shiftwidth = 2;
          tabstop = 2;
          signcolumn = "yes";
          termguicolors = true;
        };

        colorschemes.gruvbox.enable = true;

        plugins = {
          lualine.enable = true;
          web-devicons.enable = true;
          treesitter.enable = true;

          lsp = {
            enable = true;
            servers = {
              lua_ls = {
                enable = true;
                settings = {
                  Lua = {
                    diagnostics = {
                      globals = [ "vim" "describe" "it" "before_each" "after_each" ];
                    };
                    workspace = {
                      library = [
                        "\${3rd}/luv/library"
                      ];
                      checkThirdParty = false;
                    };
                  };
                };
              };
            };
          };
        };
      };

      nvimFor = system:
        let pkgs = pkgsFor system;
        in nixvim.legacyPackages.${system}.makeNixvimWithModule {
          inherit pkgs;
          module = nixvimModule pkgs;
        };
    in
    {
      packages = forAllSystems (system: {
        default = nvimFor system;
        neovim = nvimFor system;
      });

      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;
          nvim = nvimFor system;
        in {
          default = pkgs.mkShell {
            buildInputs = [
              nvim
              pkgs.beans
              pkgs.lua-language-server
              pkgs.stylua
            ];

            shellHook = ''
              echo ""
              echo "  beans.nvim Development Environment"
              echo ""
              echo " Plugin source: $(pwd) (live reload enabled)"
              echo " beans: $(beans version 2>/dev/null || echo 'not found')"
              echo ""
              echo " Commands:"
              echo "   nvim                    - Start Neovim (isolated)"
              echo "   beans tui               - Open the Beans TUI"
              echo ""
              echo " Keymaps (inside Neovim):"
              echo "   <Space>rr  - Reload beans.nvim (clears Lua cache)"
              echo "   <Space>rt  - Run plenary tests"
              echo ""

              export BEANS_NVIM_DEV_PATH="$(pwd)"

              export XDG_CONFIG_HOME="$(pwd)/.dev/config"
              export XDG_DATA_HOME="$(pwd)/.dev/share"
              export XDG_STATE_HOME="$(pwd)/.dev/state"
              export XDG_CACHE_HOME="$(pwd)/.dev/cache"

              mkdir -p "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
            '';
          };
        });

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${nvimFor system}/bin/nvim";
        };
      });
    };
}
