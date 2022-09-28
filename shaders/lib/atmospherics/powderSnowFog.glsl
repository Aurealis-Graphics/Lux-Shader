/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

void PowderSnowFog(inout vec3 color, float viewDist) 
{
	float fog = viewDist;
	fog = (1.0 - exp(-0.08 * fog * fog));
	color = mix(color, vec3(0.6, 0.85, 0.9), fog);
}