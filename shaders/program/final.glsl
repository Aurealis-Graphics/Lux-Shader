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

//Uniforms//
uniform sampler2D colortex1;

uniform float viewWidth, viewHeight;

uniform int isEyeInWater;

//Optifine Constants//
/*
const int colortex0Format = R11F_G11F_B10F; //main
const int colortex1Format = RGB8; //raw translucent, bloom
const int colortex2Format = RGBA16; //temporal stuff
const int colortex3Format = RGB8; //specular data
const int gaux1Format = R8; //cloud alpha
const int gaux2Format = RGB10_A2; //reflection image
const int gaux3Format = RGB16; //normals
const int gaux4Format = RGB16; //specular highlight
*/

const bool shadowHardwareFiltering = true;

const int noiseTextureResolution = 512;

const float drynessHalflife = 25.0;
const float wetnessHalflife = 200.0;

//Common Functions//
#if SHARPEN > 0
vec2 sharpenOffsets[4] = vec2[4](
	vec2( 1.0,  0.0),
	vec2( 0.0,  1.0),
	vec2(-1.0,  0.0),
	vec2( 0.0, -1.0)
);

void SharpenFilter(inout vec3 color){
	float mult = SHARPEN * 0.025;
	vec2 view = 1.0 / vec2(viewWidth, viewHeight);

	color *= SHARPEN * 0.1 + 1.0;

	for(int i = 0; i < 4; i++){
		vec2 offset = sharpenOffsets[i] * view;
		color -= texture2D(colortex1, texCoord + offset).rgb * mult;
	} 
}
#endif

//Program//
void main(){
	vec3 color = texture2D(colortex1, texCoord).rgb;

	if(isEyeInWater == 1) 
	{
		vec3 gradedColor = color * vec3(0.7, 0.95, 1.0);
		gradedColor.b += abs(gradedColor.b - sqrt(gradedColor.g * 0.3 * gradedColor.r));
		gradedColor.r *= 1. - abs(gradedColor.b - sqrt(gradedColor.g * 0.3 * gradedColor.r));
		gradedColor *= 0.8;
		color = mix(color, gradedColor, 0.5);
	}

	#if SHARPEN > 0
	SharpenFilter(color);
	#endif

	color = pow(color * 1.1, vec3(1.1));

	gl_FragColor = vec4(color, 1.0);
}

#endif

//Vertex Shader///////////////////////////////////////// ////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord;

//Program//
void main(){
	texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();
}

#endif