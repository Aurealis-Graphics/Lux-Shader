/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

// Settings
#include "/lib/global.glsl"

// Fragment Shader
#ifdef FSH

// Varyings
varying vec2 texCoord;
varying vec3 sunVec, upVec;

//Uniforms//
uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldDay;

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

#if defined MATERIAL_SUPPORT && defined REFLECTION_SPECULAR
uniform vec3 cameraPosition, previousCameraPosition;

uniform sampler2D colortex3;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;

uniform sampler2D gaux2;
#endif

// Optifine Constants
#if defined MATERIAL_SUPPORT && defined REFLECTION_SPECULAR
const bool colortex0MipmapEnabled = true;
const bool colortex5MipmapEnabled = true;
const bool colortex6MipmapEnabled = true;
#endif

// Common Variables
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility  = clamp(dot( sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

// Common Functions
float GetLinearDepth(float depth)
{
   	return (2.0 * near) / (far + near - depth * (far - near));
}

// Includes
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/color/blocklightColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/atmospherics/fog.glsl"
#include "/lib/color/ambientColor.glsl"
#include "/lib/atmospherics/borderFog.glsl"
#include "/lib/util/spaceConversion.glsl"

#if AA == 2
#include "/lib/vertex/jitter.glsl"
#endif

#ifdef AO
#include "/lib/lighting/ambientOcclusion.glsl"
#endif

#if defined MATERIAL_SUPPORT && defined REFLECTION_SPECULAR
#include "/lib/util/encode.glsl"
#include "/lib/reflections/raytrace.glsl"
#include "/lib/reflections/complexFresnel.glsl"
#include "/lib/surface/materialDeferred.glsl"

#ifdef REFLECTION_ROUGH
#include "/lib/reflections/roughReflections.glsl"
#endif

#include "/lib/reflections/simpleReflections.glsl"

#ifdef OVERWORLD
#include "/lib/atmospherics/clouds.glsl"

#ifdef AURORA
#include "/lib/atmospherics/aurora.glsl"
#endif
#endif
#endif

#ifdef END
#include "/lib/atmospherics/endSky.glsl"
#endif

// Program
void main()
{
	float z	= texture2D(depthtex0, texCoord).r;
	vec4 color = texture2D(colortex0, texCoord);

	float dither = InterleavedGradientNoise(gl_FragCoord.xy);
	
	vec4 screenPos = vec4(texCoord, z, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	#ifdef END
	#if AA == 2
	if (z == 1.0) color.rgb = GetEndSkyColor(ToNDC(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z)));
	#else
	if (z == 1.0) color.rgb = GetEndSkyColor(viewPos.xyz);
	#endif
	#endif

	#ifdef OVERWORLD
	vec3 skyEnvAmbientApprox = GetAmbientColor(vec3(0, 1, 0), lightCol);
	#else
	vec3 skyEnvAmbientApprox = vec3(0.0);
	#endif

	if (z < 1.0)
	{
		#if defined MATERIAL_SUPPORT && defined REFLECTION_SPECULAR
		float smoothness = 0.0, metalness = 0.0, f0 = 0.0, skymapMod = 0.0;
		vec3 normal = vec3(0.0), rawAlbedo = vec3(0.0);

		GetMaterials(smoothness, metalness, f0, skymapMod, normal, rawAlbedo, texCoord);
		smoothness *= smoothness;

		float fresnel = Pow5(clamp(1.0 + dot(normal, normalize(viewPos.xyz)), 0.0, 1.0));
		#if MATERIAL_FORMAT == 0
		vec3 fresnel3 = mix(mix(vec3(f0), rawAlbedo, metalness), vec3(1.0), fresnel);
		if (f0 >= 0.9 && f0 < 1.0) fresnel3 = ComplexFresnel(fresnel, f0);
		#else
		vec3 fresnel3 = mix(mix(vec3(0.02), rawAlbedo, metalness), vec3(1.0), fresnel);
		#endif
		fresnel3 *= smoothness;

		#ifndef FORCE_REFLECTION
		if (GetLuminance(fresnel3) > 1e-3 && Lift(f0, 12.0) * Pow2(smoothness) > 0.05)
		#else
		if (GetLuminance(fresnel3) > 1e-3)
		#endif
		{
			vec4 reflection = vec4(0.0);
			vec3 skyReflection = vec3(0.0);
			
			#ifdef REFLECTION_ROUGH
			if (smoothness != 1.0)
			{
				reflection = RoughReflection(viewPos.xyz, normal, dither, smoothness);
			}
			else
			{
				reflection = SimpleReflection(viewPos.xyz, normal, dither, far, cameraPosition, previousCameraPosition);
				reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));
			}
			
			#else
			reflection = SimpleReflection(viewPos.xyz, normal, dither, far, cameraPosition, previousCameraPosition);
			reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));
			#endif

			if (reflection.a < 1.0)
			{
				#if defined OVERWORLD || defined END
				vec3 skyRefPos = reflect(normalize(viewPos.xyz), normal);
				#endif
				
				#ifdef OVERWORLD
				skyReflection = GetSkyColor(skyRefPos, lightCol);
				
				#ifdef REFLECTION_ROUGH
				float cloudMixRate = Smooth3(smoothness);
				#else
				float cloudMixRate = 1.0;
				#endif

				#ifdef CLOUDS
				vec4 cloud = DrawCloud(skyRefPos * 100.0, dither, lightCol, skyEnvAmbientApprox);
				skyReflection = mix(skyReflection, cloud.rgb, cloud.a * cloudMixRate);
				#endif

				#ifdef AURORA
				vec4 aurora = DrawAurora(skyRefPos * 100.0, dither, AURORA_SAMPLES_REFLECTION);
				skyReflection = mix(skyReflection, aurora.rgb, aurora.a);
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
				skyReflection = GetEndSkyColor(skyRefPos);
				skyReflection += endCol.rgb * 0.01;	// End fog
				#endif
			}

			reflection.rgb = max(mix(skyReflection, reflection.rgb, reflection.a), vec3(0.0));
			color.rgb = color.rgb * (1.0 - fresnel3 * (1.0 - metalness)) + reflection.rgb * fresnel3;
		}
		#endif

		#ifdef AO
		color.rgb *= AmbientOcclusion(depthtex0, dither);
		#endif

		#ifdef FOG
		float viewDist = length(viewPos.xyz);
		vec3 viewDir = viewPos.xyz / viewDist;
		#ifdef OVERWORLD
		Fog(color.rgb, viewDist, viewDir, skyEnvAmbientApprox);
		#else
		Fog(color.rgb, viewDist, viewDir, vec3(0.0));
		#endif
		#endif
	}
	else
	{
		#ifdef NETHER
		color.rgb = netherCol.rgb * 0.04;
		#endif

		if (isEyeInWater == 2) color.rgb = vec3(1.0, 0.3, 0.01);

		if (blindFactor > 0.0) color.rgb *= 1.0 - blindFactor;
	}

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = color;

	#ifndef REFLECTION_PREVIOUS
	/* DRAWBUFFERS:05 */
	gl_FragData[1] = vec4(pow(color.rgb, vec3(0.125)) * 0.5, float(z < 1.0));
	#endif
}

#endif

// Vertex Shader
#ifdef VSH

// Varyings
varying vec2 texCoord;

varying vec3 sunVec, upVec;

// Uniforms
uniform float timeAngle;
uniform mat4 gbufferModelView;

// Program
void main()
{
	texCoord = gl_MultiTexCoord0.xy;
	gl_Position = ftransform();

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * PI) * -0.5 + 0.5 - ang) / 3.0) * TAU;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	upVec = normalize(gbufferModelView[1].xyz);
}

#endif
