#pragma once
#include "Mesh.h"
#include <assimp/Importer.hpp>
#include <assimp/scene.h>
#include <assimp/postprocess.h>

class Model
{
public:
	/*  ����   */
	Model(const char* path);
	void Draw(Shader& shader, bool isInstance = false, int amount = 0);
	vector<Mesh> GetMeshs();
	void DeleteMesh();
	void SetOffset(int x);
private:
	/*  ģ������  */
	vector<Mesh> meshes;
	string directory; // ���ģ�͵�ַ��·��
	vector<Texture> textures_loaded;
	/*  ����   */
	void loadModel(string path);
	void processNode(aiNode* node, const aiScene* scene);
	Mesh processMesh(aiMesh* mesh, const aiScene* scene);
	vector<Texture> loadMaterialTextures(aiMaterial* mat, aiTextureType type,
		string typeName);
};