/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

#ifdef REFLECTION_PREVIOUS
#define colortexR colortex5
#else
#define colortexR colortex0
#endif

const float PI = 3.14159265358979;
const float TAU = 2.0 * PI;

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
	
	float roughness = pow(1.0 - smoothness, 2.0);
	float roughness2 = min(roughness * roughness, 0.1);
	vec3 tangent = normalize(cross(normal, gbufferModelViewInverse[1].xyz));
	mat3 tbn = mat3(tangent, cross(normal, tangent), normal);
	vec3 viewDir = normalize(viewPos);
	float lod = sqrt(8.0 * roughness);

	for(int i = 0; i < 6; i++) 
	{
		vec2 hash = vec2(
			InterleavedGradientNoise(gl_FragCoord.xy + float(i) * 1.333),
			InterleavedGradientNoise(gl_FragCoord.yx * 1.333 - float(i) * 2.333)
		);

		#if AA == 2
		hash = fract(hash + frameTimeCounter * 11.333);
		#endif

		vec3 hsample = tbn * GGXVNDF(-viewDir * tbn, roughness2, hash);

		vec4 pos = Raytrace(depthtex0, viewPos, hsample, dither, 4, 1.0, 0.1, 2.0);

		if(abs(pos.y - 0.5) < 0.4999 && abs(pos.x - 0.5) < 0.4999 && pos.z < 1.0 - 1e-5)
			// color += texture2DLod(colortexR, pos.xy, 0.0);
			color += texture2DLod(colortexR, pos.xy, lod);
	}
	color /= 6.0;

	// vec4 pos = Raytrace(depthtex0, viewPos, normal, dither, 4, 1.0, 0.1, 2.0);
	// float border = clamp(1.0 - pow(cdist(pos.st), 50.0 * sqrt(smoothness)), 0.0, 1.0);
	
	// if (pos.z < 1.0 - 1e-5){
	// 	#ifdef REFLECTION_ROUGH
	// 	float dist = 1.0 - exp(-0.125 * (1.0 - smoothness) * pos.a);
	// 	float lod = log2(viewHeight / 8.0 * (1.0 - smoothness) * dist);
	// 	#else
	// 	float lod = 0.0;
	// 	#endif

	// 	if (lod < 1.0){
	// 		color.a = texture2DLod(colortex6, pos.st, 1.0).b;
	// 		if (color.a > 0.001) color.rgb = texture2DLod(colortexR, pos.st, 1.0).rgb;
	// 		#ifdef REFLECTION_PREVIOUS
	// 		color.rgb = pow(color.rgb * 2.0, vec3(8.0));
	// 		#endif
	// 	}else{
	// 		for(int i = -2; i <= 2; i++){
	// 			for(int j = -2; j <= 2; j++){
	// 				vec2 refOffset = vec2(i, j) * exp2(lod - 1.0) / vec2(viewWidth, viewHeight);
	// 				vec2 refCoord = pos.st + refOffset;
	// 				float alpha = texture2DLod(colortex6, refCoord, lod).b;
	// 				if (alpha > 0.001){
	// 					vec3 sample = texture2DLod(colortexR, refCoord, max(lod - 1.0, 0.0)).rgb;

	// 					#ifdef REFLECTION_PREVIOUS
	// 					sample = pow(sample * 2.0, vec3(8.0));
	// 					#endif

	// 					color.rgb += sample;
	// 					color.a += alpha;
	// 				}
	// 			}
	// 		}
	// 		color /= 25.0;
	// 	}

	// 	Fog(color.rgb, (gbufferProjectionInverse * pos).xyz);
		
	// 	color *= color.a;
	// 	color.a *= border;
	// }
	
    return color;
}