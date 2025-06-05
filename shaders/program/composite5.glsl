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
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight, aspectRatio;
uniform float centerDepthSmooth;
uniform float far, near;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform ivec2 eyeBrightnessSmooth;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D noisetex;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

#ifdef DIRTY_LENS
uniform sampler2D depthtex2;
#endif

#ifdef LENS_FLARE
uniform vec3 sunPosition;
#endif

uniform mat4 gbufferProjection;

// Optifine Constants
const bool colortex2Clear = false;

#ifdef AUTO_EXPOSURE
const bool colortex0MipmapEnabled = true;
#endif

// Common Variables
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility  = clamp(dot( sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float pw = 1.0 / viewWidth;
float ph = 1.0 / viewHeight;

// Includes
#include "/lib/color/lightColor.glsl"
#include "/lib/util/circleOfConfusion.glsl"

#ifdef LENS_FLARE
#include "/lib/post/lensFlare.glsl"
#endif

// Common Functions
void UnderwaterDistort(inout vec2 texCoord)
{
	vec2 originalTexCoord = texCoord;

	texCoord += vec2(
		cos(texCoord.y * 33.0 + frameTimeCounter * 3.0),
		sin(texCoord.x * 47.0 - frameTimeCounter * 1.7)
	) * 0.0008;

	float mask = float(
		texCoord.x > 0.0 && texCoord.x < 1.0 &&
	    texCoord.y > 0.0 && texCoord.y < 1.0
	);

	if (mask < 0.5) texCoord = originalTexCoord;
}

vec3 GetBloomTile(float lod, vec2 coord, vec2 offset)
{
	vec3 bloom = texture2D(colortex1, coord / exp2(lod) + offset).rgb;
	return Pow4(bloom) * 128.0;
}

float GetLinearDepth(float depth)
{
   	return (2.0 * near) / (far + near - depth * (far - near));
}

void Bloom(inout vec3 color, vec2 coord)
{
	vec3 blur1 = GetBloomTile(2.0, coord, vec2(0.0      , 0.0   ));
	vec3 blur2 = GetBloomTile(3.0, coord, vec2(0.0      , 0.26  ) );
	vec3 blur3 = GetBloomTile(4.0, coord, vec2(0.135    , 0.26  ));
	vec3 blur4 = GetBloomTile(5.0, coord, vec2(0.2075   , 0.26  ));
	vec3 blur5 = GetBloomTile(6.0, coord, vec2(0.135    , 0.3325));
	vec3 blur6 = GetBloomTile(7.0, coord, vec2(0.2075	, 0.3325));

	#ifdef DIRTY_LENS
	float newAspectRatio = 1.777777777777778 / aspectRatio;
	vec2 scale = vec2(max(newAspectRatio, 1.0), max(1.0 / newAspectRatio, 1.0));
	float dirt = texture2D(depthtex2, (coord - 0.5) / scale + 0.5).r;
	blur3 *= dirt *  1.0 + 1.0;
	blur4 *= dirt *  2.0 + 1.0;
	blur5 *= dirt *  4.0 + 1.0;
	blur6 *= dirt *  6.0 + 1.0;
	#endif

	vec3 blur = (blur1 + blur2 + blur3 + blur4 + blur5 + blur6) * 0.125;

	if (isEyeInWater == 1) 	color = mix(color, blur, 0.65 * BLOOM_STRENGTH) * (1.0 + 0.6 * BLOOM_STRENGTH);
	else
	{
		#ifndef NETHER
		color += blur * 0.2 * BLOOM_STRENGTH;
		#else
		float linZ = GetLinearDepth(texture2D(depthtex0, coord).r);
		color = mix(mix(color, blur, 0.4 * BLOOM_STRENGTH) * (1.0 + 0.6 * BLOOM_STRENGTH), color + blur * 0.2 * BLOOM_STRENGTH, exp(-linZ * 4.0));
		#endif
	}

}

void AutoExposure(inout vec3 color, inout float exposure, float tempExposure)
{
	float exposureLod = log2(viewWidth * 0.4);

	exposure = length(texture2DLod(colortex0, vec2(0.5), exposureLod).rgb);
	exposure = clamp(exposure, 0.0001, 10.0);

	color /= 2.2 * clamp(tempExposure, 0.2, 10.0) + 0.125;
}

void ColorGrading(inout vec3 color)
{
	vec3 cgColor = pow(color.r, CG_RC) * pow(vec3(CG_RR, CG_RG, CG_RB) / 255.0, vec3(2.2)) +
				   pow(color.g, CG_GC) * pow(vec3(CG_GR, CG_GG, CG_GB) / 255.0, vec3(2.2)) +
				   pow(color.b, CG_BC) * pow(vec3(CG_BR, CG_BG, CG_BB) / 255.0, vec3(2.2));
	
	vec3 cgMin = pow(vec3(CG_RM, CG_GM, CG_BM) / 255.0, vec3(2.2));
	color = (cgColor * (1.0 - cgMin) + cgMin) * vec3(CG_RI, CG_GI, CG_BI);

	vec3 cgTint = pow(vec3(CG_TR, CG_TG, CG_TB) / 255.0, vec3(2.2)) * GetLuminance(color) * CG_TI;
	color = mix(color, cgTint, CG_TM);
}

/* Modified Burgess tonemap, by yours truly */
vec3 TonemapBurgessModified(vec3 color)
{
    vec3 maxColor = color * min(vec3(1.0), 1.0 - exp(-1.0 / 0.004 * color)) * 0.8;
    vec3 retColor = (maxColor * (6.2 * maxColor + 0.5)) / (maxColor * (6.2 * maxColor + 1.7) + 0.06);
    return retColor;
}

vec3 TonemapTech2021(vec3 color)
{
    vec3 a = color * min(vec3(1.0), 1.0 - exp(-1.0 / 0.038 * color));
    a = mix(a, color, color * color);
    return a / (a + 0.6);
}

/*
    Tl: Tonemap Toe Length
    Ts: Tonemap Toe Strength
    S:  Tonemap Slope
*/
vec3 TonemapTech2022(vec3 color, const float Tl, const float Ts, const float S)
{
	return (1.0 - exp(-color / Tl) * Ts) * color / (color + S);
}

#include "/lib/post/tonemap.glsl"

void ColorSaturation(inout vec3 color)
{
	float grayVibrance = (color.r + color.g + color.b) / 3.0;
	float graySaturation = grayVibrance;
	if (SATURATION < 1.00) graySaturation = dot(color, vec3(0.299, 0.587, 0.114));

	float mn = min(color.r, min(color.g, color.b));
	float mx = max(color.r, max(color.g, color.b));
	float sat = (1.0 - (mx - mn)) * (1.0 - mx) * grayVibrance * 5.0;
	vec3 lightness = vec3((mn + mx) * 0.5);

	color = mix(color, mix(color, lightness, 1.0 - VIBRANCE), sat);
	color = mix(color, lightness, (1.0 - lightness) * (2.0 - VIBRANCE) / 2.0 * abs(VIBRANCE - 1.0));
	color = color * SATURATION - graySaturation * (SATURATION - 1.0);
}

vec2 PincushionDistortion(in vec2 uv, float strength) 
{
	vec2 st = uv - 0.5;
    float uvA = atan(st.x, st.y);
    float uvD = dot(st, st);
    return 0.5 + vec2(sin(uvA), cos(uvA)) * sqrt(uvD) * (1.0 - strength * uvD);
}

vec3 ChromaticAbberation(sampler2D texSampler, vec2 texcoord, float z)
{
	if (IsHand(z)) return texture2D(texSampler, texcoord).rgb;

	vec2 st = texcoord - 0.5;
    float uvA = atan(st.x, st.y);
    float uvD = dot(st, st);
	vec2 newCoord = vec2(sin(uvA), cos(uvA)) * sqrt(uvD);
	
	#ifndef DOF
	float coc = GetCircleOfConfusion(z, centerDepthSmooth, gbufferProjection, 1.0) * 0.7;
	#else
	float coc = GetCircleOfConfusion(z, centerDepthSmooth, gbufferProjection, DOF_STRENGTH) * 0.3;
	#endif

	#if CHROMATIC_ABBERATION_MODE == 0
	float strength = 12.0 * CHROMATIC_ABBERATION_STRENGTH * coc;
	#elif CHROMATIC_ABBERATION_MODE == 1
	float strength = 0.03 * CHROMATIC_ABBERATION_STRENGTH * CHROMATIC_ABBERATION_STATIC_STRENGTH;
	#else
	float strength = 12.0 * CHROMATIC_ABBERATION_STRENGTH * coc + 0.03 * CHROMATIC_ABBERATION_STRENGTH * CHROMATIC_ABBERATION_STATIC_STRENGTH;
	#endif

	mat2 coordMatrix = mat2(
		0.5 + newCoord * (1.0 - strength * uvD),
		0.5 + newCoord * (1.0 + strength * uvD)
	);

	// Distortion: Linear Scaling
	// mat2 coordMatrix = mat2(
	// 	texcoord * (1.0 - coc * 2.0) + coc,
	// 	texcoord * (1.0 + coc * 2.0) - coc
	// );

	#ifdef CHROMATIC_ABBERATION_ADAPTIVE_STRENGTH
	for (int i = 0; i < 2; i++) 
	{
		float tapDepth = texture2D(depthtex1, coordMatrix[i]).r;
		
		#ifndef DOF
		float tapCoc = GetCircleOfConfusion(tapDepth, centerDepthSmooth, gbufferProjection, 1.0) * 0.7;
		#else
		float tapCoc = GetCircleOfConfusion(tapDepth, centerDepthSmooth, gbufferProjection, DOF_STRENGTH) * 0.3;
		#endif

		float tapStrength = exp2(-distance(coc, tapCoc) * CHROMATIC_ABBERATION_ADAPTIVE_STRENGTH_RESPONSE);

		coordMatrix[i] = mix(texcoord, coordMatrix[i], tapStrength);
	}
	#endif

	return vec3(
		texture2D(texSampler, coordMatrix[0]).r,
		texture2D(texSampler, texcoord).g,
		texture2D(texSampler, coordMatrix[1]).b
	);
}

#ifdef LENS_FLARE
vec2 GetLightPos()
{
	vec4 tpos = gbufferProjection * vec4(sunPosition, 1.0);
	tpos.xyz /= tpos.w;
	return tpos.xy / tpos.z * 0.5;
}
#endif

void ColorGrade_SafeSaturation(inout vec3 color, in float boost)
{
    float L = GetLuminance(color);
    float maxBoost = (L - 1.0) * rcp(L - MaxOf(color));
    color = mix(vec3(L), color, min(boost, maxBoost));
}

vec3 CorrectiveSaturation(vec3 color)
{

    float m = MaxOf(color);

	if (m < 1e-5) return color;

    float t = OpenDRT_TonescalePrism(m, 1.0, 1.0, 1.0, 1); // Invserse Tonescale
    // float S = pow(rcp(pow2(t) + 1.0), 3.0 / 2.0); // Tonescle Derivative
    float S = (OpenDRT_TonescalePrism(m      , 1.0, 1.0, 1.0, 0)
            -  OpenDRT_TonescalePrism(m - EPS, 1.0, 1.0, 1.0, 0))
            * rcp(EPS);

    // Saturate color by 16.0% to account for tonemap desaturation of mid-tones
    float saturationBoost_Corrective = 0.1;
    float saturationBoost_Artistic = 0.0;
    
    ColorGrade_SafeSaturation(color, 1.0 + S * (saturationBoost_Corrective + saturationBoost_Artistic));

    return color;
}

// Program
void main()
{
    vec2 newTexCoord = texCoord;
	if (isEyeInWater == 1.0) UnderwaterDistort(newTexCoord);

	#ifdef CHROMATIC_ABBERATION
	float z = texture2D(depthtex1, newTexCoord).r;

	vec3 color = ChromaticAbberation(colortex0, newTexCoord, z);
	#else
	vec3 color = texture2D(colortex0, newTexCoord).rgb;
	#endif

	#ifdef AUTO_EXPOSURE
	float tempExposure = texture2D(colortex2, vec2(pw, ph)).r;
	#endif

	#ifdef LENS_FLARE
	float tempVisibleSun = texture2D(colortex2, vec2(3.0 * pw, ph)).r;
	#endif

	vec3 temporalColor = vec3(0.0);
	#if AA == 2
	temporalColor = texture2D(colortex2, texCoord).gba;
	#endif

	#ifdef BLOOM
	Bloom(color, newTexCoord);
	#endif

	#ifdef AUTO_EXPOSURE
	float exposure = 1.0;
	AutoExposure(color, exposure, tempExposure);
	#endif

	#ifdef COLOR_GRADING
	ColorGrading(color);
	#endif

	#if TONEMAP == 1
    color = TonemapTech2022(color * 2.5 * TONEMAP_EXPOSURE, 0.038, 1.0, 0.6);
	#elif TONEMAP == 2
	color *= 2.6 * TONEMAP_EXPOSURE;
	color = pow(color, vec3(1.15)) * 1.3;
	color = CorrectiveSaturation(TonemapPrism2024(color));
	#endif

	#ifdef LENS_FLARE
	vec2 lightPos = GetLightPos();
	float truePos = sign(sunVec.z);
	float multiplier = tempVisibleSun * LENS_FLARE_STRENGTH * 0.5;
    float visibleSun = float(texture2D(depthtex1, lightPos + 0.5).r >= 1.0);
	visibleSun *= max(1.0 - isEyeInWater, eBS) * (1.0 - blindFactor) * (1.0 - rainStrength);

	if (multiplier > 0.001) LensFlare(color, lightPos, truePos, multiplier);
	#endif

	float temporalData = 0.0;

	#ifdef AUTO_EXPOSURE
	if (texCoord.x < 2.0 * pw && texCoord.y < 2.0 * ph)
		temporalData = mix(tempExposure, sqrt(exposure), 0.016);
	#endif

	#ifdef LENS_FLARE
	if (texCoord.x > 2.0 * pw && texCoord.x < 4.0 * pw && texCoord.y < 2.0 * ph)
		temporalData = mix(tempVisibleSun, visibleSun, 0.125);
	#endif

    #ifdef VIGNETTE
	float luminance = GetLuminance(color);
	float vignette = sin(texCoord.x * PI) * sin(texCoord.y * PI);
	vignette = pow(vignette, VIGNETTE_STRENGTH / (8.0 * luminance + 1.0));
	vignette = mix(vignette, 1.0, 0.6 / (VIGNETTE_STRENGTH + 1.5));
	
	color *= vignette;
	#endif

	color = LinearTosRGB(color);

	ColorSaturation(color);

	vec3 filmGrain = texture2D(noisetex, texCoord * vec2(viewWidth, viewHeight) / 512.0).rgb;
	color += (filmGrain - 0.25) / 128.0;

	/* DRAWBUFFERS:12 */
	gl_FragData[0] = vec4(Max0(color), 1.0);
	gl_FragData[1] = vec4(temporalData, temporalColor);
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
