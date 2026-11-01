extends SceneTree
var game
var out_dir="res://tests/detailed_port/after/"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size=Vector2i(1280,800)
	if "--baseline" in OS.get_cmdline_user_args():
		out_dir="res://tests/detailed_port/before/"
		game=Node3D.new()
		game.set_script(load("res://tests/detailed_port/backup/game_3d.gd"))
	else: game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.story.new_game();game.story.drain_dialogue()
	game.set_physics_process(false)
	game.story.visible=false
	await shot("01-panorama",Vector3(-13,46,143),Vector3(-2,8,3),65)
	await shot("02-windmill-terraces",Vector3(-59,12,53),Vector3(-71,7,35),60)
	await shot("03-great-tree",Vector3(-62,11,23),Vector3(-82,8,5),61)
	await shot("04-lake-city",Vector3(87,32,113),Vector3(21,10,-98),60)
	await shot("05-house-detail",Vector3(-54,6,31),Vector3(-61,3,20),52)
	game.story.visible=true
	game.set_physics_process(true)
	game.yaw=-.5;game.pitch=.35;game.zoom=17
	game.body.position=Vector3(-7.5,game.height_at(-7.5,9.2),9.2)
	await create_timer(.8).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir+"06-playable-view.png")
	# Performance samples from actual rendered exploration, not headless mode.
	var samples=[]
	for i in 120:
		await process_frame
		samples.append(Performance.get_monitor(Performance.TIME_FPS))
	samples.sort()
	print("GPU PERFORMANCE fps_p10=",samples[12]," fps_median=",samples[60]," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	print("DETAILED PORT GPU CAPTURES COMPLETE")
	game.queue_free()
	await process_frame
	await process_frame
	quit()
func shot(title: String,p: Vector3,target: Vector3,fov: float) -> void:
	game.camera3d.fov=fov;game.camera3d.position=p;game.camera3d.look_at(target)
	await create_timer(.65).timeout
	await RenderingServer.frame_post_draw
	var err=root.get_texture().get_image().save_png(out_dir+title+".png")
	print("DETAILED PORT GPU ",title," result=",err)
