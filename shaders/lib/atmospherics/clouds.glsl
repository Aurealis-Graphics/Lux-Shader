/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

const float cloudPersistance = 0.7;
const float cloudLacunarity = 1.5;
float CloudNoise(vec2 coord, vec2 wind)
{
	float retValue = 0.0;
	float amplitude = 1.0;
	float frequency = 0.45;

	for (int i = 0; i < 6; i++)
	{
		retValue += texture2D(noisetex, (coord + wind * 0.4 * Lift(frequency, 4.34)) * frequency).r * amplitude;
		frequency *= cloudLacunarity;
		amplitude *= cloudPersistance;
	}

	return retValue * 9.0;
}

float CloudCoverage(float noise, float cosT, float coverage)
{
	float noiseFade = Saturate(sqrt(cosT * 10.0));
	float noiseCoverage = (Pow2(coverage) + CLOUD_AMOUNT);
	float multiplier = 1.0 - 0.5 * rainStrength;

	return Max0(noise * noiseFade - noiseCoverage + rainStrength * 2.0) * multiplier;
}

vec4 DrawCloud(vec3 viewPos, float dither, vec3 lightCol, vec3 ambientCol)
{
	float cosT = dot(normalize(viewPos), upVec);
	float cosS = dot(normalize(viewPos), sunVec);

	if (cosT < 0.1) return vec4(0.0);

	#if AA == 2
	dither = fract(dither + frameTimeCounter / PHI * 13.333);
	#endif

	float cloudAlpha = 0.0;
	float cloudGradient = 0.0;
	float gradientMix = dither * 0.1667;
	float colorMultiplier = CLOUD_BRIGHTNESS * (0.5 - 0.25 * (1.0 - sunVisibility) * (1.0 - rainStrength));
	float noiseMultiplier = CLOUD_THICKNESS * 0.2;
	float scattering = Pow4(abs(cosS * 0.6 * (2.0 * sunVisibility - 1.0) + 0.5));

	vec2 wind = vec2(
		frametime * CLOUD_SPEED * 0.001,
		sin(frametime * CLOUD_SPEED * 0.05) * 0.002
	) * CLOUD_HEIGHT / 15.0;

	vec3 cloudColor = vec3(0.0);
	vec3 worldPos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);

	for (int i = 0; i < 6; i++) 
	{
		if (cloudAlpha > 0.99) break;

		vec3 planeCoord = worldPos * ((CLOUD_HEIGHT + (i + dither) * 1.6) / worldPos.y) * 0.004;
		vec2 coord = cameraPosition.xz * 0.00025 + planeCoord.xz;
		float coverage = float(i - 3.0 + dither) * 0.6;

		float noise = CloudNoise(coord * 0.1, wind * 0.6);
		noise = CloudCoverage(noise, cosT, coverage) * noiseMultiplier;
		noise /= (10.0 - Pow2(rainStrength) * 8.0) + noise;

		cloudGradient = mix(
			cloudGradient,
			mix(Pow2(gradientMix), 1.0 - noise, 0.25),
			noise * (1.0 - cloudAlpha * cloudAlpha)
		);
		
		cloudAlpha = mix(cloudAlpha, 1.0, noise);
		gradientMix += 0.1667;
	}

	if (cloudAlpha < 0.005) return vec4(0.0);

	cloudColor = mix(
		ambientCol * 0.5 * (0.5 * sunVisibility + 0.5),
		mix(lightCol, ambientCol / GetLuminance(ambientCol), Pow2(Max0(dot(sunVec, upVec)))) * (1.0 + scattering),
		cloudGradient * cloudAlpha
	);
	
	cloudColor *= 1.0 - 0.6 * rainStrength;
	cloudAlpha *= Saturate(1. - exp2(-(cosT - 0.1) * 40.0)) * (1.0 - 0.6 * rainStrength);

	return vec4(cloudColor * colorMultiplier, Pow2(cloudAlpha) * CLOUD_OPACITY);
}