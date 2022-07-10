/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

#ifdef OVERWORLD
#include "lightColor.glsl"
#endif

#ifdef NETHER
float sunHeight = 0.0;
#include "netherColor.glsl"
#endif

#ifdef END
float sunHeight = 0.0;
#include "endColor.glsl"
#endif