#define rcp(x) (1.0 / (x))
#define maxEPS(x) max(x, 1e-6)

int MaxIdx(vec3 x)
{
    float val = MaxOf(x);
    
    for (int i = 0; i < 3; i++)
        if (val == x[i]) return i;
}

int MinIdx(vec3 x)
{
    float val = MinOf(x);
    
    for (int i = 0; i < 3; i++)
        if (val == x[i]) return i;
}

const mat3x3 ACESInputMat = mat3(
    0.59719, 0.35458, 0.04823,
    0.07600, 0.90834, 0.01566,
    0.02840, 0.13383, 0.83777
);

const mat3x3 ACESOutputMat = mat3(
     1.60475, -0.53108, -0.07367,
    -0.10208,  1.10813, -0.00605,
    -0.00327, -0.07276,  1.07602
);

float OpenDRT_TonescalePrism(float x, float m, float s, float c, int invert)
{
    if (invert == 0)
    {
        float k = x / (1.0 + x) + 1.0;
        x = pow(x / s, 2.0 / k);
        return pow(m * pow(x / (x + 1.0), k / 2.0), c);
    }
    else
    {
        float ic = rcp(c);
        x = pow(x, ic);
        return s * x / (m * sqrt(1.0 - Pow2(x / m)));
    }
}

float TonemapPrism2024_SmoothF(float x, float alpha)
{
    return x > 0.0 ? pow(x / (x + pow(x, -1.0 / alpha)), alpha / (1.0 + alpha)) : x;
}

float TonemapPrism2024_SmoothMax(float a, float b, float alpha)
{
    return b + 1.0 - TonemapPrism2024_SmoothF(1.0 - a + b, alpha);
}

vec3 TonemapPrism2024_Tonescale(vec3 color)
{
    return vec3(
        OpenDRT_TonescalePrism(color.r, 1.0, 1.0, 1.0, 0),
        OpenDRT_TonescalePrism(color.g, 1.0, 1.0, 1.0, 0),
        OpenDRT_TonescalePrism(color.b, 1.0, 1.0, 1.0, 0)
    );
}

const mat3 sRGB_to_LMS = transpose(mat3(
	0.31399022, 0.63951294, 0.04649755,
	0.15537241, 0.75789446, 0.08670142,
	0.01775239, 0.10944209, 0.87256922)
);

const mat3 LMS_to_sRGB = transpose(mat3(
	5.47221206, -4.6419601 ,  0.16963708,
	-1.1252419 ,  2.29317094, -0.1678952 ,
	0.02980165, -0.19318073,  1.16364789)
);

float CalcSat(vec3 x)
{
    return (MaxOf(x) - MinOf(x)) / MaxOf(x);
}

// Chromatic Adaption Matrix (CAM) Options
#define ACES 0
#define LMS 1

// Tonemap Options
#define TONEMAP24_HI_HUE_SHIFT
#define TONEMAP24_HI_DESATURATION
#define TONEMAP24_DESAT_TO_GAMUT
#define TONEMAP24_CHROM_ADAPT_MAT ACES

/*
    FIX: Turns perfect blues green at higher exposures,
    doesn't desaturate perfect greens and cold greens nearly as much as other colors.

    TODO: Check if this is realted to the CAM (chromatic adaption matrix) or not.
*/
vec3 TonemapPrism2024(vec3 color)
{
    int minIdx = MinIdx(color);
    int maxIdx = MaxIdx(color);
    int midIdx = 3 - (maxIdx + minIdx);

    /*
        Calculating the tonescale the classical way, using our hue/saturation matrices.
        Hue and saturation information will pulled from this variable in later stages.
    */
    #if TONEMAP24_CHROM_ADAPT_MAT == 0
    vec3 tsCol      = TonemapPrism2024_Tonescale(color * ACESInputMat) * ACESOutputMat;
    #elif TONEMAP24_CHROM_ADAPT_MAT == 1
    vec3 tsCol      = LMS_to_sRGB * TonemapPrism2024_Tonescale(sRGB_to_LMS * color);
    #endif

    /*
        Calculating saturation before applying the tonescale.
        This will serve as our target saturation after applying the tonescale.
    */
    float S         = CalcSat(color);
    #ifdef TONEMAP24_HI_DESATURATION
    S *= CalcSat(tsCol) / maxEPS(CalcSat(TonemapPrism2024_Tonescale(color)));
    #endif

    /*
        Calculating the minimum, maximum and middle color channel along with its index for later use.
        Falling back to input color if hue shifting is disabled.
    */
    float maxC = 0.0;
    float minC = 0.0;
    float midC = 0.0;

    #ifdef TONEMAP24_HI_HUE_SHIFT
    minIdx = MinIdx(tsCol);
    maxIdx = MaxIdx(tsCol);
    midIdx = 3 - (maxIdx + minIdx);

	maxC = tsCol[maxIdx], minC = tsCol[minIdx], midC = tsCol[midIdx];
    #else
    maxC = color[maxIdx], minC = color[minIdx], midC = color[midIdx];
    #endif

    /*
        Represents the interpolation needed between minC and maxC to get to midC
            => 1.0: midC = maxC
            => 0.0: midC = minC
        
        Will later be used to reconstruct the original color hue.
    */
	float k = maxEPS(midC - minC) / maxEPS(maxC - minC);

    //  Applying the tonescale.
	color = TonemapPrism2024_Tonescale(color);

    //  Keeping track of luminance before applying resaturation
    float lumPrev = GetLuminance(color);

    //  Updating highest/lowest/middle values after applying the tonescale.
	maxC = color[maxIdx], minC = color[minIdx], midC = color[midIdx];

    // Reconstructing the original color
	color[maxIdx] = maxC;
	color[minIdx] = (1.0 - S) * maxC;
	color[midIdx] = maxC * (1.0 - S * (1.0 - k));

    /*
        Calculating the factor needed to counteract the
        reduction in brightness due to a change in saturation.
        This happens since we use the HSV formulation of saturation,
        not the luminance deviation formulation.
    */
    float lumPost = GetLuminance(color);
    float lumRatio = min(1.0, lumPost / lumPrev);
    color   /= maxEPS(lumRatio);

    /*
        Since the previous correction factor for luminance can possibly make
        the color fall out of gamut, we desaturate the color until it is back
        in gamut. This is separate from desaturation due to chromatic adaption.
    */
    #ifdef TONEMAP24_DESAT_TO_GAMUT
    lumPost /= lumRatio;

    maxC = color[maxIdx], minC = color[minIdx], midC = color[midIdx];

    float kDesat = (1.0 - lumPost) / (TonemapPrism2024_SmoothMax(maxC, 1.0, 0.1) - lumPost);

    color = mix(vec3(lumPost), color, kDesat);
    #endif

    // return Saturate(vec3(minC < midC));
    // return Saturate(vec3(minC < midC));
    return Saturate(color);
}