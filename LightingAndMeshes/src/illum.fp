/*
 * Illumination fragment shader: phong and toon shading
 */

// From vertex shader: position and normal (in eye coordinates)
varying vec4 pos;
varying vec3 norm;

// Do Phong specular shading (r DOT v) instead of Blinn-Phong (n DOT h)
uniform int phong;
// Do toon shading
uniform int toon;
// If false, then don't do anything in fragment shader
uniform int useFragShader;

// Toon shading parameters
uniform float toonHigh;
uniform float toonLow;

// Apply volume texture to diffuse term
//uniform int volTexture;
// Volume texture scale
//uniform float volRes;

// Compute toon shade value given diffuse and specular component levels
vec4 toonShade(float diffuse, float specular)
{
	if (diffuse > toonHigh)
		diffuse = 0.8;
	else if (diffuse < toonLow)
		diffuse = 0.2;
	else
		diffuse = 0.5;
		
	if (specular > toonHigh)
		specular = 0.9;
	else 
		specular = 0.0;
		
    vec4 amb = gl_FrontLightProduct[0].ambient;
    vec4 diff = gl_FrontLightProduct[0].diffuse * diffuse;
    return vec4(amb + diff + specular);
}

void main()
{
    if (useFragShader == 0) {
        // Pass through
        gl_FragColor = gl_Color;
    } else {
        // Do lighting computation...
        vec3 n = normalize(norm);
        vec3 l = normalize(vec3(gl_LightSource[0].position) - vec3(pos));
        vec3 v = normalize(vec3(-pos));
        vec3 h = normalize(l + v);
        float n_dot_l = dot(n,l);
        float d = max(0.0, n_dot_l);
        float s = pow(max(dot(n,h),0.0), gl_FrontMaterial.shininess);
        vec4 light;
        
        if (toon == 1) {
            if (n_dot_l < 0.0) light = toonShade(d, 0.0);
            else light = toonShade(d, s);
        } else {
            vec4 amb = gl_FrontLightProduct[0].ambient;
            vec4 diff = gl_FrontLightProduct[0].diffuse * d;
            vec4 spec;
            if (phong==1) {
               vec3 r = normalize(2.0*n_dot_l*n-l);
               float r_dot_v = dot(r,v);
               float a_prime = gl_FrontMaterial.shininess * log(r_dot_v) / log(dot(n,h)) + 0.01;
               spec = gl_FrontLightProduct[0].specular * pow(max(0.0, r_dot_v), a_prime);
            } else {
        	   spec = gl_FrontLightProduct[0].specular * s;
            }
            
            light = amb + diff;
            if (n_dot_l >= 0.0) light += spec;
        }
        gl_FragColor = vec4(light.x, light.y, light.z, 1.0);
        
    }
}
