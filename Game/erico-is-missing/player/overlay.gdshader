shader_type spatial;
render_mode unshaded, fog_disabled;
uniform float pixel_size: hint_range(0.0, 20.0, 1.0);
uniform float levels: hint_range(0.0, 100.0, 1.0);
uniform vec2 gamma;
uniform float dithering_strength: hint_range(0.0, 2.0, 1.0);
uniform float contrast: hint_range(1.0, 3.0, 0.01);

uniform sampler2D screen_texture: hint_screen_texture;

// Função para gerar ruído Bayer 4x4
float bayer4x4(vec2 position) {
	int x = int(mod(position.x, 4.0));
	int y = int(mod(position.y, 4.0));
	
	// Matriz Bayer 4x4 em array 1D
	int[16] matrix = {
		0, 8, 2, 10,
		12, 4, 14, 6,
		3, 11, 1, 9,
		15, 7, 13, 5
	};
	
	return float(matrix[y * 4 + x]) / 16.0;
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 tex_size = vec2(textureSize(screen_texture, 0));
	vec2 pixel_count = tex_size / (pixel_size);
	vec2 pixelated_uv = floor(SCREEN_UV * pixel_count) / pixel_count;
	
	vec4 color = texture(screen_texture, pixelated_uv);
	
	color.rgb = pow(color.rgb, vec3(gamma.x));
	
	float grayscale = max(color.r, max(color.g, color.b));
	float lower = floor(grayscale * levels) / levels;
	float higher = ceil(grayscale * levels) / levels;
	float lower_diff = abs(lower - grayscale);
	float higher_diff = abs(higher - grayscale);
	
	float level = lower_diff < higher_diff ? lower : higher;
	float adjustment = level / grayscale;
	
	color.rgb *= adjustment;
	
	// Aplica contraste
	color.rgb = (color.rgb - 0.5) * contrast + 0.5;
	color.rgb = clamp(color.rgb, 0.0, 1.0);
	
	// Aplica dithering
	if (dithering_strength > 0.0) {
		vec2 pixel_pos = floor(SCREEN_UV * tex_size);
		float dither = bayer4x4(pixel_pos);
		float dither_value = (dither - 0.5) * dithering_strength;
		color.rgb += dither_value / levels;
		color.rgb = clamp(color.rgb, 0.0, 1.0);
	}
	
	color.rgb = pow(color.rgb, vec3(gamma.y));
	
	ALBEDO = color.rgb;
	ALPHA = color.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}