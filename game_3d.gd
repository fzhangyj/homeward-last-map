extends Node3D

const Story = preload("res://story_3d.gd")
const FANTASY_ASSET_PATHS = {
    "hero_player": "res://assets/hero_player.glb",
    "hero_companion": "res://assets/hero_companion.glb",
    "tree_fantasy": "res://assets/tree_fantasy.glb",
    "house_fantasy": "res://assets/house_fantasy.glb",
    "rock_crystal": "res://assets/rock_crystal.glb",
    "airship_landmark": "res://assets/airship_landmark.glb",
    "lighthouse_beacon": "res://assets/lighthouse_beacon.glb",
    "port_landscape": "res://assets/old_port/port_landscape.glb",
    "port_house": "res://assets/old_port/port_house.glb",
    "port_tree": "res://assets/old_port/port_tree.glb"
}
const EXTENT = Vector2(280,240)
var story
var region: Node3D
var stage: Node3D
var body: CharacterBody3D
var avatar: Node3D
var camera3d: Camera3D
var environment: WorldEnvironment
var sun: DirectionalLight3D
var markers: Dictionary = {}
var yaw = 0.0
var pitch = 0.35
var zoom = 12.0
var camera_dragging = false
var cinematic = ""
var cinematic_age = 0.0
var cinematic_seen: Array = []
var staged_spaces: Array = []
var return_position = Vector3.ZERO
var fade_alpha = 0.0
var fade_out = 0.0
var checkpoint = Vector3.ZERO
var save_path = "user://homeward_3d_v1.json"
var isolated = false
var elapsed = 0.0
var last_safe = Vector3.ZERO
var recoveries = 0
var built_chapter = -1
var test_running = false
var fantasy_scene_cache: Dictionary = {}

func _ready() -> void:
	set_process_input(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	isolated = "--self-test-3d" in OS.get_cmdline_user_args() or "--capture-3d" in OS.get_cmdline_user_args() or "--acceptance-3d" in OS.get_cmdline_user_args()
	if isolated: save_path = "user://homeward_3d_test.json"
	body = CharacterBody3D.new()
	body.name = "Explorer"
	body.floor_snap_length = 0.65
	body.floor_max_angle = deg_to_rad(48)
	add_child(body)
	var shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.38; capsule.height = 1.8
	shape.shape = capsule; shape.position.y = 0.9
	body.add_child(shape)
	avatar = person(body,Vector3.ZERO,Color("e2c48d"),"陆寻")
	camera3d = Camera3D.new()
	camera3d.fov = 63; camera3d.far = 600
	add_child(camera3d)
	camera3d.current = true
	environment = WorldEnvironment.new()
	add_child(environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38,-30,0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 95
	add_child(sun)
	var canvas = CanvasLayer.new()
	add_child(canvas)
	story = Story.new()
	story.host = self
	canvas.add_child(story)
	story.debug_test = isolated
	story.configure_world()
	if "--self-test-3d" in OS.get_cmdline_user_args():
		var runner=load("res://tests/route_3d.gd").new()
		add_child(runner); runner.call_deferred("run",self)
	elif "--capture-3d" in OS.get_cmdline_user_args(): call_deferred("capture_gallery")

func world_position(p: Vector2) -> Vector3:
	var x=(p.x-1130.0)/8.0
	var z=(p.y-740.0)/6.5
	return Vector3(x,height_at(x,z),z)

func map_position(p: Vector3) -> Vector2:
	return Vector2(p.x*8+1130,p.z*6.5+740)

func height_at(x: float,z: float) -> float:
	return sin(x*0.035)*1.8+cos(z*0.038)*2.2+7.0*exp(-((x-42)*(x-42)+(z+15)*(z+15))/2200.0)

func material(color: Color, glow: float=0) -> StandardMaterial3D:
	var m=StandardMaterial3D.new()
	m.albedo_color=color; m.roughness=0.9
	if glow>0:
		m.emission_enabled=true; m.emission=color; m.emission_energy_multiplier=glow
	return m

func fantasy_asset(kind: String, parent: Node3D, pos: Vector3, scale: Vector3=Vector3.ONE) -> Node3D:
	# Blender GLBs are visual instances. Physics remains authored below in Godot.
	if not FANTASY_ASSET_PATHS.has(kind): return Node3D.new()
	var packed: PackedScene = fantasy_scene_cache.get(kind)
	if packed == null:
		packed = load(FANTASY_ASSET_PATHS[kind]) as PackedScene
		if packed == null:
			push_warning("Fantasy asset missing: "+str(FANTASY_ASSET_PATHS[kind]))
			return Node3D.new()
		fantasy_scene_cache[kind] = packed
	var n: Node3D = packed.instantiate()
	n.position = pos; n.scale = scale
	parent.add_child(n)
	return n

func mesh_node(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, collider: bool=false) -> MeshInstance3D:
	var n=MeshInstance3D.new()
	n.mesh=mesh; n.position=pos; n.material_override=material(color)
	parent.add_child(n)
	if collider: n.create_trimesh_collision()
	return n

func box3(parent: Node3D,pos: Vector3,size: Vector3,color: Color,collider: bool=false) -> MeshInstance3D:
	var m=BoxMesh.new(); m.size=size
	var n=mesh_node(parent,m,pos,color)
	if collider:
		var solid=StaticBody3D.new()
		var collision=CollisionShape3D.new()
		var shape=BoxShape3D.new(); shape.size=size
		collision.shape=shape
		n.add_child(solid); solid.add_child(collision)
	return n

func blocker_box(parent: Node3D,pos: Vector3,size: Vector3,yaw: float=0.0) -> void:
	var solid=StaticBody3D.new()
	var collision=CollisionShape3D.new()
	var shape=BoxShape3D.new(); shape.size=size
	collision.shape=shape; collision.position=pos; collision.rotation.y=yaw
	parent.add_child(solid); solid.add_child(collision)

func blocker_cylinder(parent: Node3D,pos: Vector3,radius: float,height: float) -> void:
	var solid=StaticBody3D.new()
	var collision=CollisionShape3D.new()
	var shape=CylinderShape3D.new(); shape.radius=radius; shape.height=height
	collision.shape=shape; collision.position=pos
	parent.add_child(solid); solid.add_child(collision)

func blocker_beam(parent: Node3D,a: Vector3,b: Vector3,radius: float) -> void:
	var segment=b-a
	var solid=StaticBody3D.new()
	var collision=CollisionShape3D.new()
	var shape=CylinderShape3D.new(); shape.radius=radius; shape.height=segment.length()+radius*2
	collision.shape=shape
	collision.transform=Transform3D(Basis(Quaternion(Vector3.UP,segment.normalized())),(a+b)*0.5)
	parent.add_child(solid); solid.add_child(collision)

func cylinder(parent: Node3D,pos: Vector3,r: float,h: float,color: Color,top: float=-1,collider: bool=false) -> MeshInstance3D:
	var m=CylinderMesh.new(); m.bottom_radius=r; m.top_radius=r if top<0 else top; m.height=h; m.radial_segments=8
	return mesh_node(parent,m,pos,color,collider)

func orb(parent: Node3D,pos: Vector3,size: Vector3,color: Color) -> MeshInstance3D:
	var m=SphereMesh.new(); m.radial_segments=12; m.rings=6
	var n=mesh_node(parent,m,pos,color); n.scale=size
	return n

func label3(parent: Node3D,title: String,pos: Vector3,size: int=32) -> Label3D:
	var n=Label3D.new()
	n.text=title; n.position=pos; n.font=story.font; n.font_size=size; n.pixel_size=0.012
	n.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	n.modulate=Color("ffedbb"); n.outline_size=7
	n.no_depth_test=false
	parent.add_child(n)
	return n

func person(parent: Node3D,pos: Vector3,color: Color,title: String="") -> Node3D:
	var n=Node3D.new(); parent.add_child(n); n.position=pos
	var kind="hero_player"
	if not title.is_empty() and title!="陆寻": kind="hero_companion"
	var model=fantasy_asset(kind,n,Vector3.ZERO,Vector3.ONE*0.92)
	model.name="Blender_"+kind
	if not title.is_empty() and is_instance_valid(story): label3(n,title,Vector3(0,2.65,0),30)
	return n

func tree3(parent: Node3D,p: Vector3,s: float,color: Color,collider: bool=true) -> void:
	var port_tree=is_instance_valid(story) and story.chapter==0
	fantasy_asset("port_tree" if port_tree else "tree_fantasy",parent,p,Vector3.ONE*s*(0.64 if port_tree else 1.0))
	# Preserve the original solid trunk collider independently from the visual GLB.
	var trunk=cylinder(parent,p+Vector3(0,s*2,0),s*0.45,s*4,Color("655346"),s*0.30,collider)
	trunk.visible=false

func building(parent: Node3D,p: Vector3,color: Color,clock: bool=false) -> void:
	fantasy_asset("port_house" if story.chapter==0 else "house_fantasy",parent,p,Vector3.ONE)
	# BoxShape3D remains the walkable building boundary used by route_3d.
	var solid=box3(parent,p+Vector3(0,3,0),Vector3(8,6,7),color,true); solid.visible=false
	if clock:
		var disc=cylinder(parent,p+Vector3(0,5.5,3.6),1.0,0.15,Color("e9ca8c"))
		disc.rotation_degrees.x=90
		box3(parent,p+Vector3(0,5.85,3.73),Vector3(0.09,0.75,0.1),Color("3b4c4c"))

func old_port_landscape() -> void:
	# JSCAD-authored strata, shore, lattice mills, flower rows and cathedral town.
	# Imported visuals share the existing height function; collision is unchanged.
	var model=fantasy_asset("port_landscape",region,Vector3.ZERO)
	model.name="JSCAD_OldPort_Landscape"
	style_port_water(model)
	# The landscape GLB is one visual mesh, so its houses, windmills and trees
	# need matching primitive blockers instead of relying on mesh import physics.
	for item in [[Vector2(-71,35),1.05],[Vector2(-29,59),0.82],[Vector2(8,43),0.72]]:
		var p=item[0]; var s=float(item[1]); var base=height_at(p.x,p.y)
		blocker_cylinder(region,Vector3(p.x,base+5.0*s,p.y),2.2*s,10.0*s)
		# The windmill's four timber gantry legs sit outside its central tower.
		for x in [-3.1,3.1]:
			for z in [-2.0,2.0]:
				blocker_cylinder(region,Vector3(p.x+x*s,base+1.75*s,p.y+z*s),0.22*s,3.5*s)
				var a=Vector3(p.x+x*s,base,p.y+z*s)
				var b=Vector3(p.x+x*0.7*s,base+3.3*s,p.y-z*s)
				blocker_beam(region,a,b,0.16*s)
	for item in [[Vector2(-61,20),0.7,0.0],[Vector2(-41,28),0.62,-0.2],[Vector2(7,26),0.65,0.3],[Vector2(33,42),0.6,0.6]]:
		var p=item[0]; var s=float(item[1]); blocker_box(region,Vector3(p.x,height_at(p.x,p.y)+3.0*s,p.y),Vector3(8.2,6.0,7.1)*s,float(item[2]))
	for dock in [Vector2(36,70),Vector2(38,69),Vector2(39,71)]:
		blocker_box(region,Vector3(dock.x,height_at(dock.x,dock.y)+0.7,dock.y),Vector3(1.25,1.2,1.25))
	for item in [[Vector2(-82,5),1.0],[Vector2(-112,-13),1.0],[Vector2(-98,37),0.9],[Vector2(97,29),1.1],[Vector2(124,8),1.2],[Vector2(102,-48),0.9],[Vector2(-70,-105),0.8]]:
		var p=item[0]; var s=float(item[1]); blocker_cylinder(region,Vector3(p.x,height_at(p.x,p.y)+3.5*s,p.y),1.45*s,7.0*s)
	for i in 7:
		var p=Vector3(-240+i*74,62+(i%3)*10,-185-(i%2)*55)
		for j in 3:
			orb(region,p+Vector3(j*9,sin(j*1.5)*4,0),Vector3(30,9+j*2,14),Color("f5f3df"))

func style_port_water(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var mat=node.mesh.surface_get_material(surface)
			if mat and mat.resource_name=="water":
				var water_material=ShaderMaterial.new()
				water_material.shader=load("res://assets/old_port/water.gdshader")
				node.set_surface_override_material(surface,water_material)
	for child in node.get_children(): style_port_water(child)

func airship(parent: Node3D,p: Vector3,s: float=1) -> void:
	var n=Node3D.new(); parent.add_child(n); n.position=p
	fantasy_asset("airship_landmark",n,Vector3.ZERO,Vector3.ONE*s)
	# Deck collision stays explicit and independent of the imported balloon.
	var deck=box3(n,Vector3(0,1,0),Vector3(6,2,15),Color("765943"),true); deck.visible=false
	label3(n,"归 途",Vector3(0,12*s,0),48)

func road(a: Vector3,b: Vector3,width: float=3.3) -> void:
	var st=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dir=(b-a); dir.y=0; dir=dir.normalized()
	var side=Vector3(-dir.z,0,dir.x)*width
	var steps=maxi(1,int(a.distance_to(b)/3))
	for i in steps:
		var points=[]
		for t in [float(i)/steps,float(i+1)/steps]:
			var center=a.lerp(b,t)
			for signum in [-1,1]:
				var p=center+side*signum; p.y=height_at(p.x,p.z)+0.13; points.append(p)
		for idx in [0,1,2,1,3,2]: st.add_vertex(points[idx])
	st.generate_normals()
	var path_mesh=mesh_node(region,st.commit(),Vector3.ZERO,Color("d8c28b").darkened(0.08))
	path_mesh.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED

func meadow_details(rng: RandomNumberGenerator) -> void:
	if story.chapter in [3,4,5]: return
	var blade=SurfaceTool.new(); blade.begin(Mesh.PRIMITIVE_TRIANGLES)
	for angle in [0.0,1.05,2.10]:
		var side=Vector3(cos(angle),0,sin(angle))*0.18
		for p in [-side,side,Vector3(0,0.65,0)]: blade.add_vertex(p)
	blade.generate_normals()
	var batch=MultiMesh.new(); batch.transform_format=MultiMesh.TRANSFORM_3D
	batch.use_colors=true; batch.mesh=blade.commit(); batch.instance_count=5200
	var patch=MultiMeshInstance3D.new(); patch.multimesh=batch
	var mat=material(Color("71ad46")); mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo=true; patch.material_override=mat; region.add_child(patch)
	for i in batch.instance_count:
		var p=Vector3(rng.randf_range(-135,135),0,rng.randf_range(-115,115))
		p.y=height_at(p.x,p.z)
		# Lake decoration follows the existing collision terrain; grass stays ashore.
		if story.chapter==0:
			var lake_angle=atan2((p.z-74.0)/34.0,(p.x-78.0)/52.0)
			var lake_radius=1.0+0.065*sin(3*lake_angle)+0.035*sin(7*lake_angle)
			if Vector2((p.x-78.0)/52.0,(p.z-74.0)/34.0).length()<lake_radius:
				p.y-=100.0
		var scale_value=rng.randf_range(0.55,1.35)
		batch.set_instance_transform(i,Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3.ONE*scale_value),p))
		batch.set_instance_color(i,Color("b9d68b").lerp(Color.WHITE,rng.randf()))

func build_region() -> void:
	if is_instance_valid(region):
		remove_child(region); region.queue_free()
	region=Node3D.new(); region.name="Region_"+str(story.chapter); add_child(region)
	markers.clear(); built_chapter=story.chapter
	var terrain_colors=["6fa878","58a66a","729b9b","e6f2ef","d5af72","4a7184","c8876d","7cae83","78b9a6"]
	var ground=Color(terrain_colors[story.chapter])
	var st=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(-140,140,5):
		for z in range(-120,120,5):
			for q in [Vector2(x,z),Vector2(x+5,z),Vector2(x,z+5),Vector2(x+5,z),Vector2(x+5,z+5),Vector2(x,z+5)]:
				st.set_color(ground.lightened(0.03*sin(q.x*0.16+q.y*0.11)))
				st.add_vertex(Vector3(q.x,height_at(q.x,q.y),q.y))
	st.generate_normals()
	var terrain=mesh_node(region,st.commit(),Vector3.ZERO,Color.WHITE,true)
	var tm=ShaderMaterial.new(); tm.shader=load("res://assets/meadow.gdshader"); terrain.material_override=tm
	if story.chapter==0: old_port_landscape()
	# Mountain silhouettes and the sea extend beyond the walkable 280 x 240 island.
	box3(region,Vector3(0,-7,0),Vector3(1200,1,1200),Color("294d60"))
	for edge in [Vector3(-142,12,0),Vector3(142,12,0),Vector3(0,12,-122),Vector3(0,12,122)]:
		var wall=box3(region,edge,Vector3(3,40,246) if abs(edge.x)>1 else Vector3(286,40,3),ground,true)
		wall.visible=false
	var rng=RandomNumberGenerator.new(); rng.seed=6143+story.chapter*89
	for i in (0 if story.chapter==0 else 20):
		var x=rng.randf_range(-240,240); var z=-165.0-rng.randf_range(0,100)
		var mountain_radius=rng.randf_range(15,40)
		var mountain_height=rng.randf_range(35,85)
		if story.chapter==0:
			mountain_radius*=1.6; mountain_height*=0.48
		cylinder(region,Vector3(x,10,z),mountain_radius,mountain_height,ground.darkened(0.22),0)
	var env=Environment.new()
	env.background_mode=Environment.BG_SKY
	var sky=Sky.new(); var skymat=ProceduralSkyMaterial.new()
	var skycolors=["429cdf","57b0db","5ea8d6","83bedf","dfa45f","233e5d","e39984","5aafd5","57b5df"]
	skymat.sky_top_color=Color(skycolors[story.chapter]).darkened(0.3)
	skymat.sky_horizon_color=Color(skycolors[story.chapter]).lightened(0.24)
	skymat.ground_horizon_color=skymat.sky_horizon_color
	sky.sky_material=skymat; env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("b7c9c4"); env.ambient_light_energy=0.3
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	env.fog_enabled=true; env.fog_density=0.0019; env.fog_light_color=skymat.sky_horizon_color
	environment.environment=env
	sun.light_color=Color("ffdfb0") if story.chapter!=5 else Color("a8c6e9")
	sun.light_energy=0.72 if story.chapter!=5 else 0.42
	# Main road and branches form routes to every objective, with clearings kept free.
	var trail=[Vector2(410,1080),Vector2(760,950),Vector2(1100,760),Vector2(1450,540),Vector2(1980,330)]
	for i in range(trail.size()-1): road(world_position(trail[i]),world_position(trail[i+1]),4)
	for o in story.objects:
		var p=world_position(o.pos)
		road(world_position(Vector2(1100,760)),p,2.0)
		create_object(o,p)
	for i in 105:
		var p=Vector3(rng.randf_range(-131,131),0,rng.randf_range(-110,110)); p.y=height_at(p.x,p.z)
		var clear=false
		for o in story.objects:
			if Vector2(p.x,p.z).distance_to(Vector2(world_position(o.pos).x,world_position(o.pos).z))<9: clear=true
			var hub=world_position(Vector2(1100,760))
			var destination=world_position(o.pos)
			var closest=Geometry2D.get_closest_point_to_segment(Vector2(p.x,p.z),Vector2(hub.x,hub.z),Vector2(destination.x,destination.z))
			if closest.distance_to(Vector2(p.x,p.z))<6.5: clear=true
		# Keep the hub and travel corridors broad, even in dense forest.
		if abs(p.z-(-0.67*p.x-1))<11 or abs(p.x)<8: clear=true
		if clear: continue
		if story.chapter in [0,2,8] and i%9==0:
			building(region,p,ground.darkened(0.12),story.chapter==2)
		elif story.chapter in [1,3,6,7,8,0] and i%3!=0:
			tree3(region,p,rng.randf_range(0.8,1.7),ground.lightened(0.08))
		else:
			var rock_scale=rng.randf_range(0.5,1.8)
			fantasy_asset("rock_crystal",region,p,Vector3.ONE*rock_scale)
			var rock=orb(region,p+Vector3(0,1,0),Vector3(3,2,3)*rock_scale,ground.darkened(0.16))
			rock.visible=false; rock.create_convex_collision()
	# A climbable lookout hill is part of the terrain, not a painted backdrop.
	meadow_details(rng)
	var lookout=Vector3(42,height_at(42,-15),-15)
	for x in [-3.2,3.2]: cylinder(region,lookout+Vector3(x,3,0),0.2,6,Color("745c45"))
	box3(region,lookout+Vector3(0,6,0),Vector3(7,0.35,6),Color("9d8260"))
	label3(region,"山脊望台",lookout+Vector3(0,8,0),34)
	# Terrain itself carries all objectives; this landmark is visual and never blocks them.
	body.position=world_position(story.player)+Vector3(0,0.2,0)
	body.velocity=Vector3.ZERO; last_safe=body.position; checkpoint=body.position
	yaw=0.0; pitch=0.35
	camera_dragging=false
	update_camera(1.0)

func create_object(o: Dictionary,p: Vector3) -> void:
	var n=Node3D.new(); n.position=p; n.name="Point_"+o.id; region.add_child(n); markers[o.id]=n
	label3(n,o.name,Vector3(0,3.4,0),31)
	if o.id=="camp":
		for i in 7:
			var a=i*TAU/7; orb(n,Vector3(cos(a)*0.9,0.17,sin(a)*0.9),Vector3(0.7,0.35,0.7),Color("65716a"))
		var fire=cylinder(n,Vector3(0,0.7,0),0.5,1.5,Color("ffb65e"),0)
		fire.material_override=material(Color("ffb65e"),1.8)
		var light=OmniLight3D.new(); light.position=Vector3(0,2,0); light.light_color=Color("ffb36d"); light.omni_range=12; light.light_energy=2; n.add_child(light)
		airship(region,p+Vector3(-11,7,-10),0.7)
		person(n,Vector3(2,0,1),Color("647f89"),"顾停舟")
	elif o.id=="exit":
		for x in [-1.6,1.6]: cylinder(n,Vector3(x,2.4,0),0.25,4.8,Color("a28b62"),-1,true)
		box3(n,Vector3(0,4.5,0),Vector3(4,0.4,0.4),Color("e7d29b"),true)
	elif o.kind in ["captain","child","keeper","aman","knight","sister","echo"]:
		person(n,Vector3.ZERO,Color("c28c73") if o.kind=="knight" else Color("8cb7b0"))
	elif o.kind=="lighthouse":
		fantasy_asset("lighthouse_beacon",n,Vector3.ZERO,Vector3.ONE*1.12)
		var lighthouse_solid=cylinder(n,Vector3(0,7,0),2.4,14,Color("b9c1ac"),1.7,true); lighthouse_solid.visible=false
		var lamp=OmniLight3D.new(); lamp.position.y=15; lamp.light_color=Color("ffe0a1"); lamp.omni_range=35; lamp.light_energy=4; n.add_child(lamp)
	elif o.kind=="tree":
		tree3(n,Vector3(0,0,-6),5.8,Color("90b68b"),true)
		for x in [-3,3]: cylinder(n,Vector3(x,3.1,0),0.65,6.2,Color("c8b987"),-1,true)
		box3(n,Vector3(0,6,0),Vector3(7,1,1),Color("d7cc9c"),true)
	elif o.kind=="inn": building(n,Vector3(0,0,-5),Color("aeaa83"))
	else:
		var base=cylinder(n,Vector3(0,0.48,0),0.8,0.95,Color("7d8775"),0.7,true); base.visible=false
		var gem=orb(n,Vector3(0,1.45,0),Vector3(0.65,0.95,0.65),Color(story.COLORS[story.chapter][2]))
		gem.material_override=material(Color(story.COLORS[story.chapter][2]),0.5)
		if o.kind in ["clock","mechanism","observatory"]:
			cylinder(n,Vector3(0,3,0),1.5,4,Color("8f9986"),1.1,true)
			cylinder(n,Vector3(0,5.2,0),2.8,0.4,Color("e2c790"),-1,true)
		if o.kind=="stake":
			box3(n,Vector3(0,2,0),Vector3(0.25,4,0.3),Color("665c4e"),true)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(story): return
	elapsed+=delta
	if not cinematic.is_empty():
		cinematic_age+=delta
		fade_alpha=maxf(0,1.0-cinematic_age/0.65)
		update_cinematic(delta)
		body.velocity=Vector3.ZERO
		return
	fade_out=maxf(0,fade_out-delta); fade_alpha=fade_out/0.4
	if story.mode=="title":
		var center=world_position(Vector2(1100,760))
		camera3d.position=center+Vector3(39+sin(elapsed*0.07)*7,25,39)
		camera3d.look_at(center+Vector3(0,3,0))
		return
	var active=story.dialogue.is_empty() and story.overlay.is_empty()
	if active:
		yaw += (float(Input.is_physical_key_pressed(KEY_Q))-float(Input.is_physical_key_pressed(KEY_R)))*delta*1.5
		pitch=clampf(pitch+(float(Input.is_physical_key_pressed(KEY_PAGEUP))-float(Input.is_physical_key_pressed(KEY_PAGEDOWN)))*delta,0.10,1.12)
	var move=Vector2.ZERO
	if active:
		move=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	var direction=Vector3(move.x,0,move.y).rotated(Vector3.UP,yaw).normalized()
	var speed=9.5
	if Input.is_physical_key_pressed(KEY_SHIFT) and story.stamina>2 and move.length()>0:
		speed=16.0; story.stamina=maxf(0,story.stamina-delta*12)
	else: story.stamina=minf(100,story.stamina+delta*19)
	if story.chapter==4 and story.in_sandwind(map_position(body.position)):
		speed*=0.65
		if active: story.stamina=maxf(0,story.stamina-delta*7)
		if story.stamina<=0:
			body.position=checkpoint+Vector3(0,0.3,0); story.stamina=80
			story.toast("沙风把你推回营地。地图 M 显示风带，从旁边绕行。")
	body.velocity.x=direction.x*speed; body.velocity.z=direction.z*speed
	if not body.is_on_floor(): body.velocity.y-=24*delta
	else:
		body.velocity.y=-0.2
		if active and Input.is_physical_key_pressed(KEY_SPACE): body.velocity.y=8.5
	body.move_and_slide()
	# The imported hero meshes face local -Z (eyes, chest panel and boots are
	# authored on that side). Align local -Z with the travel direction so W
	# movement keeps the character facing away from the third-person camera.
	if direction.length()>0.05: avatar.rotation.y=lerp_angle(avatar.rotation.y,atan2(-direction.x,-direction.z),delta*12)
	avatar.position.y=sin(elapsed*13)*0.045 if direction.length()>0 and body.is_on_floor() else 0.0
	if body.is_on_floor(): last_safe=body.position
	if body.position.y < -15 or abs(body.position.x)>145 or abs(body.position.z)>125:
		body.position=last_safe if last_safe.y>-10 else checkpoint
		body.velocity=Vector3.ZERO; recoveries+=1; story.toast("已回到最近的安全落脚点。")
	story.player=map_position(body.position)
	update_nearest()
	update_camera(delta)
	for id in markers:
		var n=markers[id]
		n.visible=not (story.has(id) and (id.begins_with("name") or id.begins_with("water") or id.begins_with("lost") or id.begins_with("memory")))

func update_nearest() -> void:
	story.nearest=""
	var distance=3.7
	for o in story.objects:
		if story.has(o.id) and o.kind in ["paper","water","wisp","crystal","scarf","badge"]: continue
		var p=world_position(o.pos)
		var d=Vector2(body.position.x,body.position.z).distance_to(Vector2(p.x,p.z))
		if d<distance: distance=d; story.nearest=o.id

func update_camera(delta: float) -> void:
	var target=body.position+Vector3(0,1.6,0)
	var offset=Vector3(0,sin(pitch)*zoom,cos(pitch)*zoom).rotated(Vector3.UP,yaw)
	var desired=target+offset
	if is_inside_tree():
		var query=PhysicsRayQueryParameters3D.create(target,desired)
		query.exclude=[body.get_rid()]
		var result=get_world_3d().direct_space_state.intersect_ray(query)
		if not result.is_empty(): desired=result.position+(target-result.position).normalized()*0.45
	camera3d.position=camera3d.position.lerp(desired,minf(1,delta*12))
	if camera3d.position.distance_to(target)>0.1: camera3d.look_at(target)

func _input(event: InputEvent) -> void:
	if not is_instance_valid(story): return
	if event is InputEventMouseMotion:
		story.mouse_pos=event.position*Vector2(1280,800)/get_viewport().get_visible_rect().size
		# Exploration camera follows mouse movement directly.  A button is no longer
		# required; UI, dialogue and cinematics still keep the camera locked.
		if story.mode=="play" and cinematic.is_empty() and story.overlay.is_empty() and story.dialogue.is_empty():
			yaw-=event.relative.x*0.006
			pitch=clampf(pitch+event.relative.y*0.004,0.10,1.12)
		return
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_RIGHT,MOUSE_BUTTON_MIDDLE]:
			# A release must preserve dragging if the other camera button is held.
			camera_dragging=(event.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE))!=0 and story.mode=="play" and cinematic.is_empty() and story.overlay.is_empty() and story.dialogue.is_empty()
			return
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and story.overlay.is_empty():
			zoom=clampf(zoom+(-1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1),5,23); return
		if event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
			story.click(story.mouse_pos); return
		story.forward_input(event); return
	if not event is InputEventKey or not event.pressed or event.echo: return
	var key=event.physical_keycode
	if not cinematic.is_empty():
		if key==KEY_ESCAPE:
			var guard=0
			while not story.dialogue.is_empty() and guard<80: story.next_dialogue(); guard+=1
		elif key in [KEY_E,KEY_ENTER,KEY_SPACE]: story.next_dialogue()
		return
	if story.mode=="play" and story.dialogue.is_empty() and story.overlay.is_empty() and key in [KEY_E,KEY_SPACE]:
		if key==KEY_E:
			update_nearest()
			if not story.nearest.is_empty(): story.interact(story.nearest)
		return
	story.forward_input(event)

func cinematic_title() -> String:
	return {"intro":"序幕 · 留一盏灯","departure":"航行 · 云端甲板","knight":"沙海 · 最后一次系好的领口","sister":"灯室 · 门口有人","echo":"黄昏 · 自己系领口","tree":"树门 · 给下一个迷路的人"}.get(cinematic,"")

func begin_cinematic(kind: String) -> void:
	if not cinematic.is_empty(): return
	camera_dragging=false
	cinematic=kind; cinematic_age=0; fade_alpha=1
	if not kind in cinematic_seen: cinematic_seen.append(kind)
	return_position=body.position
	body.velocity=Vector3.ZERO
	if kind=="intro": return
	if is_instance_valid(stage) and stage.get_parent()==self: remove_child(stage); stage.queue_free()
	stage=Node3D.new(); stage.name="Stage_"+kind; stage.position=Vector3(420,35,0); add_child(stage)
	box3(stage,Vector3(0,-0.5,0),Vector3(28,1,25),Color("7a7961"),true)
	body.position=stage.position+Vector3(0,0.1,2)
	avatar.rotation.y=PI
	var space=""
	match kind:
		"departure":
			space="飞艇甲板"
			box3(stage,Vector3(0,-0.6,0),Vector3(12,1.2,25),Color("786048"),true)
			for x in [-5.7,5.7]:
				box3(stage,Vector3(x,1,0),Vector3(0.2,0.2,24),Color("cab085"))
				for z in [-10,0,10]: cylinder(stage,Vector3(x,0.8,z),0.12,1.6,Color("a79c7c"))
			orb(stage,Vector3(0,16,0),Vector3(17,9,32),Color("d8cfae"))
			for x in [-4,4]: cylinder(stage,Vector3(x,7,0),0.14,14,Color("8c8f7d"))
			person(stage,Vector3(2,0,-3),Color("65818b"),"顾停舟")
			person(stage,Vector3(-2,0,-2),Color("a0b7a1"),"陆杳" if story.chapter>=5 else "闻笛")
		"sister":
			space="灯塔灯室"
			for i in 8:
				var a=i*TAU/8
				if sin(a)>0.3: continue
				cylinder(stage,Vector3(cos(a)*9,4,sin(a)*9),0.24,8,Color("8baba6"))
			cylinder(stage,Vector3(0,8,0),11,0.5,Color("4b6566"))
			var beacon=orb(stage,Vector3(0,4,-6),Vector3(2,4,2),Color("ffe1a1")); beacon.material_override=material(Color("ffe1a1"),1.8)
			person(stage,Vector3(0,0,-1),Color("9bc3bd"),"陆杳")
			person(stage,Vector3(4,0,-4),Color("7a9e85"),"闻笛")
		"tree":
			space="归乡树门内"
			tree3(stage,Vector3(0,-1,-10),5,Color("afc890"),false)
			for x in [-4,4]: cylinder(stage,Vector3(x,4,-5),0.8,8,Color("e5d8a1"))
			box3(stage,Vector3(0,8,-5),Vector3(9,1,1),Color("e5d8a1"))
			person(stage,Vector3(0,0,-3),Color("a8b4a3"),"阿满")
			for i in 4:
				var star=orb(stage,Vector3(-6+i*4,3,-4),Vector3.ONE*0.7,Color("f2dea0")); star.material_override=material(Color("f2dea0"),2)
		"knight":
			space="沙海风闸"
			box3(stage,Vector3(0,0,0),Vector3(28,0.15,25),Color("c8a16e"))
			for x in [-7,7]:
				box3(stage,Vector3(x,3,-5),Vector3(2,6,2),Color("89664c"))
			box3(stage,Vector3(0,6,-5),Vector3(17,1,2),Color("a18660"))
			var rope=box3(stage,Vector3(0,1.1,-4),Vector3(17,0.10,0.10),Color("ede0ab")); rope.rotation_degrees.z=6
			person(stage,Vector3(0,0,-3),Color("c08b72"),"沈知微")
			box3(stage,Vector3(0,1.3,-2.6),Vector3(1.5,0.16,0.30),Color("de9b7c"))
		"echo":
			space="黄昏记忆之环"
			for i in 9:
				var a=i*TAU/9; tree3(stage,Vector3(cos(a)*10,0,sin(a)*10),1.6,Color("d49776"),false)
			person(stage,Vector3(0,0,-3),Color("d7bba0"),"沈知微的记忆")
			box3(stage,Vector3(2,1,-2),Vector3(2,0.2,1.5),Color("9e7960"))
			cylinder(stage,Vector3(2,1.25,-2),0.35,0.4,Color("e5d5b2"))
	if not space in staged_spaces: staged_spaces.append(space)
	update_cinematic(1)

func update_cinematic(delta: float) -> void:
	var target=body.position+Vector3(0,1.2,0)
	var shot=story.dialogue_index%3
	var offset=Vector3(6,3.2,7)
	if cinematic=="intro":
		target=body.position+Vector3(0,1.5,-2)
		offset=Vector3(9,5,11) if shot==0 else Vector3(-3,2.3,5)
	else:
		target=stage.position+Vector3(0,1.4,-1)
		match cinematic:
			"departure": offset=[Vector3(12,7,16),Vector3(-5,3,7),Vector3(1,2,5)][shot]
			"knight": offset=[Vector3(10,4,9),Vector3(2,2.4,2),Vector3(-4,1.8,0)][shot]
			"sister": offset=[Vector3(8,5,8),Vector3(-3,2.6,3),Vector3(1.5,2.3,4)][shot]
			"echo": offset=[Vector3(9,4,8),Vector3(-3,2.1,3),Vector3(2.5,2.5,5)][shot]
			"tree": offset=[Vector3(11,6,13),Vector3(-4,2.6,2),Vector3(0,3,6)][shot]
	var drift=Vector3(sin(cinematic_age*0.18)*0.6,0,cos(cinematic_age*0.16)*0.4)
	camera3d.position=camera3d.position.lerp(target+offset+drift,minf(1,delta*3))
	camera3d.look_at(target)

func end_cinematic() -> void:
	if cinematic.is_empty(): return
	if cinematic!="intro": body.position=return_position
	if is_instance_valid(stage) and stage.get_parent()==self: remove_child(stage); stage.queue_free()
	cinematic=""; cinematic_age=0; fade_out=0.4; fade_alpha=1
	body.velocity=Vector3.ZERO
	update_camera(1)

func cancel_cinematic() -> void:
	end_cinematic()
	cinematic_seen.clear(); staged_spaces.clear()

func save_progress() -> void:
	if story.mode!="play": return
	# Never persist a remote staging coordinate. Dialogue callbacks are atomic:
	# before completion a reload repeats the event; after completion its flag is saved.
	var p=return_position if not cinematic.is_empty() else body.position
	var data={"version":3,"chapter":story.chapter,"position":[p.x,p.y,p.z],"yaw":yaw,"pitch":pitch,"flags":story.flags,"inventory":story.inventory,"journal":story.journal,"completed":story.completed,"cinematics":cinematic_seen,"stages":staged_spaces}
	var file=FileAccess.open(save_path,FileAccess.WRITE)
	if file==null: story.toast("无法保存，请检查用户目录权限。"); return
	file.store_string(JSON.stringify(data)); file.close(); story.save_exists=true

func load_progress() -> void:
	var file=FileAccess.open(save_path,FileAccess.READ)
	if file==null: return
	var data=JSON.parse_string(file.get_as_text())
	if not data is Dictionary or data.get("version")!=3 or not data.get("flags") is Dictionary or not data.get("inventory") is Array or not data.get("journal") is Array:
		story.toast("3D 存档无法读取，可以重新启程。"); return
	end_cinematic()
	story.chapter=clampi(int(data.get("chapter",0)),0,8)
	story.flags=data.flags; story.inventory=data.inventory; story.journal=data.journal
	story.completed=bool(data.get("completed",false)); story.mode="play"; story.overlay=""; story.dialogue.clear(); story.stamina=100
	story.player=Vector2(500,1080)
	story.configure_world()
	var p=data.get("position",[])
	if p is Array and p.size()==3 and (p[0] is float or p[0] is int) and (p[1] is float or p[1] is int) and (p[2] is float or p[2] is int):
		var restored=Vector3(float(p[0]),float(p[1]),float(p[2]))
		if is_finite(restored.x) and is_finite(restored.y) and is_finite(restored.z) and abs(restored.x)<139 and abs(restored.z)<119:
			body.position=Vector3(restored.x,maxf(restored.y,height_at(restored.x,restored.z)+0.1),restored.z)
	yaw=float(data.get("yaw",0)); pitch=clampf(float(data.get("pitch",0.35)),0.10,1.12)
	cinematic_seen=data.get("cinematics",[]); staged_spaces=data.get("stages",[])
	last_safe=body.position; story.player=map_position(body.position); update_camera(1)
	story.toast("欢迎回来。山海与名字，都替你记下了。")

func draw_compass(ui: Node2D) -> void:
	var p=story.objective_position()
	if p==Vector2.ZERO: return
	var target=world_position(p)
	var relative=(target-body.position).rotated(Vector3.UP,-yaw)
	var angle=atan2(relative.x,-relative.z)
	var center=Vector2(1090,685)
	ui.draw_arc(center,38,0,TAU,40,Color("a6bca1"),1.5,true)
	var direction=Vector2(sin(angle),-cos(angle))
	ui.draw_line(center,center+direction*31,Color("f1d697"),3,true)
	ui.draw_circle(center+direction*31,4,Color("f1d697"))
	ui.text("目标 %dm" % int(Vector2(relative.x,relative.z).length()),center+Vector2(0,66),15,Color("f2dfa8"),true)

func capture_gallery() -> void:
	DirAccess.make_dir_recursive_absolute("res://tests/screenshots_3d")
	await get_tree().create_timer(1.0).timeout
	await capture("00-title")
	story.new_game()
	await capture("01-intro")
	story.drain_dialogue()
	for i in 9:
		story.chapter=i; story.player=Vector2(1070,800); story.dialogue.clear(); story.overlay=""; story.configure_world()
		yaw=-0.5; pitch=0.35; zoom=17
		await get_tree().create_timer(0.3).timeout
		await capture("%02d-region" % (i+2))
		if i==0:
			set_physics_process(false)
			camera3d.position=Vector3(-13,24,110)
			camera3d.look_at(Vector3(-13,3,42))
			await capture("02-old-port-panorama")
			set_physics_process(true)
		if i==1:
			story.overlay="map"; await capture("11-map"); story.overlay=""
	for kind in ["departure","knight","sister","echo","tree"]:
		story.talk([["实时演出",{"departure":"飞艇离开旧港。门口那盏灯，越来越小。","knight":"你往前走。我替你看一会儿家。","sister":"哥哥。想喝家里的汤。","echo":"领口，自己会系了吗？","tree":"把杯子留给下一个迷路的人。"}[kind]]])
		begin_cinematic(kind)
		await capture("12-"+kind)
		story.drain_dialogue()
	story.dialogue.clear(); story.overlay="party"; await capture("17-party")
	story.overlay="journal"; story.add_journal("山海之间","这是一段实时三维旅程。每一盏灯，都在等人回家。"); await capture("18-journal")
	story.overlay=""; story.open_puzzle("clock"); await capture("19-puzzle")
	DirAccess.remove_absolute(save_path)
	print("3D GPU CAPTURES COMPLETE: tests/screenshots_3d")
	get_tree().quit()

func capture(filename: String) -> void:
	await get_tree().create_timer(0.85).timeout
	await RenderingServer.frame_post_draw
	var err=get_viewport().get_texture().get_image().save_png("res://tests/screenshots_3d/"+filename+".png")
	print("GPU capture ",filename," result=",err)



