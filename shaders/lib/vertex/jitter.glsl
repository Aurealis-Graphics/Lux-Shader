/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

// Jitter offset from Chocapic13
vec2 jitterOffsets[8] = vec2[8](
	vec2( 0.125,-0.375),
	vec2(-0.125, 0.375),
	vec2( 0.625, 0.125),
	vec2( 0.375,-0.625),
	vec2(-0.625, 0.625),
	vec2(-0.875,-0.125),
	vec2( 0.375,-0.875),
	vec2( 0.875, 0.875)
);

vec2 TAAJitter(vec2 coord, float w)
{
	vec2 offset = jitterOffsets[int(mod(frameCounter, 8))] * (w / vec2(viewWidth, viewHeight));
	return coord + offset;
}

vec2 TAAJitter(vec2 coord, float w, vec3 cameraPosition, vec3 previousCameraPosition)
{
	if (DistanceSqr(cameraPosition, previousCameraPosition) > 0.0004) return coord;
	return TAAJitter(coord, w);
}