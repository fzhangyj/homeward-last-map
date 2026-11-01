# 3D 实施验证 · 2026-10-18

范围依据 ../PLAN_3D.md 与 ../PLAN_BLENDER.md。本文件记录实施与 Blender 资产验证结果，不代表独立验收通过。

## Blender 资产验证 · 2026-10-18

本节为阶段记录。最新模型调整、截图设备与独立验收请以 RESULTS_BLENDER.md 和 ../ACCEPTANCE_BLENDER.md 为准；下述旧设备/哈希记录不代表当前全部文件。

- Blender 4.5.10 实测运行 `assets/build_fantasy_assets.py`，生成可编辑 `assets/fantasy_assets.blend`、总览 `assets/fantasy_assets.glb` 与 7 个按集合拆分的游戏 GLB。资产源为脚本内原创 bpy 网格和材质，无外部下载。
- Godot 4.7.2 强制重导入日志见 `tests/blender-import-final.log`；导入后的包围盒复核见 `tests/probe-blender2.log`，主角头部 y=2.18、躯干 y=1.35、腿 y=0.40，确认 Blender Z-up 到 Godot Y-up 后角色正向站立。
- `game_3d.gd` 的 `fantasy_asset()` 实例化 GLB 视觉层。碰撞继续由 Godot 独立创建：CharacterBody3D 胶囊、树干圆柱、房屋 BoxShape3D、岩石凸包和飞艇甲板 BoxShape3D，未通过关闭障碍或放宽路线检查来适配模型。
- 真实 RTX 3050 Laptop / OpenGL 3.3 capture 见 `tests/blender-capture-final.log`，20 张截图全部 `result=0`。截图中的人物已站立，树冠、房屋屋檐/窗框、晶体岩石、飞艇和树门均可见。

- Godot 4.7.2 导入退出 0，见 blender-import-final.log。legacy_2d 保留独立工程，嵌套工程提示不影响资源加载。
- 完整严格输入路线：4672 checks / 0 failures，12390m walked / 79122 movement frames，见 blender-route-final2.log。
- NVIDIA RTX 3050 Laptop / OpenGL 3.3，20 张 GPU 截图保存 result=0，见 blender-capture-final.log 与 screenshots_3d。抽查探索和飞艇/树门演出，站立角色、明亮树屋与中文面板可见。

route_3d.gd 保留 0.4 米路点容差、240 帧上限、失败退出。主线无位置传送、章节或 flag 注入，真实输入覆盖移动、跳跃与落地、镜头、面板锁定、演出锁定和跳过、三组机关错误解与取消、章末营地、每章磁盘继续、结局与新游戏。主线结束后独立注入跌落位置检查恢复；暂停按钮调用 click handler，不声称系统鼠标端到端。

最初地形三角绕序导致背面碰撞失效，已修正。第二章的根因是盒状建筑用凹面三角网，形状查询可能漏掉完全处于建筑内部的采样点，误标可走。父代理改为 StaticBody3D + 实体 BoxShape3D，保留碰撞，严格路线因此通过。最终修复没有禁用景物碰撞、放宽检查或途中传送。

仍是程序几何原型，没有真人配音或预渲染影片。未按正常阅读速度人工完整游玩，未检查全部窗口比例、音频听感及跨平台字体。旧 2D 报告为历史证据。

## 启动器复查

实施代理实测执行 开始游戏.cmd，创建 Godot_v4.7.2-stable_win64.exe 游戏进程 PID 34672，命令行 --path 指向当前项目；检查后停止该次验证进程。启动器为 ASCII / CRLF，9 对 CRLF。此项证明进程启动，不代替人工窗口交互验收。

最终核心 SHA256：
- game_3d.gd: 73478418622E9A589C9ABC8C5B8E733D97045CEA85D4B26970575148AB171DE5
- story_3d.gd: C3A815993FC7CD2238971F5D8D5FC85B3205DC613AAFEC37E1F37467BEEFE8DD
- tests/route_3d.gd: 3C14B3AD6A00000F5A84EC8E2A95F34CBDA0D6CF8484D6937BCC022F05B3BD3B

## Blender 屋顶 R1 返修 · 2026-10-18

- `assets/build_fantasy_assets.py` 的房屋现用沿 Z 方向的矩形双坡屋顶，连续覆盖至 x±4.5、z±3.72；檐口 y=4.62 高于墙顶 y=4.4。两侧坡板有厚度，蓝青瓦片按行错缝；山墙填面、屋脊盖和檐口/山墙封边收口。门窗与木框保留。
- Blender 4.5.10 重建 `.blend`、总览 GLB 和七个资产 GLB：`assets/blender-roof-build.log`。独立打开 `.blend` 后，`tests/blender-roof-inspect.log` 确认七组资产均通过，House_Fantasy 为 121 个网格、含 `Roof_tile_blue` 与 `Roof_tile_cyan` 材质。Godot 4.7.2 强制重导入见 `tests/blender-roof-import.log`。
- `tests/probe_roof_geometry.py` 对已保存 `.blend` 做垂直射线检查：四个墙角 (x±3.8,z±3.0) 均被坡板在 y=5.0225 截住；两块坡板最低 y=4.4884，纵深 z±3.72，实际瓦片 96 个。见 `tests/blender-roof-geometry.log`。
- RTX 3050 / OpenGL 3.3 重拍了 `tests/screenshots_3d/22-house-roof-front.png`、`23-house-roof-oblique.png` 和探索场景 `02-region.png`；近景可见墙顶三角填面、完整檐口覆盖和错缝瓦层。资产运行检查 138 checks / 0 failures；严格输入路线 4672 checks / 0 failures、12390m、79122 movement frames，结果见 `tests/blender-roof-runtime.log` 与 `tests/blender-roof-route.log`。`game_3d.gd` 和 `tests/route_3d.gd` 未修改。
