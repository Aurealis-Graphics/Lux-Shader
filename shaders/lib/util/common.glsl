float GetLuminance(vec3 color)
{
 	return dot(color, vec3(0.2125, 0.7154, 0.0721));
}

float Hash(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 HashVec2(vec2 p)
{
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

mat2 Rotate(float angle) 
{
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

float DistanceSqr(vec3 a, vec3 b) 
{
    a -= b;
    return dot(a, a);
}

float LinearizeDepth(float z, float zFar, float zNear)
{
	return (zFar * (z - zNear)) / (z * (zFar - zNear));
}

float Saturate(float x) 
{
	return clamp(x, 0.0, 1.0);
}

vec2 Saturate(vec2 x) 
{
	return clamp(x, 0.0, 1.0);
}

vec3 Saturate(vec3 x) 
{
	return clamp(x, 0.0, 1.0);
}

vec4 Saturate(vec4 x) 
{
	return clamp(x, 0.0, 1.0);
}

/* 3rd-degree smoothstep polynomial */
float Smooth3(float x) 
{
	x = Saturate(x);
	return x * x * (3.0 - 2.0 * x);
}

vec2 Smooth3(vec2 x) 
{
	x = Saturate(x);
	return x * x * (3.0 - 2.0 * x);
}

vec3 Smooth3(vec3 x) 
{
	x = Saturate(x);
	return x * x * (3.0 - 2.0 * x);
}