shader_type spatial;
//render_mode world_vertex_coords;


uniform float heightmap_size;
uniform float heightmap_scale;

uniform sampler2D water_albedo_texture;
uniform sampler2D water_normal_texture : hint_normal;
uniform sampler2D water_specular_texture;
uniform sampler2D water_displacement_texture;

varying mat4 mdv_mx;
varying vec2 clipped_uv;
varying vec3 vtx;
varying vec3 uv_triplanar_pos;
varying vec3 uv_power_normal;


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

vec2 hash( vec2 p ) {
	return fract( sin( p * mat2( vec2( 127.1, 311.7 ), vec2( 269.5, 183.3 ) ) ) * 43758.5453 );
}

vec4 stochastic_sample(sampler2D tex, vec2 uv) {
	vec2 skewV = mat2(vec2(1.0,1.0),vec2(-0.57735027 , 1.15470054))*uv * 3.464;

	vec2 vxID = floor(skewV);
	vec2 fracV = fract(skewV);
	vec3 barry = vec3(fracV.x,fracV.y,1.0-fracV.x-fracV.y);

	mat4 bw_vx = barry.z>0.0?
		mat4(vec4(vxID,0.0,0.0),vec4((vxID+vec2(0.0,1.0)),0.0,0.0),vec4(vxID+vec2(1.0,0.0),0,0),vec4(barry.zyx,0)):
		mat4(vec4(vxID+vec2(1.0,1.0),0.0,0.0),vec4((vxID+vec2(1.0,0.0)),0.0,0.0),vec4(vxID+vec2(0.0,1.0),0,0),vec4(-barry.z,1.0-barry.y,1.0-barry.x,0));

	vec2 ddx = dFdx(uv);
	vec2 ddy = dFdy(uv);

	return (textureGrad(tex,uv+hash(bw_vx[0].xy),ddx,ddy)*bw_vx[3].x) +
	(textureGrad(tex,uv+hash(bw_vx[1].xy),ddx,ddy)*bw_vx[3].y) +
	(textureGrad(tex,uv+hash(bw_vx[2].xy),ddx,ddy)*bw_vx[3].z);
}

vec4 triplanar_stochastic_texture(sampler2D p_sampler) {
	vec3 triplanar_pos = uv_triplanar_pos;
	vec3 weights = uv_power_normal;
	vec4 samp=vec4(0.0);
	samp+= stochastic_sample(p_sampler, triplanar_pos.xy) * weights.z;
	samp+= stochastic_sample(p_sampler, triplanar_pos.xz) * weights.y;
	samp+= stochastic_sample(p_sampler, triplanar_pos.zy * vec2(-1.0,1.0)) * weights.x;
	return samp;
}

vec3 get_texture(sampler2D tex) {
	vec3 final_texture;
	final_texture = triplanar_stochastic_texture(tex).rgb;
	return final_texture;
}

void vertex() {
	vtx = VERTEX;
	mdv_mx = MODELVIEW_MATRIX;

	uv_power_normal = pow(abs(NORMAL), vec3(1.0));
	uv_triplanar_pos = VERTEX;
	uv_triplanar_pos.xy += sin(TIME*0.5);
	uv_power_normal /= dot(uv_power_normal, vec3(1.0));
	uv_triplanar_pos *= vec3(1.0, -1.0, 1.0);

	clipped_uv = ((vtx.xz + MODEL_MATRIX[3].xz) / (heightmap_size * heightmap_scale)) + 0.5;

	if (frustrum_culling() || edge_culling()) {
		VERTEX = vec3(sqrt(-MODELVIEW_MATRIX[3][3]));
	} else {
		VERTEX.y = 0.0;
	}
}

void fragment() {
	if (frustrum_culling() || edge_culling()) {
		discard;
	}

	ALBEDO = get_texture(water_albedo_texture);
	NORMAL_MAP = get_texture(water_normal_texture);
	ROUGHNESS = 1.0 - get_texture(water_specular_texture).r;
	NORMAL_MAP_DEPTH = get_texture(water_displacement_texture).r * 5.0;
}