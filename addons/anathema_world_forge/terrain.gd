@tool
extends StaticBody3D

@export var generate := false
@export var heightmap : Texture2D
@export var normalmap : Texture2D
@export var clipmap_mesh : Mesh
@export var heightmap_max_height : int
@export var heightmap_min_height : int

@onready var terrain_shader : Shader = preload("res://addons/anathema_world_forge/terrain.gdshader")

var terrain_material : ShaderMaterial
var mesh_instance : MeshInstance3D
var collision_shape : CollisionShape3D

func _ready() -> void:
	_generate()
	
func _process(delta: float) -> void:
	if generate == false: return
	_generate()
	generate = false
	
func move_terrain(pos : Vector3) -> void:
	global_transform.origin = Vector3(pos.x, 0, pos.z).snapped(Vector3(1, 1, 1))

func _generate() -> void:
	_clear_children()
	_create_terrain_collision_shape()
	_configure_terrain_material()
	_create_terrain_mesh_instance()
	
func _clear_children():
	for i in get_children():
		i.queue_free()
		
func _create_terrain_collision_shape():
	#FIXME: COLLISION SHAPE DOESN'T SHOW IN EDITOR
	collision_shape = CollisionShape3D.new()
	self.add_child(collision_shape)
	var hms = HeightMapShape3D.new()
	var hm_img = heightmap.get_image()
	hm_img.decompress()
	hm_img.convert(Image.FORMAT_RH)
	hms.update_map_data_from_image(hm_img, heightmap_min_height, heightmap_max_height)
	collision_shape.shape = hms

func _configure_terrain_material():
	terrain_material = ShaderMaterial.new()
	terrain_material.shader = terrain_shader
	terrain_material.set("shader_parameter/heightmap", heightmap)
	terrain_material.set("shader_parameter/normalmap", normalmap)
	terrain_material.set("shader_parameter/height", heightmap_max_height)
	terrain_material.set("shader_parameter/heightmap_scale", Vector2.ONE)

func _create_terrain_mesh_instance():
	mesh_instance = MeshInstance3D.new()
	self.add_child(mesh_instance)
	mesh_instance.mesh = clipmap_mesh
	mesh_instance.material_override = terrain_material
	
