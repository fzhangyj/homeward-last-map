# JSCAD 旧港模型

本目录使用独立参数建模库 JSCAD `@jscad/modeling` 2.13.0，Node.js v22.23.2、npm 10.9.8。此次没有调用 Blender 或建模 GUI。

在项目根目录执行：

```powershell
npm.cmd ci --prefix tools/old_port
node tools/old_port/build_port.cjs
& '<PROJECT_PATH>' --headless --path . --editor --import --quit
```

`build_port.cjs` 是可编辑源：`ringCliff` 管理不规则岩层/草顶，`landscape` 管理湖岸、花行、风车分布，`windmill` 管理格栅帆与斜撑木架，`house` / `roof` 管理门窗与铺瓦，`tree` 管理树根/分枝/多层树冠，`city` 管理城墙塔楼与教堂。模型单位为米、Y 轴向上；高度函数与游戏一致。确定性随机种子使重建几何可复现。

几何通过 JSCAD 的实体/变换/geom3 API 真正生成，再由脚本中的 glTF 2.0 导出器按材质批处理写入 GLB。`assets/old_port/build_manifest.json` 记录各模型的面数、材质数与尺寸。`port_landscape.glb` 内含风车与大树实例的合并几何，`port_windmill.glb` 另行保留便于复用编辑。

旧港导入的是视觉场景；原物理地形、任务碰撞、树干与房屋碰撞保持原实现。远景城堡和侧壁属于布景，不能作为新可攀爬区域；湖面为覆盖原地形的装饰水面，未增加游泳系统。其他章节继续使用原有资产。
