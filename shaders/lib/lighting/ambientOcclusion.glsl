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
	
	float d = texture2D(depth, texCoord).r;
	float hand = float(d < 0.56);
	d = GetLinearDepth(d);
	
	float sampleDepth = 0.0, angle = 0.0, dist = 0.0;
	float fovScale = gbufferProjection[1][1] / 1.37;
	float distScale = max((far - near) * d + near, 6.0);
	vec2 scale = 0.32 * vec2(1.0 / aspectRatio, 1.0) * fovScale / distScale;

	for (int i = 1; i <= samples; i++) 
	{
		vec2 offset = OffsetDist(i + dither, samples) * scale;

		sampleDepth = GetLinearDepth(texture2D(depth, texCoord + offset).r);
	
		float sample = (far - near) * (d - sampleDepth) * 2.0;
	
		if (hand > 0.5) sample *= 1024.0;
	
		angle = clamp(0.5 - sample, 0.0, 1.0);
		dist = clamp(0.25 * sample - 1.0, 0.0, 1.0);

		sampleDepth = GetLinearDepth(texture2D(depth, texCoord - offset).r);
		sample = (far - near) * (d - sampleDepth) * 2.0;
	
		if (hand > 0.5) sample *= 1024.0;
	
		angle += clamp(0.5 - sample, 0.0, 1.0);
		dist += clamp(0.25 * sample - 1.0, 0.0, 1.0);	
		ao += clamp(angle + dist, 0.0, 1.0);
	}
	ao /= samples;
	
	return pow(ao, AO_STRENGTH * 0.9);
}