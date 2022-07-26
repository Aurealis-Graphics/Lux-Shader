/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

mat3 GetLightmapTBN(vec3 viewPos)
{
    mat3 lightmapTBN = mat3(normalize(dFdx(viewPos)), normalize(dFdy(viewPos)), vec3(0.0));
    lightmapTBN[2] = cross(lightmapTBN[0], lightmapTBN[1]);
    return lightmapTBN;
}

float DirectionalLightmap(float lightmap, float lightmapRaw, vec3 normal, mat3 lightmapTBN)
{
    if (lightmap < 0.001) return lightmap;

    vec2 deriv = vec2(dFdx(lightmapRaw), dFdy(lightmapRaw)) * 256.0;
    vec3 dir = normalize(vec3(
        deriv.x * lightmapTBN[0] +
        0.0005  * lightmapTBN[2] +
        deriv.y * lightmapTBN[1]
    ));
    
    float pwr = clamp(dot(normal, dir), -1.0, 1.0);
    
    if (abs(pwr) > 0.0)
        pwr = pow(abs(pwr), DIRECTIONAL_LIGHTMAP_STRENGTH) * sign(pwr) * lightmap;
        
    if (length(deriv) > 0.001)
        lightmap = pow(lightmap, MaxEPS(1.0 - pwr));

	return lightmap;
}