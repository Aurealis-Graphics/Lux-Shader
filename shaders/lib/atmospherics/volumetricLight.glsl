/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

float GetDepth(float depth)
{
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

vec4 DistortShadow(vec4 shadowpos, float distortFactor)
{
	shadowpos.xy *= 1.0 / distortFactor;
	shadowpos.z = shadowpos.z * 0.2;
	shadowpos = shadowpos * 0.5 + 0.5;

	return shadowpos;
}

vec4 GetShadowSpace(float shadowZ, vec2 texCoord)
{
	vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord, shadowZ, 1.0) * 2.0 - 1.0);
	viewPos /= viewPos.w;

	vec4 worldPos = gbufferModelViewInverse * viewPos;
	worldPos = shadowModelView * worldPos;
	worldPos = shadowProjection * worldPos;
	worldPos /= worldPos.w;

	float distortFactor = 1.0 - shadowMapBias + length(worldPos.xy) * shadowMapBias;

	return DistortShadow(worldPos, distortFactor);
}

// Volumetric light from Robobo1221 (modified)
vec3 GetVolumetricLight(float z0, float z1, vec3 color, float dither)
{
	vec3 vl = vec3(0.0);

	#ifdef OVERWORLD
	if (z0 == 1.0) return vl;
	#endif

	#if AA == 2
	dither = fract(dither + frameTimeCounter / PHI * 13.333);
	#endif

	float maxDist = 128.0;
	float depth0 = GetDepth(z0);
	float depth1 = GetDepth(z1);
	vec4 shadowPos = vec4(0.0);
	vec3 waterCol = waterColor.rgb * sqrt(waterColor.a / waterAlpha);

	for (int i = 0; i < 7; i++)
	{
		float minDist = exp2(i + dither) - 0.9;

		if (minDist >= maxDist) break;
		if (depth1 < minDist || (depth0 < minDist && color == vec3(0.0))) break;

		shadowPos = GetShadowSpace(LinearizeDepth(minDist, far, near), texCoord.st);
		// shadowPos.z += 0.00002;

		if (length(shadowPos.xy * 2.0 - 1.0) < 1.0)
		{
			vec3 sample0 = vec3(shadow2D(shadowtex0, shadowPos.xyz).z);

			#ifdef SHADOW_COLOR
			vec3 colSample = vec3(0.0);

			if (sample0.r < shadowPos.z)
			{
				float testsample = shadow2D(shadowtex1, shadowPos.xyz).z;
				if (testsample > shadowPos.z)
				{
					colSample = texture2D(shadowcolor0, shadowPos.xy).rgb;
					colSample = Pow2(colSample / max(colSample.r, max(colSample.g, colSample.b)));
					sample0 = colSample * (1.0 - sample0) + sample0;
				}
			}
			#endif

			if (depth0 < minDist) sample0 *= color;
			else if (isEyeInWater == 1.0) sample0 *= waterCol;

			vl += sample0;
		}
		else
		{
			vl += 1.0;
		}
	}

	return max(vec3(0.0), vl);
}