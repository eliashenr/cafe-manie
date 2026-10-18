shader_type canvas_item;
// Esmaece o desenho perto de pontos de foco (personagens junto da frente e o piso escolhido), para a
// mureta da frente não esconder quem está atrás dela. No máximo 8 pontos, em coordenadas do mundo.

const int MAX_FOCUS = 8;

uniform vec2 focus[8];
uniform int focus_count = 0;
// Até onde chega o esmaecimento (pixels de mundo) e quanto sobra de opacidade no centro.
uniform float radius = 80.0;
uniform float min_alpha = 0.3;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float fade = 1.0;
	for (int i = 0; i < MAX_FOCUS; i++) {
		if (i >= focus_count) {
			break;
		}
		float distance_to_focus = distance(world_position, focus[i]);
		fade = min(fade, mix(min_alpha, 1.0, smoothstep(radius * 0.45, radius, distance_to_focus)));
	}
	COLOR.a *= fade;
}
