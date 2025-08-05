class_name Utils

## Interpolates between angles by taking the longer path
static func lerp_angle_longest(a: float, b: float, t: float) -> float:
	var delta = fposmod(b - a, TAU)
	if delta < PI:
		delta -= TAU
	return a + delta * t
