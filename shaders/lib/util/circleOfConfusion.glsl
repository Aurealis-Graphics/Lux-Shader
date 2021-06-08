float GetCircleOfConfusion(float z, float centerDepthSmooth) {
	float coc = abs(z - centerDepthSmooth) / 0.6;
	return coc / (1 / DOF_STRENGTH + coc);
}