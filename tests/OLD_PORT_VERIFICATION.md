# 旧港与视角修复验证 · 2026-10-21

执行引擎：Godot 4.7.2 stable，Windows，OpenGL 3.3 Compatibility / NVIDIA GeForce RTX 3050 Laptop GPU。

工作目录：`<PROJECT_PATH>

引擎路径：`<PROJECT_PATH>

## 实际改动

- 修复旧港新增代码的非法 C 风格三元表达式；后续将原有漂浮方形台地替换为贴合地形的低台地。
- 风车改为带塔身、红顶、竖直四叶轮的几何模型。风车、房屋、树木依据 `height_at` 贴地；港湾采用椭圆形水面，加入程序白云并降低旧港远山尖峰。新增景物保持无碰撞，未修改主线路线和既有碰撞。
- 鼠标右键和中键依据事件中的实际按钮掩码控制拖动，释放其中一键时仍可用另一键继续拖动。标题界面禁止探索视角操作，重建区域和开始演出时清空拖动状态。
- 添加 `tests/old_port_camera.gd` 输入回归检查和 `02-old-port-panorama.png` 渲染视角。

## 运行命令与最终结果

下列命令均在本工作目录执行；`<Godot>` 代表上述完整引擎路径。

```powershell
& '<Godot>' --headless --path '<PROJECT_PATH>' --editor --quit
& '<Godot>' --headless --path '<PROJECT_PATH>' --script res://tests/old_port_camera.gd -- --acceptance-3d
& '<Godot>' --path '<PROJECT_PATH>' -- --capture-3d
& '<Godot>' --headless --path '<PROJECT_PATH>' --fixed-fps 60 -- --self-test-3d
```

- 导入：退出码 0，无脚本或资源错误。仅有已存在的 `legacy_2d/project.godot` 被忽略警告。日志 `old-port-import.log`。
- 鼠标输入：退出码 0，`CAMERA INPUT PASS: 14 checks, 0 failures`。覆盖右键、中键、松键、双键组合、俯仰上下限、地图/对话锁定、标题界面、演出和区域切换重置。日志 `old-port-camera.log`。
- GPU 渲染：退出码 0，21 张截图均为 `result=0`，末行 `3D GPU CAPTURES COMPLETE: tests/screenshots_3d`。实际查看旧港全景，风车、台地、树木、房屋、水面及白云可见。日志 `old-port-capture.log`。
- 完整主线：退出码 0，`HOMEWARD 3D ROUTE PASS: 4672 checks, 0 failures, 12390m walked, 79122 movement frames`。日志 `old-port-route.log`。

`tests/route_3d.gd` 未修改，仍为路点容差 0.4m、240 帧失败上限。SHA-256：`3C14B3AD6A00000F5A84EC8E2A95F34CBDA0D6CF8484D6937BCC022F05B3BD3B`。

## 视觉边界

画面为现有低多边形原型的程序景观改造，使用参考图中的明亮草坡、风车、树木和港湾元素。未使用网页版 Blender；没有将当前成品描述成参考图级别的高精度场景。

本文件为执行检查记录，独立验收结论由父任务另行记录。
