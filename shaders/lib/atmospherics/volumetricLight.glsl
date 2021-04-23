float distx(float dist){
	return (far * (dist - near)) / (dist * (far - near));
}

float getDepth(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

vec4 distortShadow(vec4 shadowpos, float distortFactor) {
	shadowpos.xy *= 1.0 / distortFactor;
	shadowpos.z = shadowpos.z * 0.2;
	shadowpos = shadowpos * 0.5 + 0.5;

	return shadowpos;
}

vec4 getShadowSpace(float shadowdepth, vec2 texCoord){
	vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord, shadowdepth, 1.0) * 2.0 - 1.0);
	viewPos /= viewPos.w;

	vec4 wpos = gbufferModelViewInverse * viewPos;
	wpos = shadowModelView * wpos;
	wpos = shadowProjection * wpos;
	wpos /= wpos.w;
	
	float distb = sqrt(wpos.x * wpos.x + wpos.y * wpos.y);
	float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
	wpos = distortShadow(wpos,distortFactor);
	
	return wpos;
}

//Volumetric light from Robobo1221 (modified)
vec3 getVolumetricRays(float pixeldepth0, float pixeldepth1, vec3 color, float dither) {
	vec3 vl = vec3(0.0);

	#if AA == 2
	dither = fract(dither + frameCounter / 32.0);
	#endif
	
	vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord.x, texCoord.y, pixeldepth0, 1.0) * 2.0 - 1.0);
	viewPos /= viewPos.w;
	
	#ifdef OVERWORLD
	vec3 lightVec = sunVec * (1.0 - 2.0 * float(timeAngle > 0.5325 && timeAngle < 0.9675));
	float cosS = dot(normalize(viewPos.xyz), lightVec);
	float visfactor = 0.05 * (-0.75 * timeBrightness + 1.0) * (3.0 * rainStrength + 1.0);
	float invvisfactor = 1.0 - visfactor;

	float visibility = clamp(cosS * 0.5 + 0.5, 0.0, 1.0);
	visibility = clamp((visfactor / (1.0 - invvisfactor * visibility) - visfactor) *
				 1.015 / invvisfactor - 0.015, 0.0, 1.0);
	visibility = mix(1.0, visibility, 0.25 * eBS + 0.75) * 0.14285;
	#endif
	
	#ifdef END
	float visibility = 0.14285;
	#endif

	if (visibility > 0.0){
		float maxDist = 128.0;
		
		float depth0 = getDepth(pixeldepth0);
		float depth1 = getDepth(pixeldepth1);
		vec4 worldposition = vec4(0.0);
		
		vec3 watercol = waterColor.rgb * sqrt(waterColor.a / waterAlpha);
		
		for(int i = 0; i < 7; i++) {
			float minDist = exp2(i + dither) - 0.9;
			if (minDist >= maxDist) break;

			if (depth1 < minDist || (depth0 < minDist && color == vec3(0.0))){
				break;
			}

			worldposition = getShadowSpace(distx(minDist), texCoord.st);
			worldposition.z += 0.00002;

			if (length(worldposition.xy * 2.0 - 1.0) < 1.0){
				vec3 sample = vec3(shadow2D(shadowtex0, worldposition.xyz).z);
				
				vec3 colsample = vec3(0.0);
				#ifdef SHADOW_COLOR
				if (sample.r < 0.9){
					float testsample = shadow2D(shadowtex1, worldposition.xyz).z;
					if (testsample > 0.9){
						colsample = texture2D(shadowcolor0, worldposition.xy).rgb;
						colsample *= colsample;
						sample = colsample * (1.0 - sample) + sample;
					}
				}
				#endif
				if (depth0 < minDist) sample *= color;
				else if (isEyeInWater == 1.0) sample *= watercol;

				vl += sample;
			}
			else{
				vl += 1.0;
			}
		}
		vl = sqrt(vl * visibility);
	}
	
	return vl;
}