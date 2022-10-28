/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

const vec3[8] metalN = vec3[8](
    vec3( 2.9114 , 2.9497 , 2.5845  ),
    vec3( 0.18299, 0.42108, 1.3734  ),
    vec3( 1.3456 , 0.96521, 0.61722 ),
    vec3( 3.1071 , 3.1812 , 2.3230  ),
    vec3( 0.27105, 0.67693, 1.3164  ),
    vec3( 1.9100 , 1.8300 , 1.4400  ),
    vec3( 2.3757 , 2.0847 , 1.8453  ),
    vec3( 0.15943, 0.14512, 0.13547 )
);

const vec3[8] metalK = vec3[8](
    vec3( 3.0893, 2.9318, 2.7670 ),
    vec3( 3.4242, 2.3459, 1.7704 ),
    vec3( 7.4746, 6.3995, 5.3031 ),
    vec3( 3.3314, 3.3291, 3.1350 ),
    vec3( 3.6092, 2.6248, 2.2921 ),
    vec3( 3.5100, 3.4000, 3.1800 ),
    vec3( 4.2655, 3.7153, 3.1365 ),
    vec3( 3.9291, 3.1900, 2.3808 )
);

vec3 GetN(int metalIndex)
{
    if (clamp(float(metalIndex), 0.0, 7.0) == metalIndex)   return metalN[metalIndex];
    else                                                    return vec3(1.0);
}

vec3 GetK(int metalIndex)
{
    if (clamp(float(metalIndex), 0.0, 7.0) == metalIndex)   return metalK[metalIndex];
    else                                                    return vec3(1.0);
}

vec3 ComplexFresnel(float fresnel, float f0)
{
    int metalIndex = int(f0 * 255.0) - 230;
    vec3 k = GetK(metalIndex);
    vec3 n = GetN(metalIndex);
    float f = 1.0 - fresnel;

    vec3 k2 = k * k;
    vec3 n2 = n * n;
    float f2 = f * f;

    vec3 rs_num = n2 + k2 - 2 * n * f + f2;
    vec3 rs_den = n2 + k2 + 2 * n * f + f2;
    vec3 rs = rs_num / rs_den;
     
    vec3 rp_num = (n2 + k2) * f2 - 2 * n * f + 1;
    vec3 rp_den = (n2 + k2) * f2 + 2 * n * f + 1;
    vec3 rp = rp_num / rp_den;
    
    vec3 fresnel3 = clamp(0.5 * (rs + rp), vec3(0.0), vec3(1.0));
    fresnel3 *= fresnel3;

    return fresnel3;
}