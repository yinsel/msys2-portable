# MSYS2 Portable v2026.10.18.1

- 修复直接交互运行 `bash.exe` 时环境未初始化的问题：无需添加 `-l`，即可加载 MSYS 环境、提示符和自定义 `env.sh`。
- 验证登录式、非登录交互式及嵌套 Bash 启动，保留非交互式脚本的原有行为。

- 仅保留 MSYS x86_64 环境，包含 curl、wget、git、make、ssh 和 vim。
- 删除 MinGW、UCRT 和 Clang 环境目录及对应启动器、配置、图标；保留 MSYS 启动文件。
- `init.bat` 自动申请管理员权限，确认 UAC 后设置系统变量 `MSYS2_PATH_TYPE=inherit` 和 `MSYS=winsymlinks:nativestrict`；取消或提权失败时返回非零退出码。
- pacman 镜像切换为 `https://mirror.nju.edu.cn/msys2/`。
- 使用 Windows 用户主目录，并加载可在仓库中自定义的 `etc/profile.d/env.sh`。

解压 ZIP 后直接双击 `usr\bin\bash.exe`，或在终端中运行它；`bash.exe --login -i` 和保留的 MSYS 启动器也可使用。
运行 `init.bat` 后请关闭并重新打开终端应用。

此标签表示本项目便携包的发布日期。使用 `pacman -Q msys2-runtime bash pacman` 查看实际组件版本。
