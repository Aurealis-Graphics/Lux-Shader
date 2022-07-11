/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 


vec2 promoOutlineOffsets[4] = vec2[4](
	vec2( -1.0,  1.0 ),
	vec2(  0.0,  1.0 ),
	vec2(  1.0,  1.0 ),
	vec2(  1.0,  0.0 )
);

void PromoOutline(inout vec3 color, sampler2D depth)
{
	float ph = 1.0 / 1080.0;
	float pw = ph / aspectRatio;

	float outlined = 1.0;
	float z = GetLinearDepth(texture2D(depth, texCoord).r) * far;
	float totalz = 0.0;
	float maxz = 0.0;
	float sampleza = 0.0;
	float samplezb = 0.0;

	for (int i = 0; i < 4; i++)
	{
		vec2 offset = vec2(pw, ph) * promoOutlineOffsets[i];
		sampleza = GetLinearDepth(texture2D(depth, texCoord + offset).r) * far;
		samplezb = GetLinearDepth(texture2D(depth, texCoord - offset).r) * far;
		maxz = max(maxz, max(sampleza, samplezb));

		outlined *= Saturate(1.0 - ((sampleza + samplezb) - z * 2.0) * 32.0 / z);

		totalz += sampleza + samplezb;
	}
	float outlinea = 1.0 - Saturate((z * 8.0 - totalz) * 64.0 / z) *
					 Saturate(1.0 - ((z * 8.0 - totalz) * 32.0 - 1.0) / z);
	float outlineb = Saturate(1.0 +  8.0 * (z - maxz) / z);
	float outlinec = Saturate(1.0 + 64.0 * (z - maxz) / z);
	float outline = (0.35 * (outlinea * outlineb) + 0.65) * 
					(0.75 * (1.0 - outlined) * outlinec + 1.0);

	outline *= outline;
	outline *= outline;
	color *= outline;
}
