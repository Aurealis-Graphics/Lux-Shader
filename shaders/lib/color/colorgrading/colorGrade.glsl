/* 
----------------------------------------------------------------
Lux Shader by https://github.com/TechDevOnGithub/
Based on BSL Shaders v7.1.05 by Capt Tatsu https://bitslablab.com 
See AGREEMENT.txt for more information.
----------------------------------------------------------------
*/ 

#include "/lib/color/colorgrading/transforms.glsl"

/* Main Colorgrading Function */
vec3 ColorGrade(vec3 rgb) 
{
    vec3 hsv = RGBToHSV(rgb);

    /* Greens */
    RotateSaturationAroundHue(hsv, 90.0, 20.0, 0.04, 12.0);
    RotateHueAroundHue(hsv, 110.0, 20.0, 4.0, 22.0);
    RotateSaturationAroundHue(hsv, 106.0, 20.0, 0.10, 22.0);

    /* Cyan */
    RotateSaturationAroundHue(hsv, 170.0, 8.0, 0.15, 22.0);

    /* Oranges */
    // RotateSaturationAroundHue(hsv, 27.0, 4.0, 0.07, 22.0);

    hsv.yz = Saturate(hsv.yz);
    rgb = HSVToRGB(hsv);
    return mix(rgb, Smooth3(rgb), 0.1);
}