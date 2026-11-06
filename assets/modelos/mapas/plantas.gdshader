shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

// 1. Textura de la máscara alfa principal (para recortar la silueta de la planta)
uniform sampler2D textura_mascara : hint_default_white, filter_nearest;

// 2. Segunda textura (64x64 en escala de grises) para el degradé de fundido con la base
uniform sampler2D textura_fundido : hint_default_white, filter_linear;

// 3. Color base superior exacto (#ACC265FF)
uniform vec4 color_personalizado : source_color = vec4(0.675, 0.761, 0.396, 1.0);

// Interruptores para activar o desactivar cada efecto desde el Inspector
uniform bool usar_mascara = true;
uniform bool usar_fundido = true;

// Controles de recorte de la silueta
uniform float corte_alfa : hint_range(0.0, 1.0) = 0.5;
uniform float suavizado_borde : hint_range(0.0, 0.2) = 0.05;

void fragment() {
	// Invertir normales si la cara apunta hacia atrás (evita zonas oscuras)
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}

	// Color base de la planta
	ALBEDO = color_personalizado.rgb;
	ALPHA = 1.0;

	// Si está activada la máscara principal, recorta la silueta (alpha clipping)
	if (usar_mascara) {
		float valor_mascara = texture(textura_mascara, UV).r;
		float alfa_mascara = smoothstep(corte_alfa - suavizado_borde, corte_alfa + suavizado_borde, valor_mascara);
		
		if (alfa_mascara < 0.1) {
			discard;
		}
		ALPHA = alfa_mascara;
	}

	// Si está activado el fundido, usa la segunda textura de 64x64 para desvanecer la base
	if (usar_fundido) {
		float factor_fundido = texture(textura_fundido, UV).r;
		ALPHA *= factor_fundido;
	}

	ROUGHNESS = 0.8;
}