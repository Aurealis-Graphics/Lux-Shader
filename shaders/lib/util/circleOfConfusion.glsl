/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

float GetCircleOfConfusion(float z, float centerDepthSmooth, float cocStrength)
{	
	float coc = abs(z - centerDepthSmooth) / 0.6;
	return coc / (1 / cocStrength + coc);
}