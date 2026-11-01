extends SceneTree

var checks=0
var failures=0

func check(value: bool, message: String) -> void:
	checks+=1
	if not value:
		failures+=1; push_error("COLLISION REGRESSION FAIL: "+message)

func has_shape(node: Node) -> bool:
	for child in node.get_children():
		if child is CollisionShape3D and child.shape != null: return true
		if has_shape(child): return true
	return false

func capsule_blocked(game: Node, capsule: CapsuleShape3D, body: CharacterBody3D, point: Vector3) -> bool:
	var probe=PhysicsShapeQueryParameters3D.new()
	probe.shape=capsule; probe.exclude=[body.get_rid()]
	probe.transform=Transform3D(Basis.IDENTITY,point)
	return not game.get_world_3d().direct_space_state.intersect_shape(probe,32).is_empty()

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game=load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	check(has_shape(game.markers["exit"]),"departure gate has blocking shapes on both posts and beam")
	var capsule=CapsuleShape3D.new(); capsule.radius=0.38; capsule.height=1.8
	var house=Vector3(-61,game.height_at(-61,20)+3.0*0.7,20)
	check(capsule_blocked(game,capsule,game.body,house),"player capsule cannot occupy old-port house")
	var rotated_house=Vector3(35.87466,4.751945,42.32332)
	check(capsule_blocked(game,capsule,game.body,rotated_house),"rotated old-port house collision follows its 0.6 rad orientation")
	var windmill_support=Vector3(-67.745,1.007663,37.1)
	check(capsule_blocked(game,capsule,game.body,windmill_support),"outer timber windmill support blocks the player")
	var windmill_brace=Vector3(-68.055,game.height_at(-71,35)+1.7325,35.0)
	check(capsule_blocked(game,capsule,game.body,windmill_brace),"diagonal windmill brace blocks the player")
	for dock_crate in [Vector3(36,0.722059,70),Vector3(38,0.819635,69),Vector3(39,0.716657,71)]:
		check(capsule_blocked(game,capsule,game.body,dock_crate),"dock crate blocks the player at %s" % dock_crate)
	print("COLLISION REGRESSION: ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
