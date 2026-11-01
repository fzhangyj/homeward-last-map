# 独立验收 · 2026-10-18

结论：**needs_changes**。游戏核心流程通过，但 README 推荐的双击启动入口在本机实测无法启动，需修复后复验。

## 范围与独立性

按 DEVELOPMENT_PLAN.md 验收紧凑中文 2D 单机冒险原型；不按 25–30 小时商业成品或 3D 开放世界衡量。验收直接阅读 project.godot、main.tscn、game.gd、README.md 和实际启动器，独立执行 Godot 4.7.2。没有用执行 agent 的结论作为证据。

## 必须修复

`开始游戏.cmd`：PowerShell 在项目根目录执行 `& '.\开始游戏.cmd'`，退出码 1，输出：

```text
'INE' is not recognized as an internal or external command,
operable program or batch file.
'请使用' is not recognized as an internal or external command,
operable program or batch file.
Press any key to continue . . .
```

独立从隐藏 cmd 进程执行该入口，同样没有产生 Godot 游戏进程。文件当前为 UTF-8、LF 换行；建议以 cmd 支持可靠的 CRLF 保存，并在本机真实执行后确认进程存在及窗口响应。不要仅检查路径字符串。

## 已通过的实际检查

- Godot `--headless --path . --editor --import --quit`：退出 0，无解析错误。
- 独立执行工程 `--self-test`：退出 0，最初读取版本报告 268 checks；此自测大部分直接定位角色并调用交互，不能单独证明路线可行。
- 为覆盖此限制，新增独立验收脚本 `tests/independent_acceptance.gd`，执行 `--headless --path . --fixed-fps 60 --script res://tests/independent_acceptance.gd`：**569 checks, 0 failures，退出 0**。
- 独立脚本不赋值章节、位置、任务 flag 或机关值；通过 Input.parse_input_event 发送 WASD、E、方向键、Enter、Esc、M/J/P/F5/C，角色逐步走完序章与七站，抵达旅店结局。对象采用不同于工程自测的收集顺序，沙海按安全路线实际绕行。
- 每站均检查未完成任务不能出航、完成主线未休息不能出航；三个机关均验证错误解、取消、重新开启及键盘解题。
- 每站 F5 后实际读取独立 JSON 存档，检查章节、休息 flag；经暂停菜单回标题，再用 C 继续，检查章节、flag、位置恢复；结局后重开检查清空任务与完成状态。暂停菜单坐标按钮调用真实 click handler；因 headless 无窗口指针，该按钮测试不冒充系统鼠标端到端测试。
- 原创中文叙事包含兄妹重逢、沈知微牺牲、闻笛留下、阿满告别；八篇日记及围巾/茶杯/汤/领口等纪念细节在真实实现中存在，完整输入路线可达。
- 独立执行图形模式 `--path . -- --capture`，NVIDIA OpenGL 3.3 渲染，14 张 PNG 均 result=0，退出 0。抽查标题、对白、地图、机关、归乡树、伙伴面板，中文可读，主要文字/按钮无明显遮挡。

## 限制与非阻断观察

- 没有人工以正常阅读速度完整游玩 20–35 分钟；没有验证音频听感、全部窗口缩放和跨平台字体。独立输入运行证明流程与存档可达，不等于全部人工体验测试。
- 截图采集程序会直接设置章节与状态；截图只作渲染/布局证据，不作通关证据。
- 营地在任务前访问也会标记 rest，之后可直接出航；因此 README「完成主要事件后必须回营地」比实现严格。尤其沙海先休息再牺牲会跳过牺牲后的营地汤对白。可调整描述或将章末休息标记与任务完成后的营地交谈关联。此处不影响计划所需营地体验与通关。
- 验收时 game.gd SHA-256：543B7A9AAEF0DA752C907D7CB9095D5E39D8D1683476D83687269F6B2D351577。最终交付前若再改核心逻辑，需重新跑对应验证。
