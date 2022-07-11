/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

vec4 ReadNormal(vec2 coord)
{
    coord = fract(coord) * vTexCoordAM.pq + vTexCoordAM.st;
	return texture2DGradARB(normals, coord, dcdx, dcdy);
}

vec2 GetParallaxCoord(float parallaxFade)
{
    vec2 newCoord = vTexCoord.st * vTexCoordAM.pq + vTexCoordAM.st;
    vec2 coord = vTexCoord.st;
    // float dither = InterleavedGradientNoise(gl_FragCoord.xy + frameTimeCounter * 17.333);

    if (parallaxFade < 1.0)
    {
        vec3 normalMap = ReadNormal(vTexCoord.st).xyz * 2.0 - 1.0;

        float normalCheck = normalMap.x + normalMap.y;
        float minHeight = 1.0 - 1.0 / PARALLAX_QUALITY;

        if (viewVector.z < 0.0 && ReadNormal(vTexCoord.st).a < minHeight && normalCheck > -1.999)
        {
            float multiplier = 0.25 * (1.0 - parallaxFade) * PARALLAX_DEPTH / (-viewVector.z * PARALLAX_QUALITY);
            vec2 interval = viewVector.xy * multiplier;
            
            // coord += interval * (dither - 0.5);

            for(int i = 0; i < PARALLAX_QUALITY; i++) 
            {
                if (ReadNormal(coord).a < 1.0 - float(i) / PARALLAX_QUALITY) coord += interval;
                else break;
            }
            
            newCoord = fract(coord.st) * vTexCoordAM.pq + vTexCoordAM.st;
        }
    }

    return newCoord;
}

float GetParallaxShadow(float parallaxFade, vec2 coord, vec3 lightVec, mat3 tbn)
{
    float parallaxshadow = 1.0;
    float minHeight = 1.0 - 1.0 / PARALLAX_QUALITY;

    if (dist < PARALLAX_DISTANCE + 32.0)
    {
        float height = texture2DGradARB(normals, coord, dcdx, dcdy).a;
        if (height < minHeight)
        {
            vec3 parallaxdir = tbn * lightVec;
            parallaxdir.xy *= 0.2 * SELF_SHADOW_ANGLE * PARALLAX_DEPTH;
            vec2 newvTexCoord = (coord - vTexCoordAM.st) / vTexCoordAM.pq;
            float step = 1.28 / PARALLAX_QUALITY;
            
            for(int i = 0; i < PARALLAX_QUALITY / 4; i++)
            {
                float currentHeight = height + parallaxdir.z * step * i;
                vec2 parallaxCoord = fract(newvTexCoord + parallaxdir.xy * i * step) * vTexCoordAM.pq + vTexCoordAM.st;
                float offsetHeight = texture2DGradARB(normals, parallaxCoord, dcdx, dcdy).a;
                parallaxshadow *= Saturate(1.0 - (offsetHeight - currentHeight) * 40.0);
                if (parallaxshadow < 0.01) break;
            }
            
            parallaxshadow = mix(parallaxshadow, 1.0, parallaxFade);
        }
    }

    return parallaxshadow;
}