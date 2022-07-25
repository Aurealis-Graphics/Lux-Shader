/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 


vec3 GetSkyColor(vec3 viewPos, vec3 lightCol)
{
    vec3 result = vec3(0.0);

    #ifdef OVERWORLD
    vec3 viewDir = normalize(viewPos);

    float sunHeightVar = smoothstep(0.0, 0.5, sunHeight / (sunHeight + 0.6) * 1.6);
    float sunDot = exp(-distance(viewDir, sunVec) * (sunHeightVar + 0.8)) * (1.0 - rainStrength * sunHeightVar);
    float y = max(dot(viewDir, upVec), 0.0);

    vec3 skyBaseColor = mix(vec3(0.2235, 0.702, 0.8588), vec3(0.2784, 0.5961, 0.8588), sunVisibility);
    skyBaseColor = mix(skyBaseColor, GetLuminance(skyBaseColor) * weatherCol.rgb, rainStrength);

    float saturationAmount = 0.18 * (3.0 - sunVisibility * (rainStrength - 2.0));
    skyBaseColor = Saturation(skyBaseColor, saturationAmount) * (sunHeightVar * 0.3 + 0.7);

    float mieFactor = sunDot * (1.0 - sunHeight) * sunHeightVar;
    mieFactor += exp(-(y + 0.03) * 6.0) * (dot(viewDir, sunVec) * 0.35 + 0.65) * sunHeightVar * pow(1.0 - sunHeight, 2.0);
    mieFactor = min(mieFactor, 1.0);

    vec3 skyColor = skyBaseColor;

    skyColor = mix(skyColor, lightCol, mieFactor);

    y = sqrt(y + 0.1 + (1.0 - sunVisibility) + rainStrength * 0.5);

    result = exp((skyColor - 1.0) * y * 7.0);

    result = mix(result, lightCol, mieFactor);

    float mult = sunVisibility * 0.3 + 0.6;
    result *= mult;
    #endif
    
    return result; 
}