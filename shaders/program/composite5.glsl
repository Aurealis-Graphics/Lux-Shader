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
uniform int isEyeInWater;
uniform int worldTime;

uniform float blindFactor;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight, aspectRatio;
uniform float centerDepthSmooth;

uniform ivec2 eyeBrightnessSmooth;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D noisetex;
uniform sampler2D depthtex1;

#ifdef DIRTY_LENS
uniform sampler2D depthtex2;
#endif

#ifdef LENS_FLARE
uniform vec3 sunPosition;
#endif

uniform mat4 gbufferProjection;

//Optifine Constants//
const bool colortex2Clear = false;

#ifdef AUTO_EXPOSURE
const bool colortex0MipmapEnabled = true;
#endif

#include "/lib/util/circleOfConfusion.glsl"

//Common Variables//
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility  = clamp(dot( sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float pw = 1.0 / viewWidth;
float ph = 1.0 / viewHeight;

//Common Functions//
float GetLuminance(vec3 color){
	return dot(color, vec3(0.299, 0.587, 0.114));
}

void UnderwaterDistort(inout vec2 texCoord){
	vec2 originalTexCoord = texCoord;

	texCoord += vec2(
		cos(texCoord.y * 32.0 + frameTimeCounter * 3.0),
		sin(texCoord.x * 32.0 + frameTimeCounter * 1.7)
	) * 0.0005;

	float mask = float(
		texCoord.x > 0.0 && texCoord.x < 1.0 &&
	    texCoord.y > 0.0 && texCoord.y < 1.0
	)
	;
	if (mask < 0.5) texCoord = originalTexCoord;
}

void RetroDither(inout vec3 color, float dither){
	color.rgb = pow(color.rgb, vec3(0.25));
	float lenColor = length(color);
	vec3 normColor = color / lenColor;

	dither = mix(dither, 0.5, exp(-2.0 * lenColor)) - 0.25;
	color = normColor * floor(lenColor * 4.0 + dither * 1.7) / 4.0;

	color = max(pow(color.rgb, vec3(4.0)), vec3(0.0));
}

vec3 GetBloomTile(float lod, vec2 coord, vec2 offset){
	vec3 bloom = texture2D(colortex1, coord / exp2(lod) + offset).rgb;
	return pow(bloom, vec3(4.0)) * 128.0;
}

float Luma(vec3 color) {
  return dot(color, vec3(0.299, 0.587, 0.114));
}

float saturate(float x) {
	return clamp(x, 0.0, 1.0);
}

void Bloom(inout vec3 color, vec2 coord){
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

	color += blur * pow(Luma(blur), 2.0) * BLOOM_STRENGTH;
}

void AutoExposure(inout vec3 color, inout float exposure, float tempExposure){
	float exposureLod = log2(viewWidth * 0.4);

	exposure = length(texture2DLod(colortex0, vec2(0.5), exposureLod).rgb);
	exposure = clamp(exposure, 0.0001, 10.0);

	color /= 2.5 * clamp(tempExposure, 0.001, 10.0) + 0.125;
}

void ColorGrading(inout vec3 color){
	vec3 cgColor = pow(color.r, CG_RC) * pow(vec3(CG_RR, CG_RG, CG_RB) / 255.0, vec3(2.2)) +
				   pow(color.g, CG_GC) * pow(vec3(CG_GR, CG_GG, CG_GB) / 255.0, vec3(2.2)) +
				   pow(color.b, CG_BC) * pow(vec3(CG_BR, CG_BG, CG_BB) / 255.0, vec3(2.2));
	vec3 cgMin = pow(vec3(CG_RM, CG_GM, CG_BM) / 255.0, vec3(2.2));
	color = (cgColor * (1.0 - cgMin) + cgMin) * vec3(CG_RI, CG_GI, CG_BI);

	vec3 cgTint = pow(vec3(CG_TR, CG_TG, CG_TB) / 255.0, vec3(2.2)) * GetLuminance(color) * CG_TI;
	color = mix(color, cgTint, CG_TM);
}

vec3 Burgess_Modified(vec3 color)
{
    vec3 maxColor = color * min(vec3(1.0), 1.0 - exp(-1.0 / 0.004 * color)) * 0.8;
    vec3 retColor = (maxColor * (6.2 * maxColor + 0.5)) / (maxColor * (6.2 * maxColor + 1.7) + 0.06);
    return retColor;
}

vec3 TechTonemap(vec3 color)
{
    vec3 a = color * min(vec3(1.0), 1.0 - exp(-1.0 / 0.035 * color));
    vec3 b = a / (a + 0.7);
    return b;
}

void ColorSaturation(inout vec3 color){
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

#ifdef LENS_FLARE
vec2 GetLightPos(){
	vec4 tpos = gbufferProjection * vec4(sunPosition, 1.0);
	tpos.xyz /= tpos.w;
	return tpos.xy / tpos.z * 0.5;
}
#endif

//Includes//
#include "/lib/color/lightColor.glsl"


#ifdef LENS_FLARE
#include "/lib/post/lensFlare.glsl"
#endif

#ifdef RETRO_FILTER
#include "/lib/util/dither.glsl"
#endif

vec3 ChromaticAbberation(sampler2D texSampler, vec2 texcoord, float z, float centerDepthSmooth) 
{
	float fovScale = gbufferProjection[1][1] / 1.37;
	float coc = GetCircleOfConfusion(z, centerDepthSmooth) * 0.03 * fovScale;

	float handMask = float(z > 0.56);

	vec2 offsets[3] = vec2[3](
		vec2(-1.0, -1.0) * coc / vec2(aspectRatio, 1.0) * handMask,
		vec2(0.0, 0.0) * coc / vec2(aspectRatio, 1.0) * handMask,
		vec2(1.0, 1.0) * coc / vec2(aspectRatio, 1.0) * handMask
	);

	return vec3(
		texture2D(texSampler, texcoord + offsets[0]).r,
		texture2D(texSampler, texcoord + offsets[1]).g,
		texture2D(texSampler, texcoord + offsets[2]).b
	);
}

//Program//
void main(){
    vec2 newTexCoord = texCoord;
	if (isEyeInWater == 1.0) UnderwaterDistort(newTexCoord);

	#ifdef CHROMATIC_ABBERATION
	float z = texture2D(depthtex1, newTexCoord).r;
	vec3 color = ChromaticAbberation(colortex0, newTexCoord, z, centerDepthSmooth);
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

	#ifdef RETRO_FILTER
	float dither = Bayer64(gl_FragCoord.xy);
	RetroDither(color.rgb, dither);
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

	// color = BSLTonemap(color);
	// color = TechTonemap(color * 3.5);
	color = Burgess_Modified(pow(color * 1.2, vec3(1.08)) * TONEMAP_EXPOSURE);

	#ifdef LENS_FLARE
	vec2 lightPos = GetLightPos();
	float truePos = sign(sunVec.z);

    float visibleSun = float(texture2D(depthtex1, lightPos + 0.5).r >= 1.0);
	visibleSun *= max(1.0 - isEyeInWater, eBS) * (1.0 - blindFactor) * (1.0 - rainStrength);

	float multiplier = tempVisibleSun * LENS_FLARE_STRENGTH * 0.5;

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
    color *= 1.0 - length(texCoord - 0.5) * (1.0 - GetLuminance(color));
	#endif

	color = pow(color, vec3(1.0 / 2.2));

	ColorSaturation(color);

	vec3 filmGrain = texture2D(noisetex, texCoord * vec2(viewWidth, viewHeight) / 512.0).rgb;
	color += (filmGrain - 0.25) / 128.0;

	/*DRAWBUFFERS:12*/
	gl_FragData[0] = vec4(color,1.0);
	gl_FragData[1] = vec4(temporalData,temporalColor);
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
