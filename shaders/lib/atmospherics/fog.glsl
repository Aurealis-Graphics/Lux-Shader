#ifdef OVERWORLD
vec3 GetFogColor(vec3 viewPos){
	vec3 fogCol = fogCol;
	vec3 nViewPos = normalize(viewPos);
	float lViewPos = length(viewPos) / 64.0;
	lViewPos = 1.0 - exp(-lViewPos * lViewPos);

	float NdotU = clamp(dot(nViewPos, upVec), 0.0, 1.0);
    float halfNdotU = clamp(dot(nViewPos, upVec) * 0.5 + 0.5, 0.0, 1.0);
	float NdotS = dot(nViewPos, sunVec) * 0.5 + 0.5;

	float lightmix = NdotS * NdotS * (1.0 - NdotU);
	lightmix *= (pow(1.0 - 0.7 * timeBrightness, 3.0) * 0.9 + 0.1) * (1.0 - rainStrength) * lViewPos;

	float top = exp(-1.4 * halfNdotU * halfNdotU * (1.0 + sunVisibility) * (1.0 - rainStrength));

	float mult = (0.5 * sunVisibility + 0.3) * (1.0 - 0.75 * rainStrength) * top +
				 0.1 * (1.0 + rainStrength * 1.6 * float(isEyeInWater == 1));

	fogCol *= 1.0 - sqrt(lightmix);
	fogCol = mix(fogCol, lightCol * sqrt(lightCol), lightmix) * sunVisibility;
	fogCol += lightNight * lightNight * 0.4;

	vec3 fogWeather = weatherCol.rgb * weatherCol.rgb;
	fogWeather *= GetLuminance(ambientCol / fogWeather) * 1.2;
	fogCol = mix(fogCol, fogWeather, rainStrength) * mult;

	return pow(fogCol, vec3(1.125));
}
#endif

void NormalFog(inout vec3 color, vec3 viewPos){
	#ifdef OVERWORLD
	float fog = length(viewPos) * FOG_DENSITY / 256.0;
	float clearDay = sunVisibility * (1.0 - rainStrength);
	fog *= (0.5 * rainStrength + 1.0) / (3.0 * clearDay + 1.0);
	fog = 1.0 - exp(-2.0 * pow(fog, 0.25 * clearDay + 1.25) * eBS);
	vec3 fogColor = GetFogColor(viewPos);
	#endif

	#ifdef NETHER
	float viewLength = length(viewPos);
	float fog = 2.0 * pow(viewLength * FOG_DENSITY / 256.0, 1.5) + 
				6.0 * pow(viewLength * 1.5 / far, 4.0);
	fog = 1.0 - exp(-fog);
	vec3 fogColor = netherCol.rgb * 0.04;
	#endif

	#ifdef END
	float fog = length(viewPos) * FOG_DENSITY / 128.0;
	fog = 1.0 - exp(-0.8 * fog * fog);
	vec3 fogColor = endCol.rgb * 0.025;
	#endif

	color = mix(color, fogColor, fog);
}

void BlindFog(inout vec3 color, vec3 viewPos){
	float fog = length(viewPos) * (5.0 / blindFactor);
	fog = (1.0 - exp(-6.0 * fog * fog * fog)) * blindFactor;
	color = mix(color, vec3(0.0), fog);
}

void LavaFog(inout vec3 color, vec3 viewPos){
	float fog = length(viewPos) * 0.5;
	fog = (1.0 - exp(-4.0 * fog * fog * fog));
	#ifdef EMISSIVE_RECOLOR
	color = mix(color, pow(blocklightCol / BLOCKLIGHT_I, vec3(4.0)) * 2.0, fog);
	#else
	color = mix(color, vec3(1.0, 0.3, 0.01), fog);
	#endif
}

void Fog(inout vec3 color, vec3 viewPos){
	NormalFog(color, viewPos);
	if (isEyeInWater == 2) LavaFog(color, viewPos);
	if (blindFactor > 0.0) BlindFog(color, viewPos);
}