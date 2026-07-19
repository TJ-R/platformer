#version 330 core
out vec4 FragColor;

uniform vec4 yellowColor;

void main() {
	// FragColor = vec4(0.7f, 0.6f, 0.2f, 1.0f);
	FragColor = yellowColor;
}
