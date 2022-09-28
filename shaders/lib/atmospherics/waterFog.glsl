/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

void WaterFog(inout vec3 color, float viewDist, float fogrange)
{
    float fog = viewDist / fogrange;
    fog = 1.0 - exp(-3.0 * fog);
    color = mix(color, Pow2(Lift(waterColor.rgb, -0.06) * (1.0 - blindFactor)), fog * 0.9);
}