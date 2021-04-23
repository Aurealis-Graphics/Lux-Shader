vec4 netherNether  = vec4(vec3(NETHER_NR, NETHER_NG, NETHER_NB) / 255.0, 1.0) * NETHER_NI;
vec4 netherValley  = vec4(vec3(NETHER_VR, NETHER_VG, NETHER_VB) / 255.0, 1.0) * NETHER_VI;
vec4 netherCrimson = vec4(vec3(NETHER_CR, NETHER_CG, NETHER_CB) / 255.0, 1.0) * NETHER_CI;
vec4 netherWarped  = vec4(vec3(NETHER_WR, NETHER_WG, NETHER_WB) / 255.0, 1.0) * NETHER_WI;
vec4 netherBasalt  = vec4(vec3(NETHER_BR, NETHER_BG, NETHER_BB) / 255.0, 1.0) * NETHER_BI;

#ifdef WEATHER_PERBIOME
uniform float isValley, isCrimson, isWarped, isBasalt;
float nBiomeWeight = isValley + isCrimson + isWarped + isBasalt;

vec4 netherColSqrt = mix(
    netherNether,
    (
        netherValley  * isValley  + netherCrimson * isCrimson +
        netherWarped  * isWarped  + netherBasalt  * isBasalt
    ) / max(nBiomeWeight, 0.0001),
    nBiomeWeight
);
#else
vec4 netherColSqrt = netherNether;
#endif

vec4 netherCol = netherColSqrt * netherColSqrt;