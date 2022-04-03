/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

void GetMaterials(
    out float smoothness,
    out float metalness,
    out float f0,
    out float skymapMod,
    out vec3 normal,
    out vec3 spec,
    vec2 coord
    )   
{
    vec3 specularData = texture2D(colortex3, coord).rgb;

    #if MATERIAL_FORMAT == 0
    smoothness = specularData.r;

    f0 = specularData.g;
    metalness = f0 >= 0.9 ? 1.0 : 0.0;
    #endif

    #if MATERIAL_FORMAT == 1
    smoothness = specularData.r;
    
    metalness = specularData.g;
    f0 = 0.78 * metalness + 0.02;
    #endif

	normal = DecodeNormal(texture2D(colortex6, coord).xy);
	spec = texture2D(colortex7, coord).rgb;

    // Solution for rough reflection sky fallback
    skymapMod = specularData.b * smoothness;
}