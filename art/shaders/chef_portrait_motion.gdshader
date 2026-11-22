shader_type canvas_item;
render_mode unshaded;

uniform vec2 image_origin = vec2(0.0);
uniform vec2 image_size = vec2(210.0, 255.0);
uniform float head_angle = 0.0;
uniform float vertical_offset = 0.0;
uniform float blink : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D half_texture : source_color, filter_linear, repeat_disable;
uniform sampler2D closed_texture : source_color, filter_linear, repeat_disable;
uniform vec4 left_destination;
uniform vec4 left_half_source;
uniform vec4 left_closed_source;
uniform vec4 right_destination;
uniform vec4 right_half_source;
uniform vec4 right_closed_source;
uniform float eye_feather = 0.10;
varying vec4 portrait_modulate;

void vertex() {
	portrait_modulate = COLOR;
	// Chapéu, cabelo, face, pescoço e gola estão na região rígida. Só o busto faz a transição.
	float influence = 1.0 - smoothstep(0.78, 1.0, UV.y);
	vec2 pivot = image_origin + image_size * vec2(0.52, 0.73);
	vec2 local = VERTEX - pivot;
	float c = cos(head_angle);
	float s = sin(head_angle);
	vec2 rotated = vec2(c * local.x - s * local.y, s * local.x + c * local.y);
	VERTEX += (rotated - local + vec2(0.0, vertical_offset)) * influence;
}

vec3 eye_color(vec3 original, vec2 uv, vec4 destination, vec4 half_source, vec4 closed_source) {
	vec2 local = (uv - destination.xy) / max(destination.zw, vec2(0.000001));
	// Amostra antes de qualquer decisão por fragmento: derivadas de mipmap permanecem definidas.
	vec4 half_eye = texture(half_texture, half_source.xy + local * half_source.zw);
	vec4 closed_eye = texture(closed_texture, closed_source.xy + local * closed_source.zw);
	// Elipse inscrita na caixa contratada: fora dela o peso é exatamente zero.
	// O miolo cobre íris/pálpebra por inteiro; a borda apenas integra a pele ao redor.
	float radius = length((local - vec2(0.5)) * 2.0);
	float mask = 1.0 - smoothstep(1.0 - eye_feather * 2.0, 1.0, radius);
	float to_half = min(blink * 2.0, 1.0);
	float to_closed = max(blink * 2.0 - 1.0, 0.0);
	vec3 color = mix(original, half_eye.rgb, to_half * mask * half_eye.a);
	return mix(color, closed_eye.rgb, to_closed * mask * closed_eye.a);
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec3 color = base.rgb;
	if (blink > 0.0) {
		color = eye_color(color, UV, left_destination, left_half_source, left_closed_source);
		color = eye_color(color, UV, right_destination, right_half_source, right_closed_source);
	}
	// O alfa SEMPRE vem da fonte aprovada; modulate/herança é aplicado uma única vez.
	COLOR = vec4(color, base.a) * portrait_modulate;
}
