/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 


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

float LinearTosRGB(float x)
{
	float sRGBLo = x * 12.92;
	float sRGBHi = pow((x + 0.055) / 1.055, 2.4);
	return mix(sRGBLo, sRGBHi, step(x, 0.0031308));
}

float SRGBToLinear(float x)
{
	float linearLo = x / 12.92;
	float linearHi = pow((x + 0.055) / 1.055, 2.4);
	return mix(linearLo, linearHi, step(x, 0.04045));
}

vec3 LinearTosRGB(vec3 x)
{
	vec3 sRGBLo = x * 12.92;
	vec3 sRGBHi = pow(abs(x), vec3(1.0 / 2.4)) * 1.055 - 0.055;
	return mix(sRGBHi, sRGBLo, step(x, vec3(0.0031308)));
}

vec3 SRGBToLinear(vec3 x)
{
	vec3 linearLo = x / 12.92;
	vec3 linearHi = pow((x + 0.055) / 1.055, vec3(2.4));
	return mix(linearHi, linearLo, step(x, vec3(0.04045)));
}

vec3 Saturation(vec3 color, float saturation) 
{
    return mix(vec3(GetLuminance(color)), color, saturation);
}

bool IsHand(float z) 
{
	return z < 0.56;
}