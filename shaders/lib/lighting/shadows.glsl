/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

uniform sampler2DShadow shadowtex0;

#ifdef SHADOW_COLOR
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
#endif

/*
uniform sampler2D shadowtex0;

#ifdef SHADOW_COLOR
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
#endif
*/

vec2 shadowoffsets[8] = vec2[8](
    vec2(  0.0,  1.0 ),
    vec2(  0.7,  0.7 ),
    vec2(  1.0,  0.0 ),
    vec2(  0.7, -0.7 ),
    vec2(  0.0, -1.0 ),
    vec2( -0.7, -0.7 ),
    vec2( -1.0,  0.0 ),
    vec2( -0.7,  0.7 )
);

/*
float texture2DShadow(sampler2D shadowtex, vec3 shadowPos)
{
    float shadow = texture2D(shadowtex,shadowPos.st).x;
    shadow = clamp((shadow-shadowPos.z)*65536.0,0.0,1.0);
    return shadow;
}
*/

vec2 OffsetDist(float x, int s)
{
	float n = fract(x * 1.414) * PI;
    return vec2(cos(n), sin(n)) * 1.4 * x / s;
}

vec3 SampleBasicShadow(vec3 shadowPos)
{
    float shadow0 = shadow2D(shadowtex0, shadowPos).x;

    vec3 shadowcol = vec3(0.0);
    #ifdef SHADOW_COLOR
    if (shadow0 < 1.0)
    {
        float shadow1 = shadow2D(shadowtex1, shadowPos).x;
        if (shadow1 > 0.0) {
            vec4 shadowcol0 = texture2D(shadowcolor0, shadowPos.st);
            shadowcol = shadowcol0.rgb * (1.0 - shadowcol0.a) * shadow1;
        }
    }
    #endif

    return shadowcol * (1.0 - shadow0) + shadow0;
}

vec3 SampleFilteredShadow(vec3 shadowPos, float offset)
{
    vec3 shadow = SampleBasicShadow(vec3(shadowPos.st, shadowPos.z));
    
    for (int i = 0; i < 8; i++)
    {
        shadow += SampleBasicShadow(vec3(offset * shadowoffsets[i] + shadowPos.st, shadowPos.z));
    }
    
    return shadow * (1.0 / 8.0);
}

vec3 SampleTAAFilteredShadow(vec3 shadowPos, float offset)
{
    float noise = InterleavedGradientNoise(gl_FragCoord.xy);
    noise = fract(noise + frameTimeCounter * 8.0);

    vec3 shadow = vec3(0.0);

    for(int i = 0; i < 2; i++)
    {
        vec2 offset = OffsetDist(noise + i, 2) * offset;
        shadow += SampleBasicShadow(vec3(shadowPos.st + offset, shadowPos.z));
        shadow += SampleBasicShadow(vec3(shadowPos.st - offset, shadowPos.z));
    }
    
    return shadow * 0.25;
}

vec3 GetShadow(vec3 shadowPos, float bias, float offset)
{
    shadowPos.z -= bias;

    #ifdef SHADOW_FILTER
    #if AA == 2
    vec3 shadow = SampleTAAFilteredShadow(shadowPos, offset);
    #else
    vec3 shadow = SampleFilteredShadow(shadowPos, offset);
    #endif
    #else
    vec3 shadow = SampleBasicShadow(shadowPos);
    #endif

    return shadow;
}