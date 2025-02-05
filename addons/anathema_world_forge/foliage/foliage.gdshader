shader_type spatial;
render_mode world_vertex_coords;

uniform sampler2D heightmap;
uniform sampler2D normalmap : hint_normal;
uniform int max_height;
uniform int max_depth;
uniform float heightmap_scale;

uniform sampler2D albedo_texture : source_color;
uniform sampler2D normal_texture : source_color;
uniform sampler2D orm_texture : source_color;
uniform vec4 minmax_array : source_color;

varying mat4 mdv_mx;
varying vec2 clipped_uv;
varying vec3 vtx;
varying flat int absolute_height;


bool frustrum_culling() {
	float z_dist = clamp((mdv_mx * vec4(vtx, 1.0)).z * -1.0,0.0, 2000.0 + 10.0);
	if (z_dist < 0.0) {
		return true;
	} else {
		return false;
	}
}

bool edge_culling() {
	if ((clipped_uv.x > 1.0) || (clipped_uv.y > 1.0) || (clipped_uv.x < 0.0) || (clipped_uv.y < 0.0)) {
		return true;
	} else {
		return false;
	}
}

float get_slope() {
	float slope;
	slope = 1.0 - (texture(normalmap, clipped_uv).z * 2.0 - 1.0);
	return slope;
}

float get_height() {
	float height;
	height = texture(heightmap, clipped_uv).r;
	return height;
}

void vertex() {
	vec2 heightmap_size = vec2(textureSize(heightmap, 0));
	vtx = VERTEX;
	mdv_mx = MODELVIEW_MATRIX;
	absolute_height = abs(max_height) + abs(max_depth);
	clipped_uv = (vtx.xz / (heightmap_size * heightmap_scale)) + 0.5;

	if (frustrum_culling() || edge_culling()) {
		VERTEX = vec3(sqrt(-MODELVIEW_MATRIX[3][3]));
	} else {
		VERTEX.y = (get_height() * float(absolute_height)) - float(max_depth);
	}
}

void fragment() {
	if (frustrum_culling() || edge_culling()) {
		discard;
	}
}