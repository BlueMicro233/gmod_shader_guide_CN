# GMod 着色器综合教程
原作者：[Meetric](https://github.com/meetric1)

本中文教程具有一定内容补充，但不会改变总体框架。Bilibili 课程主页：[【深入理解起源引擎】着色器综合教程](https://127.0.0.1/)

# 前言
你好呀！欢迎来看我的 GMod 着色器教程！

本指南汇集了我过去几年制作 GMod 着色器所学到的一切。我做这个教程的目的是为初学者讲解**着色器**编程，尤其是起源引擎和 GMod 的着色器编程。

**本指南假定你已掌握编程基础，例如基本语法、变量和条件判断等。**

如果你不懂编程，建议先做几个 GLua 项目再回来看本指南，因为它比较有技术性而且有一定复杂度。

> [!TIP]
> 译者建议可以看看 [CS50x](https://cs50.harvard.edu/x/) 的前面几节课，主题分别是 C, Arrays, Algorithms, Memory 和 Data Structures。

> [!NOTE]
> 本指南**并不涵盖关于 GMod 着色器和 HLSL 的所有内容**，但我会尽力包含所有相关的重要部分。如果你有更新更好的创作，欢迎分享！欢迎创建 issue 或提交 pull request 并添加你自己的着色器示例。

> [!NOTE]
> **为了使本指南的例子正常运行，请在** `gm_construct` **图中加载游戏！！！**

# 目录
- [GMod 着色器综合教程](#gmod-着色器综合教程)
- [前言](#前言)
- [目录](#目录)
- [什么是着色器？](#什么是着色器)
- [着色器管线](#着色器管线)
- [screenspace\_general](#screenspace_general)
- [入门](#入门)
- [\[示例 1\] — 你的第一个着色器](#示例-1--你的第一个着色器)
- [\[示例 2\] — 像素着色器](#示例-2--像素着色器)
- [\[示例 3\] — 像素着色器常量](#示例-3--像素着色器常量)
- [\[示例 4\] - GPU 架构](#示例-4---gpu-架构)
    - [架构基础](#架构基础)
    - [控制流](#控制流)
    - [循环](#循环)
- [\[示例 5\] - 顶点着色器](#示例-5---顶点着色器)
- [\[示例 6\] - 顶点着色器常量](#示例-6---顶点着色器常量)
- [\[示例 7\] - 渲染目标 Render Target](#示例-7---渲染目标-render-target)
- [\[示例 8\] - 多渲染目标 (MRT)](#示例-8---多渲染目标-mrt)
- [\[示例 9\] - 深度缓冲](#示例-9---深度缓冲)
- [\[示例 10\] - 模型上的着色器](#示例-10---模型上的着色器)
- [\[示例 11\] - 实例化网格 (IMeshes)](#示例-11---实例化网格-imeshes)
- [\[示例 12\] - 点精灵](#示例-12---点精灵)
- [\[示例 13\] - 3D 材质](#示例-13---3d-材质)
- [完成啦！](#完成啦)

# 什么是着色器？
你可能会问自己，`着色器是什么？我为什么要关心这个问题？`好吧，那你有没有想过游戏是如何展示出如此复杂的几何体和特效的呢？在你玩的*任何游戏*中，你的 [GPU](https://en.wikipedia.org/wiki/Graphics_processing_unit) 上会一直运行一些代码来决定屏幕上每个像素的颜色。对，你没听错——**每一个像素都有相应的代码在实时决定它的颜色**，这正是我们今天要写的东西。

下面是一些很酷的着色器示例：
**GMod 草地着色器（作者：Meetric）：**\
<img src="https://github.com/user-attachments/assets/66115f5f-2375-4429-a73d-253d35cda73d" width="80%" height="80%">\
**GMod 视差遮蔽映射（Evgeny Akabenko）：**\
<img src="https://github.com/user-attachments/assets/596fe2db-c05d-4a37-b293-a2764caeb349" width="80%" height="80%">\
**GMod 体积云（Evgeny Akabenko）：**\
![Untitled](https://github.com/user-attachments/assets/0aae45f1-9d7d-49b3-acc3-df3ae7ed8fcd)\
**Half Life: Alyx 液体着色器（Valve）：**\
![ebd09ce02b4b9b7c3d59eb442ee6afe22f20d291](https://github.com/user-attachments/assets/0339658e-a9ae-4b0a-8aff-c0f55a11ae46)

# 着色器管线
所有图形 API 都包含所谓的[图形流水线](https://en.wikipedia.org/wiki/Graphics_pipeline)（Graphics Pipeline），本质上是一组通用的、固定的流水线式阶段，它将 3D 场景数据转换为 2D 屏幕上显示的内容。

图形流水线示意图：\
![图形流水线](https://github.com/user-attachments/assets/5683817d-1d03-448d-b019-3870d5a9852d)\
<sup><sub>(图片来自 [Vulkan Tutorial](https://vulkan-tutorial.com/Drawing_a_triangle/Graphics_pipeline_basics/Introduction))<sup><sub>

本指南不会深入到数学上的细节。目前你只需要知道：
1. 你看到的每个模型都是由三角形和顶点组成的（在 Source 中可在控制台输入 [mat_wireframe](https://developer.valvesoftware.com/wiki/Mat_wireframe) 将顶点网格可视化）。
2. 每个顶点都会被发送到 GPU，在顶点着色器中完成将其**变换到屏幕空间**的操作。
3. 顶点处理完成后会执行像素着色器（像素/片元着色器），像素着色器负责对[光栅化](https://en.wikipedia.org/wiki/Rasterisation)后的像素进行填色，这一步由你写的着色器代码控制。

# screenspace_general
如果你之前已经了解过 `.vmt` 的工作方式，可以直接跳过本节。

Source 引擎使用一种名为 `vmt` 的自定义材质文件扩展，用来控制材质的各类参数（flag）。在本仓库中我们使用了名为 `screenspace_general` 的着色器，它允许我们指定自定义的顶点和像素着色器。

> [!NOTE]
> 一个材质可以包含很多 flag，但只能指定一个着色器。

尽管名字里有 "screenspace"（屏幕空间），但是 `screenspace_general` 在 CS:S 2015 引擎分支中并非真正的屏幕空间着色器，它更像一个用于测试的通用着色器。

更多 `.vmt` 相关信息:\
https://developer.valvesoftware.com/wiki/VMT 

更多 `screenspace_general` 相关信息:\
https://developer.valvesoftware.com/wiki/Screenspace_General 

`screenspace_general` 源码 (来自 CS:S 2015):\
https://github.com/lua9520/source-engine-2018-cstrike15_src/blob/master/materialsystem/stdshaders/screenspace_general.cpp

# 入门
首先，将本仓库克隆到 `GarrysMod/garrysmod/addons` 文件夹下。仓库内包含 13 个示例，可以在游戏内运行并跟随练习，每个示例讲解一个着色器具体主题。希望通过阅读本指南并在游戏中运行和修改相应的着色器，你能更好地理解其工作原理。

加载完成后，在控制台输入 `shader_example 1` 来查看第一个示例（会在屏幕上显示一个红色矩形）。虽然看上去很简单，但这是一切的开始。

# [示例 1] — 你的第一个着色器
要学习制作着色器，首先得知道如何编译它。本指南选择使用 [ShaderCompile](https://github.com/SCell555/ShaderCompile)（支持 64 位），因为它仅仅是一个单程序，比普通的 Source 着色器编译环境的繁杂配置简单许多。

看完 `shader_example 1` 的效果后，我们先把目光移出 GMod 游戏，进入到 `gmod_shader_guide/shaders` 目录。所有着色器源码都在后缀为 `.hlsl` 的文件里面，目录中还有若干 `.h` 头文件，我们暂时不管它们，后面会用到。

着色器文件名格式很重要，可分为以下 5 部分：
1. `example1` — 着色器名称；
2. `_` — 必须的分隔符；
3. `ps` — 表示像素着色器（pixel shader），也可以是 `vs`（顶点着色器）；
4. `2x` — 着色器版本，本指南使用兼容性更广的 `2x`；
5. `.hlsl` — 源文件扩展名，HLSL 是高级着色器语言（High-Level Shader Language）的缩写;

按照要求命名后，把 `example1_ps2x.hlsl` 拖到 `build_single_shader.bat` 上即可编译，生成的着色器中间代码会放入 `fxc` 目录，GMod 会从这里加载着色器。

编译后的着色器为 `.vcs`（Valve Compiled Shader），它是一种中间代码，显卡驱动会实时地把它翻译成 GPU 能读懂的机器指令。

重新进入游戏并在控制台键入 `shader_example 1`，如果能在屏幕左上角看到一个**亮绿色**的矩形，就说明编译成功。

若看到的还是红色矩形，说明旧着色器没被覆盖，请检查是否遗漏步骤或查看编译错误。

> [!NOTE]
> 修改着色器但不改 `.vmt` 时需要重启游戏来重新加载。\
> 在你真正开始学习如何编辑 `.vmt` 之前，建议直接重启游戏，这是最简单的方法。添加启动选项 `-noworkshop` 有时会大大缩短加载时间。

> [!TIP]
> 当你开始写自己的着色器时，请尽量给它们取一个有辨识度的、不普通的名称，否则可能会出现名称冲突。

> [!NOTE]
> Shader Model `30`(SM 3.0) 在 Linux 系统上未经充分测试，某些功能可能无法按预期工作。\
> 如果你在 Linux 上发现着色器相关问题，请提交 pull request 或在本仓库开 issue 以便记录和改进。

![image](https://github.com/user-attachments/assets/f009c4a2-4e2b-4b65-a297-7f8fa9434880)

# [示例 2] — 像素着色器
像素着色器（Pixel / Fragment shader）是逐像素运行的代码。在[示例 1]中我们学会了编译基础着色器，现在我们尝试修改一个已有的像素着色器。

先试着在控制台输入 `shader_example 2` 看看效果：![image](https://github.com/user-attachments/assets/e33ce1e3-12d8-4bb8-941f-bc7b1c8f4dce)

打开 `gmod_shader_guide/shaders/example2_ps2x.hlsl`，**源码带有大量注释，你需要通过阅读它们来学习 HLSL 语法**（类似 C/C++）。**修改完成后别忘了重新编译！**

如果想在游戏中热加载修改，先将编译输出在 `gmod_shader_guide/shaders/fxc` 的 IL 文件 `example2_ps20b.vcs` 重命名为 `example2a_ps20b.vcs`，然后修改对应材质文件（`gmod_shader_guide/materials/gmod_shader_guide/example2.vmt`）中的 `$pixshader` 所指的像素着色器文件为新的 `$pixshader "example2a_ps20b"`，保存后查看效果。

> [!NOTE]
> 使用热加载时，同名着色器不能重复使用，**需要给它更换新名称**。比如我们刚刚修改的像素着色器名字叫 `example2a_ps20b` ，如果修改后再次热加载一遍，就要把名字改成 `example2b_ps20b` 或者类似的与上一次不同的名称。

> [!NOTE]
> 在保存 .vmt 着色器参数之前，请确保对应的 .vcs 着色器文件是存在的。

> [!TIP]
> `.vmt` 中的 `$ignorez 1` 对于 screenspace 类着色器是**必须**的，否则可能无法正常渲染。

> [!TIP]
> `.vmt` 中的 `$vertextransform 1` 确保坐标不在屏幕空间下，这在使用 `render.` 函数时很有用，因为那一系列函数都是世界空间下的。


# [示例 3] — 像素着色器常量
到现在你应该对 HLSL 语法有了基本的了解，本节展示一个略复杂的像素着色器。在控制台输入 `shader_example 3` 查看效果（如上图）。

此着色器从纹理采样，并将游戏的全局时间 `CurTime` 作为输入传入以实现动画效果。每个 `.vmt` 文件代表一个材质及其着色器，我们通过在 `.vmt` 中设置全局数值来把数据传给着色器。

本示例使用 `$c0_x` 传入一个浮点数作为 `CurTime`，相关实现可在 `gmod_shader_guide/lua/autorun/client/shader_examples.lua` 的 `example3` 函数中看到。

注意：`screenspace_general` 可用的全局常量数量有限（参见[本链接](https://developer.valvesoftware.com/wiki/Screenspace_General)），但一般情况下已经够了。本示例在 `.vmt` 中还定义了 `$c0_y`（尽管 HLSL 源码中未用到），这是为了演示你可以在 `.vmt` 中放入额外参数并在着色器内以不同方式利用它们。

现在打开 `example3.vmt` 查看其参数，尝试修改 `basetexture`（例如 `hunter/myplastic` 或 `phoenix_storms/wood`）来观察变化；然后打开 `example3_ps2x.hlsl` 阅读其源码，尝试用未使用的 `$c0_y` 做些实验，看看能做出什么效果。

> [!TIP]
> Source Engine 还有一些未记录的像素着色器常量，它们可以在 [这里](https://github.com/ficool2/sdk_screenspace_shaders/blob/94071cb6d464a7c04ced726770ca87a7ecd5d9a1/shadersrc/common.hlsl#L29) 找到。\
> 其中大多数可能没什么用，但有些时候会派上用场。

# [示例 4] - GPU 架构
我们已经了解像素着色器的基本语法和总体控制，是时候开始研究 GPU 架构与控制流了。

你需要把 GPU 当作一台完全不同的计算机来思考——事实上它确实是：GPU 有自己的处理器、显存、主板、固件，甚至独立散热。

与 CPU 相比，GPU 的工作方式截然不同，所以你需要以不同于常规的思路来考虑问题。

### 架构基础
![Blackwell GB202 GPU](https://www.nvidia.cn/content/dam/en-zz/Solutions/geforce/news/rtx-50-series-graphics-cards-gpu-laptop-announcements/nvidia-blackwell-die-shot.png)\
<sup><sub>(图片来自 NVIDIA)<sup><sub>


GPU 架构专为特定指令集设计，以实现更快的图形处理速度。GPU 在浮点运算方面表现*极其出色*。事实上，主流 GPU（2025 年, 以 RTX 5060 为例）每秒可执行 19 万亿次（即 19,000,000,000,000 次）浮点运算，这个速度远超顶级 CPU。

然而遗憾的是，这几乎是 GPU 的唯一优势。GPU 仅擅长**高速**浮点（及整数）**运算**，意思是它们速度惊人但功能受限（可理解为*更笨的 CPU*）。我们使用的 Shader Model 20b 标准甚至不支持双精度浮点运算。即便你设法实现了双精度运算，我仍建议避免使用——这类运算极其缓慢，且完全违背了 GPU 架构的设计初衷。

### 控制流

接下来我们谈谈控制流。在 CPU 执行的程序（如一般的 Lua、C++ 程序）中，`if` 语句并不算什么大问题。通过条件判断来控制代码执行通常对性能影响不大。

然而在 GPU 上，情况却截然相反。**你应该尽可能避免使用 `if` 语句**。具体原因有些复杂，但我会尽力解释。

在 GPU 中，称为“warp”的线程组（在 AMD GPU 上叫做“wavefront”）会在屏幕区域内启动异步计算。由于 GPU 架构特性（单指令多线程, SIMT），当出现分支时，这种分歧会**导致未分支的线程挂起直至语句执行完毕**，这会大大降低 GPU 的并行率，使执行性能降低，因为 `if` 语句的两侧是严格同步执行的—— GPU 并没有分支预测这种复杂控制逻辑，这就是为什么说 GPU 相较于 CPU *更笨*。

以下是一个示例：

```
if (PIXEL.x < 2)
{
    do_work_1();
}
else
{
    do_work_2();
}
```

假设有一个包含 4 个线程的 warp，它们的线程 ID 分别是 `0`、`1`、`2` 和 `3`，并假设我们正在计算一行 4 个像素。当 GPU 执行到 `if` 语句时，线程 `2` 和 `3` 会被挂起，直到线程 `0` 和 `1` 完成 `do_work_1()` 的执行。随后，线程 `0` 和 `1` 被挂起，`2` 和 `3` 被重新激活；待 `do_work_2()` 完成后，所有线程重新激活并继续执行代码。这实际上使 `do_work_1()` 和 `do_work_2()` 的计算时间翻倍。

但请不要因此产生误解。使用 `if` 语句并不总是导致性能减半，这仅在最坏情况下成立——**若所有线程都选择同一分支，效率并不会损失**。

若以上解释仍令人困惑，那么只需记住：**应尽可能避免分支**，包括但不限于：`if-else`、`continue` 和 `break` 语句。

### 循环
在本指南中，我们使用的是 Shader Model 20b，这个版本有点特别，因为所有循环都需要展开处理（详见：https://en.wikipedia.org/wiki/Loop_unrolling），并且不是动态的。

Shader Model 30 虽支持动态循环，但目前建议避免使用—— GPU 上跑无限循环会导致停机，轻则显卡驱动崩溃，重则需要重启整个系统。

为了进一步加深理解，请导航至 `gmod_shader_guide/shaders` 目录，查看 `example4_ps2x.hlsl` 着色器源文件。

# [示例 5] - 顶点着色器

既然我们已经掌握了像素着色器的基础知识，现在该深入学习顶点着色器了。

正如我在[着色器管线](#the-shader-pipeline)中解释的那样，顶点着色器的主要职能是将 3D 坐标转换到 2D 屏幕上。就像像素着色器跑在每个像素上一样，每个顶点都运行顶点着色器代码，否则它们根本不会被最终呈现在屏幕上。

顶点着色器至关重要，因为它还向像素着色器传递信息。通常会传递诸如[纹理坐标](https://en.wikipedia.org/wiki/UV_mapping)之类的结构，但具体传递什么完全取决于你。

在本顶点着色器示例中，我们将引入 Valve Helper Function。源代码位于你可能见过的 `.h` 文件中。

这些文件包含大量实用的函数和定义供我们调用。例如 `cEyePos` 函数可返回玩家当前的视角位置（这功能在各类着色器中均有广泛应用）。

现在，在 GMod 控制台输入`shader_example 5`，快速查看当前着色器的渲染效果。输出应如下所示：\
<img src="https://github.com/user-attachments/assets/9efe05ee-a962-45df-aa8b-1b84e297f655" width="50%" height="50%">

接着查看`example5_ps2x.hlsl`文件，你可以自由探索并修改代码，看看会发生什么。

> [!NOTE]
> 这次就不需要 vmt 文件里的 `$vertextransform` 和 `$ignorez` 这俩 flag 了，因为我们现在不做屏幕空间的操作。

> [!NOTE]
> 你 **不能** 用顶点着色器去采样纹理，这是早期固定管线 GPU 架构的历史原因所致，有兴趣的话可以看 B 站课程了解。

> [!TIP]
> 在默认情况下，一个表面的正反两面都会被渲染。因为一般渲染背面并没有什么用而且徒增性能消耗，所以一般会在 vmt 里加个 `$cull` 的 flag 并设置为 1 来做背面剔除优化。

> [!TIP]
> 出于性能优化的考量，一般都尽可能地让运算跑在顶点着色器上，因为一般情况下像素着色器的运行次数远多于顶点着色器。

# [示例 6] - 顶点着色器常量

<img width="484" height="530" alt="meme" src="https://github.com/user-attachments/assets/a4e2bb67-879d-4d06-b268-2bc7d3a89725" />

`screenspace_general` 没有为顶点着色器指定用于传入用户自定义数据的常量。

为了将元数据传入顶点着色器，我们需要通过**修改现有常量**来实现，因为没有专门的自定义常量可供传入。这种方法相当 hack，但我目前尚未发现其他可行方案。

我见过有人利用雾数据和投影矩阵实现，但针对当前场景我选择采用环境光照探针（ambient cube）。此方案兼容性强，最多可支持 18 个（对应 6 个面的 RGB 值）自定义输入参数。

若存在更优雅的实现方式，欢迎在此仓库提交 issue 或 pull request 以便完善文档！

以下是`shader_example 6`的预期效果图：\
<img src="https://github.com/user-attachments/assets/ca379402-9bb6-41de-94cc-011b5151bb48" width="50%" height="50%">

看完`shader_example 6`的效果后，请打开`example6_vs2x.hlsl`和`gmod_shader_guide/lua/autorun/client/shader_examples.lua`以理解其工作原理。

> [!NOTE]
> 这里像素着色器代码复用 [示例 5](#示例-5---顶点着色器)

# [示例 7] - 渲染目标 Render Target
We're going to take a small detour with shaders to talk about render targets, as they are very important when implementing your own render pipelines.

The concept of a render target is quite simple. A render target is just a texture that you can edit.\
Unless specified otherwise (using IMAGE_FORMAT) a render target has 4 color channels (Red, Green, Blue, Alpha) which you should already understand fairly well.

`shader_example 7` Shows you different flags you can use in a 16x16 render target.\
![image](https://github.com/user-attachments/assets/32b1a036-b92b-47f7-9591-68fa527a3aee)

Because this example is more of an explanation, it doesn't use any custom shaders. And since I don't really have anything else to say, I am going to document some of my findings about render targets which some people may find useful.

> [!NOTE]
> Despite what the wiki tells you, render targets do not have mipmapping.

> [!NOTE]
> In a shader you should still return a color space of `0.0 - 1.0` regardless of the render targets IMAGE_FORMAT

> [!NOTE]
> Source Engine is really weird and does gamma correction on render targets (INCLUDING on the alpha channel!), meaning you will likely want to use the `$linearwrite` flag on your shader if you want exact results. This is particularly useful with UI shaders

> [!NOTE]
> MATERIAL_RT_DEPTH_SHARED does not work when MSAA is enabled, and will automatically be set to MATERIAL_RT_DEPTH_SEPARATE

> [!NOTE]
> You can input a render target as a sampler with [IMaterial:SetTexture](https://wiki.facepunch.com/gmod/IMaterial:SetTexture)

# [示例 8] - 多渲染目标 (MRT)
Multi-render target (abbreviated MRT) is a rendering technique which allows a shader to output to multiple render targets in a single pass. This means you can output more useful data which may be required in later stages of a rendering pipeline.

![image](https://github.com/user-attachments/assets/d4105837-485f-4677-a802-99740487f91f)

Example 8 is simply 2 different postprocessing shaders of the [framebuffer](https://en.wikipedia.org/wiki/Framebuffer) (the rendered frame) running at the same time. When you type `shader_example 8`, you will see 2 rendertargets. The top is the first output, the bottom is the second. MRT allows for up to 4 separate render targets to be written to at a time.

Take a look at `example8_ps2x.hlsl` for the syntax.

> [!NOTE]
> When doing MRT, ensure you output to render targets that are the same resolution as your render context (usually just the screen resolution), otherwise you may run into undefined behavior.

> [!NOTE]
> Any operations on the GPU which read or write memory are quite expensive, this includes (but is not limited to) any of the texture sampler functions (tex1D, tex2D, tex2Dlod, etc) and MRT

# [示例 9] - 深度缓冲
This isn't something that everybody really needs, but it can be handy for a few different operations, so I'll document it.

A [depth buffer](https://en.wikipedia.org/wiki/Z-buffering) is basically just a rendertarget that stores the depth of a pixel on the screen. It essentially determines what triangles are allowed to draw on top of other triangles. A lower depth value means that a triangle is closer to the screen.

Example of the depth buffer:\
![250px-R_depthoverlay](https://github.com/user-attachments/assets/64aac3e9-bff1-4a06-9fcb-f31173318ce7)

During rasterization, the GPU will automatically compute the depth of a triangle, but we can actually override this using the DEPTH0 semantic in any pixel shader.

`shader_example 9` is a good example of this. This sphere being drawn only uses 2 triangles (I have outlined them with wireframe), but has pixel level precision.\
![image](https://github.com/user-attachments/assets/cf8a7a96-b465-458e-a314-03faf14b721b)

Take a look at `example9_vs2x.hlsl` and `example9_ps2x.hlsl` for syntax and explanation of how it works

> [!NOTE]
> If you want to write depth, screenspace_general requires the `$depthtest` flag in the .vmt to be set to 1

> [!NOTE]
> The DEPTH0 semantic disables culling optimizations and creates shader overdraw, which can cause high [fillrates](https://en.wikipedia.org/wiki/Fillrate) and negatively impact performance. Avoid it if possible.

# [示例 10] - 模型上的着色器
screenspace_general has a flaw, and unfortunately this flaw is stopping the shader from being able to be used on normal props without some issues.\
![image](https://github.com/user-attachments/assets/9b92b1e2-2844-46ff-b443-4ad8b82e9942)

The problem has to do with [this line of code](https://github.com/sr2echa/CSGO-Source-Code/blob/dafb3cafa88f37cd405df3a9ffbbcdcb1dba8f63/cstrike15_src/materialsystem/stdshaders/screenspace_general.cpp#L173). Remember before when we were talking about the depth buffer? This line basically says "ALWAYS WRITE TO THE DEPTH BUFFER NO MATTER WHAT", meaning that even if a triangle is further than another triangle when it is being rendered, depth is still being written to. This is a problem when considering normal rendering operations.

We learned however that we can override this behavior with the DEPTH0 semantic and the `$depthtest` flag. While you *could* fix it this way, I want to do a more trivial approach which doesn't involve this method (Remember I briefly talked about it being not ideal).

To fix this problem trivially, I introduce `render.OverrideDepthEnable`, which allows you to override this flag.

Take a look at `shader_example 10` for a visualization that toggles `render.OverrideDepthEnable`:\
![image](https://github.com/user-attachments/assets/908568a3-cd1d-4740-95a9-5aa091872220)

This of course begs the question, `"What if I want to use my shader on a prop, like a normal material?"`.\
And truthfully I don't know a fix for that. You will need to use the DEPTH0 semantic.

You will also need to have flags `$softwareskin 1`, `$vertexnormal 1`, and `$model 1` on your .vmt so the model renders properly.

`$softwareskin` basically disables normals compression, and while you *can* have compression enabled on your shader (you will need to do `#define COMPRESSED_VERTS 1` before including `common_vs_fxc.h`, then call `DecompressVertex_Normal` on your modelspace normal before skinning it), but for simplicity I would suggest avoiding this for now and just setting the .vmt flag.

`$vertexnormal` basically just says "Hey! this model has normals!" and lets entities / props render normally. Otherwise the material won't work.

And finally, `$model` just tells SourceEngine that you can put your material on a physical entity (I'm honestly not too sure why this flag exists. Is it for performance reasons? So shaders load faster? I honestly don't know).

# [示例 11] - 实例化网格 (IMeshes)

I think its time we should move into IMeshes, which are a form of procedural geometry.

In case you don't know already, a [mesh](https://en.wikipedia.org/wiki/Polygon_mesh) is a bunch of vertices and indices that define the triangles in a model.

IMeshes are a brilliant way to generate and render custom geometry quickly. They are very versatile because we can put our own custom data on every vertex in a mesh.

`shader_example 11` is just an example of vertex coloring, and mesh [instancing](https://en.wikipedia.org/wiki/Geometry_instancing):\
<img src="https://github.com/user-attachments/assets/1818d19d-15f4-41c2-8181-98b435ac8da4" width="50%" height="50%">

Each triangle you see is 1 mesh being rendered at a location, in this case a 10x10 grid.
Note that this shader also introduces the `$vertexcolor` flag, which is required when toying with meshes that include vertex coloring

I've also set `$cull` to 0 to ensure the shader runs on both sides of the triangle

You can also give the shader more data, for instance with `mesh.UserData` which takes the `TANGENT` vertex input.

Just remember when rendering these meshes to call `render.OverrideDepthEnable` or you'll run into the problem we had in [Example 10](#example-10---shaders-on-models)

> [!NOTE]
> Despite what the wiki says, avoid using [IMesh:BuildFromTriangles](https://wiki.facepunch.com/gmod/IMesh:BuildFromTriangles). [mesh.Begin](https://wiki.facepunch.com/gmod/mesh.Begin) is more efficient and has less memory overhead. Just ensure your code does not error inside of a `mesh.Begin` or you will crash (I suggest using a pcall).

> [!NOTE]
> To properly set up lighting on an IMesh (When using shaders like VertexLitGeneric), you will need to render a model to force SourceEngine to set up lighting.

> [!NOTE]
> All of the warnings on [this page](https://wiki.facepunch.com/gmod/Enums/MATERIAL) stating the primative types "don't work" are incorrect. They all work.

# [示例 12] - 点精灵
We're nearing the end of this guide, which means that the upcoming examples are less practical, but still worth documenting.

The point sprites in Source Engine are displayed on the screen using a [geometry shader](https://learn.microsoft.com/en-us/windows/win32/direct3d11/geometry-shader-stage).

Don't get geometry shaders confused with vertex shaders, which *modify* existing vertices. Geometry shaders allow you to *create* vertices.

In this case, point sprites have a hardcoded geometry shader, which we can utilize. If we generate a mesh with the `MATERIAL_POINTS` primative and specify the `PSIZE` semantic in the vertex shader, we can create our very own point sprites.

Theres some wacky math involved in getting the sprite size look correct, but I think I've done it properly.

Although not the most powerful thing, point sprites can create some pretty neat effects, like `shader_example 12`:\
![image](https://github.com/user-attachments/assets/ed54109b-abfe-4a99-99c3-5b3d1f200d0a)

Unfortunately, this is pretty much the most you can do with them within Source Engine.

> [!NOTE]
> Point sprites for some reason have a size limit of about 100 pixels making them honestly pretty useless for anything practical

> [!NOTE]
> This example reuses the pixel shader from [Example 11](#example-11---imeshes)

# [示例 13] - 3D 材质
Remember earlier when we sampled textures? Well you can actually sample them in 3D too! These are called Volumetric Textures and you can imagine them like a ton of 2D images stacked on top of each other.

Example of a volumetric texture:\
![image](https://github.com/user-attachments/assets/e63d2311-568b-4abf-b008-0a08de4bf63c)

There isn't too much else to say, as this is a relatively small concept. I have provided a seamless volumetric texture .vtf which I used in my [cloud shader](https://youtu.be/3A_LBtNbx7c) a few years ago. The red channel has the smallest blobs, green is medium blobs, blue is largest.

Here is a slice of the volume texture (note its quite low quality for the sake of file size):\
![worley_noise0](https://github.com/user-attachments/assets/4aa554f0-3098-4a54-b5f0-ff6d61c52a27)

`example 13` simply runs a plane through this texture and displays it.\
![image](https://github.com/user-attachments/assets/59178858-7315-49db-974e-bc9ce70ebcfb)

This can also be used for animated textures, as they aren't possible traditionally (screenspace_general doesn't support animated textures)

> [!NOTE]
> This example might not work on AMD cards, I'm not actually sure why.

# 完成啦！
If you made it here, you (hopefully) have read and understand everything there is to know (or atleast, that I know) about GMod shaders.\
Please note that this is NOT a comprehensive guide on everything HLSL! There is still plenty more to learn, but this is definitely a good starting point.

If you want more shader examples, check out shaders in the [Source SDK](https://github.com/ValveSoftware/source-sdk-2013/tree/master/src/materialsystem/stdshaders) (labeled as .fxc)

Feel free to ask questions (or concerns) in the Issues tab. I will answer them best I can :)

<ins>Happy shading!</ins>
