shader_type spatial;
render_mode depth_draw_always, blend_mix; 

// --- TEXTURA Y PALETA ---
uniform sampler2D albedo_tex : source_color, filter_nearest;

// --- CONTROLES DE LUZ Y SOMBRA (CEL SHADING) ---
uniform float shadow_softness : hint_range(0.0, 1.0) = 0.5;
uniform float light_intensity : hint_range(0.0, 5.0) = 0.6;
uniform float ambient_strength : hint_range(0.0, 1.0) = 0.2;
uniform vec3 shadow_color_tint : source_color = vec3(0.1, 0.1, 0.2); 

// --- POST-PROCESADO INTERNO ---
uniform float saturation : hint_range(0.0, 2.0) = 1.1;
uniform float contrast : hint_range(0.5, 2.0) = 1.0; 

// --- CONFIGURACIÓN DE LA DESAPARICIÓN ---
// CONTROLADO POR SCRIPT: 0.0 = Completo y visible, 1.0 = Completamente disuelto (invisible)
uniform float progreso_disolver : hint_range(0.7, 1) = 0.7; 
uniform float object_height = 4.0;       // Tus 4 metros de pieza
uniform float suavidad_borde = 0.6;      // Un degradado más ancho para que sea más suave todavía

// --- EFECTO AZULADO Y TRANSPARENTE ---
uniform vec4 color_holograma : source_color = vec4(0.0, 0.4, 1.0, 0.3); // Azul con un 60% de opacidad base
uniform float fuerza_brillo : hint_range(0, 5.0) = 1.5;             // Intensidad del brillo azul

varying float local_y;

void vertex() {
    local_y = VERTEX.y;
}

void fragment() {
    vec4 tex_color = texture(albedo_tex, UV);
    vec3 color = tex_color.rgb;
    
    color = ((color - 0.5) * contrast) + 0.5;
    float grayscale = dot(color, vec3(0.299, 0.587, 0.114));
    vec3 color_final_base = mix(vec3(grayscale), color, saturation);
    
//mezcla de tono azul
    ALBEDO = mix(color_final_base, color_holograma.rgb, color_holograma.a);
    
  
    EMISSION = color_holograma.rgb * fuerza_brillo;
    
    ROUGHNESS = 1.0;
    SPECULAR = 0.0;
    

    float factor_disolver = clamp(progreso_disolver, 0.0, 1.0);
    
  
    float cutoff = mix(object_height + suavidad_borde, -suavidad_borde, factor_disolver);
    float alpha_gradual = smoothstep(cutoff + suavidad_borde, cutoff - suavidad_borde, local_y);
    

    ALPHA = alpha_gradual * tex_color.a * color_holograma.a;
}

void light() {
    float dot_product = dot(NORMAL, LIGHT);
    float diffuse_stepped = smoothstep(-shadow_softness, 1.0, dot_product);
    float final_attenuation = diffuse_stepped * ATTENUATION * light_intensity;
    vec3 direct_light = LIGHT_COLOR * final_attenuation;
    

    vec3 custom_ambient = ALBEDO * ambient_strength * shadow_color_tint;
    DIFFUSE_LIGHT += max(direct_light, custom_ambient);
}