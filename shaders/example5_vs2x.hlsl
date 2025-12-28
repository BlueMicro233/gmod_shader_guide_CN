// 顶点着色器对应于某个位置的顶点

// 这个头文件包含一些很有用的函数，这个例子里我们用的是 SkinPosition 以及 cViewProj 函数
#include "common_vs_fxc.h"

// 这是一个 screenspace_general 顶点着色器的输入结构示例
// 这里，为了让模型可以被明显看到，我们需要贴个纹理上去，所以这里将定义一个模型的纹理 UV 坐标
struct VS_INPUT 
{
	float4 vPos		 : POSITION;
	float4 vTexCoord : TEXCOORD0;
};

// 所有顶点着色器都需要给像素着色器传点什么数据
// 在这个示例下，我们给像素着色器传模型的 UV 坐标
struct VS_OUTPUT 
{
	float4 proj_pos : POSITION;		// 屏幕空间的位置
	float2 uv       : TEXCOORD0;	// 我们传给像素着色器的 UV 坐标
};

// 以下主函数代码运行在模型的每一个顶点上
VS_OUTPUT main(VS_INPUT vert) 
{
	// SkinPosistion() 负责把模型空间的顶点变换到世界空间去
	float3 world_pos;
	SkinPosition(0, vert.vPos, 0, 0, world_pos);

	// 这部分不是必须的，但我觉得这些代码看上去很养眼
	// 把 10x10 网格里的每个顶点都进行旋转
	// 这个可以模拟出 PS1 主机游戏上的模型旋转效果
	world_pos /= 10.0;
	world_pos = floor(world_pos);	// 等效于: world_pos = float3(floor(world_pos.x), floor(world_pos.y), floor(world_pos.z));
	world_pos *= 10.0;
	// ↑ 想一想：注释掉上面的代码会发生什么变化？

	// 将世界空间坐标投影到屏幕上
	float4 proj_pos = mul(float4(world_pos, 1), cViewProj);

	// 定义我们的输出结构 (把所有值都初始化为 0)
	VS_OUTPUT output = (VS_OUTPUT)0;
	output.proj_pos = proj_pos;
	output.uv = vert.vTexCoord.xy;

	return output;
};