/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

// Adapted from "Sampling Visible GGX Normals with Spherical Caps"
// https://arxiv.org/abs/2306.05044
vec3 SampleVNDF_Hemisphere(vec3 wi, vec2 hash) 
{
    float phi      = TAU * hash.x;
    float z        = (1.0 - hash.y) * (1.0 + wi.z) - wi.z;    
    float sinTheta = sqrt(Saturate(1.0 - Pow2(z)));
    float x        = sinTheta * cos(phi);
    float y        = sinTheta * sin(phi);
    
    vec3 c = vec3(x, y, z);
    vec3 h = c + wi;
    
    return h;
}

vec3 SampleVNDF_GGX(vec3 wi, vec2 hash, float alpha)
{
    vec3 wiStd = normalize(vec3(wi.xy * alpha, wi.z));
    vec3 wmStd = SampleVNDF_Hemisphere(wiStd, hash);
    vec3 wm    = normalize(vec3(wmStd.xy * alpha, wmStd.z));
    return wm;
}

vec4 RoughReflection(vec3 viewPos, vec3 normal, float dither, float smoothness)
{
    vec4 color = vec4(0.0);
	
	float roughness = Pow2(1.0 - smoothness);
	float roughness2 = min(roughness * roughness, 0.1);
	
	vec3 tangent = normalize(cross(normal, gbufferModelViewInverse[1].xyz));
	mat3 tbn = mat3(tangent, cross(normal, tangent), normal);
	vec3 viewDir = normalize(viewPos);
	
	float lod = sqrt(8.0 * roughness);

	for (int i = 0; i < 6; i++) 
	{
		vec2 hash = vec2(
			InterleavedGradientNoise(gl_FragCoord.xy + float(i) * 1.333),
			InterleavedGradientNoise(gl_FragCoord.yx * 1.333 - float(i) * 2.333)
		);

		#if AA == 2
		hash = fract(hash + frameTimeCounter / PHI * 13.333);
		#endif

		vec3 hsample = tbn * SampleVNDF_GGX(-viewDir * tbn, hash, roughness2);

		vec4 pos = Raytrace(depthtex0, viewPos, hsample, dither, 4, 1.0, 0.1, 2.0);

		if (abs(pos.y - 0.5) < 0.5 - EPS &&
			abs(pos.x - 0.5) < 0.5 - EPS &&
			pos.z < 1.0 - EPS) 
		{
			if (texture2D(depthtex0, pos.xy).r == 1.0)	
				continue;
			else
				color += texture2DLod(colortex0, pos.xy, lod);
		}
	}

    return color / 5.0;
}