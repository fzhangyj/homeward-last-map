# 旧港细化结果

已用 **JSCAD @jscad/modeling 2.13.0** 实际建模并导出 GLB，接入游戏旧港；本轮没有调用 Blender 或 GUI 建模软件。Node.js v22.23.2、npm 10.9.8，Godot 4.7.2.stable.official.ed1daf0bf。未发现工作区或 <PROJECT_PATH>

实际读取了任务提供的三张 JPG：704c3d40（湖岸城墙城市）、ddba6234（风车峡谷梯田）、ab070fc4（大树草地）。保留了曲线岸线、分层断崖/草顶台地、风车与花行、分枝大树、城墙/教堂远景等构图线索；不是商业级复刻。

## 实际实现

- `tools/old_port/build_port.cjs` 是可编辑参数源，调用 JSCAD primitives、transforms 和 geom3 生成实体；内置 glTF 2.0 二进制导出器，按材质批处理，不依赖 Blender。
- `assets/old_port/port_landscape.glb`：不规则断面分层岩壁、草顶、连续曲线湖岸/岸石/码头、水面细分、15 行三色花田、三座风车、大树与树群、城墙塔楼/门楼/房屋/双尖塔教堂。
- 风车有八根纵梁、木架斜撑、环廊、格栅帆和局部帆布、门窗与分层屋顶。房屋有 120 片屋面瓦、门板、十字窗框、百叶窗和窗台花箱。树有七根根须、分枝与层次树冠。
- 旧港原散布树与房屋切换至新 `port_tree.glb` / `port_house.glb`，普通树使用 0.64 的视觉系数突出大树；原树干、房屋、地形和任务碰撞完全保留。主线、存档、角色和镜头输入逻辑未改。
- 旧港锥体远山改由导入岩壁远景承担；普通草批次在湖面内隐藏，水面使用轻量程序波纹材质。

| 资产 | 三角形 | 材质 | GLB 大小 |
| --- | ---: | ---: | ---: |
| port_landscape | 296,828 | 32 | 21,391,440 B |
| port_tree | 6,084 | 6 | 442,044 B |
| port_house | 3,136 | 14 | 234,144 B |
| port_windmill | 4,652 | 10 | 340,832 B |

风车已合并进 landscape 场景，单独 GLB 同时保留供编辑复用。具体统计与构建用时见 `assets/old_port/build_manifest.json` 和 `build.log`。

## 验证

- 最终版严格路线：`route-final.log` **4,672 checks / 0 failures / 12,390 m / 79,124 movement frames**，八次章节推进与旅店结局完成。使用原 `tests/route_3d.gd`，未放宽测试、未注入主线章节或任务。
- 最终版镜头输入：`camera-final.log` **14 checks / 0 failures**。
- `before_hashes.json` 与 `after_hashes.json` 可验证 `tests/route_3d.gd`、`tests/old_port_camera.gd` 和 `project.godot` 的 SHA256 相同。
- Godot 重新导入完成，`import.log`、最终路线与镜头日志无脚本解析错误。
- 实际 GPU：NVIDIA GeForce RTX 3050 Laptop GPU，OpenGL 3.3 / NVIDIA 566.14。`after/` 有六张 1280×800 图：全景、风车花田、大树、湖岸城市、瓦片门窗近景和正常探索 UI。已逐张查看；修正了首轮水面被地形顶穿、瓦片朝向、树冠过度遮挡。
- `before/` 保存旧版同六机位渲染，另外保留原 02-region / 02-old-port-panorama。改前由 `backup/game_3d.gd` 实例化，未覆盖当前脚本。固定机位仅用于美术证据，通关证据来自输入路线。
- 最终 GPU 120 帧探索采样：p10 130 FPS，中位 141 FPS，784 draw calls，1,865,156 rendered primitives（包含额外渲染通道）；原版同机位样本中位 139 FPS。样本很短，不能推断稳定长期性能或其他机器表现。
- GPU 截图程序退出时有两条纹理清理 `Texture with GL ID ... leaked 349524 bytes` 信息，改前基线也复现相同数量和字节；没有将其描述为零引擎错误。截图均成功保存，进程退出码为 0，主线和镜头 headless 验证无该信息。

## 调用与复现

```powershell
npm.cmd install --prefix tools/old_port @jscad/modeling --save-exact
node tools/old_port/build_port.cjs
$engine='<PROJECT_PATH>'
& $engine --headless --path . --editor --import --quit
& $engine --headless --path . --fixed-fps 60 -- --self-test-3d
& $engine --headless --path . --script tests/old_port_camera.gd -- --acceptance-3d
& $engine --path . --rendering-method gl_compatibility --script tests/detailed_port/capture_port.gd -- --acceptance-3d
& $engine --path . --rendering-method gl_compatibility --script tests/detailed_port/capture_port.gd -- --acceptance-3d --baseline
```

后续重建安装使用 `npm.cmd ci --prefix tools/old_port`。本轮有一条初始 `npm init -y` 在中文项目目录因 invalid name 失败，未产生根 package.json；实际依赖成功安装在工具子目录，使用其 package-lock 锁定版本。

## 文件范围与限制

唯一修改的既有源码为 `game_3d.gd`。新增计划 `PLAN_DETAILED_PORT.md`、建模工具 `tools/old_port/`、资产 `assets/old_port/` 和证据 `tests/detailed_port/`。`game_3d.diff` 是对原脚本的统一差异；`backup/` 保存原脚本、测试与配置。详细新增文件和 SHA256 见 `changes.json`；`.godot/` 导入缓存和工具 node_modules 属于可重建运行数据。

侧壁和城墙城市为视觉布景，没有新可攀爬碰撞；湖是覆盖原物理地形的装饰水域，没有新增游泳系统。场景仍为低多边形风格，保留原人物与故事资源。细化目标在旧港模型与呈现范围内完成。
