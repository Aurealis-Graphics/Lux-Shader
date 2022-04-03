/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

float LinearizeDepth(float z)
{
	return (far * (z - near)) / (z * (far - near));
}

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

vec4 getShadowSpace(float shadowdepth, vec2 texCoord)
{
	vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord, shadowdepth, 1.0) * 2.0 - 1.0);
	viewPos /= viewPos.w;

	vec4 wpos = gbufferModelViewInverse * viewPos;
	wpos = shadowModelView * wpos;
	wpos = shadowProjection * wpos;
	wpos /= wpos.w;

	float distb = sqrt(wpos.x * wpos.x + wpos.y * wpos.y);
	float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
	wpos = DistortShadow(wpos,distortFactor);

	return wpos;
}

// Volumetric light from Robobo1221 (modified)
// TODO: Rename to GetVolumetricLight()
vec3 getVolumetricRays(float z0, float z1, vec3 color, float dither)
{
	vec3 vl = vec3(0.0);

	if (z0 == 1.0) return vl;

	#if AA == 2
	dither = fract(dither + frameCounter / 32.0);
	#endif

	vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord, z0, 1.0) * 2.0 - 1.0);
	viewPos /= viewPos.w;

	#ifdef OVERWORLD
	const float fogEnd = 0.5;

	vec3 lightVec = sunVec * (1.0 - 2.0 * float(timeAngle > 0.5325 && timeAngle < 0.9675));
	float cosS = dot(normalize(viewPos.xyz), lightVec);
	float distVar = 1.0 - exp(-length(viewPos.xyz) * 0.00015);
	float visibility = distVar / fogEnd * exp2(distVar - fogEnd);
	visibility *= (1.0 + (1.0 - sunHeight) * 1.4) * (1.0 + max(cosS * cosS * cosS * 0.025, 0.0));
	#endif

	#ifdef END
	float visibility = 0.06;
	#endif

	if (visibility <= 0.0) return vec3(0.0);

	float maxDist = 128.0;
	float depth0 = GetDepth(z0);
	float depth1 = GetDepth(z1);
	vec4 shadowPos = vec4(0.0);
	vec3 watercol = waterColor.rgb * sqrt(waterColor.a / waterAlpha);

	for(int i = 0; i < 7; i++)
	{
		float minDist = exp2(i + dither) - 0.9;

		if (minDist >= maxDist) break;
		if (depth1 < minDist || (depth0 < minDist && color == vec3(0.0))) break;

		shadowPos = getShadowSpace(LinearizeDepth(minDist), texCoord.st);
		// shadowPos.z += 0.00002;

		if (length(shadowPos.xy * 2.0 - 1.0) < 1.0)
		{
			vec3 sample = vec3(shadow2D(shadowtex0, shadowPos.xyz).z);

			vec3 colsample = vec3(0.0);

			#ifdef SHADOW_COLOR
			if (sample.r < 0.9)
			{
				float testsample = shadow2D(shadowtex1, shadowPos.xyz).z;
				if (testsample > 0.9)
				{
					colsample = texture2D(shadowcolor0, shadowPos.xy).rgb;
					colsample = pow(colsample / max(colsample.r, max(colsample.g, colsample.b)), vec3(2.0));
					sample = colsample * (1.0 - sample) + sample;
				}
			}
			#endif

			if (depth0 < minDist) sample *= color;
			else if (isEyeInWater == 1.0) sample *= watercol;

			vl += sample;
		}
		else
		{
			vl += 1.0;
		}
	}
	vl *= visibility;

	return vl;
}