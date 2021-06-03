float GetCircleOfConfusion(float z, float centerDepthSmooth) {
	float coc = pow(abs(z - centerDepthSmooth) / 1.6 * DOF_STRENGTH, 0.7);
	return coc / (1 + coc);
}