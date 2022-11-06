/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

#if SHADOW_ADVANCED_FILTER == 0
uniform sampler2DShadow shadowtex0;
#else
uniform sampler2D shadowtex0;
#endif

#ifdef SHADOW_COLOR
#if SHADOW_ADVANCED_FILTER == 0
uniform sampler2DShadow shadowtex1;
#else
uniform sampler2D shadowtex1;
#endif

uniform sampler2D shadowcolor0;
#endif

#if SHADOW_ADVANCED_FILTER == 1
#if AA == 2
vec2 shadowOffsets[8] = vec2[8](
    vec2(  0.000000,  0.250000 ),
    vec2(  0.292496, -0.319290 ),
    vec2( -0.556877,  0.048872 ),
    vec2(  0.524917,  0.402445 ),
    vec2( -0.130636, -0.738535 ),
    vec2( -0.445032,  0.699604 ),
    vec2(  0.870484, -0.234003 ),
    vec2( -0.859268, -0.446273 )
);
#else
vec2 shadowOffsets[16] = vec2[16](
    vec2(  0.000000,  0.176777 ),
    vec2(  0.206826, -0.225772 ),
    vec2( -0.393771,  0.034558 ),
    vec2(  0.371173,  0.284571 ),
    vec2( -0.092373, -0.522223 ),
    vec2( -0.314685,  0.494695 ),
    vec2(  0.615525, -0.165465 ),
    vec2( -0.607594, -0.315562 ),
    vec2(  0.250029,  0.684643 ),
    vec2(  0.294010, -0.712255 ),
    vec2( -0.733729,  0.343353 ),
    vec2(  0.808931,  0.253732 ),
    vec2( -0.443184, -0.764747 ),
    vec2( -0.197235,  0.897133 ),
    vec2(  0.778774, -0.547504 ),
    vec2( -0.976089, -0.126490 )
);
#endif
#else
vec2 shadowOffsets[4] = vec2[4](
    vec2(  0.000000,  0.353553 ),
    vec2(  0.413652, -0.451544 ),
    vec2( -0.787542,  0.069116 ),
    vec2(  0.742345,  0.569143 )
);
#endif

#if SHADOW_ADVANCED_FILTER == 1
#if AA == 2
int shadowFilterSamples = 8;
#else
int shadowFilterSamples = 16;
#endif
#else
int shadowFilterSamples = 4;
#endif

#if SHADOW_ADVANCED_FILTER == 1
float SampleHardShadow(sampler2D shadowtex, vec3 shadowPos)
{
    return texture2D(shadowtex, shadowPos.xy).x > shadowPos.z ? 1.0 : 0.0;
}
#endif

vec3 SampleBasicShadow(vec3 shadowPos)
{
    #if SHADOW_ADVANCED_FILTER == 0
    float shadow0 = shadow2D(shadowtex0, shadowPos).x;
    #else
    float shadow0 = SampleHardShadow(shadowtex0, shadowPos);
    #endif

    vec3 shadowCol = vec3(0.0);

    #ifdef SHADOW_COLOR
    if (shadow0 < 1.0)
    {
        #if SHADOW_ADVANCED_FILTER == 0
        float shadow1 = shadow2D(shadowtex1, shadowPos).x;
        #else
        float shadow1 = SampleHardShadow(shadowtex1, shadowPos);
        #endif
        
        if (shadow1 > 0.0)
        {
            vec4 shadowCol0 = texture2D(shadowcolor0, shadowPos.st);
            shadowCol = shadowCol0.rgb * (1.0 - shadowCol0.a) * shadow1;
        }
    }
    #endif

    return shadowCol * (1.0 - shadow0) + shadow0;
}

vec3 SampleTAAFilteredShadow(vec3 shadowPos, float offset, mat2 rotMat)
{
    vec3 shadow = vec3(0.0);

    for (int i = 0; i < shadowFilterSamples; i++)
    {
        shadow += SampleBasicShadow(vec3(shadowPos.st + rotMat * shadowOffsets[i] * offset, shadowPos.z));
    }
    
    return shadow * (1.0 / float(shadowFilterSamples));
}

vec3 GetShadow(vec3 shadowPos, float bias, float offset, float NdotL, float foliage)
{
    shadowPos.z -= bias;

    #if AA == 2
    float dither = InterleavedGradientNoise(gl_FragCoord.xy);
    dither = fract(dither + frameTimeCounter * 8.0);

    mat2 ditherRotMat = Rotate(dither * TAU);
    #else
    mat2 ditherRotMat = Rotate(0.0);
    #endif

    #if SHADOW_ADVANCED_FILTER == 1
    if (NdotL > 0.0 || foliage > 0.5) 
    {
        float avgBlockerDistance = 0.0;
        
        for (int i = 0; i < shadowFilterSamples; i++)
        {
            vec2 offset = ditherRotMat * shadowOffsets[i] * 0.015;
            avgBlockerDistance += Max0(shadowPos.z - texture2D(shadowtex0, shadowPos.xy + offset).x);
        }
        
        avgBlockerDistance *= 1.0 / float(shadowFilterSamples);
        offset = max(offset, avgBlockerDistance * 0.32);
    }
    #endif

    #ifdef SHADOW_FILTER
    vec3 shadow = vec3(0.0);
    if (offset > EPS)   shadow = SampleTAAFilteredShadow(shadowPos, offset, ditherRotMat);
    else                shadow = SampleBasicShadow(shadowPos);
    #else
    vec3 shadow = SampleBasicShadow(shadowPos);
    #endif

    return shadow;
}