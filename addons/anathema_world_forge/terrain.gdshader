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

vec4 texture_triplanar(sampler2D tex, vec3 world_pos, vec3 blend) {
	vec4 xaxis = stochastic_sample(tex, world_pos.yz);
	vec4 yaxis = stochastic_sample(tex, world_pos.xz);
	vec4 zaxis = stochastic_sample(tex, world_pos.xy);
	return xaxis * blend.x + yaxis * blend.y + zaxis * blend.z;
}

vec3 get_albedo() {
	//float slope = acos(dot((texture(normalmap, clipped_uv) * 2.0 - 1.0).rgb, vec3(0.0, 0.0, 1.0)));
	float slope = acos(texture(normalmap, clipped_uv) * 2.0 - 1.0).z;
	vec3 final_texture;
	if(slope < 0.2)
	{
		float blend_amount = slope / 0.2f;
		final_texture = mix(
			stochastic_sample(flat_texture, clipped_uv * heightmap_size).rgb, 
			stochastic_sample(slant_texture, clipped_uv * heightmap_size).rgb, 
			blend_amount
		);
		final_texture = stochastic_sample(flat_texture, clipped_uv * heightmap_size).rgb;
	}
	
	if((slope < 0.7) && (slope >= 0.2f))
	{
		float blend_amount = (slope - 0.2f) * (1.0f / (0.7f - 0.2f));
		final_texture = mix(
			stochastic_sample(slant_texture, clipped_uv * heightmap_size).rgb, 
			stochastic_sample(slope_texture, clipped_uv * heightmap_size).rgb, 
			blend_amount
		);
		final_texture = stochastic_sample(slant_texture, clipped_uv * heightmap_size).rgb; 
	}

	if(slope >= 0.7) 
	{
		final_texture = stochastic_sample(slope_texture, clipped_uv * heightmap_size).rgb;
	}
	return final_texture;
}

void vertex() {
	heightmap_size = vec2(textureSize(heightmap, 0));
	vtx = VERTEX;
	mdv_mx = MODELVIEW_MATRIX;

	clipped_uv = ((vtx.xz + MODEL_MATRIX[3].xz) / (heightmap_size * heightmap_scale)) + 0.5;
	
	if (frustrum_culling() || edge_culling()) {
		VERTEX = vec3(sqrt(-MODELVIEW_MATRIX[3][3]));
	} else {
		VERTEX.y = texture(heightmap, clipped_uv).r * float(height);
	}
}

void fragment() {
	if (frustrum_culling() || edge_culling()) {
		discard;
	}

	//ALBEDO = texture_triplanar(flat_texture, texture(heightmap, clipped_uv).rgb * vec3(0.0, float(height), 0.0), acos(texture(normalmap, clipped_uv)).rgb).rgb;
	//ALBEDO = stochastic_sample(flat_texture, clipped_uv).rgb;
	ALBEDO = get_albedo();
	NORMAL_MAP = texture(normalmap, clipped_uv).rgb;
	NORMAL_MAP_DEPTH = float(height);
	ROUGHNESS = 1.0;
}