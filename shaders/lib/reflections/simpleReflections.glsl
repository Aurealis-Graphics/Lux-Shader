/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

vec4 SimpleReflection(vec3 viewPos, vec3 normal, float dither, float far, vec3 cameraPosition, vec3 previousCameraPosition)
{
    vec4 color = vec4(0.0);
    vec4 hitPos = Raytrace(depthtex1, viewPos, normal, dither, 4, 1.0, 0.1, 2.0);
	
	#if defined(OVERWORLD) && defined(BORDER_FOG)
	float hitDepth = texture2D(depthtex1, hitPos.st).r;
	vec4 hitScreenPos = vec4(hitPos.st, hitDepth, 1.0);
	
	#if AA == 2
	vec3 hitViewPos = ToNDC(vec3(TAAJitter(hitScreenPos.xy, -0.5, cameraPosition, previousCameraPosition), hitScreenPos.z));
	#else
	vec3 hitViewPos = ToNDC(hitScreenPos.xyz);
	#endif

	vec3 hitEyePlayerPos = mat3(gbufferModelViewInverse) * hitViewPos.xyz;
	bool hasBorderFog = false;
	float borderFogMixFactor = GetBorderFogMixFactor(hitEyePlayerPos, far, hitDepth, hasBorderFog);
	#endif

	float border = Saturate(1.0 - Pow8(Max0(10.0 * cdist(hitPos.st) - 9.0)));
	
	if (hitPos.z < 1.0 - EPS)
	{
		color.a = texture2D(gaux2, hitPos.st).a;
		
		if (color.a > 0.001) color.rgb = texture2D(gaux2, hitPos.st).rgb;
		
		#if defined(OVERWORLD) && defined(BORDER_FOG)
		color.a *= 1.0 - borderFogMixFactor;
		#endif

		color.a *= border;
	}
	
    return color;
}