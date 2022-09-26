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
    out float metalData, 
    inout float emissive,
    out float ao, 
    out vec3 normalMap,
    vec2 newCoord,
    vec2 dcdx,
    vec2 dcdy
    )
{
    vec4 specularMap = texture2DGradARB(specular, newCoord, dcdx, dcdy);

    #if MATERIAL_FORMAT == 0
    smoothness = specularMap.r;

    f0 = specularMap.g;
    metalness = f0 >= 0.9 ? 1.0 : 0.0;
    metalData = f0;

    /*
    if (!isMetal) 
    {
        if (specularMap.b > 0.250980) subsurface = specularMap.b;
        else						  porosity   = specularMap.b;
    }
    */

    emissive = mix(specularMap.a < 1.0 ? specularMap.a : 0.0, 1.0, emissive);
    ao = texture2DGradARB(normals, newCoord, dcdx, dcdy).z;

	normalMap = vec3(texture2DGradARB(normals, newCoord, dcdx, dcdy).xy, 0.0) * 2.0 - 1.0;
    float normalCheck = normalMap.x + normalMap.y;

    if (normalCheck > -1.999)
    {
        if (length(normalMap.xy) > 1.0) normalMap.xy = normalize(normalMap.xy);
        normalMap.z = sqrt(1.0 - dot(normalMap.xy, normalMap.xy));
        normalMap = normalize(clamp(normalMap, vec3(-1.0), vec3(1.0)));
    }
    else
    {
        normalMap = vec3(0.0, 0.0, 1.0);
        ao = 1.0;
    }
    #endif

    #if MATERIAL_FORMAT == 1
    smoothness = specularMap.r;
    metalness = specularMap.g;

    f0 = 0.78 * metalness + 0.02;
    metalData = metalness;
    emissive = mix(specularMap.b, 1.0, emissive);
    ao = 1.0;

	normalMap = texture2DGradARB(normals, newCoord, dcdx, dcdy).xyz * 2.0 - 1.0;
    
    if (normalMap.x + normalMap.y < -1.999) normalMap = vec3(0.0, 0.0, 1.0);
    #endif
}