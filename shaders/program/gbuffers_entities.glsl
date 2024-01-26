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
uniform int entityId;
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

uniform vec4 entityColor;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform sampler2D texture;

#ifdef MATERIAL_SUPPORT
uniform sampler2D specular;
uniform sampler2D normals;
#endif

#if AA == 2 || defined(DYNAMIC_HANDLIGHT)
uniform vec3 cameraPosition;
#if AA == 2
uniform vec3 previousCameraPosition;
#endif
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
#include "/lib/surface/ggx.glsl"
#include "/lib/surface/materialGbuffers.glsl"
#include "/lib/surface/parallax.glsl"
#endif

#if MC_VERSION >= 11500 && defined TEMPORARY_FIX
#undef PARALLAX
#undef SELF_SHADOW
#endif

// Program
void main()
{
    vec4 albedo = texture2D(texture, texCoord) * color;
	vec3 newNormal = normal;

	#ifdef MATERIAL_SUPPORT
	vec2 newCoord = vTexCoord.st * vTexCoordAM.pq + vTexCoordAM.st;
	float parallaxFade = Saturate((dist - PARALLAX_DISTANCE) / 32.0);
	float skipAdvMat = float(entityId == 10100);
	
	#ifdef PARALLAX
	if (skipAdvMat < 0.5)
	{
		newCoord = GetParallaxCoord(parallaxFade);
		albedo = texture2DGradARB(texture, newCoord, dcdx, dcdy) * color;
	}
	#endif

	float smoothness = 0.0, metalData = 0.0, skymapMod = 0.0;
	vec3 rawAlbedo = vec3(0.0);
	#endif

	albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
	
	float lightningBolt = float(entityId == 10101);
	if(lightningBolt > 0.5)
	{
		#ifdef OVERWORLD
		albedo.rgb = Pow3(weatherCol.rgb / weatherCol.a);
		#endif
		#ifdef NETHER
		albedo.rgb = sqrt(netherCol.rgb / netherCol.a);
		#endif
		#ifdef END
		albedo.rgb = endCol.rgb / endCol.a;
		#endif
		albedo.a = 1.0;
	}

	if (albedo.a > 0.001 && lightningBolt < 0.5)
	{
		vec2 lightmap = Saturate(lmCoord);
			  
		float emissive = float(entityColor.a > 0.05) * 0.05;

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
					 
		#if MC_VERSION >= 11500 && defined TEMPORARY_FIX
		normalMap = vec3(0.0, 0.0, 1.0);
		#endif
		
		mat3 tbnMatrix = mat3(
			tangent.x, binormal.x, normal.x,
			tangent.y, binormal.y, normal.y,
			tangent.z, binormal.z, normal.z
		);

		if (normalMap.x > -0.999 && normalMap.y > -0.999 && skipAdvMat < 0.5)
			newNormal = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
		#endif
		
		albedo.rgb = SRGBToLinear(albedo.rgb);

		#ifdef WHITE_WORLD
		albedo.rgb = vec3(0.5);
		#endif
		
		float NdotL = clamp(dot(newNormal, lightVec) * 1.01 - 0.01, 0.0, 1.0);
		bool isBackface = dot(normal, lightVec) < -0.0001;
		float quarterNdotU = clamp(0.25 * dot(newNormal, upVec) + 0.75, 0.5, 1.0);
		quarterNdotU *= quarterNdotU;

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
		
		if (doParallax > 0.5)
		{
			parallaxShadow = GetParallaxShadow(parallaxFade, newCoord, lightVec, tbnMatrix);
			NdotL *= parallaxShadow;
		}
		#endif
		#endif
		
		vec3 shadow = vec3(0.0);
		
		#ifdef OVERWORLD
		vec3 skyEnvAmbientApprox = GetAmbientColor(newNormal, lightCol);
		#else
		vec3 skyEnvAmbientApprox = vec3(0.0);
		#endif

		GetLighting(albedo.rgb, shadow, viewPos, worldPos, lightmap, 1.0, NdotL, quarterNdotU, parallaxShadow, emissive, 0.0, skyEnvAmbientApprox);

		#ifdef MATERIAL_SUPPORT
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
		normalMap = mix(vec3(0.0, 0.0, 1.0), normalMap, smoothness);
		newNormal = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
		#endif
		#endif
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

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView, gbufferModelViewInverse;

#if AA == 2
uniform int frameCounter;

uniform float viewWidth, viewHeight;

uniform vec3 previousCameraPosition;
#endif

// Attributes
attribute vec4 mc_Entity;

#ifdef MATERIAL_SUPPORT
attribute vec4 mc_midTexCoord;
attribute vec4 at_tangent;
#endif

// Common Variables
#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

// Includes
#if AA == 2
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
	tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	
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

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * PI) * -0.5 + 0.5 - ang) / 3.0) * TAU;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	upVec = normalize(gbufferModelView[1].xyz);

    #ifdef WORLD_CURVATURE
	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	position.y -= WorldCurvature(position.xz);
	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	#else
	gl_Position = ftransform();
    #endif
	
	#if AA == 2
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w, cameraPosition, previousCameraPosition);
	#endif
}

#endif