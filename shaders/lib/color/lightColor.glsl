/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 


vec3 lightMorning    = vec3(LIGHT_MR,   LIGHT_MG,   LIGHT_MB)   * LIGHT_MI / 255.0;
vec3 lightDay        = vec3(LIGHT_DR,   LIGHT_DG,   LIGHT_DB)   * LIGHT_DI / 255.0;
vec3 lightEvening    = vec3(LIGHT_ER,   LIGHT_EG,   LIGHT_EB)   * LIGHT_EI / 255.0;
vec3 lightNight      = vec3(LIGHT_NR,   LIGHT_NG,   LIGHT_NB)   * LIGHT_NI * 0.3 / 255.0;

vec4 weatherRain     = vec4(vec3(WEATHER_RR, WEATHER_RG, WEATHER_RB) / 255.0, 1.0) * WEATHER_RI;
vec4 weatherCold     = vec4(vec3(WEATHER_CR, WEATHER_CG, WEATHER_CB) / 255.0, 1.0) * WEATHER_CI;
vec4 weatherDesert   = vec4(vec3(WEATHER_DR, WEATHER_DG, WEATHER_DB) / 255.0, 1.0) * WEATHER_DI;
vec4 weatherBadlands = vec4(vec3(WEATHER_BR, WEATHER_BG, WEATHER_BB) / 255.0, 1.0) * WEATHER_BI;
vec4 weatherSwamp    = vec4(vec3(WEATHER_SR, WEATHER_SG, WEATHER_SB) / 255.0, 1.0) * WEATHER_SI;
vec4 weatherMushroom = vec4(vec3(WEATHER_MR, WEATHER_MG, WEATHER_MB) / 255.0, 1.0) * WEATHER_MI;
vec4 weatherSavanna  = vec4(vec3(WEATHER_VR, WEATHER_VG, WEATHER_VB) / 255.0, 1.0) * WEATHER_VI;

#ifdef WEATHER_PERBIOME
uniform float isDesert, isMesa, isCold, isSwamp, isMushroom, isSavanna;
float weatherWeight = isCold + isDesert + isMesa + isSwamp + isMushroom + isSavanna;

vec4 weatherCol = mix(
	weatherRain,
	(	weatherCold  * isCold  + weatherDesert   * isDesert   + weatherBadlands * isMesa    +
		weatherSwamp * isSwamp + weatherMushroom * isMushroom + weatherSavanna  * isSavanna
	) / max(weatherWeight, 0.0001),
	weatherWeight
);

#else
vec4 weatherCol = weatherRain;
#endif

float mefade = 1.0 - clamp(abs(timeAngle - 0.5) * 8.0 - 1.5, 0.0, 1.0);
float dfade = 1.0 - timeBrightness;
float sunHeight = clamp(dot(sunVec, upVec) * 2.0, 0.0, 1.0);

vec3 GetDirectColor(float height) 
{
    height = (1.0 - height) * 0.4;
    vec3 baseColGradient = mix(vec3(1.0, 0.651, 0.0), vec3(0.6824, 0.0, 1.0), height);
    vec3 sunCol = pow(exp(-(1.0 - baseColGradient) * height * 4.0), vec3(6.0));
	vec3 moonCol = vec3(0.2824, 0.7725, 1.0) * vec3(0.05);
	vec3 result = mix(moonCol, sunCol, sunVisibility);
	return mix(result, dot(result, vec3(0.2125, 0.7154, 0.0721)) * weatherCol.rgb, rainStrength);
}

vec3 lightCol = GetDirectColor(1.5 * (sunHeight / (0.5 + sunHeight)));