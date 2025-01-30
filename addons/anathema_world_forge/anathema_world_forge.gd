@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("Terrain", "StaticBody3D", preload("terrain.gd"), preload("icon.svg"))


func _exit_tree():
	remove_custom_type("Terrain")
