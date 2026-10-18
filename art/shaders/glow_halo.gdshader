shader_type canvas_item;
// Halo de brilho: o desenho do móvel numa cor só, desenhado um pouco maior atrás dele, pulsando.
// Marca o móvel selecionado e o fogão com prato pronto. Uma leitura de textura por pixel.

uniform vec4 glow_color : source_color = vec4(1.0, 0.62, 0.12, 0.8);
uniform float pulse_speed = 3.2;
uniform float pulse_amount = 0.35;

void fragment() {
	float alpha = texture(TEXTURE, UV).a;
	float pulse = 1.0 - pulse_amount * (0.5 + 0.5 * sin(TIME * pulse_speed));
	COLOR = vec4(glow_color.rgb, glow_color.a * alpha * pulse);
}
