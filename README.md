# MSYS2 Portable

只包含 **MSYS x86_64** 环境的 MSYS2 便携版，包含 Bash、pacman、基础运行依赖，以及 `curl`、`wget`、`git`、`make`、`ssh`（`openssh` 包）和 `vim`。
不安装 MinGW、UCRT 或 Clang 工具链，并删除这些环境的目录、启动器、配置文件和图标；只保留 MSYS 启动文件。

## 使用

将 ZIP 解压到固定目录，例如 `D:\Tools\msys2`。在 CMD 中运行：

```bat
"D:\Tools\msys2\usr\bin\bash.exe" --login -i
```

PowerShell 中运行：

```powershell
& 'D:\Tools\msys2\usr\bin\bash.exe' --login -i
```

`--login` 用于加载 `/etc/profile` 和 `/etc/profile.d/env.sh`。
`/etc/nsswitch.conf` 设置为 `db_home: windows`，通常使用 Windows 用户配置目录作为主目录。
外部已经设置的 `HOME` 或用户自己的启动脚本仍可能覆盖默认行为。

## 系统环境变量

双击根目录的 `init.bat`，或在 CMD / PowerShell 中运行（PowerShell 使用 `.\init.bat`）。
如果当前进程没有管理员权限，脚本会自动弹出 Windows UAC 请求；确认后以管理员身份继续执行。取消或提权失败时会返回非零退出码。

脚本检查管理员权限，并使用 `setx /M` 设置以下**系统级**变量；已有同名系统变量会被替换：

| 变量 | 值 |
| --- | --- |
| `MSYS2_PATH_TYPE` | `inherit` |
| `MSYS` | `winsymlinks:nativestrict` |

运行后关闭并重新打开终端应用；已有进程的环境不会自动改变。
原生符号链接的创建仍需要 Windows 提供相应权限。
`init.bat` 不用于启动 Bash。

## pacman 镜像

便携包默认使用南京大学镜像 `https://mirror.nju.edu.cn/msys2/`。
镜像配置位于仓库的 `etc/pacman.d/mirrorlist.msys` 和 `etc/pacman.d/mirrorlist.mingw`，构建时覆盖安装包中对应的文件。
MSYS 包使用 `https://mirror.nju.edu.cn/msys2/msys/$arch/`，其他保留的 pacman 仓库配置也指向该镜像。

## 自定义环境

直接编辑仓库中的 [`etc/profile.d/env.sh`](etc/profile.d/env.sh)，构建时会复制到安装包的 `/etc/profile.d/env.sh`。
当前配置将 `vi` 设为 `vim` 的别名，并在登录脚本切换到主目录后，回到有效的 `OLDPWD`：

```bash
alias vi='vim'

if [[ "$PWD" == "$HOME" && -d "${OLDPWD:-}" ]]; then
    cd -- "$OLDPWD"
fi
```

该写法与条件满足时执行 `cd` 的行为一致，也处理了未设置 `OLDPWD` 或无需切换目录的情况。
需要调整软件包时，修改 [构建工作流](.github/workflows/build.yml) 中的 `install` 列表。

## 构建与发布

- 在 GitHub Actions 中手动运行 **Build MSYS-only portable**，或提交到 `main`，获取构建产物。
- 验证通过后，在该次 Actions 运行中下载 `msys2-portable-msys-x86_64` artifact。
- 更新 `VERSION` 和 `RELEASE_NOTES.md`，将它们作为一次提交直接推送到 `main`，会在验证通过后创建对应 tag 并发布 Release。
- 推送以 `v` 或 `c` 开头的 tag 会在验证通过后发布 ZIP 到对应 GitHub Release。

本项目使用日期标签（例如 `v2026.10.18`）标识便携包发布。组件版本以 `pacman -Q msys2-runtime bash pacman` 为准。

构建使用全新的 MSYS2 安装，执行 [`scripts/customize.sh`](scripts/customize.sh)，然后压缩。
ZIP 根目录包含 `init.bat`、`usr`、`etc`，并保留 `msys2.exe`、`msys2.ini`、`msys2.ico` 和 `msys2_shell.cmd`；构建用户的主目录、临时文件和日志不会打包。
验证会将 ZIP 解压到另一目录，直接运行其中的 `bash.exe`，检查工具、主目录、工作目录、别名、包依赖和 MSYS 启动文件，并确认其他环境的目录、启动器、配置及图标均已删除，再验证 `init.bat` 的系统环境变量写入。
验证还会从配置的南京大学镜像下载 MSYS 包数据库，并执行 `init.bat` 的 RunAs 重启路径；CI 已具有管理员权限，不会显示交互式 UAC 确认界面。

构建时删除 `mingw32`、`mingw64`、`ucrt64`、`clang32`、`clang64`、`clangarm64` 目录及其同名 `.exe`、`.ini`、`.ico` 文件，同时删除 `/etc/msystem.d/` 中对应的非 MSYS 环境配置。
保留 `/etc/profile`、`/etc/msystem`、`/etc/msystem.d/MSYS`、pacman 配置等正常运行所需的文件。
`scripts/customize.sh` 只用于构建中的全新安装。

本项目基于 [dirkarnez/msys2-portable](https://github.com/dirkarnez/msys2-portable)，使用 [msys2/setup-msys2](https://github.com/msys2/setup-msys2)。
