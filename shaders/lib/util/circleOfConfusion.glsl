/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

float GetCircleOfConfusion(float z, float centerDepth, mat4 gbufferProjection, float cocStrength)
{	
	float coc = abs(z - centerDepth) / 0.8;
	return coc / (1.0 / cocStrength + coc) * gbufferProjection[1][1] / 1.37 * 0.1;
}