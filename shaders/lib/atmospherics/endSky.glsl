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
    float k = TAU / wavelength;
    float a = steepness / k;
    vec2 dir = direction;
    float f = k * (dot(dir, coord.xy) - Lift(k, 1.6) * time * speed);
    
    vec3 layer;
    layer.xz += dir.xy * (a * cos(f)) / a;
    layer.y = sin(f);
    
    return layer;
}

const float endSkyPersistance = 0.99;
const float endSkyLacunarity = 1.2;
vec3 GetEndSkyColor(vec3 viewPos) 
{
    vec3 viewDir = mat3(gbufferModelViewInverse) * normalize(viewPos);
    vec2 coord = viewDir.xz / (1.0 + abs(viewDir.y)) * 80.0;

    vec3 pattern = vec3(0.0);

    float amplitude = 1.0;
    float frequency = 1.0;

    for (int i = 0; i < 16; i++)
    {
        vec2 direction = vec2(0.707106782) * Rotate(float(i) * 4.3333);
        vec3 waveLayer = GetWaveLayer(coord, 20.0 / frequency, amplitude, frameTimeCounter, 0.31321, direction);
        
        pattern += waveLayer.y * 0.5 + 0.5;
        coord -= waveLayer.xz * 0.36;

        amplitude *= endSkyPersistance;
        frequency *= endSkyLacunarity;
    }

    pattern = Saturate(pattern * 0.05);
    pattern = pattern * pattern * exp((Pow2(Max0(1.3 * pattern - 0.3)) - 1.0) * (1.0 - vec3(0.7686, 0.6275, 1.0) * 0.5) * 13.0) * 60.0;
    pattern *= exp2(-abs(viewDir.y) * 3.0);

    return pattern;
}