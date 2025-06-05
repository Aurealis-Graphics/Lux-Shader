/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

#define Saturate(x) clamp(x, 0.0, 1.0)
#define Max0(x) max(x, 0.0)
#define MaxEPS(x) max(x, EPS)

float Pow2(float x) { 				return x * x; 		}
float Pow3(float x) { 				return Pow2(x) * x; }
float Pow4(float x) { x = Pow2(x); 	return x * x; 		}
float Pow5(float x) { 				return Pow4(x) * x; }
float Pow6(float x) { x = Pow3(x); 	return x * x; 		}
float Pow8(float x) { x = Pow4(x); 	return x * x; 		}

vec2 Pow2(vec2 x) { 				return x * x; 		}
vec2 Pow3(vec2 x) { 				return Pow2(x) * x; }
vec2 Pow4(vec2 x) { x = Pow2(x); 	return x * x; 		}
vec2 Pow5(vec2 x) { 				return Pow4(x) * x; }
vec2 Pow6(vec2 x) { x = Pow3(x); 	return x * x; 		}
vec2 Pow8(vec2 x) { x = Pow4(x); 	return x * x; 		}

vec3 Pow2(vec3 x) { 				return x * x; 		}
vec3 Pow3(vec3 x) { 				return Pow2(x) * x; }
vec3 Pow4(vec3 x) { x = Pow2(x); 	return x * x; 		}
vec3 Pow5(vec3 x) { 				return Pow4(x) * x; }
vec3 Pow6(vec3 x) { x = Pow3(x); 	return x * x; 		}
vec3 Pow8(vec3 x) { x = Pow4(x); 	return x * x; 		}

vec4 Pow2(vec4 x) { 				return x * x; 		}
vec4 Pow3(vec4 x) { 				return Pow2(x) * x; }
vec4 Pow4(vec4 x) { x = Pow2(x); 	return x * x; 		}
vec4 Pow5(vec4 x) { 				return Pow4(x) * x; }
vec4 Pow6(vec4 x) { x = Pow3(x); 	return x * x; 		}
vec4 Pow8(vec4 x) { x = Pow4(x); 	return x * x; 		}

float MaxOf(vec3 x) { return max(x.x, max(x.y, x.z)); }
float MinOf(vec3 x) { return min(x.x, min(x.y, x.z)); }

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

float GetLuminance(vec3 color)
{
 	return dot(color, vec3(0.2125, 0.7154, 0.0721));
}

float Hash11(float x)
{
	x = fract(x * 0.3183099);
	x += dot(x, x + 19.19);
	return fract(x * 0.3183099);
}

float Hash21(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

vec2 Hash22(vec2 p)
{
	p = vec2(
		dot(p, vec2(127.1, 311.7)),
		dot(p, vec2(269.5, 183.3))
	);

	return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

mat2 Rotate(float angle) 
{
    float s = sin(angle), c = cos(angle);
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

/* amount := lifting amount [-1, inf] */
float Lift(float x, float amount)
{
	return (1.0 + amount) * x / (amount * x + 1.0);
}

vec3 Lift(vec3 x, float amount)
{
	return (1.0 + amount) * x / (amount * x + 1.0);
}

float SmoothF(float x, float alpha)
{
	return x > 0.0 ? pow(x / (x + pow(x, -1.0 / alpha)), alpha / (1.0 + alpha)) : x;
}

float SmoothMin(float a, float b, float alpha)
{
	return b + 1.0 + SmoothF(a - b + 1.0, alpha);
}

float SmoothMax(float a, float b, float alpha)
{
	return b + 1.0 - SmoothF(1.0 - a + b, alpha);
}