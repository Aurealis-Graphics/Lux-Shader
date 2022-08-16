/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

#ifdef SKY_VANILLA
uniform vec3 skyColor;
uniform vec3 fogColor;

vec3 skyCol = pow(skyColor, vec3(2.2)) * SKY_I * SKY_I;
vec3 fogCol = pow(fogColor, vec3(2.2)) * SKY_I * SKY_I;
#else
vec3 sky_ColorSqrt = vec3(SKY_R, SKY_G, SKY_B) * SKY_I / 255.0;
vec3 skyCol = sky_ColorSqrt * sky_ColorSqrt;
vec3 fogCol = sky_ColorSqrt * sky_ColorSqrt;
#endif