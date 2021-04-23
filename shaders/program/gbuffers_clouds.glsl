/* 
BSL Shaders v7.1.05 by Capt Tatsu 
https://bitslablab.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
varying vec2 texCoord;

varying vec3 normal;
varying vec3 sunVec, upVec;

varying vec4 color;

//Uniforms//
uniform int isEyeInWater;
uniform int worldTime;

uniform float rainStrength;
uniform float timeAngle, timeBrightness;

uniform ivec2 eyeBrightnessSmooth;

uniform sampler2D texture;

//Common Variables//
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;

//Includes//
#include "/lib/color/lightColor.glsl"

//Program//
void main(){
	vec4 albedo = texture2D(texture, texCoord);
	albedo.rgb = pow(albedo.rgb,vec3(2.2));
	
	float quarterNdotU = clamp(0.25 * dot(normal, upVec) + 0.75,0.5,1.0);
	albedo.rgb *= lightCol * (quarterNdotU * (0.3 * sunVisibility + 0.2));
	
	albedo.a *= 0.5 * color.a;
	
    /* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;

	#ifdef ADVANCED_MATERIALS
	/* DRAWBUFFERS:0367 */
	gl_FragData[1] = vec4(0.0, 0.0, 0.0, 1.0);
	gl_FragData[2] = vec4(0.0, 0.0, 0.0, 1.0);
	gl_FragData[3] = vec4(0.0, 0.0, 0.0, 1.0);
	#endif
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord;

varying vec3 normal;
varying vec3 sunVec, upVec;

varying vec4 color;

//Uniforms//
#if AA == 2
uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;
#include "/lib/util/jitter.glsl"
#endif

uniform float timeAngle;

uniform mat4 gbufferModelView;

//Program//
void main(){
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	color = gl_Color;

	normal = normalize(gl_NormalMatrix * gl_Normal);
	
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
	
	gl_Position = ftransform();
	
	#if AA == 2
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif