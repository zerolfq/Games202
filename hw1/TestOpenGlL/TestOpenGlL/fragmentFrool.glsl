#version 410 core
out vec4 FragColor;

in vec3 Normal;
in vec2 texTcoords;
in vec3 FragPos;
in vec4 lightFragPos;


uniform vec3 lightPos;
uniform vec3 viewPos;
uniform vec3 Intensity;
uniform vec3 ks;
uniform sampler2D DepthMap;


#define NUM_SAMPLES 40
#define BLOCKER_SEARCH_NUM_SAMPLES NUM_SAMPLES
#define PCF_NUM_SAMPLES NUM_SAMPLES
#define NUM_RINGS 10

#define EPS 1e-3
#define PI 3.141592653589793
#define PI2 6.283185307179586
#define LIGHT_RINGS 30

float bias = 0.005;

highp float rand_1to1(highp float x ) { 
  // -1 -1
  return fract(sin(x)*10000.0);
}

highp float rand_2to1(vec2 uv ) { 
  // 0 - 1
	const highp float a = 12.9898, b = 78.233, c = 43758.5453;
	highp float dt = dot( uv.xy, vec2( a,b ) ), sn = mod( dt, PI );
	return fract(sin(sn) * c);
}

vec2 poissonDisk[NUM_SAMPLES];

void poissonDiskSamples( const in vec2 randomSeed,const float range) {

  float ANGLE_STEP = PI2 * float( NUM_RINGS ) / float( NUM_SAMPLES );
  float INV_NUM_SAMPLES = range / float( NUM_SAMPLES );

  float angle = rand_2to1( randomSeed ) * PI2;
  float radius = INV_NUM_SAMPLES;
  float radiusStep = radius;

  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    poissonDisk[i] = vec2( cos( angle ), sin( angle ) ) * pow( radius, 0.75 );
    radius += radiusStep;
    angle += ANGLE_STEP;
  }
}

void uniformDiskSamples( const in vec2 randomSeed ) {

  float randNum = rand_2to1(randomSeed);
  float sampleX = rand_1to1( randNum ) ;
  float sampleY = rand_1to1( sampleX ) ;

  float angle = sampleX * PI2;
  float radius = sqrt(sampleY);

  for( int i = 0; i < NUM_SAMPLES; i ++ ) {
    poissonDisk[i] = vec2( radius * cos(angle) , radius * sin(angle)  );

    sampleX = rand_1to1( sampleY ) ;
    sampleY = rand_1to1( sampleX ) ;

    angle = sampleX * PI2;
    radius = sqrt(sampleY);
  }
}

float findBlocker(vec2 uv,float zReceiver){
	const int range = 1;
	poissonDiskSamples(uv,range);
	float cnt = 0.0;
	float ans = 0.0;
	vec2 texelSize = 1.0 / textureSize(DepthMap, 0);
	for (int i = 0; i< NUM_SAMPLES;i++){
		float closestDepth = texture(DepthMap, uv + poissonDisk[i] * texelSize).r; 
		cnt += zReceiver - bias < closestDepth ? 0.0 : 1.0;
		ans += zReceiver - bias < closestDepth ? 0.0 :closestDepth;
	}

	return ans / cnt;
}

float PCSS(vec4 fragPosLightSpace){
	vec3 projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;
    // 变换到[0,1]的范围
    projCoords = projCoords * 0.5 + 0.5;
	float currentDepth = projCoords.z;
	float blocaker = findBlocker(projCoords.xy,currentDepth);

	float cnt = 0.0;
	float ans = 0.0;
	vec2 texelSize = 1.0 / textureSize(DepthMap, 0);

	float range = float(float(LIGHT_RINGS) * (currentDepth - blocaker) / blocaker);
	poissonDiskSamples(projCoords.xy,range);
	for (int i = 0; i< NUM_SAMPLES;i++){
		float closestDepth = texture(DepthMap, projCoords.xy + poissonDisk[i] * texelSize).r; 
		ans += currentDepth - bias < closestDepth  ? 1.0 : 0.0;
		cnt += 1.0;
	}
	return ans / cnt;
}

float PCF(vec4 fragPosLightSpace){
	vec3 projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;
    // 变换到[0,1]的范围
    projCoords = projCoords * 0.5 + 0.5;
	float currentDepth = projCoords.z;
	float cnt = 0.0;
	float ans = 0.0;
	vec2 texelSize = 1.0 / textureSize(DepthMap, 0);
	const float range = 8;
	poissonDiskSamples(projCoords.xy,range);
	//uniformDiskSamples(projCoords.xy);
	for (int i = 0; i< NUM_SAMPLES;i++){
		float closestDepth = texture(DepthMap, projCoords.xy + poissonDisk[i] * texelSize).r; 
		ans += currentDepth - bias < closestDepth  ? 1.0 : 0.0;
		cnt += 1.0;
	}
	return ans / cnt;
}

float ShadowCalculation(vec4 fragPosLightSpace){
	vec3 projCoords = fragPosLightSpace.xyz / fragPosLightSpace.w;
    // 变换到[0,1]的范围
    projCoords = projCoords * 0.5 + 0.5;
    // 取得最近点的深度(使用[0,1]范围下的fragPosLight当坐标)
    float closestDepth = texture(DepthMap, projCoords.xy).r; 
    // 取得当前片段在光源视角下的深度
    float currentDepth = projCoords.z;
    // 检查当前片段是否在阴影中
	float shadow = currentDepth - bias < closestDepth  ? 1.0 : 0.0;

    return shadow;
}

vec3 blinnPhong(){
	vec3 color = vec3(0.5,0.5,0.5);
	color = pow(color, vec3(2.2));

	vec3 ambient = 0.05 * color;

	vec3 lightDir = (lightPos - FragPos);
	float lightLen = length(lightDir);
	lightDir = normalize(lightDir);

	vec3 normal = normalize(Normal);

	bias = max(bias* (1.0 - dot(normal, lightDir)), bias);

	float diff = max(dot(lightDir,normal),0.0);
	vec3 light_atten_coff = Intensity / (pow(lightLen,2));
	vec3 diffuse = diff * light_atten_coff * color;
	
	vec3 viewDir = normalize(viewPos - FragPos);
	vec3 halfDir = normalize((lightDir + viewDir));
	float spec = pow(max(dot(halfDir, normal), 0.0), 32.0);
	vec3 specular = ks * light_atten_coff * spec;
	

	float visibility = PCSS(lightFragPos);


	vec3 radiance = (ambient + (diffuse + specular) * visibility);
	vec3 phongColor = pow(radiance, vec3(1.0 / 2.2));

	return phongColor;
	//return pow(vec3(visibility), vec3(1.0 / 2.2));
}

void main()
{       
	FragColor =  vec4(blinnPhong() ,1.0);
}