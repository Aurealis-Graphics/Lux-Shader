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

    float sunHeightLifted = smoothstep(0.0, 0.5, Lift(sunHeight, 2.0));
    float sunDot = exp(-distance(viewDir, sunVec) * (sunHeightLifted + 0.8)) * (1.0 - rainStrength * sunHeightLifted);
    float y = max(dot(viewDir, upVec), 0.0);

    vec3 skyBaseColor = mix(vec3(0.2235, 0.702, 0.8588), vec3(0.2784, 0.5765, 0.8588), sunVisibility);
    skyBaseColor = mix(skyBaseColor, GetLuminance(skyBaseColor) * weatherCol.rgb, rainStrength);

    float saturationAmount = 0.18 * (3.0 - sunVisibility * (rainStrength - 2.0));
    skyBaseColor = Saturation(skyBaseColor, saturationAmount) * (sunHeightLifted * 0.3 + 0.7);

    float mieFactor = sunDot * (1.0 - sunHeight) * sunHeightLifted;
    mieFactor += exp(-(y + 0.02) * 7.0) * (dot(viewDir, sunVec) * 0.25 + 0.75) * sunHeightLifted * Pow2(1.0 - sunHeight);
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