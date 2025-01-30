shader_type spatial;
//render_mode vertex_lighting;

uniform sampler2D heightmap;
uniform sampler2D normalmap : hint_normal;
uniform int height;
uniform vec2 heightmap_scale;

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
	vec2 heightmap_size = vec2(textureSize(heightmap, 0));
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
	NORMAL_MAP = normalize(texture(normalmap, clipped_uv).rgb);
}