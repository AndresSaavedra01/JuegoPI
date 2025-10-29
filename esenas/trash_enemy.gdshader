shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque ;

const int n_balls = 8;
uniform vec3 ball_pos[n_balls];
uniform float radi[n_balls];
uniform float blend_r;
const float EPS = 1e-3;


uniform vec3 base_color : source_color;
uniform vec3 fresnel_color : source_color;
uniform float fresnel_strength;
uniform float fresnel_emition;


bool ray_box_intersect(vec3 ray_origin, vec3 ray_dir,vec3 b_min, vec3 b_max, out float t_min, out float t_max){
	

	vec3 t1 = (b_min - ray_origin)/ray_dir;
	vec3 t2 = (b_max - ray_origin)/ray_dir;
	
	vec3 t_min_vec = min(t1,t2);
	vec3 t_max_vec = max(t1,t2);
	
	t_max =min(t_max_vec.x ,min(t_max_vec.y, t_max_vec.z));
	t_min =max(t_min_vec.x ,max(t_min_vec.y, t_min_vec.z));
	//if (t_min < 0.0){
		//return false;
	//}
		
	if (t_max < t_min){
		return false;
	}
	return true;
	}


float s_min(float a, float b, float k){
 	float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float sdf_metaballs(vec3 p){
	float fields[n_balls];
	
	for (int i = 0; i < n_balls; i++){		
		fields[i] = length(p - ball_pos[i]) - radi[i];
	}
	float d = fields[0];
	for (int i = 0; i < n_balls; i++){		
		d = s_min(d,fields[i], blend_r);
	}
	return d;
	
}

vec3 estimate_normal(vec3 p) {
    float dx = sdf_metaballs(p + vec3( EPS, 0.0, 0.0)) -
               sdf_metaballs(p - vec3( EPS, 0.0, 0.0));

    float dy = sdf_metaballs(p + vec3(0.0,  EPS, 0.0)) -
               sdf_metaballs(p - vec3(0.0,  EPS, 0.0));

    float dz = sdf_metaballs(p + vec3(0.0, 0.0,  EPS)) -
               sdf_metaballs(p - vec3(0.0, 0.0,  EPS));

    return normalize(vec3(dx, dy, dz));
}


bool ray_march(vec3 ray_origin, vec3 ray_dir, float t_min, float t_max, out vec3 p) {
	float t = t_min;
    const int MAX_STEPS = 64;
    for (int i = 0; i < MAX_STEPS; i++) {
        p = ray_origin + t * ray_dir;
        float d = sdf_metaballs(p);    // distance to surface
        if (d < 0.001) {               // hit!            
            return true;
        }
        t += d;                        // advance by the distance field
        if (t > t_max) 
			break;
    }
	return false;
}

vec3 fresnel_glow(float amount, float intensity, vec3 color, vec3 normal, vec3 view)
{
	return pow((1.0 - dot(normalize(normal), normalize(view))), amount) * color * intensity;
}



void fragment() {
	
	vec3 world_position = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 ray_origin = CAMERA_POSITION_WORLD;
	vec3 ray_dir = normalize(world_position - ray_origin);

    ray_origin = (inverse(MODEL_MATRIX) * vec4(ray_origin, 1.0)).xyz;
    ray_dir    = normalize((inverse(MODEL_MATRIX) * vec4(ray_dir, 0.0)).xyz);

    // 2. Find where the ray enters and exits the cube (ray–box intersection)
    float t_min, t_max;
    if (!ray_box_intersect(ray_origin, ray_dir, vec3(-0.5), vec3(0.5), t_min, t_max))
        discard;         
	// keep cull_disabled
	if (!FRONT_FACING && t_min > 0.0) {
	    discard;          // skip back faces only when the eye is outside
	}
          // misses the box
    // 3. March the ray through the SDF field
	vec3 p = vec3(0);
	if(!ray_march(ray_origin, ray_dir, t_min, t_max, p))
		discard;
		
		
	vec3 normals = estimate_normal(p);
	NORMAL  = normals;
	vec3 fresnel = fresnel_glow(fresnel_strength, fresnel_emition, fresnel_color, NORMAL, normalize(-ray_dir));
	ALBEDO = base_color + fresnel;
	ALPHA = 1.0;
    vec4 world_p = MODEL_MATRIX * vec4(p, 1.0);
	
    vec4 clip_p  = PROJECTION_MATRIX * VIEW_MATRIX * world_p;
    float depth  = clip_p.z / clip_p.w;     // −1 … 1
    DEPTH = depth ;       //  0 … 1  //  0 … 1
	}