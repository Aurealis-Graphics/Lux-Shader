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

// Extensions

// Varyings
varying float mat, recolor;

varying vec2 texCoord, lmCoord;

varying vec3 normal;
varying vec3 sunVec, upVec;

varying vec4 color;

#ifdef MATERIAL_SUPPORT
varying float dist;

varying vec3 binormal, tangent;
varying vec3 viewVector;

varying vec4 vTexCoord, vTexCoordAM;
#endif

// Uniforms
uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;

#ifdef DYNAMIC_HANDLIGHT
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
#endif

uniform float frameTimeCounter;
uniform float nightVision;
uniform float rainStrength;
uniform float screenBrightness; 
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform sampler2D texture;

#ifdef MATERIAL_SUPPORT
uniform sampler2D specular;
uniform sampler2D normals;

#ifdef REFLECTION_RAIN
uniform float wetness;

uniform mat4 gbufferModelView;
#endif
#endif

#if AA == 2
uniform vec3 previousCameraPosition;
#endif

#if AA == 2 || (defined(MATERIAL_SUPPORT) && defined(REFLECTION_RAIN)) || defined(DYNAMIC_HANDLIGHT)
uniform vec3 cameraPosition;
#endif

#if (defined(MATERIAL_SUPPORT) && defined(REFLECTION_RAIN))
uniform sampler2D noisetex;
#endif

// Common Variables
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility  = clamp(dot( sunVec,upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec,upVec) + 0.05, 0.0, 0.1) * 10.0;

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

#ifdef MATERIAL_SUPPORT
vec2 dcdx = dFdx(texCoord);
vec2 dcdy = dFdy(texCoord);
#endif

vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

// Common Functions

// Includes
#include "/lib/color/blocklightColor.glsl"
#include "/lib/color/dimensionColor.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/lighting/forwardLighting.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/color/ambientColor.glsl"

#if AA == 2
#include "/lib/vertex/jitter.glsl"
#endif

#ifdef MATERIAL_SUPPORT
#include "/lib/util/encode.glsl"
#include "/lib/surface/directionalLightmap.glsl"
#include "/lib/surface/ggx.glsl"
#include "/lib/surface/materialGbuffers.glsl"
#include "/lib/surface/parallax.glsl"

#ifdef REFLECTION_RAIN
#include "/lib/reflections/rainPuddles.glsl"
#endif
#endif

// Program
void main()
{
    vec4 albedo = texture2D(texture, texCoord) * vec4(color.rgb, 1.0);
	vec3 newNormal = normal;

	#ifdef MATERIAL_SUPPORT
	vec2 newCoord = vTexCoord.st * vTexCoordAM.pq + vTexCoordAM.st;
	float parallaxFade = Saturate((dist - PARALLAX_DISTANCE) / 32.0);
	float skipAdvMat = float(mat > 2.98 && mat < 3.02);
	
	#ifdef PARALLAX
	if(skipAdvMat < 0.5)
	{
		newCoord = GetParallaxCoord(parallaxFade);
		albedo = texture2DGradARB(texture, newCoord, dcdx, dcdy) * vec4(color.rgb, 1.0);
	}
	#endif

	float smoothness = 0.0, metalData = 0.0, skymapMod = 0.0;
	vec3 rawAlbedo = vec3(0.0);
	#endif

	if (albedo.a > 0.001)
	{
		vec2 lightmap = Saturate(lmCoord);
		
		float foliage  = float(mat > 0.98 && mat < 1.02);
		float emissiveIntensity = 0.5 * EMISSIVE_BRIGHTNESS;
		float emissive = float(mat > 1.98 && mat < 2.02) * emissiveIntensity;
		if (mat > 3.98 && mat < 4.02) emissive = 0.25 * emissiveIntensity;
		float lava     = float(mat > 2.98 && mat < 3.02) * emissiveIntensity;

		#ifdef GLOWING_ORES
		if (mat > 4.98 && mat < 5.02) emissive = emissiveIntensity * 1.5 * smoothstep(0.0, 0.4, MaxOf(albedo.rgb) - MinOf(albedo.rgb));
		#endif

		#ifndef SHADOW_SUBSURFACE
		foliage = 0.0;
		#endif

		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		#if AA == 2
		vec3 viewPos = ToNDC(vec3(TAAJitter(screenPos.xy, -0.5, cameraPosition, previousCameraPosition), screenPos.z));
		#else
		vec3 viewPos = ToNDC(screenPos);
		#endif
		vec3 worldPos = ToWorld(viewPos);

		#ifdef DYNAMIC_HANDLIGHT
		float maxIntensity	= max(float(heldBlockLightValue), float(heldBlockLightValue2));
		if (maxIntensity > EPS)
		{
			float handheldDist	= distance(worldPos.xyz, vec3(0.0));
			float scaleFactor	= 2.828 / (maxIntensity + 0.5);
			float attenuation	= (maxIntensity / 15.0) * (1.0 / (Pow2(scaleFactor * handheldDist) + 1.0));

			lightmap.x = SmoothMax(lightmap.x, attenuation, 0.08);
		}
		#endif

		#ifdef MATERIAL_SUPPORT
		float metalness = 0.0, f0 = 0.0, ao = 1.0;
		vec3 normalMap = vec3(0.0, 0.0, 1.0);
		GetMaterials(smoothness, metalness, f0, metalData, emissive, ao, normalMap, newCoord, dcdx, dcdy);
		
		mat3 tbnMatrix = mat3(
			tangent.x, binormal.x, normal.x,
			tangent.y, binormal.y, normal.y,
			tangent.z, binormal.z, normal.z
		);

		if (normalMap.x > -0.999 && normalMap.y > -0.999)
			newNormal = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
		#endif

		albedo.rgb = SRGBToLinear(albedo.rgb);

		float ec = GetLuminance(albedo.rgb) * 1.7;

		if (recolor > 0.5) albedo.rgb *= ec * 0.25 + 0.5;

		#ifdef WHITE_WORLD
		albedo.rgb = vec3(0.5);
		#endif

		float NdotL = clamp(dot(newNormal, lightVec) * 1.01 - 0.01, 0.0, 1.0);
		bool isBackface = dot(normal, lightVec) < -0.0001;
		float quarterNdotU = clamp(0.25 * dot(newNormal, upVec) + 0.75, 0.5, 1.0);
		float parallaxShadow = 1.0;

		#ifdef MATERIAL_SUPPORT
		rawAlbedo = albedo.rgb * 0.999 + 0.001;
		albedo.rgb *= ao;

		#ifdef REFLECTION_SPECULAR
		float roughnessSqr = (1.0 - smoothness) * (1.0 - smoothness);
		albedo.rgb *= (1.0 - metalness * (1.0 - roughnessSqr));
		#endif

		float doParallax = 0.0;

		#ifdef SELF_SHADOW
		#ifdef OVERWORLD
		doParallax = float(lightmap.y > 0.0 && NdotL > 0.0);
		#endif
		#ifdef END
		doParallax = float(NdotL > 0.0);
		#endif
		
		if (doParallax > 0.5 && skipAdvMat < 0.5)
		{
			parallaxShadow = GetParallaxShadow(parallaxFade, newCoord, lightVec, tbnMatrix);
		}
		#endif

		#ifdef DIRECTIONAL_LIGHTMAP
		mat3 lightmapTBN = GetLightmapTBN(viewPos);
		lightmap.x = DirectionalLightmap(lightmap.x, lmCoord.x, newNormal, lightmapTBN);
		lightmap.y = DirectionalLightmap(lightmap.y, lmCoord.y, newNormal, lightmapTBN);
		#endif
		#endif

		vec3 shadow = vec3(0.0);

		#ifdef OVERWORLD
		vec3 skyEnvAmbientApprox = GetAmbientColor(newNormal, lightCol);
		#else
		vec3 skyEnvAmbientApprox = vec3(0.0);
		#endif

		quarterNdotU *= quarterNdotU * (foliage > 0.5 ? 1.5 : 1.0);

		GetLighting(albedo.rgb, shadow, viewPos, worldPos, lightmap, color.a, NdotL, quarterNdotU, parallaxShadow, emissive + lava, foliage, skyEnvAmbientApprox);

		#ifdef MATERIAL_SUPPORT
		float puddles = 0.0;
		#if defined REFLECTION_RAIN && defined OVERWORLD
		float NdotU = clamp(dot(newNormal, upVec), 0.0, 1.0);

		#if REFLECTION_RAIN_TYPE == 0
		puddles = GetPuddles(worldPos) * NdotU * wetness;
		#else
		puddles = NdotU * wetness;
		#endif
		
		#ifdef WEATHER_PERBIOME
		float weatherweight = isCold + isDesert + isMesa + isSavanna;
		puddles *= 1.0 - weatherweight;
		#endif
		
		puddles *= Saturate(lightmap.y * 32.0 - 31.0);
		smoothness = mix(smoothness, 1.0, puddles);
		f0 = max(f0, puddles * 0.02);
		albedo.rgb *= 1.0 - puddles * 0.15;

		if (puddles > 0.001 && rainStrength > 0.001)
		{
			mat3 tbnMatrix = mat3(
				tangent.x, binormal.x, normal.x,
				tangent.y, binormal.y, normal.y,
				tangent.z, binormal.z, normal.z
			);

			vec3 puddleNormal = GetPuddleNormal(worldPos, viewPos, tbnMatrix);
			newNormal = normalize(mix(newNormal, puddleNormal, puddles * rainStrength));
		}
		#endif

		skymapMod = Smooth3(lightmap.y);

		#if defined OVERWORLD || defined END
		#ifdef OVERWORLD
		vec3 specularColor = lightCol;		
		#endif

		#ifdef END
		vec3 specularColor = endCol.rgb;
		#endif
		
		if (!isBackface)
			albedo.rgb += GetSpecularHighlight(smoothness, metalness, f0, specularColor, rawAlbedo, shadow, newNormal, viewPos);
		#endif
		
		#if defined REFLECTION_SPECULAR && defined REFLECTION_ROUGH
		if (normalMap.x > -0.999 && normalMap.y > -0.999)
		{
			normalMap = mix(vec3(0.0, 0.0, 1.0), normalMap, smoothness);
			newNormal = mix(normalMap * tbnMatrix, newNormal, 1.0 - Pow4(1.0 - puddles));
			newNormal = clamp(normalize(newNormal), vec3(-1.0), vec3(1.0));
		}
		#endif
		#endif

	}
	else
	{
		albedo.a = 0.0;
	}

    /* DRAWBUFFERS:0 */
    gl_FragData[0] = albedo;

	#if defined MATERIAL_SUPPORT && defined REFLECTION_SPECULAR
	/* DRAWBUFFERS:0367 */
	gl_FragData[1] = vec4(smoothness, metalData, skymapMod, 1.0);
	gl_FragData[2] = vec4(EncodeNormal(newNormal), float(gl_FragCoord.z < 1.0), 1.0);
	gl_FragData[3] = vec4(rawAlbedo, 1.0);
	#endif
}

#endif

// Vertex Shader
#ifdef VSH

// Varyings
varying float mat, recolor;

varying vec2 texCoord, lmCoord;

varying vec3 normal;
varying vec3 sunVec, upVec;

varying vec4 color;

#ifdef MATERIAL_SUPPORT
varying float dist;

varying vec3 binormal, tangent;
varying vec3 viewVector;

varying vec4 vTexCoord, vTexCoordAM;

#endif

// Uniforms
uniform int worldTime;

uniform float frameTimeCounter;
uniform float timeAngle;
uniform float rainStrength;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView, gbufferModelViewInverse;

#if AA == 2
uniform int frameCounter;

uniform float viewWidth, viewHeight;
#endif

// Attributes
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

#ifdef MATERIAL_SUPPORT
attribute vec4 at_tangent;
#endif

// Common Variables
#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

// Includes
#include "/lib/vertex/waving.glsl"

#if AA == 2
uniform vec3 previousCameraPosition;

#include "/lib/vertex/jitter.glsl"
#endif

#ifdef WORLD_CURVATURE
#include "/lib/vertex/worldCurvature.glsl"
#endif

// Program
void main()
{
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = Saturate((lmCoord - 0.03125) * 1.06667);
	normal = normalize(gl_NormalMatrix * gl_Normal);
	color = gl_Color;

	#ifdef MATERIAL_SUPPORT
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	
	mat3 tbnMatrix = mat3(
		tangent.x, binormal.x, normal.x,
		tangent.y, binormal.y, normal.y,
		tangent.z, binormal.z, normal.z
	);
								  
	viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;
	dist = length(gl_ModelViewMatrix * gl_Vertex);

	vec2 midCoord = (gl_TextureMatrix[0] *  mc_midTexCoord).st;
	vec2 texMinMidCoord = texCoord - midCoord;

	vTexCoordAM.pq  = abs(texMinMidCoord) * 2;
	vTexCoordAM.st  = min(texCoord, midCoord - texMinMidCoord);
	vTexCoord.xy    = sign(texMinMidCoord) * 0.5 + 0.5;
	#endif
	
	mat = 0.0; recolor = 0.0;

	if (mc_Entity.x == 10100 || 
		mc_Entity.x == 10101 || 
		mc_Entity.x == 10102 || 
		mc_Entity.x == 10103 ||
	    mc_Entity.x == 10104 || 
		mc_Entity.x == 10105 || 
		mc_Entity.x == 10106 || 
		mc_Entity.x == 10107 ||
	    mc_Entity.x == 10108 || 
		mc_Entity.x == 10109 ||
		mc_Entity.x == 10110) 
	{
		mat = 1.0;
	}
		
	if (mc_Entity.x == 10200 ||
		mc_Entity.x == 10207 ||
		mc_Entity.x == 10210 ||
		mc_Entity.x == 10214 ||
		mc_Entity.x == 10215 || 
		mc_Entity.x == 10216 || 
		mc_Entity.x == 10226 || 
		mc_Entity.x == 10231 ||
		mc_Entity.x == 10249 || 
		mc_Entity.x == 10250 || 
		mc_Entity.x == 10251 || 
		mc_Entity.x == 10252 ||
		mc_Entity.x == 10253)
	{
		mat = 2.0;
	}

	if (mc_Entity.x == 10254)
	{
		mat = 4.0;
	}

	if (mc_Entity.x == 10248) 
	{
		mat = 3.0;
	}

	if (mc_Entity.x == 10402) 
	{
		mat = 5.0;
	}

	if (mc_Entity.x == 10216 ||
		mc_Entity.x == 10226 ||
		mc_Entity.x == 10231 || 
		mc_Entity.x == 10250 ||
		mc_Entity.x == 10251 || 
		mc_Entity.x == 10253 ||
		mc_Entity.x == 10254) 
	{
		recolor = 1.0;	
	}

	if (mc_Entity.x == 10215 ||
		mc_Entity.x == 10231 || 
		mc_Entity.x == 10248 || 
		mc_Entity.x == 10249 ||
		mc_Entity.x == 10251)
	{
		lmCoord.x = 1.0;
	}
	
	if (mc_Entity.x == 10245)
	{
		lmCoord.x -= 0.0667;
	}

	if (mc_Entity.x == 10400)
	{
		color.a = 1;
	}

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * PI) * -0.5 + 0.5 - ang) / 3.0) * TAU;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	upVec = normalize(gbufferModelView[1].xyz);

	float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;

	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
	position.xyz = WavingBlocks(position.xyz, istopv, lmCoord.y, sunVisibility, rainStrength);

    #ifdef WORLD_CURVATURE
	position.y -= WorldCurvature(position.xz);
    #endif

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	
	#if AA == 2
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w, cameraPosition, previousCameraPosition);
	#endif
}

#endif