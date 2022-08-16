/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

/* RGB/HSV conversion based on https://gist.github.com/983/e170a24ae8eba2cd174f */
const vec4 HsvK = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
vec3 RGBToHSV(vec3 c)
{
    vec4 p = c.g < c.b ? vec4(c.bg, HsvK.wz) : vec4(c.gb, HsvK.xy);
    vec4 q = c.r < p.x ? vec4(p.xyw,    c.r) : vec4(c.r,    p.yzx);

    float m = min(q.w, q.y);
    float d = q.x - m;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + EPS)) * 360.0, d / (q.x + EPS), q.x);
}

const vec4 RgbK = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
vec3 HSVToRGB(vec3 c)
{
    vec3 p = abs(fract(c.xxx / 360.0 + RgbK.xyz) * 6.0 - RgbK.www);
    return c.z * mix(RgbK.xxx, clamp(p - RgbK.xxx, 0.0, 1.0), c.y);
}

/* Color Transform Response Function */
float GetTransformResponse(float x, float c, float r, float a, float f) 
{
    x = 1.0 - min(1.0, max(0.0, abs(x - c) - r) / f);
    return a * x * x * (3.0 - 2.0 * x);
}

/* Color Transforms */
void RotateHueAroundHue(inout vec3 hsv, float c, float r, float a, float f) 
{
    if (hsv.y < 0.02 || hsv.z < 0.005) return;
    hsv.x += GetTransformResponse(hsv.x, c, r, a, f);
}

void RotateSaturationAroundHue(inout vec3 hsv, float c, float r, float a, float f) 
{
    if (hsv.y < 0.02 || hsv.z < 0.005) return;
    hsv.y *= 1.0 + GetTransformResponse(hsv.x, c, r, a, f);
}

void RotateValueAroundHue(inout vec3 hsv, float c, float r, float a, float f) 
{
    if (hsv.y < 0.02) return;
    hsv.z += GetTransformResponse(hsv.x, c, r, a, f);
}

void RotateHueAroundSaturation(inout vec3 hsv, float c, float r, float a, float f) 
{
    if (hsv.y < 0.02 || hsv.z < 0.005) return;
    hsv.x += GetTransformResponse(hsv.y, c, r, a, f);
}

void RotateSaturationAroundSaturation(inout vec3 hsv, float c, float r, float a, float f) 
{
    if (hsv.y < 0.02 || hsv.z < 0.005) return;
    hsv.y *= 1.0 + GetTransformResponse(hsv.y, c, r, a, f);
}

void RotateValueAroundSaturation(inout vec3 hsv, float c, float r, float a, float f) 
{
    if (hsv.y < 0.02) return;
    hsv.z += GetTransformResponse(hsv.y, c, r, a, f);
}

void RotateHueAroundValue(inout vec3 hsv, float c, float r, float a, float f) 
{
    if (hsv.y < 0.02 || hsv.z < 0.005) return;
    hsv.x += GetTransformResponse(hsv.z, c, r, a, f);
}

void RotateSaturationAroundValue(inout vec3 hsv, float c, float r, float a, float f) 
{
    if (hsv.y < 0.02 || hsv.z < 0.005) return;
    hsv.y *= 1.0 + GetTransformResponse(hsv.z, c, r, a, f);
}

void RotateValueAroundValue(inout vec3 hsv, float c, float r, float a, float f) 
{
    hsv.z += GetTransformResponse(hsv.z, c, r, a, f);
}