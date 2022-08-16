/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

const vec4 netherNether  = vec4(vec3(NETHER_NR, NETHER_NG, NETHER_NB) / 255.0, 1.0) * NETHER_NI;
const vec4 netherValley  = vec4(vec3(NETHER_VR, NETHER_VG, NETHER_VB) / 255.0, 1.0) * NETHER_VI;
const vec4 netherCrimson = vec4(vec3(NETHER_CR, NETHER_CG, NETHER_CB) / 255.0, 1.0) * NETHER_CI;
const vec4 netherWarped  = vec4(vec3(NETHER_WR, NETHER_WG, NETHER_WB) / 255.0, 1.0) * NETHER_WI;
const vec4 netherBasalt  = vec4(vec3(NETHER_BR, NETHER_BG, NETHER_BB) / 255.0, 1.0) * NETHER_BI;

#ifdef WEATHER_PERBIOME
uniform float isValley, isCrimson, isWarped, isBasalt;

float nBiomeWeight = isValley + isCrimson + isWarped + isBasalt;

vec4 netherColSqrt = mix(
    netherNether, (
        netherValley  * isValley  +
        netherCrimson * isCrimson +
        netherWarped  * isWarped  +
        netherBasalt  * isBasalt
    ) / MaxEPS(nBiomeWeight),
    nBiomeWeight
);
#else
vec4 netherColSqrt = netherNether;
#endif

vec4 netherCol = Pow2(netherColSqrt);