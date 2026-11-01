# 实施验证记录

环境：Windows，Godot 4.7.2 stable，OpenGL Compatibility，NVIDIA GeForce RTX 3050 Laptop GPU。

## 已实际执行

1. 首次 headless 导入发现了自定义 `wrap` 与 GDScript 内置函数冲突，已更名为 `wrap_text` 并修复。
2. 完整流程自测：`Godot_v4.7.2-stable_win64_console.exe --headless --path . -- --self-test`。
3. 实际 OpenGL 渲染：`Godot_v4.7.2-stable_win64_console.exe --path . --rendering-method gl_compatibility -- --capture`。14 张 PNG 均返回保存结果 0。
4. 已人工打开并检查标题、序章对白、七章地区、尾声、地图、钟盘机关、完整日记和伙伴页截图：中文可显示，任务与操作提示可见，面板未出现截断；它们是渲染截图检查，并非独立完整视觉验收。

## 自动流程覆盖

- 序章 → 七章 → 海边旅店尾声 → 结局。
- 所有必需交互物存在且在互动半径内能被选中。
- 任务未完成时不可出航；剧情完成后仍需营地交谈。
- 三种机关的错误答案不会通过，正确答案触发剧情并置位。
- 四份名字、三个星镜、三座钟、水囊、风锚、灯与记忆收集。
- 日记共八篇、骑士围巾纪念、沙风带可绕过。
- 合成物理键 D 导致实际移动；M 与 Esc 通过 Godot 输入管线开关地图。
- 实际写入并读取专用测试存档，确认结局、全局旗标与八篇日记恢复。
- 失败检查不会被后续成功覆盖；测试有失败时退出码为 1。

最近一次通过输出：

```text
HOMEWARD SELFTEST PASS: 271 checks; prologue + 7 chapters + epilogue; 3 puzzles; 8 camp gates; keyboard movement; real save/load.
```

## 诚实范围

自动流程会将角色移动到交互点附近以测试路线门槛，不模拟完整地图步行寻路。键盘移动单独进行了真实输入测试。截图不验证音响实际听感，也不等于真人连续通关。没有宣称已执行 25 小时内容或独立视觉验收。

