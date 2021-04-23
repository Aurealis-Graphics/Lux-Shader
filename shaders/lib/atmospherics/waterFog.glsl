void WaterFog(inout vec3 color, vec3 viewPos, float fogrange){
    float fog = length(viewPos) / fogrange;
    fog = 1.0 - exp(-3.0 * fog * fog);
    color = mix(color, pow(waterColor.rgb * (1.0 - blindFactor), vec3(2.0)), fog);
}