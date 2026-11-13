shader_type spatial;
render_mode unshaded;

// Color superior y color inferior
uniform vec4 top_color : source_color = vec4(0.60, 0.69, 0.40, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.40, 0.25, 0.12, 1.0);

// Altura exacta del corte
uniform float cut_height = 0.0;

// Pasamos la posición Y local del vértice
varying float vert_z;

void vertex() {
    vert_z = VERTEX.z;
}

void fragment() {
    // Invertimos el orden del step para dar la vuelta al corte de los colores
    float cut = step(vert_z, cut_height);
    
    // Aplicamos el corte seco invertido
    ALBEDO = mix(top_color.rgb, bottom_color.rgb, cut);
}