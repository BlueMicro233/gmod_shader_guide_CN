// example5 的示例纹理
sampler BASETEXTURE : register(s0);

// 被顶点着色器定义的输入结构
struct PS_INPUT 
{
	float2 uv : TEXCOORD0;
};

float4 main(PS_INPUT frag) : COLOR 
{
	return float4(tex2D(BASETEXTURE, frag.uv).xyz, 1.0);
};