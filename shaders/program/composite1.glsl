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

varying vec3 sunVec, upVec;

// Uniforms
uniform int isEyeInWater;
uniform int worldTime;

uniform float blindFactor;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float far;
uniform float near;
uniform float nightVision;

uniform ivec2 eyeBrightnessSmooth;

uniform sampler2D colortex0;
uniform sampler2D colortex1;

#if defined(OVERWORLD) || defined(BORDER_FOG)
uniform sampler2D depthtex0;
#endif

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

// Optifine Constants
const bool colortex1MipmapEnabled = true;

// Common Variables
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.07, 0.0, 0.1) * 10.0;

// Includes
#include "/lib/color/lightColor.glsl"
#include "/lib/color/endColor.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/atmospherics/borderFog.glsl"

// Program
void main()
{
    vec4 color = texture2D(colortex0, texCoord.xy);
	vec3 vl = texture2D(colortex1, texCoord.xy).rgb;

	float vlVisibilityMult = (1.0 - rainStrength * eBS * 0.875) * shadowFade * (1.0 - blindFactor);

	float z0 = texture2D(depthtex0, texCoord).r;
	vec4 screenPos = vec4(texCoord, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	#ifdef OVERWORLD
	float cosS = dot(normalize(viewPos.xyz), sunVec);
	vec3 sky = GetSkyColor(viewPos.xyz, lightCol);
	sky *= (4.0 - 3.0 * eBS) * (1.0 + nightVision);

	float globalMult = Pow2((1.0 - Max0(sunHeight)) * min(1.0, sunHeight * 5.0));
	
	float vlVisibilitySun = Max0(cosS * 0.5 + 0.5);
	vlVisibilitySun *= globalMult;
	vlVisibilitySun = Lift(vlVisibilitySun, 5.0);
	vlVisibilitySun *= 0.12;

	vec3 vlSun = Pow4(vl * vlVisibilitySun);

	#if VOLUMETRIC_FOG_TYPE == 0
	vlSun *= lightCol;
	#elif VOLUMETRIC_FOG_TYPE == 1
	vlSun *= sky;
	#endif

	color.rgb += vlSun * vlVisibilityMult * VOLUMETRIC_FOG_STRENGTH;

	const float fogEnd = 0.5 / VOLUMETRIC_FOG_STRENGTH;
	float distVar = 1.0 - exp2(-length(viewPos.xyz) * 0.00015);
	float vlVisibilityFog = distVar / fogEnd * exp2(distVar - fogEnd);
	vlVisibilityFog *= (1.0 + (1.0 - sunHeight + moonHeight * 8.0) * 0.5) * (1.0 + Max0(cosS * cosS * cosS * 0.025)) * 0.5;
	
	vec3 vlFog = vl * vlVisibilityFog * vlVisibilityMult;

	color.rgb = mix(color.rgb, sky, min(vlFog, 0.8));

	#endif

	#ifdef END
	const float fogEnd = 0.7 / VOLUMETRIC_FOG_STRENGTH;
	float distVar = 1.0 - exp2(-length(viewPos.xyz) * 0.00015);
	float vlVisibilityFog = min(distVar / fogEnd * exp2(distVar - fogEnd) * (float(z0 != 1.0) * 0.99 + 0.01), 0.001);

    vl *= endCol.rgb * vlVisibilityFog;
	color.rgb += vl * vlVisibilityMult;
	#endif

	#ifdef BORDER_FOG
	if (isEyeInWater != 1) 
	{
		vec3 eyePlayerPos = mat3(gbufferModelViewInverse) * viewPos.xyz;
		bool hasBorderFog = false;
		float borderFogFactor = GetBorderFogMixFactor(eyePlayerPos, far, z0, hasBorderFog);

		if (hasBorderFog) 
		{
			#ifdef OVERWORLD
			color.rgb = mix(color.rgb, sky, borderFogFactor);
			#endif

			#ifdef END
			// TODO
			// color.rgb = mix(color.rgb, endCol.rgb, borderFogFactor);
			#endif
		}
	}
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = color;
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