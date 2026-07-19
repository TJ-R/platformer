#version 330 core
out vec4 FragColor;

in vec4 vertexColor;
in vec3 appColor;

// uniform vec4 appColor;

void main()
{
	//FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
	//FragColor = vertexColor;
	FragColor = vec4(appColor, 1.0f);
}
