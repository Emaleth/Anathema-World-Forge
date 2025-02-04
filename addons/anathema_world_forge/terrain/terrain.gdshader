shader_type spatial;
render_mode world_vertex_coords;

const float EPSILON = 0.000001; // NOTE: this is to fix edge case in get_albedo() whe flat terrain at lowest point would have blendWeight of 0.0
const int array_size = 5;
const vec3 base_color = vec3(1.0, 0.5, 0.5); 

uniform sampler2D heightmap;
uniform sampler2D normalmap : hint_normal;
uniform int max_height;
uniform int max_depth;
uniform float heightmap_scale;

uniform sampler2D[array_size] albedo_texture_array : source_color;
uniform sampler2D[array_size] normal_texture_array : source_color;
uniform sampler2D[array_size] orm_texture_array : source_color;
uniform vec4[array_size] minmax_array : source_color;

varying mat4 mdv_mx;
varying vec2 clipped_uv;
varying vec3 vtx;
varying vec3 uv_triplanar_pos;
varying vec3 uv_power_normal;
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

vec3 get_albedo(sampler2D[array_size] texture_array) {
    float slope = get_slope();
    float height = get_height();
    vec3 albedo;
    for (int i = 0; i < texture_array.length(); i++) {
        if ((slope >= minmax_array[i].r) && (slope < minmax_array[i].g) && (height >= minmax_array[i].b) && (height < minmax_array[i].a)) {
            albedo = triplanar_stochastic_texture(texture_array[i]).rgb;
            break;
        } else {
            albedo = base_color;
        }
    }
    return albedo;
}

void vertex() {
	vec2 heightmap_size = vec2(textureSize(heightmap, 0));
	vtx = VERTEX;
	mdv_mx = MODELVIEW_MATRIX;
	absolute_height = abs(max_height) + abs(max_depth);

	uv_power_normal = pow(abs(NORMAL), vec3(1.0));
	uv_triplanar_pos = VERTEX;
	uv_power_normal /= dot(uv_power_normal, vec3(1.0));
	uv_triplanar_pos *= vec3(1.0, -1.0, 1.0);

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

	ALBEDO = get_albedo(albedo_texture_array);
	NORMAL_MAP = mix(texture(normalmap, clipped_uv).rgb, get_albedo(normal_texture_array), 0.5);
	NORMAL_MAP_DEPTH = 2.0;
	ROUGHNESS = 1.0;
}