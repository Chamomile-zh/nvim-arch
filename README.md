# nvim-arch

> 一套重度定制、几乎不依赖插件管理器的 Neovim 配置。

基于 **Neovim 0.12** 的原生能力构建：用 `vim.pack` 管理插件、`vim.lsp.enable` 启动语言服务器、`vim.loader` 加速启动 —— **没有** lazy.nvim、**没有** mason、**没有** lspconfig。Dashboard、状态栏、代码运行器、命令编辑器等大量 UI 均为手写实现，插件只保留少数必要件。

---

## ✨ 特性

- **原生插件管理**：`vim.pack` + 手写迷你懒加载器，插件清单与配置分离，`nvim-pack-lock.json` 锁定版本
- **原生 LSP**：`lsp/<server>.lua` 直接定义服务器，`vim.lsp.enable()` 一键启用
- **blink.cmp** 补全（LSP / 路径 / buffer / snippet）
- **自绘 UI**：Dashboard 启动页、状态栏（分段 + 事件驱动）、浮动终端代码运行器
- **可编辑的命令确认**：按 `<F5>` 弹出预填好的完整命令，改完再执行
- **自写增强**：彩虹括号、surround、快速替换、wildfire、todo、wiki、agenda、markdown 表格格式化等
- **5 套手写配色**：gruvbox / tokyonight / nord / solarized / mariana
- 极快的启动速度（重活全部推迟到 `UIEnter` 之后）

---

## 📦 依赖

### 必需

| 依赖 | 说明 |
|---|---|
| **Neovim ≥ 0.12** | 依赖 `vim.pack` / `vim.lsp.enable` / `vim.system` 等新 API |
| **git** | 插件下载 |
| **[fzf](https://github.com/junegunn/fzf)** | fzf-lua 的底层 |
| **[ripgrep](https://github.com/BurntSushi/ripgrep)** (`rg`) | 内容搜索 |

### 语言服务器（按需安装）

配置文件在 `lsp/` 目录，缺哪个语言就装哪个：

| 配置 | 服务器 | 安装示例 |
|---|---|---|
| `clangd.lua` | clangd | `sudo pacman -S clangd` |
| `luals.lua` | lua-language-server | `sudo pacman -S lua-language-server` |
| `pyright.lua` | pyright | `npm i -g pyright` |
| `gopls.lua` | gopls | `go install golang.org/x/tools/gopls@latest` |
| `rust_analyzer.lua` | rust-analyzer | `rustup component add rust-analyzer` |
| `tsls.lua` | typescript-language-server | `npm i -g typescript typescript-language-server` |
| `bashls.lua` | bash-language-server | `npm i -g bash-language-server` |
| `zls.lua` | zls | `sudo pacman -S zls` |
| `cssls.lua` / `html.lua` / `jsonls.lua` | vscode-*-language-server | `npm i -g vscode-langservers-extracted` |
| `cmake.lua` | cmake-language-server | `pip install cmake-language-server` |

> 想临时禁用一个服务器：把对应文件移走，或参考 `lsp/rust_analyzer.lua` 自行调整。

### 格式化工具（`;f` / guard.nvim）

| 语言 | 工具 |
|---|---|
| C / C++ | `clang-format` |
| Python | `black` |
| Lua | `stylua` |
| Shell | `shfmt` |
| Go / HTML / CSS / JS / JSON / Rust | 由 LSP 格式化 |

### 运行 / 编译（Code Runner 按文件类型调用）

| 语言 | 依赖 |
|---|---|
| C | `gcc` |
| C++ | `g++` |
| Python | `python3` |
| Lua | `luajit` |
| Shell | `bash` |
| Go | `go` |
| Rust | `rustc` / `cargo`（检测到 `Cargo.toml` 自动切换） |
| TypeScript | `deno` |
| Zig | `zig` |
| HTML | `live-server` |
| Markdown | `typora` |

### 平台 / UI 相关

| 依赖 | 说明 |
|---|---|
| **Nerd Font** | 图标渲染（状态栏、Dashboard、补全图标） |
| **Wayland** + `wl-copy` / `wl-paste` | 剪贴板、粘贴图片到 Markdown |
| **Kitty** 终端 | `image.nvim` 的后端 |
| **magick** | 图片处理 |
| **zsh** | 浮动终端的默认 shell |
| **firefox** | `gX` 搜索、`live-server` 打开的浏览器 |

---

## 🚀 安装

```bash
# 1. 克隆到标准配置目录（已有配置请先备份）
git clone https://github.com/Chamomile-zh/nvim-arch.git ~/.config/nvim

# 2. 首次启动：会自动通过 vim.pack 下载插件（需要联网）
nvim

# 3. 安装你需要的语言服务器（见上表）
```

- 插件版本由 `nvim-pack-lock.json` 锁定，`PackUpdate` 时保持一致。
- 删除所有插件缓存：`make clean`（等价于清空 `~/.local/share/nvim/site/pack/`）。
- 想换配色：改 `lua/internal/init.lua` 里的 `vim.cmd.colorscheme('gruvbox')`。

> ⚠️ 配置对平台有假设（Wayland + Kitty + zsh + Arch）。其他环境需按需改 `lua/core/init.lua` 里的平台相关项。

---

## ⌨️ 快捷键

`<leader>` = **空格**。

### 基础编辑 / 窗口

| 键 | 功能 |
|---|---|
| `jj` | 退出插入模式 |
| `W` / `Q` / `B` | 保存 / 退出 / 关闭 buffer |
| `ca` | 复制整个 buffer 到系统剪贴板 |
| `j` / `k` | 软换行下逐行移动 |
| `J` / `K` | 向下 / 向上翻半屏 |
| `H` / `L` | 行首 / 行尾 |
| `Y` | 复制到系统剪贴板 |
| `<C-h/j/k/l>` | 窗口间移动 |
| `<leader>W` | 循环切换窗口 |
| `<leader>sh/sj/sk/sl` | 分屏（左 / 下 / 上 / 右） |
| `<leader>smv/smh` | 布局转竖 / 横 |
| `<Up/Down/Left/Right>` | 调整窗口尺寸 |
| `<leader>sc` | 拼写检查开关 |
| `<leader>sw` | 软换行开关 |
| `<leader>cc` | 注释 / 取消注释 |
| `<leader>rc` | 删除选中行内的注释 |
| `<leader><leader>` | 跳到 `<++>` 占位符 |
| `<leader>vim` | 打开本配置 |

### 搜索 / 文件（fzf-lua）

| 键 | 功能 |
|---|---|
| `<leader>ff` | 项目文件 |
| `<leader>fw` | 内容搜索（live grep） |
| `<leader>fd` | 指定目录搜索 |
| `<leader>fo` | 最近文件 |
| `<leader>b` | buffer 列表 |
| `<leader>fh` | 帮助标签 |
| `<leader>fk` | 快捷键列表 |
| `<leader>fm` | man 手册 |
| `<leader>n` | Noice 消息历史 |

### LSP / 代码导航

| 键 | 功能 |
|---|---|
| `<leader>pd` | 悬浮预览定义 |
| `<leader>gp` | 跳转定义 |
| `<leader>gh` | LSP finder |
| `<leader>pr` | 查找引用 |
| `<leader>K` | 悬浮文档 |
| `<leader>rn` | 重命名 |
| `<leader>ca` | 代码动作 |
| `d[` / `d]` | 上一个 / 下一个诊断 |
| `<leader>o` | 当前文件符号 |
| `<leader>d` / `<leader>D` | 文档 / 工作区诊断 |

### 运行 / 构建（Code Runner）

| 键 | 功能 |
|---|---|
| `<F5>` | 运行（弹出预填命令，可编辑后回车执行） |
| `<F10>` | 居中大窗运行 |
| `<F6>` | 编译（小窗看报错） |
| `<F11>` | 居中大窗编译 |

> 命令编辑器默认 **Normal 模式**：`i` / `a` / `A` 进入编辑，`<CR>` 执行，`<Esc>` / `q` 取消。多条命令用 `&&` 连接。

### Git（gitsigns）

| 键 | 功能 |
|---|---|
| `g[` / `g]` | 上一个 / 下一个 hunk |
| `<leader>H` | 预览 hunk |
| `<leader>gd` | 对比当前 hunk |
| `<leader>gr` | 重置 hunk |
| `<leader>lg` | 打开 Lazygit |

### 终端 / 文件管理

| 键 | 功能 |
|---|---|
| `<A-t>` | 切换浮动终端 |
| `<A-f>` | 聚焦终端 |
| `<A-r>` | 终端切换位置（终端内） |
| `<A-q>` | 关闭终端进程（终端内） |
| `<A-m>` | 终端内退出插入模式 |
| `<A-x>` | 打开 Shell |
| `<leader>ra` | 打开 Yazi |

### 文本对象 / 编辑增强

| 键 | 功能 |
|---|---|
| `cs` / `rs` / `S`(visual) | 改 / 删 / 加 surround |
| `<leader>ss` | 快速替换（当前词） |
| `<CR>` | wildfire 扩展选区 |
| `f` / `F` | 字符跳跃 |
| `<C-t>` | 标记跳转（toggle mark） |
| `if` / `af` | 函数内 / 外（textobject） |
| `ic` / `ac` | 类内 / 外 |
| `as` | 局部作用域 |
| `<leader>iw` | 反转单词大小写 |
| `;f` | 格式化（guard） |

### 其他

| 键 | 功能 |
|---|---|
| `<leader>ww` | 打开 Wiki |
| `<leader>td` / `<leader>tD` | Todo（全部 / 未完成） |
| `<leader>tm` | 插入代码模板 |
| `gX` | 用 Bing 搜索光标词 / 选中文本 |
| `gs` | 输入关键词搜索 |
| `<leader>l` | Markdown 中粘贴剪贴板图片 |

---

## 🗂️ 目录结构

```
~/.config/nvim
├── init.lua                  # 入口
├── lua/
│   ├── core/                 # 全局变量 / 选项 / keymap DSL
│   ├── modules/              # 插件清单 + 懒加载器 + 各插件配置
│   ├── keymap/               # 快捷键定义
│   └── internal/             # 自研特性（dashboard/status/compile/...）
├── lsp/                      # 语言服务器配置（每个文件一个服务器）
├── colors/                   # 手写配色
├── after/                    # ftplugin / syntax / treesitter queries
├── snippets/                 # VSCode 格式代码片段（blink 使用）
├── template/                 # 代码脚手架模板
└── nvim-pack-lock.json       # 插件版本锁定
```

---

## 📝 常用命令

| 命令 | 说明 |
|---|---|
| `:Run [ft]` / `:Build` | 运行 / 编译 |
| `:PackUpdate` / `:PackStatus` | 更新 / 查看插件 |
| `:PackLoaded` / `:PackDelete` | 查看已加载 / 删除插件 |
| `:Dashboard` / `:Agenda` | 启动页 / 任务清单 |
| `:Template` | 插入代码模板 |
| `:Compile` | 编译并解析 quickfix |
| `:Chdir` | 切换到当前文件目录 |
| `:LspLog` / `:LspDebug` | LSP 日志 |

---

## 🙏 致谢

- [blink.cmp](https://github.com/Saghen/blink.cmp) · [fzf-lua](https://github.com/ibhagwan/fzf-lua) · [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) · [lspsaga.nvim](https://github.com/nvimdev/lspsaga.nvim) · [noice.nvim](https://github.com/folke/noice.nvim) · [guard.nvim](https://github.com/nvimdev/guard.nvim) · [indentmini.nvim](https://github.com/nvimdev/indentmini.nvim) · [image.nvim](https://github.com/3rd/image.nvim) · [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
