/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 


void WaterFog(inout vec3 color, vec3 viewPos, float fogrange)
{
    float fog = length(viewPos) / fogrange;
    fog = 1.0 - exp(-3.0 * fog * fog);
    color = mix(color, Pow2(waterColor.rgb * (1.0 - blindFactor)), fog);
}