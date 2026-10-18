shader_type canvas_item;
// Silhueta chapada: a forma do desenho numa cor só, meio transparente. É o "raio-X" de quem está
// atrás de um móvel alto (o nó pai recorta a silhueta no formato do móvel). Barato: uma leitura de
// textura por pixel, sem laços, compatível com o renderer mobile.

uniform vec4 tint : source_color = vec4(0.33, 0.56, 1.0, 0.5);

void fragment() {
	float alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(tint.rgb, tint.a * alpha);
}
