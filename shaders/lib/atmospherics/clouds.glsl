float CloudNoise(vec2 coord, vec2 wind){
	float noise = texture2D(noisetex, coord * 0.5      + wind * 0.55).x;
		  noise+= texture2D(noisetex, coord * 0.25     + wind * 0.45).x * 2.0;
		  noise+= texture2D(noisetex, coord * 0.125    + wind * 0.35).x * 3.0;
		  noise+= texture2D(noisetex, coord * 0.0625   + wind * 0.25).x * 4.0;
		  noise+= texture2D(noisetex, coord * 0.03125  + wind * 0.15).x * 5.0;
		  noise+= texture2D(noisetex, coord * 0.016125 + wind * 0.05).x * 6.0;
	return noise;
}

float CloudCoverage(float noise, float cosT, float coverage){
	float noiseMix = mix(noise, 21.0, 0.33 * rainStrength);
	float noiseFade = clamp(sqrt(cosT * 10.0), 0.0, 1.0);
	float noiseCoverage = ((coverage * coverage) + CLOUD_AMOUNT);
	float multiplier = 1.0 - 0.5 * rainStrength;

	return max(noiseMix * noiseFade - noiseCoverage, 0.0) * multiplier;
}

vec4 DrawCloud(vec3 viewPos, float dither, vec3 lightCol, vec3 ambientCol){
	float cosT = dot(normalize(viewPos), upVec);
	float cosS = dot(normalize(viewPos), sunVec);

	#if AA == 2
	dither = fract(16.0 * frameTimeCounter + dither);
	#endif

	float cloud = 0.0;
	float cloudGradient = 0.0;
	float gradientMix = dither * 0.1667;
	float colorMultiplier = CLOUD_BRIGHTNESS * (0.5 - 0.25 * (1.0 - sunVisibility) * (1.0 - rainStrength));
	float noiseMultiplier = CLOUD_THICKNESS * 0.2;
	float scattering = pow(cosS * 0.5 * (2.0 * sunVisibility - 1.0) + 0.5, 6.0);

	vec2 wind = vec2(
		frametime * CLOUD_SPEED * 0.001,
		sin(frametime * CLOUD_SPEED * 0.05) * 0.002
	) * CLOUD_HEIGHT / 15.0;

	vec3 cloudcolor = vec3(0.0);

	if (cosT > 0.1){
		vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);
		for(int i = 0; i < 6; i++) {
			if (cloud > 0.99) break;
			vec3 planeCoord = wpos * ((CLOUD_HEIGHT + (i + dither) * 0.75) / wpos.y) * 0.004;
			vec2 coord = cameraPosition.xz * 0.00025 + planeCoord.xz;
			float coverage = float(i - 3.0 + dither) * 0.667;

			float noise = CloudNoise(coord, wind);
				  noise = CloudCoverage(noise, cosT, coverage) * noiseMultiplier;
				  noise = noise / pow(pow(noise, 2.5) + 1.0, 0.4);

			cloudGradient = mix(
				cloudGradient,
				mix(gradientMix * gradientMix, 1.0 - noise, 0.25),
				noise * (1.0 - cloud * cloud)
			);
			cloud = mix(cloud, 1.0, noise);
			gradientMix += 0.1667;
		}
		cloudcolor = mix(
			ambientCol * (0.5 * sunVisibility + 0.5),
			lightCol * (1.0 + scattering),
			cloudGradient * cloud
		);
		cloudcolor *= 1.0 - 0.6 * rainStrength;
		cloud *= sqrt(sqrt(clamp(cosT * 10.0 - 1.0, 0.0, 1.0))) * (1.0 - 0.6 * rainStrength);
	}

	return vec4(cloudcolor * colorMultiplier, cloud * cloud * CLOUD_OPACITY);
}