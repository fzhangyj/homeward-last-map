# 归途：最后一张地图 · 3D 探索版

默认启动为第三人称 3D 剧情探索游戏。保留序章、七站旅途与海边旅店结局，以及三组机关、营地日常、八篇日记和纪念物。新增真实地形、重力碰撞、第三人称镜头与实时剧情演出。使用原创程序几何、Blender 资产、系统字体和程序氛围音，无需下载素材或联网。

## 运行

本机双击 **开始游戏.cmd**，使用桌面现有的 Godot 4.7.2。也可用 Godot 4.7.2 导入 project.godot 后按 F5；其他版本未经本轮验证。标题按 Enter 启程，按 C 继续。窗口默认 1280 × 800，可缩放；中文优先微软雅黑。

## 操作

| 操作 | 按键 |
| --- | --- |
| 相对镜头方向行走 | WASD / 方向键 |
| 快跑 | Shift，消耗体力，松开恢复 |
| 跳跃 | Space；对白中继续对白 |
| 镜头转向 | 按住鼠标右键拖动，或 Q / R |
| 镜头俯仰 | 右键纵向拖动，或 PageUp / PageDown |
| 镜头远近 | 鼠标滚轮 |
| 交谈与收集 | 约 3.7 米内按 E，或点击交互提示 |
| 继续对白 | E / Space / Enter / 鼠标点击 |
| 跳过整段实时演出 | Esc |
| 地图 / 日记 / 伙伴 | M / J / P，或右上按钮 |
| 日记翻页 | 方向键 / 鼠标滚轮 |
| 暂停与收起面板 | Esc |
| 保存 | F5，或暂停菜单 |
| 机关 | 左右选择，↑ / E 切换，Enter 确认，Esc 取消；亦可点击 |

左上角显示任务，右下角罗盘指向目标并显示米数，地图显示主线交互点和营地。暂停、面板与对白期间锁定行走；演出期间锁定探索镜头。沙海风带减速并耗体力，耗尽时回到营地，可以绕行。越界或跌落会返回最近安全落脚点。

每站完成主要事件后，需要回营地听完章末交谈才能出航。提前休息仅恢复体力，不能替代章末交谈。

## 地图与演出

九个地区各装载约 **280 × 240 米**真实地形，有山脊、营地、地标、收集支路和带碰撞的树木、岩石、建筑。营地到出航标直线距离约 228 米。完整验证因覆盖失败出航、营地和读档往返，累计行走 **12,390 米**，这不是玩家最短路线或游戏时长。旧地图使用屏幕像素，不能直接把像素与米比较。

| 航路 | 主要内容 |
| --- | --- |
| 旧港 | 信、茶杯、结识旅伴 |
| 迁徙林 | 名字碎片、风铃、救回孩子 |
| 沉钟城 | 三座钟、机关、船长回家 |
| 永昼雪岭 | 阿满、星镜、妹妹的方向 |
| 无名沙海 | 水囊、风锚、骑士留守风闸 |
| 黑海灯塔 | 引航灯、旋律、兄妹重逢 |
| 黄昏原野 | 日常记忆、骑士告别 |
| 归乡树 | 四个名字、阿满守门 |
| 海边旅店 | 早餐、来信、旅店命名、看海结局 |

六类实时演出包括序幕、飞艇航行、沙海告别、灯室重逢、黄昏记忆与树门。使用角色站位、多机位、缓慢运镜、字幕、黑边和淡入淡出。飞艇甲板、灯塔灯室、沙海风闸、记忆之环和树门内是剧情强制进入的布景，结束或跳过后返回探索；出航结束后进入下一站。演出由引擎实时渲染，没有预渲染视频文件。

## 存档与旧版本

3D 使用独立单槽 `user://homeward_3d_v1.json`（格式 version 3），保存三维位置、镜头、章节、任务、日记与演出记录。Windows 通常位于 `%APPDATA%/Godot/app_userdata/归途：最后一张地图/`。音量单独存于 preferences.cfg，新旅途覆盖当前 3D 槽。

旧 2D 的 homeward_v1.json 不导入 3D，也不会被覆盖。旧工程与说明保留在 **legacy_2d/**，可用 Godot 打开其中 project.godot。对白完成才提交对应事件；演出期间保存探索坐标，读档不会落在远处布景。

## Blender 美术资产

本轮资产由本机 Blender 4.5.10 以 `assets/build_fantasy_assets.py` 生成，来源为原创程序化 bpy 网格与手工 Principled 材质，没有外部模型或联网素材。可编辑源文件为 `assets/fantasy_assets.blend`；游戏实际实例化 `hero_player.glb`、`hero_companion.glb`、`tree_fantasy.glb`、`house_fantasy.glb`、`rock_crystal.glb`、`airship_landmark.glb`、`lighthouse_beacon.glb`，总览导出为 `assets/fantasy_assets.glb`。

重新生成命令：

```powershell
$blender = '<PROJECT_PATH>'
$engine = '<PROJECT_PATH>'
& $blender --background --python assets/build_fantasy_assets.py
& $engine --headless --path . --editor --import --quit
```

人物 GLB 含脸部、眼睛、分层发束、围巾、披风、胸甲、靴子和配饰，伙伴使用独立青绿色/珊瑚配色；树、房屋、晶体岩石、飞艇和灯塔由独立集合复用。`game_3d.gd` 仅将 GLB 作为视觉实例，人物胶囊、树干、房屋盒体、岩石凸包和飞艇甲板碰撞仍在 Godot 独立创建。

草地使用 `assets/meadow.gdshader` 与 MultiMesh 草丛。工程关闭 `.blend` 自动导入，游戏读取已导出的 GLB，修改 Blender 源文件后需运行上面的重建和导入命令。当前为原创低多边形动漫幻想原型，人物仍为简化比例，未达到商业游戏角色精度。

## 开发与验证

main.tscn → game_3d.gd 为默认入口。game_3d.gd 管理三维物理、地图、镜头、演出和存档；story_3d.gd 复用 legacy_2d/game.gd 的中文剧情与面板。根目录 game.gd 与旧 2D 报告为历史记录。

在项目根目录的 PowerShell 执行：

```powershell
$engine = '<PROJECT_PATH>'
& $engine --headless --path . --editor --import --quit
& $engine --headless --path . --fixed-fps 60 -- --self-test-3d
& $engine --path . --rendering-method gl_compatibility -- --capture-3d
```

完整输入路线 **tests/route_3d.gd** 通过真实键盘移动、交互和解机关，按物理查询规划路径，主线不赋值章节、任务或位置。路点容差 0.4 米，超时失败即退出。主线结束后才单独注入跌落位置检查恢复。暂停菜单通过 click handler 验证，不声称系统鼠标端到端测试。

修复后完整路线 **4672 checks / 0 failures**，见 **tests/blender-roof-route.log**。真实 OpenGL 渲染保存 20 张截图，见 **tests/screenshots_3d/** 与 **tests/blender-roof-game-capture.log**；`20-characters-closeup.png`、`21-house-tree.png` 分别覆盖 Blender 角色近景和房屋树木，`02-region.png`、`12-departure.png`、`12-tree.png` 覆盖探索、飞艇和树门演出。截图会直接配置章节，只作渲染证据，通关证据来自输入路线。自动验证不等于按正常阅读速度人工完整游玩；未覆盖全部窗口比例、音频听感或其他平台。详见 **tests/RESULTS_BLENDER.md**，独立模型验收另行记录。

