extends Node

# Full route: no assignment of chapter, flags, player position or puzzle solution.
# The grid samples real physics colliders; movement and interactions use input.
var game
var s
var checks=0
var failures=0
var grid: AStarGrid2D
var travel_distance=0.0
var physics_frames=0

func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures+=1; push_error("3D ROUTE FAIL: "+message)

func key(code: int,pressed: bool) -> void:
	var e=InputEventKey.new(); e.physical_keycode=code; e.keycode=code; e.pressed=pressed
	Input.parse_input_event(e)

func tap(code: int) -> void:
	key(code,true); await get_tree().physics_frame
	key(code,false); await get_tree().physics_frame

func settle(n: int=3) -> void:
	for i in n: await get_tree().physics_frame

func dismiss(skip: bool=false) -> void:
	if skip and not game.cinematic.is_empty(): await tap(KEY_ESCAPE)
	var guard=0
	while not s.dialogue.is_empty() and guard<60:
		await tap(KEY_E); guard+=1
	check(s.dialogue.is_empty(),"dialogue/scene terminates")
	await settle()

func build_grid() -> void:
	await settle(4)
	grid=AStarGrid2D.new()
	grid.region=Rect2i(0,0,111,95); grid.cell_size=Vector2(2.5,2.5)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var shape=CapsuleShape3D.new(); shape.radius=1.1; shape.height=2.2
	var q=PhysicsShapeQueryParameters3D.new(); q.shape=shape; q.exclude=[game.body.get_rid()]
	for x in 111:
		for z in 95:
			var p=cell_world(Vector2i(x,z)); p.y=game.height_at(p.x,p.z)+1.45
			q.transform=Transform3D(Basis.IDENTITY,p)
			if not game.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(): grid.set_point_solid(Vector2i(x,z))

func cell_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x*2.5-137.5,0,cell.y*2.5-117.5)

func to_cell(p: Vector3) -> Vector2i:
	return Vector2i(roundi((p.x+137.5)/2.5),roundi((p.z+117.5)/2.5)).clamp(Vector2i.ZERO,Vector2i(110,94))

func walk_to(target: Vector3) -> void:
	var start=to_cell(game.body.position)
	var end=to_cell(target)
	grid.set_point_solid(start,false)
	# Pick a reachable approach within the 3.7 m interaction radius.
	var path=PackedVector2Array()
	for offset in [Vector2i.ZERO,Vector2i(0,1),Vector2i(1,0),Vector2i(-1,0),Vector2i(0,-1)]:
		var cell=end+offset
		if grid.is_in_boundsv(cell) and not grid.is_point_solid(cell):
			path=grid.get_point_path(start,cell)
			if not path.is_empty(): break
	check(not path.is_empty(),"physical path exists")
	if path.is_empty(): return
	for i in range(1,path.size()):
		var p=Vector3(path[i].x-137.5,0,path[i].y-117.5)
		await steer(p,0.4)
	await steer(target,0.75)
	await settle(3)

func steer(target: Vector3,tolerance: float) -> void:
	var guard=0
	var previous=game.body.position
	while Vector2(game.body.position.x-target.x,game.body.position.z-target.z).length()>tolerance and guard<240:
		var d=(target-game.body.position).rotated(Vector3.UP,-game.yaw)
		var xcode=KEY_D if d.x>0 else KEY_A
		var zcode=KEY_S if d.z>0 else KEY_W
		for code in [KEY_A,KEY_D,KEY_W,KEY_S]: key(code,false)
		if abs(d.x)>tolerance*0.55: key(xcode,true)
		if abs(d.z)>tolerance*0.55: key(zcode,true)
		# Walking keeps measurements deterministic and avoids exhausting in sand.
		await get_tree().physics_frame
		physics_frames+=1
		travel_distance+=game.body.position.distance_to(previous)
		previous=game.body.position; guard+=1
	for code in [KEY_A,KEY_D,KEY_W,KEY_S]: key(code,false)
	check(guard<240,"walk reaches physical waypoint")
	if guard>=240:
		print("STUCK chapter=",s.chapter," current=",game.body.position," target=",target," near=",s.nearest)
		get_tree().quit(1)

func visit(id: String,skip: bool=false) -> void:
	var object={}
	for o in s.objects:
		if o.id==id: object=o
	check(not object.is_empty(),"object exists "+id)
	if object.is_empty(): return
	var target=game.world_position(object.pos)+Vector3(0,0,3.0)
	await walk_to(target)
	game.update_nearest()
	check(s.nearest==id,"3D proximity "+id)
	await tap(KEY_E)
	await dismiss(skip)

func solve(id: String) -> void:
	await visit(id)
	check(s.overlay=="puzzle","puzzle opens "+id)
	await tap(KEY_ENTER)
	check(s.overlay=="puzzle","wrong puzzle rejected")
	await tap(KEY_ESCAPE)
	check(s.overlay.is_empty(),"puzzle can cancel")
	await tap(KEY_E)
	var solution: Array=s.puzzle.solution.duplicate()
	for i in 3:
		for n in int(solution[i]): await tap(KEY_UP)
		await tap(KEY_RIGHT)
	await tap(KEY_ENTER); await dismiss()
	check(s.has(id),"puzzle solved through input "+id)

func run(host: Node) -> void:
	game=host; s=host.story; game.test_running=true
	print("HOMEWARD 3D INPUT ROUTE START")
	await tap(KEY_ENTER)
	check(game.cinematic=="intro","intro starts with control lock")
	var locked=game.body.position
	key(KEY_W,true); await settle(12); key(KEY_W,false)
	check(game.body.position.distance_to(locked)<0.01,"cinematic locks movement")
	game.save_progress()
	var pending=JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
	check(abs(float(pending.position[0]))<140,"cinematic save uses exploration coordinate")
	await dismiss(true)
	check(game.cinematic.is_empty(),"skip restores exploration")
	await settle(12)
	check(game.body.is_on_floor(),"terrain supports explorer")
	var ground_y=game.body.position.y
	key(KEY_SPACE,true); await settle(8); key(KEY_SPACE,false)
	check(game.body.position.y>ground_y+0.3,"space jumps with gravity")
	await settle(60)
	check(game.body.is_on_floor(),"jump lands on terrain")
	var yaw_before=game.yaw
	key(KEY_Q,true); await settle(8); key(KEY_Q,false)
	check(game.yaw!=yaw_before,"keyboard camera rotates")
	key(KEY_R,true); await settle(8); key(KEY_R,false)
	for code in [KEY_M,KEY_J,KEY_P]:
		await tap(code); check(not s.overlay.is_empty(),"panel opens "+str(code))
		var fixed=game.body.position; key(KEY_D,true); await settle(5); key(KEY_D,false)
		check(game.body.position.distance_to(fixed)<0.03,"panel locks movement")
		await tap(KEY_ESCAPE)
	var sequences=[
		["letter","cup","captain"],
		["name2","name0","name1","bell","child"],
		["keeper","clock2","clock0","clock1"],
		["aman","star2","star0","star1"],
		["water2","water0","water1","stake2","stake0","stake1","knight"],
		["lamp2","lamp0","lamp1"],
		["memory2","memory0","memory1","echo"],
		["lost2","lost0","lost3","lost1","tree"]]
	for chapter in 8:
		await build_grid()
		check(s.chapter==chapter,"chapter reached "+str(chapter))
		check(game.EXTENT.x>=180 and game.EXTENT.y>=180,"large real 3D region")
		await visit("exit")
		check(s.chapter==chapter,"incomplete exit blocked")
		await visit("camp")
		check(not s.has("rest"),"early camp never bypasses ending conversation")
		for id in sequences[chapter]: await visit(id,id in ["knight","echo"])
		if chapter==2: await solve("mechanism")
		if chapter==3: await solve("observatory")
		if chapter==5:
			await solve("lighthouse")
			await visit("sister")
		check(s.goal_complete(),"chapter objective complete "+str(chapter))
		check(not s.has("rest"),"post-event camp still required")
		await visit("exit")
		check(s.chapter==chapter,"no departure without post-event camp")
		await visit("camp")
		check(s.has("rest"),"post-event camp completed")
		if chapter==4: check(s.journal[-1].title=="最后一次系好的领口","farewell journal exists")
		await tap(KEY_F5)
		var saved=game.body.position
		await tap(KEY_ESCAPE)
		s.click(Vector2(600,440))
		check(s.mode=="title","pause returns to title")
		await tap(KEY_C)
		check(s.chapter==chapter and s.has("rest"),"save reload preserves progression")
		check(game.body.position.distance_to(saved)<0.25,"3D position survives load")
		await build_grid()
		await visit("exit",chapter%2==0)
		check(s.chapter==chapter+1,"departure advances once "+str(chapter))
		check(game.cinematic.is_empty() and abs(game.body.position.x)<140,"stage returns to next region")
		print("3D PASS chapter ",chapter," -> ",s.chapter," travel=",int(travel_distance),"m")
	await build_grid()
	for id in ["breakfast","postcard","inn","sea"]: await visit(id)
	check(s.completed and s.overlay=="credits","inn ending complete")
	check(s.journal.size()==8,"eight narrative journal entries retained")
	check(s.inventory.has("沈知微的围巾"),"scarf retained")
	check(game.cinematic_seen.size()==6,"six distinct real-time cinematics reached")
	check(game.staged_spaces.size()>=3,"at least three remote staged spaces visited")
	check(travel_distance>3000,"objectives distributed over kilometres of walkable terrain")
	game.save_progress()
	game.load_progress()
	check(s.completed and s.chapter==8,"ending round-trips actual disk save")
	# Boundary probes are isolated after the input-only story route.
	var safe=game.body.position
	game.body.position=Vector3(0,-30,0)
	await settle(3)
	check(game.recoveries>0 and game.body.position.distance_to(safe)<1,"fall recovery returns to last floor")
	s.new_game(); await dismiss(true)
	check(s.chapter==0 and s.flags.is_empty() and not s.completed,"new game resets route")
	DirAccess.remove_absolute(game.save_path)
	print("HOMEWARD 3D ROUTE ","PASS" if failures==0 else "FAIL",": ",checks," checks, ",failures," failures, ",int(travel_distance),"m walked, ",physics_frames," movement frames")
	get_tree().quit(0 if failures==0 else 1)
