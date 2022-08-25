/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

float GetCircleOfConfusion(float z, float centerDepth, mat4 gbufferProjection, float cocStrength)
{
	#if CAMERA_FOCUS_MODE == 0
	float coc = abs(z - centerDepth) / 0.8;
	#else
	float coc = abs(z - LinearizeDepth(CAMERA_FOCUS_DISTANCE, far, near)) / 0.8;
	#endif
	
	return coc / (1.0 / cocStrength + coc) * gbufferProjection[1][1] / 1.37 * 0.1;
}