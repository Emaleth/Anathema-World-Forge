@tool
extends StaticBody3D

@export_category("basic")
@export var generate := false
@export var show_collision_shape_in_editor := false
@export var heightmap : Image
@export var clipmap_mesh : Mesh
@export var max_height : int = 0
@export var max_depth : int = 0
@export var heightmap_scale : int = 1

var procedural_textures : Dictionary = {
	"sand" : {
		"albedo_texture" : preload("res://Ground080_1K-PNG/Ground080_1K-PNG_Color.png"),
		"normal_texture" : preload("res://Ground080_1K-PNG/Ground080_1K-PNG_NormalGL.png"),
		"orm_texture" : preload("res://Ground080_1K-PNG/Ground080_1K-PNG_Color.png"),
		"minmax_slope" : [0.0, 0.7],
		"minmax_height" : [-5.0, 1.0]
	}, 
	"grass" : {
		"albedo_texture" : preload("res://Grass008_1K-PNG/Grass008_1K-PNG_Color.png"),
		"normal_texture" : preload("res://Ground080_1K-PNG/Ground080_1K-PNG_NormalGL.png"),
		"orm_texture" : preload("res://Ground080_1K-PNG/Ground080_1K-PNG_Color.png"),
		"minmax_slope" : [0.0, 0.5],
		"minmax_height" : [1.0, 20.0]
	}, 
	"rock_moss" : {
		"albedo_texture" : preload("res://Rock053_1K-PNG/Rock053_1K-PNG_Color.png"),
		"normal_texture" : preload("res://Ground080_1K-PNG/Ground080_1K-PNG_NormalGL.png"),
		"orm_texture" : preload("res://Ground080_1K-PNG/Ground080_1K-PNG_Color.png"),
		"minmax_slope" : [0.5, 0.7],
		"minmax_height" : [1.0, 20.0]
	}, 
	"rock" : {
		"albedo_texture" : preload("res://Rock030_1K-PNG/Rock030_1K-PNG_Color.png"),
		"normal_texture" : preload("res://Ground080_1K-PNG/Ground080_1K-PNG_NormalGL.png"),
		"orm_texture" : preload("res://Ground080_1K-PNG/Ground080_1K-PNG_Color.png"),
		"minmax_slope" : [0.7, 1.0],
		"minmax_height" : [-5.0, 25.0]
	}, 
	"snow" : {
		"albedo_texture" : preload("res://Snow010A_1K-PNG/Snow010A_1K-PNG_Color.png"),
		"normal_texture" : preload("res://Ground080_1K-PNG/Ground080_1K-PNG_NormalGL.png"),
		"orm_texture" : preload("res://Ground080_1K-PNG/Ground080_1K-PNG_Color.png"),
		"minmax_slope" : [0.0, 0.7],
		"minmax_height" : [20.0, 25.0]
	}
}

@onready var terrain_shader : Shader = preload("res://addons/anathema_world_forge/terrain/terrain.gdshader")

var normalmap : Image
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
	_generate_normalmap()
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
	var hm_img = heightmap
	hm_img.decompress()
	hm_img.convert(Image.FORMAT_RF)
	hms.update_map_data_from_image(hm_img, 0.0, abs(max_height) + abs(max_depth))
	terrain_collision_shape.shape = hms
	terrain_collision_shape.top_level = true
	terrain_collision_shape.global_position = Vector3.ZERO
	terrain_collision_shape.global_position.y = -abs(max_depth)

func _configure_terrain_material():
	terrain_material = ShaderMaterial.new()
	terrain_material.shader = terrain_shader
	terrain_material.set("shader_parameter/heightmap", generate_texture_from_image(heightmap))
	terrain_material.set("shader_parameter/normalmap", generate_texture_from_image(normalmap))
	terrain_material.set("shader_parameter/max_height", max_height)
	terrain_material.set("shader_parameter/max_depth", max_depth)
	terrain_material.set("shader_parameter/heightmap_scale", heightmap_scale)

	var albedo_texture_array : Array = []
	for i in procedural_textures:
		albedo_texture_array.append(procedural_textures[i]["albedo_texture"])
	terrain_material.set("shader_parameter/albedo_texture_array", albedo_texture_array)
	
	var normal_texture_array : Array = []
	for i in procedural_textures:
		normal_texture_array.append(procedural_textures[i]["albedo_texture"])
	terrain_material.set("shader_parameter/normal_texture_array", normal_texture_array)

	var orm_texture_array : Array = []
	for i in procedural_textures:
		orm_texture_array.append(procedural_textures[i]["albedo_texture"])
	terrain_material.set("shader_parameter/orm_texture_array", orm_texture_array)
	
	var minmax_array : PackedColorArray = []
	for i in procedural_textures:
		minmax_array.append(Color(
			procedural_textures[i]["minmax_slope"][0],
			procedural_textures[i]["minmax_slope"][1],
			reduce_to_raw_heightmap_height(procedural_textures[i]["minmax_height"][0]),
			reduce_to_raw_heightmap_height(procedural_textures[i]["minmax_height"][1])
			))
	terrain_material.set("shader_parameter/minmax_array", minmax_array)
	
func reduce_to_raw_heightmap_height(m_height):
	var final_value : float
	final_value = (m_height + abs(max_depth)) / (abs(max_height) + abs(max_depth))
	final_value = clamp(final_value, 0.0, 1.0)
	return final_value
	
func _create_terrain_mesh_instance():
	terrain_mesh_instance = MeshInstance3D.new()
	self.add_child(terrain_mesh_instance)
	terrain_mesh_instance.owner = self
	terrain_mesh_instance.mesh = clipmap_mesh
	terrain_mesh_instance.material_override = terrain_material
	
func _generate_normalmap():
	normalmap = heightmap.duplicate()
	normalmap.bump_map_to_normal_map(abs(max_height) + abs(max_depth))
	 
func _reset_position():
	global_position = Vector3.ZERO
	global_rotation = Vector3.ZERO

func generate_texture_from_image(image : Image) -> ImageTexture:
	var texture := ImageTexture.new()
	texture.set_image(image)
	return texture
