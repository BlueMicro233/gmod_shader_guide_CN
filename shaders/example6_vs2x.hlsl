
/// 简单的果冻着色器，使顶点产生抖动

#include "common_vs_fxc.h"

// 默认顶点数据输入结构
struct VS_INPUT 
{
	float4 vPos		 : POSITION;
	float4 vTexCoord : TEXCOORD0;
};

// 默认顶点数据输出结构
struct VS_OUTPUT 
{
	float4 proj_pos : POSITION;		// 屏幕空间投影坐标
	float2 uv       : TEXCOORD0;	// 我们将要传送给像素着色器的 UV 坐标
};

float hash(float x) 
{
	return sin(x * 25.0);		// 一个把任意时间映射到 [-1, 1] 的周期函数
}

// 应用该顶点着色器的每个顶点都要经过以下处理
VS_OUTPUT main(VS_INPUT vert) 
{
	float3 world_pos;
	SkinPosition(0, vert.vPos, 0, 0, world_pos);

	// 在 shader_examples.lua 里，已经设定 ambient cube 正面光照值的 y 分量为 CurTime 的值
	// 所以我们直接通过 cAmbientCubeX[0].y 读取元数据
	float curtime = cAmbientCubeX[0].y;

	// 让顶点动起来！
	world_pos.x += hash(world_pos.x + curtime);
	world_pos.y += hash(world_pos.y + curtime);
	world_pos.z += hash(world_pos.z + curtime);

    // 将顶点从世界空间转换到裁剪空间
    // 顶点坐标在裁剪空间中进行裁剪（剔除不可见的部分）
    // 在裁剪之后，GPU 会自动执行透视除法，将裁剪空间坐标转换为归一化设备坐标（NDC）
	float4 proj_pos = mul(float4(world_pos, 1), cViewProj);

	VS_OUTPUT output = (VS_OUTPUT)0;
	output.proj_pos = proj_pos;
	output.uv = vert.vTexCoord.xy;

	return output;
};