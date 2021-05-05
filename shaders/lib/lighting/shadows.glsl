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

vec2 shadowoffsets[8] = vec2[8](    vec2( 0.0, 1.0),
                                    vec2( 0.7, 0.7),
                                    vec2( 1.0, 0.0),
                                    vec2( 0.7,-0.7),
                                    vec2( 0.0,-1.0),
                                    vec2(-0.7,-0.7),
                                    vec2(-1.0, 0.0),
                                    vec2(-0.7, 0.7));

/*
float texture2DShadow(sampler2D shadowtex, vec3 shadowPos){
    float shadow = texture2D(shadowtex,shadowPos.st).x;
    shadow = clamp((shadow-shadowPos.z)*65536.0,0.0,1.0);
    return shadow;
}
*/

vec2 offsetDist(float x, int s){
	float n = fract(x * 1.414) * 3.1415;
    return vec2(cos(n), sin(n)) * 1.4 * x / s;
}

vec3 SampleBasicShadow(vec3 shadowPos){
    float shadow0 = shadow2D(shadowtex0,vec3(shadowPos.st, shadowPos.z)).x;
    //float shadow0 = texture2DShadow(shadowtex0,vec3(shadowPos.st, shadowPos.z));

    vec3 shadowcol = vec3(0.0);
    #ifdef SHADOW_COLOR
    if (shadow0 < 1.0){
        float shadow1 = shadow2D(shadowtex1,vec3(shadowPos.st, shadowPos.z)).x;
        //float shadow1 = texture2DShadow(shadowtex1,vec3(shadowPos.st, shadowPos.z));
        if (shadow1 > 0.0)
            shadowcol = texture2D(shadowcolor0,shadowPos.st).rgb * shadow1;
    }
    #endif

    return shadowcol * (1.0 - shadow0) + shadow0;
}

vec3 SampleFilteredShadow(vec3 shadowPos, float offset){
    vec3 shadow = SampleBasicShadow(vec3(shadowPos.st, shadowPos.z));

    for(int i = 0; i < 8; i++){
        shadow+= SampleBasicShadow(vec3(offset * shadowoffsets[i] + shadowPos.st, shadowPos.z));
    }

    return shadow * 0.1;
}

vec3 SampleTAAFilteredShadow(vec3 shadowPos, float offset){
    float noise = InterleavedGradientNoise();

    vec3 shadow = vec3(0.0);

    for(int i = 0; i < 2; i++){
        vec2 offset = offsetDist(noise + i, 2) * offset;
        shadow += SampleBasicShadow(vec3(shadowPos.st + offset, shadowPos.z));
        shadow += SampleBasicShadow(vec3(shadowPos.st - offset, shadowPos.z));
    }
    
    return shadow * 0.25;
}

vec3 GetShadow(vec3 shadowPos, float bias, float offset, float foliage){
    shadowPos.z -= bias;

    if(foliage > 0.5) offset *= 4.0;

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