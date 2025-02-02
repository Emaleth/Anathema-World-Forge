@tool
extends StaticBody3D

@export_category("basic")
@export var generate := false
@export var show_collision_shape_in_editor := false
@export var heightmap : Texture2D
@export var normalmap : Texture2D
@export var clipmap_mesh : Mesh
@export var max_height : int = 0
@export var max_depth : int = 0
@export var heightmap_scale : int = 1

@export_category("slope textures")
@export var flat_texture : Texture2D
@export var slant_texture : Texture2D
@export var slope_texture : Texture2D

@onready var terrain_shader : Shader = preload("res://addons/anathema_world_forge/terrain/terrain.gdshader")

var terrain_material : ShaderMaterial
var terrain_mesh_instance : MeshInstance3D
var terrain_collision_shape : CollisionShape3D


func _ready() -> void:
	_generate()
	
func _process(delta: float) -> void:
	if generate == false: return
	_generate()
	generate = false

func move_terrain(pos : Vector3) -> void:
	terrain_mesh_instance.global_transform.origin = Vector3(pos.x, 0, pos.z).snapped(Vector3(1, 1, 1))
	
func _generate() -> void:
	_clear_children()
	_reset_position()
	_check_if_normalmap_existis()
	_create_terrain_collision_shape()
	_configure_terrain_material()
	_create_terrain_mesh_instance()
	
func _clear_children():
	for i in get_children():
		i.queue_free()
		
func _create_terrain_collision_shape():
	terrain_collision_shape = CollisionShape3D.new()
	self.add_child(terrain_collision_shape)
	if show_collision_shape_in_editor:
		terrain_collision_shape.owner = self
	var hms = HeightMapShape3D.new()
	var hm_img = heightmap.get_image()
	hm_img.decompress()
	hm_img.convert(Image.FORMAT_RH)
	hms.update_map_data_from_image(hm_img, 0.0, abs(max_height) + abs(max_depth))
	terrain_collision_shape.shape = hms
	terrain_collision_shape.top_level = true
	terrain_collision_shape.global_position = Vector3.ZERO
	terrain_collision_shape.global_position.y = -abs(max_depth)

func _configure_terrain_material():
	terrain_material = ShaderMaterial.new()
	terrain_material.shader = terrain_shader
	terrain_material.set("shader_parameter/heightmap", heightmap)
	terrain_material.set("shader_parameter/normalmap", normalmap)
	terrain_material.set("shader_parameter/max_height", max_height)
	terrain_material.set("shader_parameter/max_depth", max_depth)
	terrain_material.set("shader_parameter/heightmap_scale", heightmap_scale)
	terrain_material.set("shader_parameter/flat_texture", flat_texture)
	terrain_material.set("shader_parameter/slant_texture", slant_texture)
	terrain_material.set("shader_parameter/slope_texture", slope_texture)

func _create_terrain_mesh_instance():
	terrain_mesh_instance = MeshInstance3D.new()
	self.add_child(terrain_mesh_instance)
	terrain_mesh_instance.owner = self
	terrain_mesh_instance.mesh = clipmap_mesh
	terrain_mesh_instance.material_override = terrain_material
	terrain_mesh_instance.global_position.y = -abs(max_depth)
	
func _check_if_normalmap_existis():
#FIXME: find out why godot generated normalmap is fucked. 
	if normalmap:
		return
	normalmap = heightmap.duplicate()
	normalmap.get_image().bump_map_to_normal_map()
	 
func _reset_position():
	global_position = Vector3.ZERO
	global_rotation = Vector3.ZERO
