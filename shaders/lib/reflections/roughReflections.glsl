#ifdef REFLECTION_PREVIOUS
#define colortexR colortex5
#else
#define colortexR colortex0
#endif

float Hash(vec2 p)
{
	vec3 p3  = fract(vec3(p.xyx) * .1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

const float PI = 3.14159265358979;
const float TAU = 2.0 * PI;

/* GGXVNDF from: https://schuttejoe.github.io/post/ggximportancesamplingpart2/ */
// TODO: Fix 't1' not being correct
vec3 GGXVNDF(vec3 normal, float roughness, vec2 hash) 
{
	vec3 v = normalize(vec3(normal.x * roughness, normal.y, normal.z * roughness));
	vec3 t1 = v.y < 0.999 ? normalize(cross(v, gbufferModelViewInverse[2].xyz)) : gbufferModelViewInverse[0].xyz;
	vec3 t2 = cross(t1, v);
	float a = 1.0 / (1.0 + v.y);
	float r = sqrt(hash.x);
	float phi = hash.y < a ? (hash.y / a) * PI : PI + (hash.y - a) / (1.0 - a) * PI;
	float p1 = r * cos(phi);
	float p2 = r * sin(phi) * (hash.y < a ? 1.0 : v.y);
	vec3 n = p1 * t1 + p2 * t2 + sqrt(max(0.0, 1.0 - p1 * p1 - p2 * p2)) * v;
	return normalize(vec3(roughness * n.x, max(0.0, n.y), roughness * n.z));
}

// alpha2D is just vec2(roughness)
// rand is a 2d uniform value
// Ve is "view dir" (-incoming raydir) in tangent space
// tbn = tangent to view space
// Usage: tbn * GGXVNDF(Ve * tbn, alpha2D, rand)
/////////////////////////////////////////
// vec3 GGXVNDF(vec3 Ve, vec2 alpha2D, vec2 rand) {
//     vec3 Vh = normalize(vec3(alpha2D.x * Ve.x, alpha2D.y * Ve.y, Ve.z));

//     float lensq = Vh.x * Vh.x + Vh.y * Vh.y;
//     vec3 T1 = lensq > 0.0f ? vec3(-Vh.y, Vh.x, 0.0f) * inversesqrt(lensq) : vec3(1.0f, 0.0f, 0.0f);
//     vec3 T2 = cross(Vh, T1);

//     float r = sqrt(rand.x);
//     float phi = 2.0 * PI * rand.y;
//     float t1 = r * cos(phi);
//     float t2 = r * sin(phi);
//     float s = 0.5f * (1.0f + Vh.z);
//     t2 = mix(sqrt(1.0f - t1 * t1), t2, s);

//     vec3 Nh = t1 * T1 + t2 * T2 + sqrt(max(0.0f, 1.0f - t1 * t1 - t2 * t2)) * Vh;

//     return normalize(vec3(alpha2D.x * Nh.x, alpha2D.y * Nh.y, max(0.0f, Nh.z)));
// }

vec4 RoughReflection(vec3 viewPos, vec3 normal, float dither, float smoothness)
{
    vec4 color = vec4(0.0);
	float roughness = (1.0 - smoothness) * 0.5;	// use pow(1.0 - smoothness, 2.0) for accuracy

	for(int i = 0; i < 8; i++) 
	{
		vec2 hash = vec2(
			InterleavedGradientNoise(gl_FragCoord.xy + float(i) * 1.333),
			InterleavedGradientNoise(gl_FragCoord.yx * 1.333 - float(i) * 2.333)
		);

		#if AA == 2
		hash = fract(hash + frameTimeCounter * 11.333);
		#endif

		vec3 hsample = GGXVNDF(normal, roughness * roughness, hash);

		vec4 pos = Raytrace(depthtex0, viewPos, mix(normal, hsample, roughness), dither, 4, 1.0, 0.1, 2.0);

		if(abs(pos.y - 0.5) < 0.499 && abs(pos.x - 0.5) < 0.499)
			color += texture2D(colortex0, pos.xy);
	}
	color /= 8.0;
	
	/*float border = clamp(1.0 - pow(cdist(pos.st), 50.0 * sqrt(smoothness)), 0.0, 1.0);
	
	if (pos.z < 1.0 - 1e-5){
		#ifdef REFLECTION_ROUGH
		float dist = 1.0 - exp(-0.125 * (1.0 - smoothness) * pos.a);
		float lod = log2(viewHeight / 8.0 * (1.0 - smoothness) * dist);
		#else
		float lod = 0.0;
		#endif

		if (lod < 1.0){
			color.a = texture2DLod(colortex6, pos.st, 1.0).b;
			if (color.a > 0.001) color.rgb = texture2DLod(colortexR, pos.st, 1.0).rgb;
			#ifdef REFLECTION_PREVIOUS
			color.rgb = pow(color.rgb * 2.0, vec3(8.0));
			#endif
		}else{
			for(int i = -2; i <= 2; i++){
				for(int j = -2; j <= 2; j++){
					vec2 refOffset = vec2(i, j) * exp2(lod - 1.0) / vec2(viewWidth, viewHeight);
					vec2 refCoord = pos.st + refOffset;
					float alpha = texture2DLod(colortex6, refCoord, lod).b;
					if (alpha > 0.001){
						vec3 sample = texture2DLod(colortexR, refCoord, max(lod - 1.0, 0.0)).rgb;

						#ifdef REFLECTION_PREVIOUS
						sample = pow(sample * 2.0, vec3(8.0));
						#endif

						color.rgb += sample;
						color.a += alpha;
					}
				}
			}
			color /= 25.0;
		}

		//Fog(color.rgb, (gbufferProjectionInverse * pos).xyz);
		
		color *= color.a;
		color.a *= border;
	}*/
	
    return color;
}