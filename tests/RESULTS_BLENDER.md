# Blender 美术验证

范围见 ../PLAN_BLENDER.md。实际使用 Blender 4.5.10 生成可编辑 assets/fantasy_assets.blend 和七组游戏 GLB；源脚本 assets/build_fantasy_assets.py。

- tests/blender-build-final.log：Blender 导出完成，退出码 0。
- tests/blender-import-final.log：Godot 导入完成，退出码 0。关闭 .blend 自动导入，运行期读取 GLB。
- tests/blender-route-final.log：严格输入路线 4672 checks、0 failures、12390m walked、79122 movement frames。碰撞保留，测试仍为 0.4 米路点容差与 240 帧超时。
- tests/blender-capture-final.log：20 张探索/面板/演出截图 result=0。
- tests/blender-closeups.log：两个独立资产展示场景截图 result=0，使用游戏同一 GLB。最近一轮近景渲染设备为 Intel UHD Graphics；不将所有截图统称 NVIDIA 渲染。

截图位于 screenshots_3d：20-characters-closeup.png 是人物正面，21-house-tree.png 是房屋与树木展示，02-region.png 是实际探索，12-departure.png 与 12-tree.png 是实时演出。展示场景不作为通关证据。screenshots_before_blender 为阶段性对比资料，可能已含初轮换模，不能作为严格的初始版本基准。

已修正人物和树干轴向、屋顶朝向、刘海遮眼、袖子姿态、道路背面不可见；保留独立 Godot 碰撞。人物和地形仍是简化低多边形原型，缺少精细角色拓扑、绑定和商业级贴图；当前是向明亮动漫幻想方向的美术调整。未覆盖正常阅读速度人工通关、全部分辨率、音频听感与其他平台。

独立验收结果见 ../ACCEPTANCE_BLENDER.md；模型调用记录见 ../check-run-blender-calls.json。

## 首轮验收返工

首轮独立验收 needs_changes，具体为菱形锥屋顶未覆盖矩形墙角且缺少瓦层。已重做为双坡厚屋面、96 块错缝蓝青瓦、连续木檐与实心山墙。真实 Blender、GLB 导入、四角覆盖检查及正面/侧面截图已重做。最新截图增加 22-house-roof-front.png 和 23-house-roof-oblique.png。

本轮返工日志为 assets/blender-roof-build.log 与 tests/blender-roof-{geometry,inspect,import,closeups,game-capture,runtime,route}.log。严格路线仍 4672/0，独立碰撞检查脚本运行 138/0。产品游戏与路线脚本未因屋顶返工改变；最新模型以本轮日志和独立复验为准。

最终独立复验因协作接口不可用、备用 App 派发被拒绝而受阻。首轮报告保留原 needs_changes，不能把实施者运行验收脚本称作独立批准；详细工具错误和模型元数据见 ../CHECK_RUN_BLENDER.md。
