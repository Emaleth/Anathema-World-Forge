@tool
extends Node

@export var generate := false
@export var heightmap : Image

@export var max_height : int = 0
@export var max_depth : int = 0
@export var heightmap_scale : int = 1

var _foliage_index : Dictionary = {
	"grass" : {
		"slope" : [0.0, 0.7],
		"height" : [0.5, 100.0],
		"mesh" : preload("res://foliage_mesh.tres"),
		"albedo_texture" : preload("res://sprite_0005.png"),
		"density" : 64,
		"patch_size" : 8
	}
}

@onready var foliage_shader : Shader = preload("res://addons/anathema_world_forge/foliage/foliage.gdshader")

var foliage_material : ShaderMaterial

func _ready() -> void:
	_generate()
	
func _process(delta: float) -> void:
	if generate == false: return
	_generate()
	generate = false

func move_foliage(pos : Vector3) -> void:
	for i in _foliage_index:
		_foliage_index[i]["multimesh"].global_transform.origin = Vector3(pos.x, 0, pos.z).snapped(Vector3(1, 1, 1))
	
func _generate() -> void:
	_clear_children()
	_create_and_configure_multimeshes()

	
func _clear_children():
	for i in get_children():
		i.queue_free()
	
		
		
func _create_and_configure_multimeshes():
	for i in _foliage_index:
		
		_foliage_index[i]["multimesh"] = MultiMeshInstance3D.new()
		add_child(_foliage_index[i]["multimesh"])
		
		_foliage_index[i]["multimesh"].multimesh = MultiMesh.new()
		_foliage_index[i]["multimesh"].multimesh.mesh = _foliage_index[i]["mesh"]
		_foliage_index[i]["multimesh"].multimesh.transform_format = MultiMesh.TRANSFORM_3D
		_foliage_index[i]["multimesh"].cast_shadow = false
		_foliage_index[i]["multimesh"].multimesh.instance_count = int(_foliage_index[i]["density"] * pow(_foliage_index[i]["patch_size"], 2))
		
		_configure_shader(i)
		_foliage_index[i]["multimesh"].material_override = _foliage_index[i]["material"]
		_foliage_index[i]["multimesh"].extra_cull_margin = abs(max_height) + abs(max_depth)
		
		
func _configure_shader(m_i):
	_foliage_index[m_i]["material"] = ShaderMaterial.new()
	_foliage_index[m_i]["material"].shader = _foliage_index[m_i]["shader"]
	var minmax_linear := Color(
		_foliage_index[m_i]["slope"][0], 
		_foliage_index[m_i]["slope"][1], 
		reduce_to_raw_heightmap_height(_foliage_index[m_i]["height"][0]),
		reduce_to_raw_heightmap_height(_foliage_index[m_i]["height"][1])
		)  
	var minmax_srgb := minmax_linear.linear_to_srgb()
	var minmax := Color(minmax_linear.r, minmax_linear.g, minmax_srgb.b, minmax_srgb.a)
#	print(minmax)
	_foliage_index[m_i]["material"].set_shader_parameter("minmax", minmax)
	_foliage_index[m_i]["material"].set_shader_parameter("top_color", _foliage_index[m_i]["top_color"])
	_foliage_index[m_i]["material"].set_shader_parameter("bottom_color", _foliage_index[m_i]["bottom_color"])
	_foliage_index[m_i]["material"].set_shader_parameter("is_dynamic", _foliage_index[m_i]["is_dynamic"])
	_foliage_index[m_i]["material"].set_shader_parameter("albedo_texture", _foliage_index[m_i]["albedo_texture"])


func _get_instance_positions():
	for i in _foliage_index:
		var valid_positions := []
		var point_distribution = _distribute_in_a_grid(_foliage_index[i]["density"])
			
		for point in point_distribution:
			var basis := Basis.from_euler(Vector3(0.0, deg_to_rad(randf_range(-180, 180)), 0.0))
			
			var origin := Vector3(point.x, 0, point.y)
			
			for x in range(-_foliage_index[i]["patch_size"] / 2, _foliage_index[i]["patch_size"] / 2):
				for z in range(-_foliage_index[i]["patch_size"] / 2, _foliage_index[i]["patch_size"] / 2):
					valid_positions.append(Transform3D(basis, origin + Vector3(x, 0, z)))

		for z in _foliage_index[i]["multimesh"].multimesh.instance_count:
			if z >= valid_positions.size():
				return
			_foliage_index[i]["multimesh"].multimesh.set_instance_transform(z, valid_positions[z - 1])


func _distribute_in_a_grid(m_density):
	var points = []
	var rows_and_columns = round(sqrt(m_density))
	var cell_size = 1 / rows_and_columns
	var half_offset = cell_size * 0.5
	
	for x in rows_and_columns:
		for y in rows_and_columns:
			var new_point = Vector2(x * cell_size + randf_range(-half_offset, half_offset), y * cell_size + randf_range(-half_offset, half_offset))
			points.append(new_point)
			
	return points
		
		
func reduce_to_raw_heightmap_height(m_height):
	var final_value : float
	final_value = (m_height + abs(max_depth)) / (abs(max_height) + abs(max_depth))
	final_value = clamp(final_value, 0.0, 1.0)
	return final_value
