/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

float GetPuddles(vec3 pos)
{
	pos = (pos + cameraPosition) * 0.005;

	float noise = texture2D(noisetex, pos.xz).r;
	noise += texture2D(noisetex, pos.xz * 0.5   ).r * 2.0;
	noise += texture2D(noisetex, pos.xz * 0.25  ).r * 4.0;
	noise += texture2D(noisetex, pos.xz * 0.125 ).r * 8.0;
	noise += texture2D(noisetex, pos.xz * 0.0625).r * 16.0;
	noise = Max0(abs(noise - 15.5) * 0.8 - 1.2) * wetness;
	noise /= abs(noise) + 1.0 / (abs(noise) + 1.0);
	
	return clamp(noise, 0.0, 0.95);
}

// Bicubic sampling from http://www.java-gaming.org/index.php?topic=35123.0
vec4 Cubic(float v)
{
    vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
    vec4 s = n * n * n;
    float x = s.x;
    float y = s.y - 4.0 * s.x;
    float z = s.z - 4.0 * s.y + 6.0 * s.x;
    float w = 6.0 - x - y - z;
    return vec4(x, y, z, w) * (1.0/6.0);
}

vec4 textureBicubic(sampler2D sampler, vec2 coord)
{
   	float texSize = 512.0;

   	coord = coord * texSize - 0.5;

	vec2 fxy = fract(coord);
	coord -= fxy;

	vec4 xcubic = Cubic(fxy.x);
	vec4 ycubic = Cubic(fxy.y);

	vec4 c = coord.xxyy + vec2 (-0.5, 1.5).xyxy;

	vec4 s = vec4(xcubic.xz + xcubic.yw, ycubic.xz + ycubic.yw);
	vec4 offset = c + vec4 (xcubic.yw, ycubic.yw) / s;

	offset /= texSize;

	vec4 sample0 = texture2D(sampler, offset.xz);
	vec4 sample1 = texture2D(sampler, offset.yz);
	vec4 sample2 = texture2D(sampler, offset.xw);
	vec4 sample3 = texture2D(sampler, offset.yw);

	float sx = s.x / (s.x + s.y);
	float sy = s.z / (s.z + s.w);

	return mix(mix(sample3, sample2, sx), mix(sample1, sample0, sx), sy);
}

float GetPuddleHeight(vec3 pos, vec3 fpos)
{
	float noise = 0.0;
	pos = pos + cameraPosition;

	float mult = sqrt(-dot(normalize(normal), normalize(fpos)) / sqrt(max(length(pos), 4.0)));
	
	if (mult > 0.01)
	{
		noise = textureBicubic(noisetex,pos.xz / 32.0).r;
	}

	noise = sin((noise + frametime) * 16.0) * 0.15 + 0.5;
	noise *= mult;

	return noise;
}

vec3 GetPuddleNormal(vec3 pos, vec3 fpos, mat3 tbn)
{
    const float deltaPos = 0.05;
	const float bumpmult = 0.03;

    float h0 = GetPuddleHeight(pos, fpos.xyz);
    float h1 = GetPuddleHeight(pos + vec3( deltaPos, 0.0, 0.0), fpos.xyz);
    float h2 = GetPuddleHeight(pos + vec3(-deltaPos, 0.0, 0.0), fpos.xyz);
    float h3 = GetPuddleHeight(pos + vec3(0.0, 0.0,  deltaPos), fpos.xyz);
    float h4 = GetPuddleHeight(pos + vec3(0.0, 0.0, -deltaPos), fpos.xyz);
    
    float xDelta = ((h1 - h0) + (h0 - h2)) / deltaPos;
    float yDelta = ((h3 - h0) + (h0 - h4)) / deltaPos;
    
    vec3 pnormalMap = vec3(xDelta, yDelta, 1.0 - (xDelta * xDelta + yDelta * yDelta));
    pnormalMap = pnormalMap * vec3(bumpmult) + vec3(0.0, 0.0, 1.0 - bumpmult);

    return clamp(normalize(pnormalMap * tbn), vec3(-1.0), vec3(1.0));
}