/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

#if AA == 2
vec2 aoOffsets[5] = vec2[5](
	vec2(0.000000, 0.316228),
	vec2(0.369981, -0.403873),
	vec2(-0.704399, 0.061819),
	vec2(0.663974, 0.509057),
	vec2(-0.165243, -0.934181)
);
#else
vec2 aoOffsets[10] = vec2[10](
	vec2(0.000000, 0.223607),
	vec2(0.261616, -0.285582),
	vec2(-0.498086, 0.043713),
	vec2(0.469500, 0.359958),
	vec2(-0.116844, -0.660566),
	vec2(-0.398049, 0.625745),
	vec2(0.778585, -0.209299),
	vec2(-0.768552, -0.399158),
	vec2(0.316264, 0.866012),
	vec2(0.371897, -0.900940)
);
#endif

float AmbientOcclusion(sampler2D depth, float dither)
{
	float ao = 0.0;

	#if AA == 2
	const int samples = 5;
	dither = fract(dither + frameTimeCounter / PHI * 13.333);
	#else
	const int samples = 10;
	#endif
	
	float z = texture2D(depth, texCoord).r;
	bool hand = IsHand(z);
	z = GetLinearDepth(z);
	
	float sampleDepth = 0.0, angle = 0.0, dist = 0.0;
	float fovScale = gbufferProjection[1][1] / 1.37;
	float distScale = max((far - near) * z + near, 6.0);
	mat2 offsetRot = Rotate(dither * TAU);
	vec2 scale = 0.25 * vec2(1.0 / aspectRatio, 1.0) * fovScale / distScale;

	for (int i = 0; i < samples; i++) 
	{
		vec2 offset = aoOffsets[i - 1] * scale;

		sampleDepth = GetLinearDepth(texture2D(depth, texCoord + offsetRot * aoOffsets[i - 1] * scale).r);
	
		float sample0 = (far - near) * (z - sampleDepth) * 2.0;
	
		if (hand) sample0 *= 1024.0;
	
		angle = Saturate(0.5 - sample0);
		dist = Saturate(0.25 * sample0 - 1.0);

		sampleDepth = GetLinearDepth(texture2D(depth, texCoord - offsetRot * offset).r);
		sample0 = (far - near) * (z - sampleDepth) * 2.0;
	
		if (hand) sample0 *= 1024.0;
	
		angle += Saturate(0.5 - sample0);
		dist += Saturate(0.25 * sample0 - 1.0);	
		ao += Saturate(angle + dist);
	}
	ao /= samples;
	
	// return pow(ao, AO_STRENGTH * 0.9);
	return ao * 0.9 + 0.1;
}