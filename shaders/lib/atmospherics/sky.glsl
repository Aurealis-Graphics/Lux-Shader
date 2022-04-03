/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 


float Luma(vec3 color) 
{
    return dot(color, vec3(0.2125, 0.7154, 0.0721));
}

vec3 Saturation(vec3 color, float saturation) 
{
    return mix(vec3(Luma(color)), color, saturation);
}

vec3 GetSkyColor(vec3 viewPos, vec3 lightCol)
{
    vec3 result = vec3(0.0);

    #ifdef OVERWORLD
    vec3 viewDir = normalize(viewPos);

    float sunHeightVar = smoothstep(0.0, 0.5, sunHeight / (sunHeight + 0.6) * 1.6);
    float sunDot = exp(-distance(viewDir, sunVec) * (sunHeightVar + 0.8)) * (1.0 - rainStrength * sunHeightVar);
    float y = max(dot(viewDir, upVec), 0.0);

    vec3 skyBaseColor = mix(vec3(0.2235, 0.6675, 0.8588), vec3(0.2784, 0.5961, 0.8588), sunVisibility);
    skyBaseColor = mix(skyBaseColor, Luma(skyBaseColor) * weatherCol.rgb, rainStrength);

    float saturationAmount = sunVisibility * 0.4 + 0.2 * (1.0 - rainStrength * sunVisibility) + 0.4;
    skyBaseColor = Saturation(skyBaseColor, saturationAmount) * (sunHeightVar * 0.3 + 0.7);

    vec3 lightColor = GetDirectColor(sunHeightVar);
    vec3 skyColor = skyBaseColor;
    float mieFactor = sunDot * (1.0 - sunHeight) * sunHeightVar;

    skyColor = mix(skyColor, lightCol, mieFactor);

    result = exp(-(1.0 - skyColor) * (sqrt(y * 0.9 + 0.1 + (1.0 - sunVisibility) + rainStrength * 0.3)) * 7.0);

    result = mix(result, lightCol, mieFactor);

    float mult = sunVisibility * 0.4 + 0.6;
    result *= mult;
    #endif
    
    return result; 
}