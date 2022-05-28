#ifndef MESH_H
#define MESH_H

#include <glad/glad.h> // holds all OpenGL type declarations

#include <glm.hpp>
#include <gtc/matrix_transform.hpp>

#include "Shader.h"

#include <string>
#include <vector>
using namespace std;

#define MAX_BONE_INFLUENCE 4

struct Vertex {
	// position
	glm::vec3 Position;
	// normal
	glm::vec3 Normal;
	// texCoords
	glm::vec2 TexCoords;
	// tangent
	//glm::vec3 Tangent;
	//// bitangent
	//glm::vec3 Bitangent;
	////bone indexes which will influence this vertex
	//int m_BoneIDs[MAX_BONE_INFLUENCE];
	////weights from each bone
	//float m_Weights[MAX_BONE_INFLUENCE];
};

struct Texture {
	unsigned int id;
	string type;
	string path;
};

class Mesh {
public:
	// mesh Data
	vector<Vertex>       vertices;
	vector<unsigned int> indices;
	vector<Texture>      textures;

	// constructor
	Mesh(vector<Vertex> vertices, vector<unsigned int> indices, vector<Texture> textures);

	// render the mesh
	void Draw(Shader& shader,bool isInstance = false,int amount = 0);
	void DeleteMesh();
	unsigned int GetVAO();
	void SetOffset(int x);
private:
	// render data 
	int offset;
	unsigned int VBO, EBO;
	unsigned int VAO;
	// initializes all the buffer objects/arrays
	void setupMesh();
};
#endif