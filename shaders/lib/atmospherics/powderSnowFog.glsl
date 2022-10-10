/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

void PowderSnowFog(inout vec3 color, float viewDist, vec3 ambientCol) 
{
	float fog = viewDist;
	fog = (1.0 - exp(-0.2 * fog * fog));
	vec3 fogCol = vec3(0.6, 0.85, 0.9);
	
	#ifdef OVERWORLD
	fogCol *= mix(vec3(eBS) + 0.16, ambientCol + lightCol * 0.5 + moonCol * moonVisibility, eBS);
	#else
	fogCol *= ambientCol / GetLuminance(ambientCol) * 0.05 + 0.015;
	#endif

	color = mix(color, fogCol, fog);
}