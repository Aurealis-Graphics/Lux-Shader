float WorldCurvature(vec2 pos){
    return dot(pos, pos) / WORLD_CURVATURE_SIZE;
}