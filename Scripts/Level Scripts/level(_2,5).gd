extends Level


func on_first_enter():
	
	spawn_wall_ghost(Vector2(55,55))
	spawn_wall_ghost(Vector2(277,130))
	
func spawn_wall_ghost(location):
		
		var type = "wall_ghost"
		emit_signal("spawn_enemy", type, location)
