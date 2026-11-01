extends SceneTree
var scene:Node3D
var cam:Camera3D
func _initialize(): call_deferred("run")
func run():
 scene=Node3D.new();root.add_child(scene)
 var world=WorldEnvironment.new();var env=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("98d2e4");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("c6ddf4");env.ambient_light_energy=0.65;world.environment=env;scene.add_child(world)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-30,0);sun.light_energy=0.85;sun.shadow_enabled=true;scene.add_child(sun)
 var plane=MeshInstance3D.new();var pm=PlaneMesh.new();pm.size=Vector2(150,150);plane.mesh=pm;var mat=StandardMaterial3D.new();mat.albedo_color=Color("69ab68");plane.material_override=mat;scene.add_child(plane)
 for spec in [["hero_player",Vector3.ZERO],["hero_companion",Vector3(2,0,0)],["house_fantasy",Vector3(13,0,1)],["tree_fantasy",Vector3(6,0,3)]]:
  var n=load("res://assets/"+spec[0]+".glb").instantiate();scene.add_child(n);n.position=spec[1]
 cam=Camera3D.new();scene.add_child(cam);cam.current=true;cam.fov=42
 cam.position=Vector3(3.9,2.8,-6.7);cam.look_at(Vector3(0.9,1.5,0))
 await shot("20-characters-closeup")
 cam.position=Vector3(22,8,-16);cam.look_at(Vector3(11,3,0))
 await shot("21-house-tree")
 cam.position=Vector3(13,7,-11);cam.look_at(Vector3(13,3,1))
 await shot("22-house-roof-front")
 cam.position=Vector3(20,7,-10);cam.look_at(Vector3(13,3,1))
 await shot("23-house-roof-oblique")
 quit()
func shot(name):
 await create_timer(1).timeout
 await RenderingServer.frame_post_draw
 var e=root.get_texture().get_image().save_png("res://tests/screenshots_3d/"+name+".png");print("ASSET CLOSEUP ",name," result=",e)
