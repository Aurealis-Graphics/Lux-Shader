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

varying vec3 sunVec, upVec;

//Uniforms//
uniform int frameCounter;
uniform int isEyeInWater;

uniform float blindFactor, nightVision;
uniform float far, near;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight, aspectRatio;
uniform float worldTime;

uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjection, gbufferPreviousProjection, gbufferProjectionInverse;
uniform mat4 gbufferModelView, gbufferPreviousModelView, gbufferModelViewInverse;

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D depthtex2;

#if defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR
uniform vec3 cameraPosition, previousCameraPosition;

uniform sampler2D colortex3;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D noisetex;
#endif

//Optifine Constants//
#if defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR
const bool colortex0MipmapEnabled = true;
const bool colortex5MipmapEnabled = true;
const bool colortex6MipmapEnabled = true;
#endif

//Common Variables//
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility  = clamp(dot( sunVec,upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec,upVec) + 0.05, 0.0, 0.1) * 10.0;

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

//Common Functions//
float GetLuminance(vec3 color){
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float GetLinearDepth(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

float InterleavedGradientNoise(){
	float n = 52.9829189 * fract(0.06711056 * gl_FragCoord.x + 0.00583715 * gl_FragCoord.y);
	return fract(n + frameCounter / 8.0);
}

//Includes//
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/color/blocklightColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/atmospherics/fog.glsl"

#ifdef AO
#include "/lib/lighting/ambientOcclusion.glsl"
#endif

#ifdef BLACK_OUTLINE
#include "/lib/atmospherics/waterFog.glsl"
#include "/lib/outline/blackOutline.glsl"
#endif

#ifdef PROMO_OUTLINE
#include "/lib/outline/promoOutline.glsl"
#endif

#if defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR
#include "/lib/util/encode.glsl"
#include "/lib/reflections/raytrace.glsl"
#include "/lib/reflections/complexFresnel.glsl"
#include "/lib/surface/materialDeferred.glsl"
#include "/lib/reflections/roughReflections.glsl"
#ifdef OVERWORLD
#include "/lib/atmospherics/clouds.glsl"
#include "/lib/atmospherics/sky.glsl"
#ifdef AURORA
#include "/lib/atmospherics/aurora.glsl"
#endif
#endif
#endif

//Program//
void main()
{
	float z	    = texture2D(depthtex0, texCoord).r;
	vec4 color = texture2D(colortex0, texCoord);	

	float dither = Bayer64(gl_FragCoord.xy);
	
	vec4 screenPos = vec4(texCoord, z, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	if (z < 1.0){
		#if defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR
		float smoothness = 0.0, metalness = 0.0, f0 = 0.0, skymapMod = 0.0;
		vec3 normal = vec3(0.0), rawAlbedo = vec3(0.0);

		GetMaterials(smoothness, metalness, f0, skymapMod, normal, rawAlbedo, texCoord);
		smoothness *= smoothness;

		float fresnel = pow(clamp(1.0 + dot(normal, normalize(viewPos.xyz)), 0.0, 1.0), 5.0);
		#if MATERIAL_FORMAT == 0
		vec3 fresnel3 = mix(mix(vec3(f0), rawAlbedo, metalness), vec3(1.0), fresnel);
		if (f0 >= 0.9 && f0 < 1.0) fresnel3 = ComplexFresnel(fresnel, f0);
		#else
		vec3 fresnel3 = mix(mix(vec3(0.02), rawAlbedo, metalness), vec3(1.0), fresnel);
		#endif
		fresnel3 *= smoothness;

		if (length(fresnel3) > 0.0025){
			vec4 reflection = vec4(0.0);
			vec3 skyReflection = vec3(0.0);
			
			reflection = RoughReflection(viewPos.xyz, normal, dither, smoothness);

			if (reflection.a < 1.0){
				#ifdef OVERWORLD
				vec3 skyRefPos = reflect(normalize(viewPos.xyz), normal);
				skyReflection = GetSkyColor(skyRefPos, lightCol);
				
				#ifdef REFLECTION_ROUGH
				float cloudMixRate = smoothness * smoothness * (3.0 - 2.0 * smoothness);
				#else
				float cloudMixRate = 1.0;
				#endif

				#ifdef AURORA
				vec4 aurora = DrawAurora(skyRefPos * 100.0, dither, vec3(1.0), vec3(1.0), 6);
				skyReflection = mix(skyReflection, aurora.rgb, aurora.a);
				#endif

				#ifdef CLOUDS
				vec4 cloud = DrawCloud(skyRefPos * 100.0, dither, lightCol, ambientCol);
				skyReflection = mix(skyReflection, cloud.rgb, cloud.a * cloudMixRate);
				#endif

				float quarterNdotU = clamp(0.25 * dot(normal, upVec) + 0.75, 0.5, 1.0);
				quarterNdotU *= quarterNdotU;

				skyReflection = mix(
					quarterNdotU * vec3(0.001),
					skyReflection * (4.0 - 3.0 * eBS),
					skymapMod
				);
				#endif
				#ifdef NETHER
				skyReflection = netherCol.rgb * 0.04;
				#endif
				#ifdef END
				skyReflection = endCol.rgb * 0.025;
				#endif
			}

			reflection.rgb = max(mix(skyReflection, reflection.rgb, reflection.a), vec3(0.0));
			
			color.rgb = color.rgb * (1.0 - fresnel3 * (1.0 - metalness)) +
						reflection.rgb * fresnel3;
		}
		#endif

		#ifdef AO
		color.rgb *= AmbientOcclusion(depthtex0, dither);
		#endif

		#ifdef PROMO_OUTLINE
		PromoOutline(color.rgb, depthtex0);
		#endif

		#ifdef FOG
		Fog(color.rgb, viewPos.xyz);
		#endif
	}else{
		#ifdef NETHER
		color.rgb = netherCol.rgb * 0.04;
		#endif
		#if defined END && !defined LIGHT_SHAFT
		color.rgb+= endCol.rgb * 0.025;
		#endif

		if (isEyeInWater == 2){
			#ifdef EMISSIVE_RECOLOR
			color.rgb = pow(blocklightCol / BLOCKLIGHT_I, vec3(4.0)) * 2.0;
			#else
			color.rgb = vec3(1.0, 0.3, 0.01);
			#endif
		}

		if (blindFactor > 0.0) color.rgb *= 1.0 - blindFactor;
	}

	#ifdef BLACK_OUTLINE
	float wFogMult = 1.0 + eBS;
	BlackOutline(color.rgb, depthtex0, wFogMult);
	#endif
    
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = color;
	#ifndef REFLECTION_PREVIOUS
	/*DRAWBUFFERS:05*/
	gl_FragData[1] = vec4(pow(color.rgb, vec3(0.125)) * 0.5, float(z < 1.0));
	#endif
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord;

varying vec3 sunVec, upVec;

//Uniforms//
uniform float timeAngle;
uniform mat4 gbufferModelView;

//Program//
void main(){
	texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
}

#endif
