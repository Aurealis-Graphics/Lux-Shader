/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

#ifdef OVERWORLD
vec3 GetFogColor(float viewDist, vec3 viewDir, vec3 ambientCol)
{
	vec3 fogCol = fogCol;
	float fog = viewDist / 64.0;
	fog = 1.0 - exp(-fog * fog);

	float NdotU = clamp(dot(viewDir, upVec), 0.0, 1.0);
    float halfNdotU = clamp(dot(viewDir, upVec) * 0.5 + 0.5, 0.0, 1.0);
	float NdotS = dot(viewDir, sunVec) * 0.5 + 0.5;

	float lightmix = NdotS * NdotS * (1.0 - NdotU);
	lightmix *= (Pow3(1.0 - 0.7 * timeBrightness) * 0.9 + 0.1) * (1.0 - rainStrength) * fog;

	float top = exp(-1.4 * halfNdotU * halfNdotU * (1.0 + sunVisibility) * (1.0 - rainStrength));

	float mult = (0.5 * sunVisibility + 0.3) * (1.0 - 0.75 * rainStrength) * top +
				 0.1 * (1.0 + rainStrength * 1.6 * float(isEyeInWater == 1));

	fogCol = lightNight * lightNight * 0.4 + mix(fogCol, lightCol * sqrt(lightCol), lightmix) * sunVisibility;

	vec3 fogWeather = weatherCol.rgb * weatherCol.rgb;
	fogWeather *= GetLuminance(ambientCol / fogWeather) * 1.2;
	fogCol = mix(fogCol, fogWeather, rainStrength) * mult;

	return Lift(fogCol, -0.16);
}
#endif

void NormalFog(inout vec3 color, float viewDist, vec3 viewDir, vec3 ambientCol)
{	
	#ifdef OVERWORLD
	float fog = viewDist * FOG_DENSITY / 256.0;
	float clearDay = sunVisibility * (1.0 - rainStrength);
	fog *= (0.5 * rainStrength + 1.0) / (10.0 * (dot(upVec, sunVec) * 0.5 + 0.5) + 1.0);
	fog = 1.0 - exp(-fog * eBS);
	vec3 fogColor = GetFogColor(viewDist, viewDir, ambientCol);
	#endif

	#ifdef NETHER
	float fog = 2.0 * Lift(viewDist * FOG_DENSITY / 256.0, -0.44) + 
				6.0 * Pow4(viewDist * 1.5 / far);
	fog = 1.0 - exp(-fog);
	vec3 fogColor = netherCol.rgb * 0.04;
	#endif

	#ifdef END
	float fog = viewDist * FOG_DENSITY / 128.0;
	fog = (1.0 - exp(-1.8 * fog * sqrt(fog))) * 0.5;
	vec3 fogColor = endCol.rgb * 0.005;
	#endif

	color = mix(color, fogColor, fog);
}

void BlindFog(inout vec3 color, float viewDist)
{
	float fog = viewDist * (5.0 / blindFactor);
	fog = (1.0 - exp(-6.0 * fog * fog * fog)) * blindFactor;
	color = mix(color, vec3(0.0), fog);
}

void LavaFog(inout vec3 color, float viewDist)
{
	float fog = viewDist * 0.5;
	fog = (1.0 - exp(-4.0 * fog * fog * fog));
	color = mix(color, vec3(1.0, 0.3, 0.01), fog);
}

void Fog(inout vec3 color, float viewDist, vec3 viewDir, vec3 ambientCol)
{
	NormalFog(color, viewDist, viewDir, ambientCol);
	if (isEyeInWater == 2) LavaFog(color, viewDist);
	if (blindFactor > 0.0) BlindFog(color, viewDist);
}