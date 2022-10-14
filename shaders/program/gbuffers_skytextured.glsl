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
varying vec2 texCoord;

varying vec3 upVec, sunVec;

varying vec4 color;

// Uniforms
uniform float nightVision;
uniform float rainStrength;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjectionInverse;

uniform sampler2D texture;
uniform sampler2D gaux1;

// Common Variables
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;

// Common Functions

// Includes
#ifdef OVERWORLD
#include "/lib/color/lightColor.glsl"
#endif

// Program
void main()
{
	vec4 albedo;
	
	#ifndef ROUND_SUN_MOON
	vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	albedo = texture2D(texture, texCoord);

	if (dot(sunVec, viewPos.xyz) < 0.0)	albedo.rgb *= 1.6 * sqrt(albedo.rgb) * moonCol / GetLuminance(moonCol);
	else									   albedo.rgb *= 1.6 * Lift(lightCol, 2.0);
	#endif

	#ifdef OVERWORLD
	albedo *= color;
	albedo.rgb = SRGBToLinear(albedo.rgb) * SKYBOX_BRIGHTNESS * albedo.a;

	#ifdef CLOUDS
	if (albedo.a > 0.0)
	{
		float cloudAlpha = texture2D(gaux1, gl_FragCoord.xy / vec2(viewWidth, viewHeight)).r;
		float alphaMult = 1.0 - 0.6 * rainStrength;
		albedo.a *= 1.0 - cloudAlpha / (alphaMult * alphaMult);
	}
	#endif
	
	#ifdef SKY_DESATURATION
	albedo.rgb = mix(vec3(GetLuminance(albedo.rgb)), albedo.rgb, sunVisibility * 0.3 + 0.7);
	#endif
	#endif

	#ifdef END
	albedo.rgb = SRGBToLinear(albedo.rgb) * SKYBOX_BRIGHTNESS * 0.01;
	#endif
	
    /* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}

#endif

// Vertex Shader
#ifdef VSH

// Varyings
varying vec2 texCoord;

varying vec3 sunVec, upVec;

varying vec4 color;

// Uniforms
uniform float timeAngle;

uniform mat4 gbufferModelView;

#if AA == 2
uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

#include "/lib/vertex/jitter.glsl"
#endif

// Program
void main()
{
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	color = gl_Color;

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * PI) * -0.5 + 0.5 - ang) / 3.0) * TAU;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	upVec = normalize(gbufferModelView[1].xyz);
	gl_Position = ftransform();
	
	#if AA == 2
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w, cameraPosition, previousCameraPosition);
	#endif
}

#endif