/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

vec4 waterColorSqrt = vec4(vec3(WATER_R, WATER_G, WATER_B) / 255.0, 1.0) * WATER_I;
vec4 waterColor = waterColorSqrt * waterColorSqrt;

const float waterAlpha = WATER_A;
const float waterFog = WATER_F;