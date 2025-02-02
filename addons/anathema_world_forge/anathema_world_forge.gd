@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("Terrain", "StaticBody3D", preload("terrain/terrain.gd"), preload("icon.svg"))
	add_custom_type("Water", "StaticBody3D", preload("water/water.gd"), preload("icon.svg"))


func _exit_tree():
	remove_custom_type("Terrain")
	remove_custom_type("Water")
