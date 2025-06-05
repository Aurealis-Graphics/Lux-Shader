/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

// Simplex Noise 2D by Inigo Quillez
const float K1 = 0.366025404; 	// (sqrt(3) - 1) / 2;
const float K2 = 0.211324865; 	// (3 - sqrt(3)) / 6;
float SimplexNoise(in vec2 p)
{
	vec2 i = floor(p + (p.x + p.y) * K1);
    vec2 a = p - i + (i.x + i.y) * K2;
    float m = step(a.y, a.x); 
    vec2 o = vec2(m, 1.0 - m);
    vec2 b = a - o + K2;
	vec2 c = a - 1.0 + 2.0 * K2;
    vec3 h = max(0.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
	vec3 n = h * h * h * h * vec3(dot(a, Hash22(i)), dot(b, Hash22(i + o)), dot(c, Hash22(i + 1.0)));
    return dot(n, vec3(70.0));
}
////////////////////////////////

float GetWarpedRidgedMultifractalNoise(in vec2 coord, float scale, float time, float sharpness)
{
	float simplexOne = SimplexNoise((coord + time) * scale);
	float simplexTwo = SimplexNoise((coord.yx - time) * scale);
	float ridged = 1. - abs(simplexOne + simplexTwo);
	return pow(ridged, sharpness);
}

float GetAuroraNoise(in vec2 coord, float scale, float time, float sharpness, float localY)
{
	float noise = GetWarpedRidgedMultifractalNoise(coord, scale, time, sharpness);
	noise *= texture2D(noisetex, coord * 2.5 + time * 5.0).r * 0.5 + 0.5;
	return Smooth3(noise) * (1.0 - localY);
}

const vec3 auroraBlue 	= vec3(0.1, 0.2, 1.0);
const vec3 auroraRed 	= vec3(1.0, 0.1, 0.6);
const vec3 auroraGreen 	= vec3(0.1, 1.0, 0.2);
vec3 GetAuroraColor(in vec2 coord, float scale)
{
	#if AURORA_COLORING_TYPE == 0
		float n1 = SimplexNoise(coord * scale * 0.7) * 0.5 + 0.5;
		float n2 = SimplexNoise(coord.yx * scale * 0.7) * 0.5 + 0.5;
		float mixFactor = SimplexNoise((coord - frameTimeCounter * 0.05) * scale * 0.2) * 0.5 + 0.5;

		vec3 finalColor = mix(mix(auroraBlue, auroraGreen, n1), mix(auroraBlue, auroraRed, n2), mixFactor);
	#else
		float mixFactor = SimplexNoise((coord.yx - frameTimeCounter * 0.02) * scale * 0.7) * 0.5 + 0.5;
		
		#if AURORA_COLORING_TYPE == 1
			vec3 finalColor = mix(auroraBlue, auroraGreen, mixFactor);
		#elif AURORA_COLORING_TYPE == 2
			vec3 finalColor = mix(auroraBlue, auroraRed, mixFactor);
		#else
			const vec3 colorOne = vec3(AURORA_COLOR_ONE_R, AURORA_COLOR_ONE_G, AURORA_COLOR_ONE_B);
			const vec3 colorTwo = vec3(AURORA_COLOR_TWO_R, AURORA_COLOR_TWO_G, AURORA_COLOR_TWO_B);
			vec3 finalColor = mix(colorOne, colorTwo, mixFactor);
		#endif
	#endif

	return Pow2(finalColor);
}

float GetAuroraHorizonIntensity(in float cosT)
{
	return 1.0 - exp2(-cosT * 20.0);
}

float GetAuroraNoiseSharpness(in float cosT, in float horizonIntensity) 
{
	/*
		TODO: Use Ray Box Intersection to calculate the distance through the imaginary volume,
		not a hemisphere projection.
	*/ 
	return mix(1.0, 16.0, sqrt(1.0 - Pow2(cosT - 1.0)) * horizonIntensity);
}

vec4 DrawAurora(vec3 viewPos, float dither, int iterations)
{
	float probabilityHash = Hash11(worldDay * 239.996322973);

	if (1.0 - max(sunVisibility, rainStrength) == 0.0 || probabilityHash > AURORA_PROBABILITY) return vec4(0.0);

	#ifdef AURORA_PERBIOME
	if(isCold < 0.005) return vec4(0.0);
	#endif

	float cosT = dot(normalize(viewPos), upVec);

	if(cosT < 0.0) return vec4(0.0);

	#if AA == 2
	dither = fract(dither + frameTimeCounter / PHI * 13.333);
	#endif

	float auroraAlpha = 0.0;
	float horizonIntensity = GetAuroraHorizonIntensity(cosT);
	float noiseSharpness = GetAuroraNoiseSharpness(cosT, horizonIntensity);
    vec3 worldPos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);
	float fIterations = float(iterations);
	float iMult = 12.0 / fIterations;

	for (int i = 0; i < iterations; i++)
	{
		if (auroraAlpha > 0.99) break;

		vec2 planeCoord = worldPos.xz * (AURORA_HEIGHT + (i + dither) * iMult) / worldPos.y * 0.0005;
		vec2 coord = planeCoord.xy + cameraPosition.xz * 0.0001;
		float localYPos = (float(i) + dither) / fIterations;
		float noise = GetAuroraNoise(coord, 35.0, frameTimeCounter * 0.0003, noiseSharpness, localYPos);

		auroraAlpha = mix(auroraAlpha, 1.0, noise / fIterations * 6.0);
	}
	
	auroraAlpha *= horizonIntensity * (1.0 - 0.6 * rainStrength);

	if (auroraAlpha < 0.005) return vec4(0.0);

	auroraAlpha = auroraAlpha * auroraAlpha * 0.05 * Pow2((1. - rainStrength) * (1. - sunVisibility));

	vec3 colorAlbedo = GetAuroraColor(worldPos.xz, 1.7);

	#ifdef AURORA_PERBIOME
	auroraAlpha *= Smooth3(isCold);
	#endif

	return vec4(colorAlbedo * AURORA_BRIGHTNESS, auroraAlpha);
}