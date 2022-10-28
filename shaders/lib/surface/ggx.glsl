/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

// GGX area light approximation from Horizon Zero Dawn
float GetNoHSquared(float radiusTan, float NoL, float NoV, float VoL)
{
    float radiusCos = 1.0 / sqrt(1.0 + radiusTan * radiusTan);
    
    float RoL = 2.0 * NoL * NoV - VoL;
    if (RoL >= radiusCos)
        return 1.0;

    float rOverLengthT = radiusCos * radiusTan / sqrt(1.0 - RoL * RoL);
    float NoTr = rOverLengthT * (NoV - RoL * NoL);
    float VoTr = rOverLengthT * (2.0 * NoV * NoV - 1.0 - RoL * VoL);

    float triple = sqrt(Saturate(1.0 - NoL * NoL - NoV * NoV - VoL * VoL + 2.0 * NoL * NoV * VoL));
    
    float NoBr = rOverLengthT * triple, VoBr = rOverLengthT * (2.0 * triple * NoV);
    float NoLVTr = NoL * radiusCos + NoV + NoTr, VoLVTr = VoL * radiusCos + 1.0 + VoTr;
    float p = NoBr * VoLVTr, q = NoLVTr * VoLVTr, s = VoBr * NoLVTr;    
    float xNum = q * (-0.5 * p + 0.25 * VoBr * NoLVTr);
    float xDenom = p * p + s * ((s - 2.0 * p)) + NoLVTr * ((NoL * radiusCos + NoV) * VoLVTr * VoLVTr + 
                   q * (-0.5 * (VoLVTr + VoL * radiusCos) - 0.5));
    float twoX1 = 2.0 * xNum / (xDenom * xDenom + xNum * xNum);
    float sinTheta = twoX1 * xDenom;
    float cosTheta = 1.0 - twoX1 * xNum;
    NoTr = cosTheta * NoTr + sinTheta * NoBr;
    VoTr = cosTheta * VoTr + sinTheta * VoBr;
    
    float newNoL = NoL * radiusCos + NoTr;
    float newVoL = VoL * radiusCos + VoTr;
    float NoH = NoV + newNoL;
    float HoH = 2.0 * newVoL + 2.0;
    return Max0(NoH * NoH / HoH);
}

float GGX(vec3 normal, vec3 viewPos, vec3 lightVec, float smoothness, float f0, float sunSize)
{
    float roughness = max(1.0 - smoothness, 0.03);
    roughness *= roughness;
    roughness *= roughness;
    
    vec3 halfVec = normalize(lightVec - viewPos);

    float dotLH = clamp(dot(halfVec, lightVec), 0.0, 1.0);
    float dotNL = clamp(dot(normal,  lightVec), 0.0, 1.0);
    float dotNH = GetNoHSquared(sunSize, dotNL, dot(normal, -viewPos), dot(-viewPos, lightVec));
    
    float denom = dotNH * roughness - dotNH + 1.0;
    float D = roughness / (PI * denom * denom);
    float F = exp2((-5.55473 * dotLH - 6.98316) * dotLH) * (1.0 - f0) + f0;
    float k2 = roughness * 0.25;

    float specular = Max0(dotNL * dotNL * D * F / (dotLH * dotLH * (1.0 - k2) + k2));
    specular = specular * (1.0 - roughness * (1.0 - 0.025 * f0));
    specular = specular / (0.125 * specular + 1.0);

    return specular;
}

const vec3 metalAlbedos[8] = vec3[8](
    vec3(0.24867, 0.22965, 0.21366),
    vec3(0.88140, 0.57256, 0.11450),
    vec3(0.81715, 0.82021, 0.83177),
    vec3(0.27446, 0.27330, 0.27357),
    vec3(0.84430, 0.48677, 0.22164),
    vec3(0.36501, 0.35675, 0.37653),
    vec3(0.42648, 0.37772, 0.31138),
    vec3(0.91830, 0.89219, 0.83662)
);

vec3 GetMetalCol(int metalIndex)
{
    if (clamp(float(metalIndex), 0.0, 7.0) == metalIndex)   return metalAlbedos[metalIndex];
    else                                                    return vec3(1.0);
}

vec3 GetSpecularHighlight(
    float smoothness,
    float metalness, 
    float f0, 
    vec3 specularColor,
    vec3 rawAlbedo,
    vec3 shadow,
    vec3 normal,
    vec3 viewPos
    )
{
    if (dot(shadow, shadow) < 0.001) return vec3(0.0);

    float sunSize = 0.025 * sunVisibility + 0.05;

    #ifdef ROUND_SUN_MOON
    sunSize = 0.02;
    #endif

    float specular = GGX(normal, normalize(viewPos), lightVec, smoothness, f0, sunSize);
    specular *= (1.0 - sqrt(rainStrength)) * shadowFade;
    
    specularColor = pow(specularColor, vec3(1.0 - 0.5 * metalness));
    
    #if MATERIAL_FORMAT == 0
    if (metalness > 0.5)
    {
        if (f0 < 1.0)   specularColor *= GetMetalCol(int(f0 * 255.0) - 230);
        else            specularColor *= rawAlbedo;
    }
    #else
    specularColor *= pow(rawAlbedo, vec3(metalness));
    #endif

    return specular * specularColor * shadow;
}