extends MeshInstance3D


func _move_terrain(pos : Vector3) -> void:
	global_transform.origin = Vector3(pos.x, 0, pos.z).snapped(Vector3(1, 1, 1))
