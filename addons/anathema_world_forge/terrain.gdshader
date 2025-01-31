shader_type spatial;
//render_mode world_vertex_coords;

uniform sampler2D heightmap;
uniform sampler2D normalmap : hint_normal;
uniform int height;
uniform float heightmap_scale;
uniform sampler2D flat_texture;
uniform sampler2D slant_texture;
uniform sampler2D slope_texture;

varying vec2 heightmap_size;
varying mat4 mdv_mx;
varying vec2 clipped_uv;
varying vec3 vtx;

bool frustrum_culling() {
	float z_dist = clamp((mdv_mx * vec4(vtx, 1.0)).z * -1.0,0.0, 2000.0 + 10.0);
	if (z_dist < 0.0) {
		return true;
	} else {
		return false;
	}
}

void vertex() {
	heightmap_size = vec2(textureSize(heightmap, 0));
	vtx = VERTEX;
	mdv_mx = MODELVIEW_MATRIX;
	clipped_uv = ((vtx.xz + MODEL_MATRIX[3].xz) / (heightmap_size * heightmap_scale)) + 0.5;
	if (frustrum_culling() || (clipped_uv.x > 1.0) || (clipped_uv.y > 1.0) || (clipped_uv.x < 0.0) || (clipped_uv.y < 0.0)) {
		VERTEX = vec3(sqrt(-MODELVIEW_MATRIX[3][3]));
	} else {
		VERTEX.y = texture(heightmap, clipped_uv).r * float(height);
	}
}

void fragment() {
	if (frustrum_culling() || (clipped_uv.x > 1.0) || (clipped_uv.y > 1.0) || (clipped_uv.x < 0.0) || (clipped_uv.y < 0.0)) {
		discard;
	}
	float slope = acos(dot((texture(normalmap, clipped_uv) * 2.0 - 1.0).rgb, vec3(0.0, 0.0, 1.0)));
	vec3 final_texture;
	if(slope < 0.2)
	{
		float blend_amount = slope / 0.2f;
		final_texture = mix(texture(flat_texture, clipped_uv * heightmap_size).rgb, texture(slant_texture, clipped_uv * heightmap_size).rgb, blend_amount);
	}
	
	if((slope < 0.7) && (slope >= 0.2f))
	{
		float blend_amount = (slope - 0.2f) * (1.0f / (0.7f - 0.2f));
		final_texture = mix(texture(slant_texture, clipped_uv * heightmap_size).rgb, texture(slope_texture, clipped_uv * heightmap_size).rgb, blend_amount);
	}

	if(slope >= 0.7) 
	{
		final_texture = texture(slope_texture, clipped_uv * heightmap_size).rgb;
	}
	ALBEDO = final_texture;
	NORMAL_MAP = texture(normalmap, clipped_uv).rgb;
	NORMAL_MAP_DEPTH = float(height);
}