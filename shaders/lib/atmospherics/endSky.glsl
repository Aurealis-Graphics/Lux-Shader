/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

const float gravitationalConst = 9.81;
vec3 GetWaveLayer(vec2 coord, float wavelength, float steepness, float time, float speed, vec2 direction) 
{
    vec3 gerstner;
    float k = 2.0 * PI / wavelength;
    float c = sqrt(gravitationalConst / k);
    float a = steepness / k;
    vec2 dir = normalize(direction);
    float f = k * (dot(dir, coord.xy) - c * time * speed);
    
    gerstner.x += dir.x * (a * cos(f)) / a;
    gerstner.y = sin(f);
    gerstner.z += dir.y * (a * cos(f)) / a;
    
    return gerstner;
}

vec3 GetEndSkyColor(vec3 viewPos) 
{
    vec3 viewDir = mat3(gbufferModelViewInverse) * normalize(viewPos);
    vec2 coord = viewDir.xz / (1.0 + abs(viewDir.y));
    coord *= 80.0;

    vec3 pattern = vec3(0.0);
    
    const float persistance = 0.99;
    const float lacunarity = 1.2;
    float amplitude = 1.0;
    float frequency = 1.0;

    for (int i = 0; i < 16; i++)
    {
        vec2 direction = vec2(1.0) * Rotate(float(i) * 4.3333);
        vec3 waveLayer = GetWaveLayer(coord, 20.0 / frequency, amplitude, frameTimeCounter, 0.1, direction);
        
        pattern += waveLayer.y * 0.5 + 0.5;

        coord -= waveLayer.xz * 0.36;

        amplitude *= persistance;
        frequency *= lacunarity;
    }

    pattern = Saturate(pattern * 0.05);
    pattern = pattern * pattern * exp((Pow2(Max0(1.3 * pattern - 0.3)) - 1.0) * (1.0 - vec3(0.7686, 0.6275, 1.0) * 0.5) * 13.0) * 60.0;
    pattern *= exp2(-abs(viewDir.y) * 3.0);

    return pattern;
}