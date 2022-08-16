/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

vec3 GetAmbientColor(vec3 normal, vec3 lightCol, float quarterNdotU)
{
    #ifdef OVERWORLD
    normal = normalize(mix(normal, vec3(0.0, 1.0, 0.0), 0.3));
    
    vec3 ambient = pow(GetSkyColor(normal, lightCol), vec3(0.25)) / PI;
    ambient *= sqrt(lightCol) * 0.1 + 0.9;
    ambient *= Smooth3(sunHeight + moonHeight * (0.43 - 0.13 * rainStrength)) * 0.7 + 0.3;

    vec3 ambientRain = dot(ambient, vec3(0.2125, 0.7154, 0.0721)) * weatherCol.rgb;
    
    return mix(ambient, ambientRain, rainStrength);
    #else
    return vec3(0.0);
    #endif
}