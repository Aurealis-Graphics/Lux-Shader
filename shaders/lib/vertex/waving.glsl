/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

// Use Simplex instead?
float Noise2D(vec2 pos)
{
    vec2 flr = floor(pos);
    vec2 frc = fract(pos);
    frc = Smooth3(frc);

    float n00 = Hash21(flr);
    float n01 = Hash21(flr + vec2(0.0, 1.0));
    float n10 = Hash21(flr + vec2(1.0, 0.0));
    float n11 = Hash21(flr + vec2(1.0, 1.0));

    float n0 = mix(n00, n01, frc.y);
    float n1 = mix(n10, n11, frc.y);

    return mix(n0, n1, frc.x) - 0.5;
}

vec3 CalcMove(vec3 pos, float density, float speed, vec2 mult)
{
    pos = pos * density + frametime * speed;
    vec3 wave = vec3(Noise2D(pos.yz), Noise2D(pos.xz + 0.333), Noise2D(pos.xy + 0.667));
    return wave * vec3(mult, mult.x) * 0.4;
}

float CalcLilypadMove(vec3 worldpos)
{
    float wave = sin(TAU * (frametime * 0.7 + worldpos.x * 0.14 + worldpos.z * 0.07)) +
                 sin(TAU * (frametime * 0.5 + worldpos.x * 0.10 + worldpos.z * 0.20));
    return wave * 0.025;
}

float CalcLavaMove(vec3 worldpos)
{
    float fy = fract(worldpos.y + 0.005);
		
    if (fy > 0.01)
    {
        float wave = sin(PI * (frametime * 0.7 + worldpos.x * 0.14 + worldpos.z * 0.07)) +
                     sin(PI * (frametime * 0.5 + worldpos.x * 0.10 + worldpos.z * 0.20));
        return wave * 0.025;
    }
    else 
    {
        return 0.0;
    }
}

vec3 CalcLanternMove(vec3 position)
{
    vec3 frc = fract(position);
    frc = vec3(frc.x - 0.5, fract(frc.y - 0.001) - 1.0, frc.z - 0.5);
    vec3 flr = position - frc;

    float offset = flr.x * 2.4 + flr.y * 2.7 + flr.z * 2.2;
    float rx = sin(frametime       + offset) * PI * 0.016;
    float ry = sin(frametime * 1.7 + offset) * PI * 0.016;
    float rz = sin(frametime * 1.4 + offset) * PI * 0.016;
    
    float sinRotX = sin(rx), cosRotX = cos(rx);
    float sinRotY = sin(ry), cosRotY = cos(ry);
    float sinRotZ = sin(rz), cosRotZ = cos(rz);

    mat3 rotX = mat3(
        1,        0,        0,
        0,  cosRotX, -sinRotX,
        0,  sinRotX,  cosRotX
    );
    
    mat3 rotY = mat3(
         cosRotY, 0, sinRotY,
               0, 1,       0,
        -sinRotY, 0, cosRotY
    );

    mat3 rotZ = mat3(
        cosRotZ, -sinRotZ, 0,
        sinRotZ,  cosRotZ, 0,
              0,        0, 1
    );
    
    frc = rotX * rotY * rotZ * frc;
    
    return flr + frc - position;
}

vec3 WavingBlocks(vec3 position, float istopv, float skyLight, float sunVisibility, float rainStrength)
{
    vec3 wave = vec3(0.0);
    vec3 worldPos = position + cameraPosition;

    #ifdef SCENE_AWARE_WAVING
    float mult = mc_Entity.x == 10248 ? 1.0 : skyLight * skyLight * skyLight * (sunVisibility * 0.6 * (1.0 - rainStrength) + 0.4 + 0.6 * rainStrength) * (rainStrength + 1.0);
    #endif

    #ifdef WAVING_GRASS
    if (mc_Entity.x == 10100 && istopv > 0.9)
        wave += CalcMove(worldPos, 0.35, 1.0, vec2(0.25, 0.06));
    #endif
    #ifdef WAVING_CROPS
    if ((mc_Entity.x == 10102 || mc_Entity.x == 10108) && (istopv > 0.9 || fract(worldPos.y + 0.0675) > 0.01))
        wave += CalcMove(worldPos, 0.35, 1.15, vec2(0.15, 0.06));
    #endif
    #ifdef WAVING_PLANT
    if (mc_Entity.x == 10101 && (istopv > 0.9 || fract(worldPos.y + 0.005) > 0.01))
        wave += CalcMove(worldPos, 0.7, 1.35, vec2(0.12, 0.06));
    #endif
    #ifdef WAVING_TALL_PLANT
    if (mc_Entity.x == 10103 || (mc_Entity.x == 10104.0 && (istopv > 0.9 || fract(worldPos.y + 0.005) > 0.01)))
        wave += CalcMove(worldPos, 0.7, 1.25, vec2(0.12, 0.06));
    #endif
    #ifdef WAVING_LEAVES
    if (mc_Entity.x == 10105)
        wave += CalcMove(worldPos, 0.25, 1.0, vec2(0.08, 0.08));
    #endif
    #ifdef WAVING_VINES
    if (mc_Entity.x == 10106)
        wave += CalcMove(worldPos, 0.35, 1.25, vec2(0.06, 0.06));
    #endif
    #ifdef WAVING_LILYPAD
    if (mc_Entity.x == 10107)
        wave.y += CalcLilypadMove(worldPos);
    #endif
    #ifdef WAVING_FIRE
    if ((mc_Entity.x == 10249 || mc_Entity.x == 10252) && istopv > 0.9)
        wave += CalcMove(worldPos, 1.0, 1.5, vec2(0.0, 0.37));
    #endif
    #ifdef WAVING_LAVA
    if (mc_Entity.x == 10248)
        wave.y += CalcLavaMove(worldPos);
    #endif
    #ifdef WAVING_LANTERN
    if(mc_Entity.x == 10251 || mc_Entity.x == 10253)
		wave += CalcLanternMove(worldPos);
    #endif

    #ifdef SCENE_AWARE_WAVING
    return position + mult * wave;
    #else
    return position + wave;
    #endif
}