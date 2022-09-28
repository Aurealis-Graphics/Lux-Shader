/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

float GetBorderFogMixFactor(in vec3 eyePlayerPos, in float far, inout bool hasBorderFog) 
{
	float eyeDist = length(eyePlayerPos);
	if (eyeDist > far * 0.6)
	{
		float borderFogFactor = smoothstep(far * 0.6, far * 0.9, eyeDist);
		borderFogFactor *= borderFogFactor;
		hasBorderFog = true;
		return borderFogFactor;
	}
	
	hasBorderFog = false;
	return 0.0;
}

float GetBorderFogMixFactor(in vec3 eyePlayerPos, in float far, in float z0, inout bool hasBorderFog) 
{
    if (z0 == 1.0) 
    {
        hasBorderFog = false;
        return 0.0;
    }

	return GetBorderFogMixFactor(eyePlayerPos, far, hasBorderFog);
}