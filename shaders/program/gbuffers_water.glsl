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
varying float mat;
varying float dist;

varying vec2 texCoord, lmCoord;

varying vec3 normal, binormal, tangent;
varying vec3 sunVec, upVec;
varying vec3 viewVector;

varying vec4 color;

#ifdef MATERIAL_SUPPORT
varying vec4 vTexCoord, vTexCoordAM;
#endif

// Uniforms
uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;
uniform int worldDay;

uniform float blindFactor, nightVision;
uniform float far, near;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float screenBrightness;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition, previousCameraPosition;

uniform mat4 gbufferProjection, gbufferPreviousProjection, gbufferProjectionInverse;
uniform mat4 gbufferModelView, gbufferPreviousModelView, gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform sampler2D texture;
uniform sampler2D gaux2;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;

#ifdef MATERIAL_SUPPORT
uniform sampler2D specular;
uniform sampler2D normals;

#ifdef REFLECTION_RAIN
uniform float wetness;
#endif
#endif

// Optifine Constants
#ifdef MATERIAL_SUPPORT
const bool gaux2MipmapEnabled = true;
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
float GetWaveLayer(vec2 coord, float wavelength, vec2 direction, float speed) 
{
    float k = TAU / wavelength;
	float x = k * dot(normalize(direction), coord.xy) - frameTimeCounter * 3.0 * speed;
    return sin(x + cos(x) * 0.8) / k;
}

float ComputeWaterWaves(
	in vec2 planeCoord,
	in float mult,
	in float waveSpeed,
	in float gWaveLength,
	in float gWaveLacunarity,
	in float gWavePersistance,
	in float gWaveAmplitude,
	in float gWaveDirSpread,
	in int gWaveIterations,
	in float noiseScale,
	in float noiseLacunarity,
	in float noiseAmplitude,
	in float noisePersistance,
	in int noiseIterations
)
{
	float noise;

	for (int i = 0; i < gWaveIterations; i++) 
	{
		vec2 direction = vec2(Hash11(float(i)), Hash11(-float(i))) * 2.0 - 1.0;
		direction = mix(vec2(1.0), direction, gWaveDirSpread);
		noise += GetWaveLayer(planeCoord * 8.4, gWaveLength, direction, waveSpeed) * gWaveAmplitude;
		gWaveLength *= gWaveLacunarity;
		gWaveAmplitude *= gWavePersistance;
	}
	noise *= gWaveAmplitude;

	for (int i = 0; i < noiseIterations; i++) 
	{
		float wind = frameTimeCounter * waveSpeed * 0.7 * (float(fract(i / 2.0) == 0.0) * 2.0 - 1.0);
		noise += texture2D(noisetex, (planeCoord + wind) * noiseScale).r * noiseAmplitude;
		noiseScale *= noiseLacunarity;
		noiseAmplitude *= noisePersistance;
	}

	return noise * Pow2(mult);
}

float GetWaterHeightMap(vec3 worldPos, vec3 viewPos)
{
    float noise = 0.0;
    float mult = Saturate(-dot(normalize(normal), normalize(viewPos)) * 8.0) / pow(max(dist, 4.0), 0.25);
    // vec2 wind = vec2(frametime) * 0.35;

    if (mult > 0.01)
	{
        #if WATER_NORMALS == 1

		noise += ComputeWaterWaves(
			worldPos.xz,
			mult,
			1.0,		// WAVE_SPEED
			16.0,		// GERSTNER_WAVE_LENGTH
			1.4,		// GERSTNER_WAVE_LACUNARITY
			0.93,		// GERSTNER_WAVE_PERSISTANCE
			0.34,		// GERSTNER_WAVE_AMPLITUDE
			0.42,		// GERSTNER_WAVE_DIR_SPREAD
			5,			// GERSTNER_WAVE_ITERATIONS
			0.007,		// NOISE_WAVE_SCALE
			0.7,		// NOISE_WAVE_LACUNARITY
			0.45,		// NOISE_WAVE_AMPLITUDE
			0.75,		// NOISE_WAVE_PERSISTANCE
			4			// NOISE_WAVE_ITERATIONS
		);

		#elif WATER_NORMALS == 2

		noise += ComputeWaterWaves(
			worldPos.xz,
			mult,
			WAVE_SPEED,
			GERSTNER_WAVE_LENGTH,
			GERSTNER_WAVE_LACUNARITY,
			GERSTNER_WAVE_PERSISTANCE,
			GERSTNER_WAVE_AMPLITUDE,
			GERSTNER_WAVE_DIR_SPREAD,
			GERSTNER_WAVE_ITERATIONS,
			NOISE_WAVE_SCALE,
			NOISE_WAVE_LACUNARITY,
			NOISE_WAVE_AMPLITUDE,
			NOISE_WAVE_PERSISTANCE,
			NOISE_WAVE_ITERATIONS
		);

		#endif
    }

    return noise;
}

vec3 GetParallaxWaves(vec3 worldPos, vec3 viewPos, vec3 viewVector)
{
	vec3 parallaxPos = worldPos;

	for (int i = 0; i < 4; i++)
	{
		float height = (GetWaterHeightMap(parallaxPos, viewPos) - 0.5) * 0.24;
		parallaxPos.xz += height * viewVector.xy / dist;
	}
	return parallaxPos;
}

vec3 GetWaterNormal(vec3 worldPos, vec3 viewPos, vec3 viewVector)
{
	vec3 waterPos = worldPos + cameraPosition;
	
    #ifdef WATER_PARALLAX
	waterPos = GetParallaxWaves(waterPos, viewPos, viewVector);
	#endif

    float h1 = GetWaterHeightMap(waterPos + vec3( 0.1, 0.0, 0.0), viewPos);
	float h2 = GetWaterHeightMap(waterPos + vec3(-0.1, 0.0, 0.0), viewPos);
	
    float h3 = GetWaterHeightMap(waterPos + vec3(0.0, 0.0,  0.1), viewPos);
	float h4 = GetWaterHeightMap(waterPos + vec3(0.0, 0.0, -0.1), viewPos);

	float xDelta = (h1 - h2) / 0.1;
	float yDelta = (h3 - h4) / 0.1;

	vec3 normalMap = vec3(xDelta, yDelta, 1.0 - (xDelta * xDelta + yDelta * yDelta));
	return normalMap * 0.03 + vec3(0.0, 0.0, 0.97);
}

// Includes
#if AA == 2
#include "/lib/vertex/jitter.glsl"
#endif

#include "/lib/color/blocklightColor.glsl"
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/surface/ggx.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/reflections/raytrace.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/atmospherics/fog.glsl"
#include "/lib/lighting/forwardLighting.glsl"
#include "/lib/atmospherics/borderFog.glsl"
#include "/lib/reflections/simpleReflections.glsl"
#include "/lib/color/ambientColor.glsl"

#ifdef OVERWORLD
#include "/lib/atmospherics/clouds.glsl"
#ifdef AURORA
#include "/lib/atmospherics/aurora.glsl"
#endif
#endif

#ifdef END
#include "/lib/atmospherics/endSky.glsl"
#endif

#ifdef MATERIAL_SUPPORT
#include "/lib/surface/directionalLightmap.glsl"
#include "/lib/reflections/complexFresnel.glsl"
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

	#ifdef PARALLAX
	newCoord = GetParallaxCoord(parallaxFade);
	albedo = texture2DGradARB(texture, newCoord, dcdx, dcdy) * vec4(color.rgb, 1.0);
	#endif

	float smoothness = 0.0, metalData = 0.0, skymapMod = 0.0;
	vec3 spec = vec3(0.0);
	#endif

	float emissive = 0.0;
	vec3 vlAlbedo = vec3(1.0);

	if (albedo.a > 0.001)
	{
		vec2 lightmap = Saturate(lmCoord);
		
		float water       = float(mat > 0.98 && mat < 1.02);
		float translucent = float(mat > 1.98 && mat < 2.02);

		#ifndef REFLECTION_TRANSLUCENT
		translucent = 0.0;
		#endif

		vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
		#if AA == 2
		vec3 viewPos = ToNDC(vec3(TAAJitter(screenPos.xy, -0.5, cameraPosition, previousCameraPosition), screenPos.z));
		#else
		vec3 viewPos = ToNDC(screenPos);
		#endif
		vec3 worldPos = ToWorld(viewPos);

		float dither = InterleavedGradientNoise(gl_FragCoord.xy);
		vec3 normalMap = vec3(0.0, 0.0, 1.0);
		mat3 tbnMatrix = mat3(
			tangent.x, binormal.x, normal.x,
			tangent.y, binormal.y, normal.y,
			tangent.z, binormal.z, normal.z
		);

		#if WATER_NORMALS == 1 || WATER_NORMALS == 2
		if (water > 0.5)
		{
			normalMap = GetWaterNormal(worldPos, viewPos, viewVector);
			newNormal = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
		}
		#endif


		#ifdef MATERIAL_SUPPORT
		float metalness = 0.0, f0 = 0.0, ao = 1.0;
		if (water < 0.5)
		{
			GetMaterials(smoothness, metalness, f0, metalData, emissive, ao, normalMap, newCoord, dcdx, dcdy);
			if (normalMap.x > -0.999 && normalMap.y > -0.999)
				newNormal = clamp(normalize(normalMap * tbnMatrix), vec3(-1.0), vec3(1.0));
		}
		#endif

		albedo.rgb = SRGBToLinear(albedo.rgb);

		#ifdef WHITE_WORLD
		albedo.rgb = vec3(0.5);
		#endif

		if (water > 0.5)
		{
			#if WATER_MODE == 0
			albedo.rgb = waterColor.rgb * waterColor.a;
			#elif WATER_MODE == 1
			albedo.rgb *= albedo.a;
			#elif WATER_MODE == 2
			float waterLuma = length(albedo.rgb / MaxEPS(SRGBToLinear(color.rgb))) * 2.0;
			albedo.rgb = waterLuma * waterColor.rgb * waterColor.a * albedo.a;
			#endif
			albedo.a = waterAlpha;
		}

		vlAlbedo = mix(vec3(1.0), albedo.rgb, sqrt(albedo.a)) * (1.0 - pow(albedo.a, 64.0));

		float NdotL = clamp(dot(newNormal, lightVec) * 1.01 - 0.01, 0.0, 1.0);
		bool isBackface = dot(normal, lightVec) < -0.0001;
		float quarterNdotU = clamp(0.25 * dot(newNormal, upVec) + 0.75, 0.5, 1.0);
		quarterNdotU *= quarterNdotU;

		float parallaxShadow = 1.0;

		#ifdef MATERIAL_SUPPORT
		vec3 rawAlbedo = albedo.rgb * 0.999 + 0.001;
		albedo.rgb *= ao;

		#ifdef REFLECTION_SPECULAR
		float roughnessSqr = (1.0 - smoothness) * (1.0 - smoothness);
		albedo.rgb *= (1.0 - metalness * (1.0 - roughnessSqr));
		#endif

		#ifdef SELF_SHADOW
		if (lightmap.y > 0.0 && NdotL > 0.0 && water < 0.5)
		{
			parallaxShadow = GetParallaxShadow(parallaxFade, newCoord, lightVec, tbnMatrix);
			NdotL *= parallaxShadow;
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

		GetLighting(albedo.rgb, shadow, viewPos, worldPos, lightmap, color.a, NdotL, quarterNdotU, parallaxShadow, 0.0, 0.0, skyEnvAmbientApprox);

		#ifdef MATERIAL_SUPPORT
		float puddles = 0.0;
		#if defined REFLECTION_RAIN && defined OVERWORLD
		float NdotU = clamp(dot(newNormal, upVec),0.0,1.0);

		if (water < 0.5)
		{
			#if REFLECTION_RAIN_TYPE == 0
			puddles = GetPuddles(worldPos) * NdotU * wetness;
			#else
			puddles = NdotU * wetness;
			#endif
		}

		#ifdef WEATHER_PERBIOME
		float weatherweight = isCold + isDesert + isMesa + isSavanna;
		puddles *= 1.0 - weatherweight;
		#endif

		puddles *= Saturate(lightmap.y * 32.0 - 31.0);
		smoothness = mix(smoothness, 1.0, puddles);
		f0 = max(f0, puddles * 0.02);
		albedo.rgb *= 1.0 - (puddles * 0.15);

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
		#endif

		float fresnel = Pow5(clamp(1.0 + dot(newNormal, normalize(viewPos)), 0.0, 1.0));

		#ifdef OVERWORLD
		vec3 specularColor = lightCol;
		#endif
		
		#ifdef END
		vec3 specularColor = endCol.rgb;
		#endif

		if (water > 0.5 || (translucent > 0.5 && albedo.a < 0.95))
		{
			vec4 reflection = vec4(0.0);
			vec3 skyReflection = vec3(0.0);

			fresnel = fresnel * 0.98 + 0.02;
			fresnel *= max(1.0 - isEyeInWater * 0.5 * water, 0.5);
			fresnel *= 1.0 - translucent * 0.3;

			#ifdef REFLECTION
			reflection = SimpleReflection(viewPos, newNormal, dither, far, cameraPosition, previousCameraPosition);
			reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));
			#endif

			if (reflection.a < 1.0)
			{
				#if defined OVERWORLD || defined END
				vec3 skyRefPos = reflect(normalize(viewPos), newNormal);
				#endif

				#ifdef OVERWORLD
				skyReflection += GetSkyColor(skyRefPos, lightCol);

				float sunSize = 0.025 * sunVisibility + 0.05;

				#ifdef ROUND_SUN_MOON
				sunSize = 0.02;
				#endif

				float specular = GGX(newNormal, normalize(viewPos), lightVec, 1.0, 0.02, sunSize) * 2.0;
				specular *= (1.0 - sqrt(rainStrength)) * shadowFade / 4.5;
				float specularDiv = (4.0 - 3.0 * eBS) * fresnel * albedo.a;

				skyReflection += (specular / specularDiv) * specularColor * shadow;

				#ifdef CLOUDS
				vec4 cloud = DrawCloud(skyRefPos * 100.0, dither, lightCol, skyEnvAmbientApprox);
				skyReflection = mix(skyReflection, cloud.rgb, cloud.a);
				#endif

				#ifdef AURORA
				vec4 aurora = DrawAurora(skyRefPos.xyz * 100.0, dither, AURORA_SAMPLES_REFLECTION);
				skyReflection = mix(skyReflection, aurora.rgb, aurora.a);
				#endif

				skyReflection *= (4.0 - 3.0 * eBS) * lightmap.y;
				#endif

				#ifdef NETHER
				skyReflection = netherCol.rgb * 0.04;
				#endif

				#ifdef END
				skyReflection = endCol.rgb * 0.01;
				skyReflection += GetEndSkyColor(skyRefPos);
				#endif

				skyReflection *= Saturate(1.0 - isEyeInWater);
			}

			reflection.rgb = max(mix(skyReflection, reflection.rgb, reflection.a), vec3(0.0));

			albedo.rgb += reflection.rgb * pow(fresnel, 0.3);
			albedo.a = mix(albedo.a, 1.0, fresnel * fresnel);
		}
		else
		{
			#ifdef MATERIAL_SUPPORT
			skymapMod = Smooth3(lightmap.y);

			#ifdef REFLECTION_SPECULAR
			#if MATERIAL_FORMAT == 0
			vec3 fresnel3 = mix(mix(vec3(f0), rawAlbedo * 0.8, metalness), vec3(1.0), fresnel);
			if (f0 >= 0.9 && f0 < 1.0) fresnel3 = ComplexFresnel(fresnel, f0);
			#else
			vec3 fresnel3 = mix(mix(vec3(0.02), rawAlbedo * 0.8, metalness), vec3(1.0), fresnel);
			#endif
			fresnel3 *= smoothness;

			if (length(fresnel3) > 0.005)
			{
				vec4 reflection = vec4(0.0);
				vec3 skyReflection = vec3(0.0);

				reflection = SimpleReflection(viewPos, newNormal, dither, far, cameraPosition, previousCameraPosition);
				reflection.rgb = pow(reflection.rgb * 2.0, vec3(8.0));

				if (reflection.a < 1.0)
				{
					#if defined OVERWORLD || defined END
					vec3 skyRefPos = reflect(normalize(viewPos.xyz), newNormal);
					#endif

					#ifdef OVERWORLD
					skyReflection = GetSkyColor(skyRefPos, lightCol);

					#ifdef CLOUDS
					vec4 cloud = DrawCloud(skyRefPos * 100.0, dither, lightCol, skyEnvAmbientApprox);
					skyReflection = mix(skyReflection, cloud.rgb, cloud.a);
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
					skyReflection = endCol.rgb * 0.01;
					skyReflection += GetEndSkyColor(skyRefPos);
					#endif
				}

				reflection.rgb = max(mix(skyReflection, reflection.rgb, reflection.a), vec3(0.0));
				albedo.rgb = albedo.rgb * (1.0 - fresnel3 * (1.0 - metalness)) + reflection.rgb * fresnel3;
				albedo.a = mix(albedo.a, 1.0, GetLuminance(fresnel3));
			}
			#endif

			#if defined OVERWORLD || defined END
			if (!isBackface)
				albedo.rgb += GetSpecularHighlight(smoothness, metalness, f0, specularColor, rawAlbedo, shadow, newNormal, viewPos);
			#endif
			#endif
		}

		#ifdef FOG
		#ifdef OVERWORLD
		vec3 skyEnvAmbientApproxFog = GetAmbientColor(vec3(0, 1, 0), lightCol);
		#endif

		#ifdef END
		vec3 skyEnvAmbientApproxFog = endColSqrt.rgb;
		#endif

		#ifdef NETHER
		vec3 skyEnvAmbientApproxFog = netherColSqrt.rgb;
		#endif

		float viewDist = length(viewPos);
		vec3 viewDir = viewPos / viewDist;

		Fog(albedo.rgb, viewDist, viewDir, skyEnvAmbientApproxFog);

		if (isEyeInWater == 1) albedo.a = mix(albedo.a, 1.0, min(viewDist / waterFog, 1.0));
		#endif
	}

    /* DRAWBUFFERS:01 */
    gl_FragData[0] = albedo;
	gl_FragData[1] = vec4(vlAlbedo, 1.0);
}

#endif

// Vertex Shader
#ifdef VSH

// Varyings
varying float mat;
varying float dist;

varying vec2 texCoord, lmCoord;

varying vec3 normal, binormal, tangent;
varying vec3 sunVec, upVec;
varying vec3 viewVector;

varying vec4 color;

#ifdef MATERIAL_SUPPORT
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
attribute vec4 mc_midTexCoord;
attribute vec4 at_tangent;

// Common Variables
#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

// Common Functions
float WavingWater(vec3 worldPos)
{
	float fractY = fract(worldPos.y + cameraPosition.y + 0.005);

	#ifdef WAVING_WATER
	float wave = sin(8.28 * (-frametime * 0.4 + worldPos.x * 0.14 + worldPos.z * 0.07)) +
				 sin(8.28 * (-frametime * 0.3 + worldPos.x * 0.10 + worldPos.z * 0.20));
	if (fractY > 0.01) return wave * 0.025;
	#endif

	return 0.0;
}

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
	normal   = normalize(gl_NormalMatrix * gl_Normal);
	binormal = normalize(gl_NormalMatrix * cross(at_tangent.xyz, gl_Normal.xyz) * at_tangent.w);
	tangent  = normalize(gl_NormalMatrix * at_tangent.xyz);

	mat3 tbnMatrix = mat3(
		tangent.x, binormal.x, normal.x,
		tangent.y, binormal.y, normal.y,
		tangent.z, binormal.z, normal.z
	);

	viewVector = tbnMatrix * (gl_ModelViewMatrix * gl_Vertex).xyz;
	dist = length(gl_ModelViewMatrix * gl_Vertex);

	#ifdef MATERIAL_SUPPORT
	vec2 midCoord = (gl_TextureMatrix[0] *  mc_midTexCoord).st;
	vec2 texMinMidCoord = texCoord - midCoord;

	vTexCoordAM.pq  = abs(texMinMidCoord) * 2;
	vTexCoordAM.st  = min(texCoord, midCoord - texMinMidCoord);
	vTexCoord.xy    = sign(texMinMidCoord) * 0.5 + 0.5;
	#endif

	color = gl_Color + vec4(0.0, 0.0, 0.001, 0.0);
	mat = 0.0;

	if (mc_Entity.x == 10301) mat = 2.0;

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * PI) * -0.5 + 0.5 - ang) / 3.0) * TAU;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	upVec = normalize(gbufferModelView[1].xyz);

	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;
	float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;

	if (mc_Entity.x == 10300)
	{
		position.y += WavingWater(position.xyz);
		mat = 1.0;
	}

    #ifdef WORLD_CURVATURE
	position.y -= WorldCurvature(position.xz);
    #endif

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;
	if (mat == 0.0) gl_Position.z -= 0.00001;

	#if AA == 2
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w, cameraPosition, previousCameraPosition);
	#endif
}

#endif
