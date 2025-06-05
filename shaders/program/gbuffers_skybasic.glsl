/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

// Global Include
#include "/lib/global.glsl"

// Fragment Shader
#ifdef FSH

// Varyings
varying float star;

varying vec3 upVec, sunVec;

// Uniforms
uniform int isEyeInWater;
uniform int worldTime;
uniform int worldDay;

uniform float blindFactor;
uniform float frameCounter;
uniform float frameTimeCounter;
uniform float nightVision;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform sampler2D noisetex;

// Common Variables
#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.07, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec, upVec) + 0.07, 0.0, 0.1) * 10.0;

vec3 lightVec = sunVec * (1.0 - 2.0 * float(timeAngle > 0.5325 && timeAngle < 0.9675));

// Common Functions
void RoundSunMoon(inout vec3 color, vec3 viewPos, vec3 lightCol, vec3 moonCol)
{
	vec3 viewDir = normalize(viewPos.xyz);
	float sunDot = clamp(1.0 - dot(sunVec, viewDir), 0.0, 1.0);
	float moonDot = clamp(1.0 - dot(-sunVec, viewDir), 0.0, 1.0);

	vec3 sun = vec3(min(0.002 / MaxEPS(sunDot - 0.0001), 40.0 * (1.0 - rainStrength))) * lightCol;
	vec3 moon = vec3(min(0.001 / MaxEPS(moonDot - 0.0001), 20.0 * (1.0 - rainStrength)));
	moon *= clamp(dot(-sunVec, upVec), 0.0, 1.0) * 10.0 * moonCol / (moonCol + 0.3);

	float y = dot(viewDir, upVec);
	float horizonFade = smoothstep(0.0, 0.05, y + 0.02) * Pow5(1.0 - rainStrength);

	color += (sun + moon) * horizonFade;
}

void SunGlare(inout vec3 color, vec3 viewPos, vec3 lightCol)
{
	float cosS = dot(normalize(viewPos), lightVec);
	float visfactor = 0.05 * (1.0 - 0.8 * timeBrightness) * (3.0 * rainStrength + 1.0);
	float invvisfactor = 1.0 - visfactor;

	float visibility = Saturate(cosS * 0.5 + 0.5);
    visibility = visfactor / (1.0 - invvisfactor * visibility) - visfactor;
	visibility = Saturate(visibility * 1.015 / invvisfactor - 0.015);
	visibility = mix(1.0, visibility, 0.25 * eBS + 0.75) * (1.0 - rainStrength * eBS * 0.875);
	visibility *= shadowFade * VOLUMETRIC_FOG_STRENGTH;

	#ifdef VOLUMETRIC_FOG
	if (isEyeInWater == 1) color += 0.225 * lightCol * visibility;
	#else
	color += 0.225 * lightCol * visibility;
	#endif
}

// Includes
#include "/lib/color/lightColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/atmospherics/clouds.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/color/ambientColor.glsl"

#ifdef STARS
#include "/lib/atmospherics/stars.glsl"
#endif

#ifdef AURORA
#include "/lib/atmospherics/aurora.glsl"
#endif

// Program
void main()
{
	#ifdef OVERWORLD
	vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	vec3 albedo = GetSkyColor(viewPos.xyz, lightCol);
	vec3 skyEnvAmbientApprox = GetAmbientColor(vec3(0, 1, 0), lightCol);

	#ifdef ROUND_SUN_MOON
	RoundSunMoon(albedo, viewPos.xyz, lightCol, moonCol);
	#endif

	#ifdef STARS
	if (moonVisibility > 0.0) 
	{
		DrawStars(albedo.rgb, viewPos.xyz);
		#ifdef SHOOTING_STARS
		albedo.rgb += DrawShootingStars(viewPos.xyz, frameTimeCounter);
		#endif
	}
	#endif

	float dither = InterleavedGradientNoise(gl_FragCoord.xy);

	#ifdef CLOUDS
	vec4 cloud = DrawCloud(viewPos.xyz, dither, lightCol, skyEnvAmbientApprox);
	albedo.rgb = mix(albedo.rgb, cloud.rgb, cloud.a);
	#endif

	#ifdef AURORA
	vec4 aurora = DrawAurora(viewPos.xyz, dither, AURORA_SAMPLES_SKY);
	albedo.rgb = mix(albedo.rgb, aurora.rgb, aurora.a);
	#endif

	SunGlare(albedo, viewPos.xyz, lightCol);

	albedo.rgb *= (4.0 - 3.0 * eBS) * (1.0 + nightVision);
	#endif

	#ifdef END
	vec3 albedo = vec3(0.0);
	#endif

    /* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(albedo, 1.0 - star);

    #if defined OVERWORLD && defined CLOUDS
	/* DRAWBUFFERS:04 */
	gl_FragData[1] = vec4(cloud.a, 0.0, 0.0, 0.0);
    #endif
}

#endif

// Vertex Shader
#ifdef VSH

// Varyings
varying float star;

varying vec3 sunVec, upVec;

// Uniforms
uniform float timeAngle;

uniform mat4 gbufferModelView;

// Program
void main()
{
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * PI) * -0.5 + 0.5 - ang) / 3.0) * TAU;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	upVec = normalize(gbufferModelView[1].xyz);
	gl_Position = ftransform();
	star = float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0);
}

#endif
