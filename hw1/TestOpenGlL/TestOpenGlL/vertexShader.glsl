#version 410 core
layout (location = 0) in vec3 aPos;
layout (location = 1) in vec3 aNormal;
layout (location = 2) in vec2 aTexCoords;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;
uniform mat4 NormalModel;
uniform mat4 lightProjection;
uniform mat4 lightview;

out vec3 Normal;
out vec2 texTcoords;
out vec3 FragPos;
out vec4 lightFragPos;

void main()
{
    texTcoords = aTexCoords;
    Normal = mat3(NormalModel) * aNormal; 
    FragPos = vec3(model * vec4(aPos,1.0));
    gl_Position = projection * view * model * vec4(aPos, 1.0); 
    lightFragPos = lightProjection * lightview * model * vec4(aPos,1.0);
}