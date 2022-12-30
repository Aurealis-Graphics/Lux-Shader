/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

const vec3 lightNight      = vec3(LIGHT_NR, LIGHT_NG, LIGHT_NB) * LIGHT_NI * 0.3 / 255.0;

const vec4 weatherRain     = vec4(vec3(WEATHER_RR, WEATHER_RG, WEATHER_RB) / 255.0, 1.0) * WEATHER_RI;
const vec4 weatherCold     = vec4(vec3(WEATHER_CR, WEATHER_CG, WEATHER_CB) / 255.0, 1.0) * WEATHER_CI;
const vec4 weatherDesert   = vec4(vec3(WEATHER_DR, WEATHER_DG, WEATHER_DB) / 255.0, 1.0) * WEATHER_DI;
const vec4 weatherBadlands = vec4(vec3(WEATHER_BR, WEATHER_BG, WEATHER_BB) / 255.0, 1.0) * WEATHER_BI;
const vec4 weatherSwamp    = vec4(vec3(WEATHER_SR, WEATHER_SG, WEATHER_SB) / 255.0, 1.0) * WEATHER_SI;
const vec4 weatherMushroom = vec4(vec3(WEATHER_MR, WEATHER_MG, WEATHER_MB) / 255.0, 1.0) * WEATHER_MI;
const vec4 weatherSavanna  = vec4(vec3(WEATHER_VR, WEATHER_VG, WEATHER_VB) / 255.0, 1.0) * WEATHER_VI;

#if defined WEATHER_PERBIOME || defined AURORA_PERBIOME
uniform float isDesert, isMesa, isCold, isSwamp, isMushroom, isSavanna;
float weatherWeight = isCold + isDesert + isMesa + isSwamp + isMushroom + isSavanna;

vec4 weatherCol = mix(
	weatherRain,
	(	weatherCold  * isCold  + weatherDesert   * isDesert   + weatherBadlands * isMesa    +
		weatherSwamp * isSwamp + weatherMushroom * isMushroom + weatherSavanna  * isSavanna
	) / MaxEPS(weatherWeight),
	weatherWeight
);

#else
vec4 weatherCol = weatherRain;
#endif

float sunHeight = clamp(dot(sunVec, upVec) * 2.0, 0.0, 1.0);
float moonHeight = clamp(-dot(sunVec, upVec) * 2.0, 0.0, 1.0);

const vec3 moonCol = vec3(0.2, 0.7451, 1.0) * 0.08;

// vec3 GetDirectColor(float height) 
// {
// 	height = 1.5 * (height / (0.5 + height));
// 	height = (1.0 - height) * 0.5;
// 	vec3 baseColGradient = mix(vec3(1.0, 0.651, 0.0), vec3(0.6824, 0.0, 1.0), height);
// 	vec3 sunCol = pow(exp(-(1.0 - baseColGradient) * height * 4.0), vec3(6.0)) * 2.0;
// 	vec3 result = mix(moonCol, sunCol, sunVisibility);

// 	float prevLuma = GetLuminance(result);
// 	result /= prevLuma;
// 	result *= min(prevLuma, 0.9);

// 	return mix(result, dot(result, vec3(0.2125, 0.7154, 0.0721)) * weatherCol.rgb, rainStrength);
// }

// vec3 lightCol = GetDirectColor(sunHeight);

float lightCol_heightCurve = 1.5 * (sunHeight / (0.5 + sunHeight));
float lightCol_height = max((1.0 - lightCol_heightCurve) * 0.5, 0.006);
vec3 lightCol_baseColGradient = mix(vec3(1.0, 0.651, 0.0), vec3(0.6824, 0.0, 1.0), lightCol_height);
vec3 lightCol_sunCol = pow(exp(-(1.0 - lightCol_baseColGradient) * lightCol_height * 4.0), vec3(6.0)) * 2.4;
vec3 lightCol_result = mix(moonCol, lightCol_sunCol, sunVisibility);

float lightCol_prevLuma = dot(lightCol_result, vec3(0.2125, 0.7154, 0.0721));
vec3 lightCol_newResult = lightCol_result / lightCol_prevLuma * min(lightCol_prevLuma, 0.9);

vec3 lightCol = mix(lightCol_newResult, dot(lightCol_newResult, vec3(0.2125, 0.7154, 0.0721)) * weatherCol.rgb, rainStrength);