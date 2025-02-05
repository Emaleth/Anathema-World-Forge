@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("Terrain", "StaticBody3D", preload("terrain/terrain.gd"), preload("res://addons/anathema_world_forge/terrain/map-regular.svg"))
	add_custom_type("Water", "Area3D", preload("water/water.gd"), preload("res://addons/anathema_world_forge/water/water-solid.svg"))
	add_custom_type("Foliage", "Node", preload("foliage/foliage.gd"), preload("res://addons/anathema_world_forge/foliage/pagelines-brands-solid.svg"))


func _exit_tree():
	remove_custom_type("Terrain")
	remove_custom_type("Water")
	remove_custom_type("Foliage")
