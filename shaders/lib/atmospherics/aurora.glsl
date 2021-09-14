
vec2 hash( vec2 p )
{
	p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) );
	return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

// Simplex Noise 2D by Inigo Quillez
float simplex(in vec2 p)
{
    const float K1 = 0.366025404; // (sqrt(3)-1)/2;
    const float K2 = 0.211324865; // (3-sqrt(3))/6;

	vec2  i = floor( p + (p.x+p.y)*K1 );
    vec2  a = p - i + (i.x+i.y)*K2;
    float m = step(a.y,a.x); 
    vec2  o = vec2(m,1.0-m);
    vec2  b = a - o + K2;
	vec2  c = a - 1.0 + 2.0*K2;
    vec3  h = max( 0.5-vec3(dot(a,a), dot(b,b), dot(c,c) ), 0.0 );
	vec3  n = h*h*h*h*vec3( dot(a,hash(i+0.0)), dot(b,hash(i+o)), dot(c,hash(i+1.0)));
    return dot( n, vec3(70.0) );
}

float GetWarpedRidgedMultifractalNoise(in vec2 coord, float scale, float time, float sharpness)
{
	float simplex1 = simplex((coord + time) * scale);
	float simplex2 = simplex((coord.yx - time) * scale);
	float ridged = 1. - abs(simplex1 + simplex2);
	return pow(ridged, sharpness);
}

float GetAuroraNoise(in vec2 coord, float scale, float time, float sharpness, float localY)
{
	float noise = GetWarpedRidgedMultifractalNoise(coord, scale, time, sharpness);
	noise *= mix(texture2D(noisetex, coord * 2.5 + time * 3.0).r, 1.0, 0.6);
	
	return smoothstep(0.0, 1.0, noise);
}

vec3 GetAuroraColor(in vec2 coord, float scale)
{
	float n1 = simplex(coord * scale - frameTimeCounter * 0.01) * 0.5 + 0.5;

	#if AURORA_COLORING_TYPE == 0
	vec3 colorOne = vec3(0.1, 0.2, 1.0);
	vec3 colorTwo = vec3(0.1, 1.0, 0.2);
	#elif AURORA_COLORING_TYPE == 1
	vec3 colorOne = vec3(AURORA_COLOR_ONE_R, AURORA_COLOR_ONE_G, AURORA_COLOR_ONE_B);
	vec3 colorTwo = vec3(AURORA_COLOR_TWO_R, AURORA_COLOR_TWO_G, AURORA_COLOR_TWO_B);
	#endif

	return pow(mix(colorOne, colorTwo, n1), vec3(1.1));
}

float GetAuroraNoiseSharpness(in float cosT) {
	return 12.0 * (1. - exp(-cosT * 3.0) + 0.05);
}

vec4 DrawAurora(vec3 viewPos, float dither, int iterations)
{
	if(1.0 - sunVisibility <= 0.0) return vec4(0.0);

	#ifdef AURORA_PERBIOME
	if(isCold < 0.005) return vec4(0.0);
	#endif

	float cosT = dot(normalize(viewPos), upVec);

	if(cosT < 0.0) return vec4(0.0);

	#if AA == 2
		dither = fract(16.0 * frameTimeCounter + dither);
	#endif

	float aurora = 0.0;
	float noiseSharpness = GetAuroraNoiseSharpness(cosT);

	vec3 auroracolor = vec3(0.0);
    vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);
	vec3 colorAlbedo = GetAuroraColor(wpos.xz, 1.7);

	for(int i = 0; i < iterations; i++)
	{
		if (aurora > 0.99) break;
		vec3 planeCoord = wpos * ((AURORA_HEIGHT + (i * 11.0 / float(iterations) + dither * 11.0 / float(iterations))) / wpos.y) * 0.0005;
		vec2 coord = (cameraPosition.xz + 1000002.0) * 0.00005 + planeCoord.xz;

		float localYPos = (float(i) + dither) / float(iterations);
		float noise = GetAuroraNoise(coord, 35.0, frameTimeCounter * 0.0005, noiseSharpness, localYPos);

		noise *= 1. - localYPos;
		aurora = mix(aurora, 1.0, noise);
	}
	aurora *= clamp(1. - exp2(-cosT * 20.0), 0.0, 1.0) * (1.0 - 0.6 * rainStrength);

	float alpha = aurora * aurora * 0.05 * pow((1. - rainStrength) * (1. - sunVisibility), 2.0);

	#ifdef AURORA_PERBIOME
	alpha *= smoothstep(0.0, 1.0, isCold);
	#endif

	return vec4(colorAlbedo * AURORA_BRIGHTNESS, alpha);
}