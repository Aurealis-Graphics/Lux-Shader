/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

vec4 endColSqrt = vec4(vec3(END_R, END_G, END_B) / 255.0, 1.0) * END_I;
vec4 endCol = Pow2(endColSqrt);