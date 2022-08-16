/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

vec2 OffsetDist(float x, int s)
{
	float n = fract(x * 1.414) * PI;
    return vec2(cos(n), sin(n)) * x / s;
}

float AmbientOcclusion(sampler2D depth, float dither)
{
	float ao = 0.0;

	#if AA == 2
	int samples = 5;
	dither = fract(dither + frameTimeCounter / PHI * 13.333);
	#else
	int samples = 10;
	#endif
	
	float z = texture2D(depth, texCoord).r;
	bool hand = IsHand(z);
	z = GetLinearDepth(z);
	
	float sampleDepth = 0.0, angle = 0.0, dist = 0.0;
	float fovScale = gbufferProjection[1][1] / 1.37;
	float distScale = max((far - near) * z + near, 6.0);
	vec2 scale = 0.32 * vec2(1.0 / aspectRatio, 1.0) * fovScale / distScale;

	for (int i = 1; i <= samples; i++) 
	{
		vec2 offset = OffsetDist(i + dither, samples) * scale;

		sampleDepth = GetLinearDepth(texture2D(depth, texCoord + offset).r);
	
		float sample = (far - near) * (z - sampleDepth) * 2.0;
	
		if (hand) sample *= 1024.0;
	
		angle = Saturate(0.5 - sample);
		dist = Saturate(0.25 * sample - 1.0);

		sampleDepth = GetLinearDepth(texture2D(depth, texCoord - offset).r);
		sample = (far - near) * (z - sampleDepth) * 2.0;
	
		if (hand) sample *= 1024.0;
	
		angle += Saturate(0.5 - sample);
		dist += Saturate(0.25 * sample - 1.0);	
		ao += Saturate(angle + dist);
	}
	ao /= samples;
	
	return pow(ao, AO_STRENGTH * 0.9);
}