shader_type spatial;
render_mode cull_disabled, vertex_lighting, unshaded;

uniform sampler2D terrain_height_map;
uniform highp sampler2D terrain_normal_map;
uniform sampler2D wind_noise;
uniform float wind_speed;
uniform vec3 wind_direction;
uniform int max_altitude;
uniform int max_depth;
uniform sampler2D foliage_density_noise;

uniform float roughness = 0.3;
uniform vec3 bottom_color = vec3(0.0, 0.0, 0.0);
uniform vec3 top_color = vec3(0.0, 1.0, 0.0);
uniform vec4 minmax : source_color;
uniform float horizontal_bendiness = 0.3;
uniform float vertical_bendiness = 0.3;

uniform bool is_dynamic = true;

varying vec2 map_size;
varying mat4 mdv_mx;
varying vec3 vtx;
varying vec2 clipped_uv;
varying float slope;
varying float height;
varying float current_wind;
varying float instance_random;


float random(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

vec3 unpack_normalmap(vec4 rgba) {
	vec3 n = rgba.xyz * 2.0 - vec3(1.0);
	n.z *= -1.0;
	return n;
}

float sclamp(float f,float sc){
	return clamp(((f-0.5)*sc)+0.5,0.0,1.0);
}

bool frustrum_culling() {
	float z_dist = clamp((mdv_mx * vec4(vtx, 1.0)).z * -1.0,0.0, 2000.0 + 10.0);
	if (z_dist < 0.0) {
		return true;
	} else {
		return false;
	}
}

bool slope_filter() {
	if ((slope < minmax.r) || (slope > minmax.g)) {
		return true;
	} else {
		return false;
	}
}

bool density_filter() {
	if (instance_random < texture(foliage_density_noise, clipped_uv).r) {
		return true;
	} else {
		return false;
	}
}

bool height_filter() {
	if ((height < minmax.b) || (height > minmax.a)) {
		return true;
	} else {
		return false;
	}
}

void vertex() {
	vtx = VERTEX;
	map_size = vec2(textureSize(terrain_height_map, 0));
	mdv_mx = MODELVIEW_MATRIX;
	clipped_uv = (MODEL_MATRIX[3].xz / map_size) + 0.5; // instance pos
	slope = acos((texture(terrain_normal_map, clipped_uv).rgb * 2.0 - 1.0).z);
	height = texture(terrain_height_map, clipped_uv).r;// * float(max_altitude - max_depth) + float(max_depth);
	instance_random = random(MODEL_MATRIX[3].xz);

	if (frustrum_culling() || slope_filter() || height_filter() || density_filter() || (clipped_uv.x > 0.995) || (clipped_uv.y > 0.995) || (clipped_uv.x < 0.005) || (clipped_uv.y < 0.005)) {
		VERTEX = vec3(sqrt(-MODELVIEW_MATRIX[3][3]));
	} else {
//		NORMAL = unpack_normalmap(texture(terrain_normal_map, clipped_uv));
		if (is_dynamic) {
			vec4 wind_dir_local = vec4(wind_direction,0.0) * MODEL_MATRIX;
			vec2 world_vertex = MODEL_MATRIX[3].xz;
//			current_wind = (sin(TIME) * normalize(wind_direction.xz) *  wind_speed + world_vertex).x;
			current_wind = texture(wind_noise, normalize(wind_direction.xz) * (-TIME * wind_speed) + world_vertex).x;
			VERTEX += normalize(wind_dir_local.xyz) * horizontal_bendiness * (VERTEX.y) * sclamp(current_wind, 1.5);
//			NORMAL += normalize(wind_dir_local.xyz) * horizontal_bendiness * (VERTEX.y) * sclamp(current_wind, 1.5);
			VERTEX.y -= current_wind * vertical_bendiness * UV.y;
//			NORMAL.y -= current_wind * vertical_bendiness * UV.y;
		}
		VERTEX *= mix(0.5, 1.5, instance_random);
		VERTEX.y += height * float(max_altitude - max_depth) + float(max_depth);
	}
}

void fragment() {
	vec4 a = texture(texturee, UV);
	if (frustrum_culling() || slope_filter() || height_filter() || density_filter() || (clipped_uv.x > 0.995) || (clipped_uv.y > 0.995) || (clipped_uv.x < 0.005) || (clipped_uv.y < 0.005) || (a.a < 1.0)) {
		discard;
	} else {
//		ALBEDO = mix(bottom_color, top_color * instance_random, UV.y + 0.2);
		ALBEDO = a.rgb;
//		SPECULAR = 1.0;
//		NORMAL = (VIEW_MATRIX * vec4(normalize(unpack_normalmap(texture(terrain_normal_map, clipped_uv))), 0.0)).xyz;
		if (is_dynamic) {
			ROUGHNESS = roughness * current_wind;
		} else {
			ROUGHNESS = roughness;
		}
	}
}"