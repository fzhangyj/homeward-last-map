extends SceneTree
func _initialize():
    for path in ["res://assets/hero_player.glb", "res://assets/tree_fantasy.glb", "res://assets/house_fantasy.glb", "res://assets/airship_landmark.glb"]:
        var p=load(path) as PackedScene
        print("ASSET ",path," scene=",p)
        if p:
            var n=p.instantiate()
            print(" ROOT ",n.name," type=",n.get_class()," scale=",n.scale," pos=",n.position)
            var todo=[n]
            while not todo.is_empty():
                var x=todo.pop_back()
                if x is MeshInstance3D:
                    print(" MESH ",x.name," pos=",x.position," scale=",x.scale," aabb=",x.mesh.get_aabb())
                for c in x.get_children(): todo.append(c)
            n.free()
    quit()
