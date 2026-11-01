extends SceneTree
func _initialize(): call_deferred("run")
func run():
 var g=load("res://main.tscn").instantiate()
 root.add_child(g)
 g.save_path="user://probe_3d.json"
 g.story.new_game()
 g.story.drain_dialogue()
 for i in 120:
  await physics_frame
  if i%20==0: print(i," body ",g.body.position," floor ",g.body.is_on_floor()," height ",g.height_at(g.body.position.x,g.body.position.z)," cam ",g.camera3d.position)
 quit()
