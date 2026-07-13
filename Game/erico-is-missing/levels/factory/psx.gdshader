shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D albedo_texture : source_color;

// Controle do snap da geometria (efeito PSX)
uniform float snap_amount = 200.0;

// Profundidade de cor (quantização)
uniform float color_depth = 32.0;

// Força do affine mapping (distorção de textura)
uniform float affine_strength = 0.005;

// Tamanho do pixel nas bordas (menor = mais pixelizado)
uniform float edge_pixel_size = 0.0;

// Intensidade do dithering
uniform float dither_strength = 0.015;

varying float v_w;
varying vec3 v_pos;

// Bayer Matrix 4x4 para dithering
float bayer4(vec2 pos) {
    int x = int(mod(pos.x, 4.0));
    int y = int(mod(pos.y, 4.0));
    
    int index = x + y * 4;
    
    float matrix[16] = float[](
        0.0,  8.0,  2.0, 10.0,
        12.0, 4.0, 14.0, 6.0,
        3.0,  11.0, 1.0, 9.0,
        15.0, 7.0, 13.0, 5.0
    );
    
    return matrix[index] / 16.0;
}

void vertex() {
    // Calcula posição no espaço de clip
    vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    
    // Guarda o w para affine mapping
    v_w = clip.w;
    v_pos = VERTEX;
    
    // Normaliza para coordenadas de tela
    vec3 screen_pos = clip.xyz / clip.w;
    
    // Snap da geometria (efeito PSX)
    screen_pos.xy = floor(screen_pos.xy * snap_amount) / snap_amount;
    
    // Pixelização das bordas (opcional)
    if (edge_pixel_size > 0.0) {
        screen_pos.xy = floor(screen_pos.xy / edge_pixel_size) * edge_pixel_size;
    }
    
    // Volta para coordenadas de clip
    clip.xyz = screen_pos * clip.w;
    
    POSITION = clip;
}

void fragment() {
    vec2 uv = UV;
    
    // Affine texture mapping (distorção típica do PSX)
    // Quanto maior affine_strength, mais distorcida fica a textura
    if (affine_strength > 0.0) {
        float affine_factor = mix(1.0, v_w, affine_strength);
        // Centraliza a distorção no centro da textura
        uv = (uv - 0.5) * affine_factor + 0.5;
    }
    
    // Sample da textura com filtro mais próximo (efeito pixelado)
    vec3 color = texture(albedo_texture, uv).rgb;
    
    // Bayer dithering para suavizar a transição de cores
    float dither = (bayer4(FRAGCOORD.xy) - 0.5) * dither_strength;
    color += dither;
    
    // Quantização de cor (reduz a profundidade de cor)
    color = floor(color * color_depth) / color_depth;
    
    // Clamp para evitar valores fora do range
    color = clamp(color, 0.0, 1.0);
    
    ALBEDO = color;
}