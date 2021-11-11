vec3 GetSkyColor(vec3 viewPos, vec3 lightCol)
{
    vec3 sky = skyCol;
    vec3 nViewPos = normalize(viewPos);

    float NdotU = clamp(dot(nViewPos, upVec), 0.0, 1.0);
    float invNdotU = clamp(dot(nViewPos, -upVec) * 1.015 - 0.015, 0.0, 1.0);
    float NdotS = clamp(dot(nViewPos, sunVec) * 0.5 + 0.5, 0.0, 1.0);

    float horizonExponent = 3.0 * ((1.0 - NdotS) * sunVisibility * (1.0 - rainStrength) *
                            (1.0 - 0.5 * timeBrightness)) + HORIZON_DISTANCE;
    float horizon = pow(1.0 - NdotU, horizonExponent);
    horizon *= (0.5 * sunVisibility + 0.3) * (1.0 - rainStrength * 0.75);
    
    float lightmix = NdotS * NdotS * (1.0 - NdotU) * pow(1.0 - 0.7 * timeBrightness, 3.0) +
                     horizon * 0.075 * timeBrightness;
    lightmix *= sunVisibility * (1.0 - rainStrength);

    #ifdef SKY_VANILLA
    sky = mix(fogCol, sky, NdotU);
    #endif

    float groundFactor = 0.5 * (11.0 * rainStrength * rainStrength + 1.0) * 
                         (-5.0 * sunVisibility + 6.0);
    float ground = 1.0 - exp(-(groundFactor * FOG_DENSITY) / (invNdotU * 8.0));
    float mult = (0.2 * (1.0 + rainStrength) + horizon) * ground;

    sky = mix(
        sky * pow(max(1.0 - lightmix, 0.0), 2.0 * sunVisibility),
        lightCol * sqrt(lightCol),
        lightmix
    ) * sunVisibility + (lightNight * lightNight * 0.4);
    
    vec3 weatherSky = weatherCol.rgb * weatherCol.rgb;
    weatherSky *= GetLuminance(ambientCol / (weatherSky)) * 1.4;
    sky = mix(sky, weatherSky, rainStrength) * mult;

    return pow(sky, vec3(1.1));
}