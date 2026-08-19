# easy-dotnet: "failed to resolve project context"

Status: **not fixed, deliberately ignored.** Two ready-to-run actions are below:
report it upstream, and optionally patch it locally.

## The warning

```
Roslyn failed to resolve project context: Method not found: textDocument/_vs_getProjectContexts
```

Source: `easy-dotnet.nvim`, `lua/easy-dotnet/roslyn/lsp.lua:81`, in
`does_file_belong_to_active_client`.

Environment when found: Neovim v0.12.2 on Windows 11, easy-dotnet.nvim at
`0a8cfb96e40b985921e6613f31f75811e31b8edf`. `roslyn.nvim` is commented out in
`lua/plugins.lua`, so easy-dotnet owns the only C# client.

## What triggers it

`does_file_belong_to_active_client` is reached from `find_project_or_solution`,
which is easy-dotnet's `root_dir` resolver for the `easy_dotnet` client. Only one
branch reaches the request: a solution is already selected, and the buffer's file
is readable but **not under cwd**.

The `gri` keymap in `lua/plugins/lspconfig.lua` walks a ladder ending at "go to
the type declaration". On a variable of a built-in type such as `string`, that
last rung opens Roslyn's metadata-as-source file for `System.String`, which lives
in a temp directory. Opening it fires `FileType cs`, easy-dotnet resolves a
root_dir for a real file far outside the solution, and the request goes out.

Jumps into first-party code take the `is_file_in_cwd` early return and never ask.
That is why the warning tracks built-in types exactly.

## Why the request fails

```lua
local function has_client_for_root_dir(root_dir) return vim.lsp.get_clients({ root_dir = root_dir })[1] end
```

`vim.lsp.get_clients` has no `root_dir` filter. Its loop tests `id`, `bufnr`,
`name`, and `method`, and ignores every other key, so the call returns **all**
initialized clients and `[1]` is whichever client started first. easy-dotnet then
sends `textDocument/_vs_getProjectContexts`, a Visual Studio protocol extension,
to `lua_ls` or `jsonls` or whatever holds that slot. The server answers JSON-RPC
-32601, "Method not found".

Proof, with two fake clients registered in `vim.lsp.client._all`:

```
clients returned for root_dir = C:/my/solution:
  lua_ls (root_dir C:/some/other/place)
  easy_dotnet (root_dir C:/my/solution)
first match: lua_ls
root_dir filter honoured: false
```

`has_roslyn_client_for_root`, two lines below the bug, filters by
`name = constants.lsp_client_name` and is the pattern the fix should follow.

## Why it comes and goes

- Within a session, `[1]` is effectively the earliest-started client. Open a Lua
  file first and `lua_ls` owns that slot, so the warning appears. Open a `.cs`
  file first and `easy_dotnet` may own it, so the request succeeds silently.
- On a second `gri` to the same type, the metadata buffer already exists with its
  client attached. No `FileType` fires, no root_dir resolves, no request is sent.

## What it costs

When the misdirected request fails, `does_file_belong_to_active_client` returns
false, `find_project_or_solution` falls through to the csproj search, finds
nothing near a temp file, and resolves the root_dir to the **temp metadata
directory**. easy-dotnet can then start a second `easy_dotnet` client rooted
there. `on_init` finds no `.sln` or `.csproj`, so it loads no project: a wasted
server process that gives that buffer nothing.

Check for it right after the warning appears:

```vim
:lua =vim.tbl_map(function(c) return c.name .. " @ " .. tostring(c.root_dir) end, vim.lsp.get_clients())
```

An `easy_dotnet` entry rooted in a temp path is the real problem. Without one,
the warning is cosmetic.

## Action 1: report upstream

Repo: <https://github.com/GustavEikaas/easy-dotnet.nvim>

Issue body, ready to paste:

> **`has_client_for_root_dir` passes an unsupported filter key, so
> `_vs_getProjectContexts` goes to the wrong server**
>
> `lua/easy-dotnet/roslyn/lsp.lua:97`
>
> ```lua
> local function has_client_for_root_dir(root_dir) return vim.lsp.get_clients({ root_dir = root_dir })[1] end
> ```
>
> `vim.lsp.get_clients` filters on `id`, `bufnr`, `name`, and `method` only, and
> silently ignores unknown keys. So this returns every initialized client and
> `[1]` is whichever started first, not the Roslyn client.
>
> `find_project_or_solution` then hands that client to
> `does_file_belong_to_active_client`, which sends
> `textDocument/_vs_getProjectContexts` to it. When the client is not Roslyn, the
> server answers `Method not found` and the user sees:
>
> ```
> Roslyn failed to resolve project context: Method not found: textDocument/_vs_getProjectContexts
> ```
>
> It then falls through and resolves the root_dir to the directory of the file
> being opened, which for a metadata-as-source file is a temp directory, so a
> second `easy_dotnet` client can start there with no project loaded.
>
> **Reproduction**: with a solution selected, open a `.cs` file, make sure a
> non-Roslyn server started first in the session (opening a `.lua` file first is
> enough), then go to the definition of a built-in type such as `string` so
> Neovim opens Roslyn's metadata-as-source file from outside the solution root.
>
> **Suggested fix**, matching `has_roslyn_client_for_root` directly below it:
>
> ```lua
> local function has_client_for_root_dir(root_dir)
>   return vim.iter(vim.lsp.get_clients({ name = constants.lsp_client_name })):find(function(client)
>     return client.root_dir == root_dir
>   end)
> end
> ```
>
> **Second, related bug** at `lua/easy-dotnet/roslyn/lsp.lua:181`:
>
> ```lua
> local possible_client = vim.lsp.get_clients({ root_dir = vim.fs.dirname(existing_sln) })
> if possible_client then return end
> ```
>
> `get_clients` returns a table, and a table is always truthy, so this always
> returns and `current_solution.set_solution(r.display)` on the next line never
> runs after the solution picker. `[1]` or `#... > 0` was probably intended.
>
> Neovim v0.12.2, easy-dotnet.nvim `0a8cfb9`.

## Action 2: patch locally (optional)

Only worth doing if the client check above shows a stray `easy_dotnet` server.
Drop it when upstream lands.

### 2a. Teach `get_clients` the `root_dir` key (real fix)

Add to the top of `lua/plugins/easy-dotnet.lua`, above the `vim.pack.add` call,
so it is in place before easy-dotnet builds its LSP config:

```lua
-- MonkeyPatch - easy-dotnet's has_client_for_root_dir passes root_dir to
-- vim.lsp.get_clients, which ignores unknown filter keys and returns every
-- client. It then sends textDocument/_vs_getProjectContexts to whichever client
-- came first, and a non-Roslyn server answers "Method not found".
local get_clients = vim.lsp.get_clients
vim.lsp.get_clients = function(filter)
	local clients = get_clients(filter)
	local root_dir = filter and filter.root_dir
	if not root_dir then
		return clients
	end

	root_dir = vim.fs.normalize(root_dir)
	return vim.tbl_filter(function(client)
		return client.root_dir and vim.fs.normalize(client.root_dir) == root_dir
	end, clients)
end
```

`vim.fs.normalize` on both sides is load-bearing on Windows: easy-dotnet builds
the path with `vim.fs.dirname`, while `client.root_dir` can carry backslashes,
and a raw string compare would filter every client out and silently reintroduce
the fall-through.

Verified against fake clients: a matching `root_dir` returns exactly the Roslyn
client across separator styles, an unknown `root_dir` returns nothing, and calls
with no `root_dir` or with `name` or `bufnr` behave as before.

### 2b. Mute the message only (cosmetic)

Does **not** stop the stray client. Use only to quiet the notification. This one
goes **between** `vim.pack.add` and `require("easy-dotnet").setup`, because the
module is not on the runtimepath until `vim.pack.add` has run:

```lua
local logger = require("easy-dotnet.logger")
local warn = logger.warn
logger.warn = function(msg)
	if type(msg) == "string" and msg:find("failed to resolve project context", 1, true) then
		return
	end

	return warn(msg)
end
```

## Open question

Whether easy-dotnet's Roslyn build answers `textDocument/_vs_getProjectContexts`
when it is asked correctly is untested here. Fixing the client filter is needed
either way. If the warning survives 2a, the method genuinely is not registered
by the server and that is a separate upstream conversation.
