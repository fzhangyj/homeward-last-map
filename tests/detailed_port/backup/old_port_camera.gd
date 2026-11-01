extends SceneTree

var game
var checks=0
var failures=0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks+=1
	print("CAMERA ","PASS " if ok else "FAIL ",message)
	if not ok: failures+=1

func button(index: int, pressed: bool, mask: int) -> void:
	var event=InputEventMouseButton.new()
	event.button_index=index; event.pressed=pressed; event.button_mask=mask
	Input.parse_input_event(event)
	await process_frame

func motion(relative: Vector2, mask: int=0) -> void:
	var event=InputEventMouseMotion.new()
	event.relative=relative; event.position=Vector2(700,400); event.button_mask=mask
	Input.parse_input_event(event)
	await process_frame

func run() -> void:
	# Match the project window so injected deltas use real viewport pixels.
	root.size=Vector2i(1280,800)
	game=load("res://main.tscn").instantiate(); root.add_child(game)
	await process_frame
	game.story.new_game(); game.story.drain_dialogue()
	await physics_frame
	var yaw_before=game.yaw
	await motion(Vector2(50,20))
	check(is_equal_approx(game.yaw,yaw_before),"pointer movement alone keeps view fixed")
	await button(MOUSE_BUTTON_RIGHT,true,MOUSE_BUTTON_MASK_RIGHT)
	await motion(Vector2(50,20),MOUSE_BUTTON_MASK_RIGHT)
	check(is_equal_approx(game.yaw,yaw_before-0.3),"right drag rotates yaw")
	check(is_equal_approx(game.pitch,0.43),"right drag tilts pitch")
	await button(MOUSE_BUTTON_RIGHT,false,0)
	yaw_before=game.yaw
	await motion(Vector2(50,20))
	check(is_equal_approx(game.yaw,yaw_before) and not game.camera_dragging,"release ends drag")
	await button(MOUSE_BUTTON_MIDDLE,true,MOUSE_BUTTON_MASK_MIDDLE)
	await motion(Vector2(-50,-20),MOUSE_BUTTON_MASK_MIDDLE)
	check(is_equal_approx(game.yaw,yaw_before+0.3),"middle drag rotates yaw")
	await motion(Vector2(0,10000),MOUSE_BUTTON_MASK_MIDDLE)
	check(is_equal_approx(game.pitch,1.12),"pitch upper limit remains enforced")
	await motion(Vector2(0,-10000),MOUSE_BUTTON_MASK_MIDDLE)
	check(is_equal_approx(game.pitch,0.10),"pitch lower limit remains enforced")
	await button(MOUSE_BUTTON_RIGHT,true,MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE)
	await button(MOUSE_BUTTON_RIGHT,false,MOUSE_BUTTON_MASK_MIDDLE)
	yaw_before=game.yaw
	await motion(Vector2(20,0),MOUSE_BUTTON_MASK_MIDDLE)
	check(is_equal_approx(game.yaw,yaw_before-0.12),"releasing right preserves held middle drag")
	game.story.overlay="map"
	yaw_before=game.yaw
	await motion(Vector2(20,0),MOUSE_BUTTON_MASK_MIDDLE)
	check(is_equal_approx(game.yaw,yaw_before),"panel locks drag")
	await button(MOUSE_BUTTON_MIDDLE,false,0)
	game.story.overlay=""
	await motion(Vector2(20,0))
	check(is_equal_approx(game.yaw,yaw_before),"release inside panel clears drag")
	await button(MOUSE_BUTTON_RIGHT,true,MOUSE_BUTTON_MASK_RIGHT)
	game.story.talk([["测试","对话锁定"]])
	await motion(Vector2(20,0),MOUSE_BUTTON_MASK_RIGHT)
	check(is_equal_approx(game.yaw,yaw_before),"dialogue locks drag")
	game.story.drain_dialogue()
	game.begin_cinematic("intro")
	check(not game.camera_dragging,"cinematic clears drag state")
	await button(MOUSE_BUTTON_RIGHT,false,0)
	game.end_cinematic()
	game.story.mode="title"
	yaw_before=game.yaw
	await button(MOUSE_BUTTON_RIGHT,true,MOUSE_BUTTON_MASK_RIGHT)
	await motion(Vector2(20,0),MOUSE_BUTTON_MASK_RIGHT)
	check(is_equal_approx(game.yaw,yaw_before),"title does not arm exploration drag")
	await button(MOUSE_BUTTON_RIGHT,false,0)
	game.story.mode="play"
	await button(MOUSE_BUTTON_MIDDLE,true,MOUSE_BUTTON_MASK_MIDDLE)
	game.story.configure_world()
	check(not game.camera_dragging,"region rebuild clears drag state")
	await button(MOUSE_BUTTON_MIDDLE,false,0)
	print("CAMERA INPUT ","PASS" if failures==0 else "FAIL",": ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
