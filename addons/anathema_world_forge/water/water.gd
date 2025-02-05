@tool
extends Area3D

@export_category("basic")
@export var generate := false
@export var clipmap_mesh : Mesh
@export var heightmap_size : int
@export var heightmap_scale : int = 1
@export var water_albedo_texture : Texture2D
@export var water_normal_texture : Texture2D
@export var water_specular_texture : Texture2D
@export var water_displacement_texture : Texture2D

@onready var water_shader : Shader = preload("res://addons/anathema_world_forge/water/water.gdshader")

var water_material : ShaderMaterial
var water_mesh_instance : MeshInstance3D


func _ready() -> void:
	_generate()
	
func _process(delta: float) -> void:
	if generate == false: return
	_generate()
	generate = false

func move_water(pos : Vector3) -> void:
	water_mesh_instance.global_transform.origin = Vector3(pos.x, 0, pos.z).snapped(Vector3(1, 1, 1))

func _generate() -> void:
	_clear_children()
	_reset_position()
	_configure_water_material()
	_create_water_mesh_instance()
	
func _clear_children():
	for i in get_children():
		i.queue_free()
		
func _configure_water_material():
	water_material = ShaderMaterial.new()
	water_material.shader = water_shader
	water_material.set("shader_parameter/heightmap_size", heightmap_size)
	water_material.set("shader_parameter/heightmap_scale", heightmap_scale)
	water_material.set("shader_parameter/water_albedo_texture", water_albedo_texture)
	water_material.set("shader_parameter/water_normal_texture", water_normal_texture)
	water_material.set("shader_parameter/water_specular_texture", water_specular_texture)
	water_material.set("shader_parameter/water_displacement_texture", water_displacement_texture)

func _create_water_mesh_instance():
	water_mesh_instance = MeshInstance3D.new()
	self.add_child(water_mesh_instance)
	water_mesh_instance.owner = self
	water_mesh_instance.mesh = clipmap_mesh
	water_mesh_instance.material_override = water_material
	
func _reset_position():
	global_position = Vector3.ZERO
	global_rotation = Vector3.ZERO
