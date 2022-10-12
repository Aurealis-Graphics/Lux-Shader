/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

vec3 GGXVNDF(vec3 Ve, float roughness, vec2 hash) 
{
    vec3 v = normalize(vec3(roughness * Ve.x, roughness * Ve.y, Ve.z));

    float lensq = dot(v.xy, v.xy);
    vec3 t1 = lensq > 0.0 ? vec3(-v.y, v.x, 0.0) * inversesqrt(lensq) : vec3(1.0, 0.0, 0.0);
    vec3 t2 = cross(v, t1);
    float r = sqrt(hash.x);
    float phi = TAU * hash.y;

    float p1 = r * cos(phi);
    float p2 = r * sin(phi);
    float s = 0.5 * (1.0 + v.z);
    p2 = mix(sqrt(1.0 - p1 * p1), p2, s);

    vec3 n = p1 * t1 + p2 * t2 + sqrt(max(0.0, 1.0 - p1 * p1 - p2 * p2)) * v;

    return normalize(vec3(roughness * n.x, roughness * n.y, max(0.0, n.z)));
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

		vec3 hsample = tbn * GGXVNDF(-viewDir * tbn, roughness2, hash);

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

    return color / 6.0;
}