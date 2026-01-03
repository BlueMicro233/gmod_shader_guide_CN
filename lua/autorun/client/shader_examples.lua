-- This is the Lua file that controls the rendering for each shader example
-- Each example is defined by a function and is ran in a PostDrawOpaque hook depending on which convar option is selected
-- Hopefully its pretty easy to understand and follow


-- helper method to put screenspace stuff in the top right corner
local function draw_screen_quad(mat)
	render.SetMaterial(mat)
	render.DrawScreenQuadEx(0, 0, ScrW() / 4, ScrH() / 4)
end

-----------------------------------------------------------
------------------------ Example 1 ------------------------
-----------------------------------------------------------
local material1 = Material("gmod_shader_guide/example1.vmt")
local function example1()
	draw_screen_quad(material1)
end




-----------------------------------------------------------
------------------------ Example 2 ------------------------
-----------------------------------------------------------
local material2 = Material("gmod_shader_guide/example2.vmt")
local function example2()
	draw_screen_quad(material2)
end



-----------------------------------------------------------
------------------------ Example 3 ------------------------
-----------------------------------------------------------
local material3 = Material("gmod_shader_guide/example3.vmt")
local function example3()
	-- set up our material input the shader will use
	material3:SetFloat("$c0_x", CurTime())

	draw_screen_quad(material3)
end



-----------------------------------------------------------
------------------------ Example 4 ------------------------
-----------------------------------------------------------
local material4 = Material("gmod_shader_guide/example4.vmt")
local function example4()
	draw_screen_quad(material4)
end



-----------------------------------------------------------
------------------------ Example 5 ------------------------
-----------------------------------------------------------
local material5 = Material("gmod_shader_guide/example5.vmt")
local function example5()
	render.SetMaterial(material5)
	render.DrawBox(Vector(), Angle(30, 30, 30) * CurTime(), Vector(-50, -50, -50), Vector(50, 50, 50))
end



-----------------------------------------------------------
------------------------ Example 6 ------------------------
-----------------------------------------------------------
local material6 = Material("gmod_shader_guide/example6.vmt")
local dummy_model = ClientsideModel("models/shadertest/vertexlit.mdl")
dummy_model:SetModelScale(0)	-- 让模型不可见
local function set_vertex_metadata(x, y, z)
	-- 截胡原来引擎想要发送给 GPU 的光照信息，否则下面的更改将无效
	render.SuppressEngineLighting(true)
	-- 向着色器传输元数据。这里，使用 ambient cube（起源引擎的光照探针）的正面 (0 号方向) 
	-- ambient cube 探针存储 6 个方向的环境光照信息，这意味着我们可以传 6 个不同的元数据
	-- (源代码可以在 common_vs_fxc.h 里被找到)
	render.SetModelLighting(0, x, y, z)

	-- 强制起源引擎使用我们的模型进行渲染
	dummy_model:DrawModel()

	-- 不要忘了重新开启光照！
	render.SuppressEngineLighting(false)
end

local function example6()
	render.SetMaterial(material6)
	set_vertex_metadata(0, CurTime(), 0)
	render.DrawSphere(Vector(), 50, 10, 10)
end



-----------------------------------------------------------
------------------------ Example 7 ------------------------
-----------------------------------------------------------

--
-- 这应该是整个教程里最复杂的代码
-- 并不强求逐字逐句地理解这些，而是要理解它的整体思路
--

local rt_mat = CreateMaterial("ex7_mat", "UnlitGeneric", {["$ignorez"] = 1, ["$basetexture"] = "lights/white"})

-- 让我们创建一个函数来填充渲染目标
-- 这里，使用一个草方块纹理来填充渲染目标
local function fill_rt(rt)
	rt_mat:SetTexture("$basetexture", "gmod_shader_guide/grass_block")
	render.SetMaterial(rt_mat)

	render.PushRenderTarget(rt)
	render.DrawScreenQuad()
	render.PopRenderTarget()
end

-- 创建一些渲染目标，它们唯一有区别的地方在于 flag
local nopoint_noclamp = GetRenderTargetEx("ex7_0", 16, 16, 0, 2,  16,          0, 0) fill_rt(nopoint_noclamp)
local point_noclamp   = GetRenderTargetEx("ex7_1", 16, 16, 0, 2,  1,           0, 0) fill_rt(point_noclamp)
local nopoint_clamp   = GetRenderTargetEx("ex7_2", 16, 16, 0, 2,  4 + 8 + 16,  0, 0) fill_rt(nopoint_clamp)
local point_clamp     = GetRenderTargetEx("ex7_3", 16, 16, 0, 2,  1 + 4 + 8,   0, 0) fill_rt(point_clamp)

-- 顺带一提，这个 draw_texture 是一个非常低效的函数，不要用在你做的东西里
local function draw_texture(texture, x, y, size)
	-- 设置材质到我们的渲染目标
	rt_mat:SetTexture("$basetexture", texture:GetName())
	render.SetMaterial(rt_mat)

	cam.Start2D()
	-- 这相当糟糕，但我需要一个 UV 很奇怪的网格
	mesh.Begin(MATERIAL_QUADS, 1)
		mesh.Position(x, y, 0)
		mesh.TexCoord(0, -1, -1)
		mesh.AdvanceVertex()

		mesh.Position(x + size, y, 0)
		mesh.TexCoord(0, 2, -1)
		mesh.AdvanceVertex()

		mesh.Position(x + size, y + size, 0)
		mesh.TexCoord(0, 2, 2)
		mesh.AdvanceVertex()

		mesh.Position(x, y + size, 0)
		mesh.TexCoord(0, -1, 2)
		mesh.AdvanceVertex()
	mesh.End()
	cam.End2D()
end

local function example7()
	cam.Start2D()
	draw.DrawText("anisotropic + noclamp", "ChatFont", 0, 30)
	draw.DrawText("point + noclamp", "ChatFont", 250, 30)
	draw.DrawText("anisotropic + clamp", "ChatFont", 0, 280)
	draw.DrawText("point + clamp", "ChatFont", 250, 280)
	cam.End2D()

	draw_texture(nopoint_noclamp, 0, 50, 200)
	draw_texture(point_noclamp, 250, 50, 200)
	draw_texture(nopoint_clamp, 0, 300, 200)
	draw_texture(point_clamp, 250, 300, 200)
end



-----------------------------------------------------------
------------------------ Example 8 ------------------------
-----------------------------------------------------------
local material8 = Material("gmod_shader_guide/example8.vmt")
local color0 = GetRenderTarget("ex8_0", ScrW(), ScrH())
local color1 = GetRenderTarget("ex8_1", ScrW(), ScrH())
local function example8()
	-- update our framebuffer
	render.UpdateScreenEffectTexture()

	-- cache rendertarget so we can set it back (we only need to worry about the first rt)
	local rt0 = render.GetRenderTarget()

	-- Setup MRT
	render.SetRenderTargetEx(0, color0)
	render.SetRenderTargetEx(1, color1)

	-- Draw shader
	render.SetMaterial(material8)

	-- Must be in a 3D context for some reason? I tried render.DrawScreenQuad but only the first RT got updated
	-- I am genuinely confused by why this happens so if anyone has an answer I'd love to know
	render.DrawBox(Vector(), Angle(0, -90, 0), Vector(-1, -1), Vector(1, 1))

	-- Reset rendertargets
	render.SetRenderTargetEx(0, rt0)
	render.SetRenderTargetEx(1, nil)

	-- Display our results
	local scrw = ScrW() / 4
	local scrh = ScrH() / 4
	render.DrawTextureToScreenRect(color0, 0, 0, scrw, scrh)
	render.DrawTextureToScreenRect(color1, 0, scrh, scrw, scrh)
end



-----------------------------------------------------------
------------------------ Example 9 ------------------------
-----------------------------------------------------------
local material9 = Material("gmod_shader_guide/example9.vmt")
local wireframe = Material("models/wireframe")
local function example9()
	-- Wireframe (to show triangles being drawn)
	render.SetMaterial(wireframe)
	render.DrawQuadEasy(Vector(), EyePos(), 200, 200)

	-- Sphere
	render.SetMaterial(material9)
	render.DrawQuadEasy(Vector(), EyePos(), 200, 200)
end



-----------------------------------------------------------
------------------------ Example 10 ------------------------
-----------------------------------------------------------
local model = ClientsideModel("models/props_junk/wood_crate001a_damagedmax.mdl")
model:SetNoDraw(true)
model:SetMaterial("gmod_shader_guide/example10")

local function example10()
	local override = CurTime() % 2
	local ply = LocalPlayer()
	model:SetPos(ply:EyePos() + ply:GetAimVector() * 100)

	if override > 1 then
		-- draw with override
		render.OverrideDepthEnable(true, true)
		model:DrawModel()
		render.OverrideDepthEnable(false, false)

		cam.Start2D()
		draw.DrawText("DEPTH OVERRIDE ON", "ChatFont", ScrW() / 2, ScrH() / 2, nil, TEXT_ALIGN_CENTER)
		cam.End2D()
	else
		-- draw without override
		model:DrawModel()
		
		cam.Start2D()
		draw.DrawText("DEPTH OVERRIDE OFF", "ChatFont", ScrW() / 2, ScrH() / 2, nil, TEXT_ALIGN_CENTER)
		cam.End2D()
	end
end


------------------------------------------------------------
------------------------ Example 11 ------------------------
------------------------------------------------------------
local material11 = Material("gmod_shader_guide/example11")

-- Generate a simple imesh
local example_imesh = Mesh()
mesh.Begin(example_imesh, MATERIAL_TRIANGLES, 1)
	-- x (red)
	mesh.Position(10, 0, 0)
	mesh.Color(255, 0, 0, 255)
	mesh.AdvanceVertex()
	-- y (green)
	mesh.Position(0, 10, 0)
	mesh.Color(0, 255, 0, 255)
	mesh.AdvanceVertex()
	-- z (blue)
	mesh.Position(0, 0, 10)
	mesh.Color(0, 0, 255, 255)
	mesh.AdvanceVertex()
mesh.End()

local function example11()
	-- Draw XYZ coordinate system (x = red, y = green, z = blue)
	render.DrawLine(Vector(), Vector(110, 0, 0), Color(255, 0, 0, 255), true)
	render.DrawLine(Vector(), Vector(0, 110, 0), Color(0, 255, 0, 255), true)
	render.DrawLine(Vector(), Vector(0, 0, 110), Color(0, 0, 255, 255), true)

	-- remember, we need to override depth for proper depth sorting
	render.OverrideDepthEnable(true, true)
	render.SetMaterial(material11)
	for y = 0, 9 do
		for x = 0, 9 do
			-- fun little wave
			local height = math.sin((x - y + CurTime()) / 2) * 0.5
			local matrix = Matrix()
			matrix:SetTranslation(Vector(x, y, height) * 10)

			-- Each triangle you see is a mesh being drawn. 
			-- We push a model matrix which is our instancing (same mesh drawn at different location)
			cam.PushModelMatrix(matrix)
			example_imesh:Draw()
			cam.PopModelMatrix()
		end
	end

	render.OverrideDepthEnable(false, false)
end



------------------------------------------------------------
------------------------ Example 12 ------------------------
------------------------------------------------------------
local material12 = Material("gmod_shader_guide/example12")

local function example12()
	-- remember, we need to override depth for proper depth sorting
	render.OverrideDepthEnable(true, true)

	render.SetMaterial(material12)

	-- The VPOS size is in pixel space, meaning we will need to do some calculations to make it appear the same scale
	-- I'll need to send the player FOV into the shader to scale our points correctly
	-- Ideally this calculation would be done within the shader but I don't know how to extract the FOV from the view projection matrix
	local point_scale = 2000
	local point_fov = math.tan(math.rad((LocalPlayer():GetFOV() / 2)))
	set_vertex_metadata(point_scale / point_fov, 0, 0)

	-- generate and render a dynamic IMesh with random points
	mesh.Begin(MATERIAL_POINTS, 360)
		for i = 1, 360 do
			-- weird little pattern
			local random_x = math.sin(CurTime() + i * 0.02) * 100
			local random_y = math.sin(CurTime() + i * 0.03) * 100
			local random_z = math.sin(CurTime() + i * 0.04) * 100

			mesh.Position(random_x, random_y, random_z)
			mesh.Color(HSVToColor(i, 1, 1):Unpack())	-- rainbow
			mesh.AdvanceVertex()
		end
	mesh.End()

	render.OverrideDepthEnable(false, false)
end


-----------------------------------------------------------
------------------------ Example 13 ------------------------
-----------------------------------------------------------
local material13 = Material("gmod_shader_guide/example13.vmt")
local function example13()
	render.DrawWireframeBox(Vector(), Angle(), Vector(), Vector(100, 100, 100), color_white, true)

	render.SetMaterial(material13)
	local pos = Vector(50, 50, math.sin(CurTime()) * 49 + 50)
	local dir = Vector(0, 0, 1)
	render.DrawQuadEasy(pos, dir, 100, 100, color_white)
end



-----------------------------------------------------------
------------------------ Rendering ------------------------
-----------------------------------------------------------

local switch = CreateConVar("shader_example", "0")
local examples = {
	example1,
	example2,
	example3,
	example4,
	example5,
	example6,
	example7,
	example8,
	example9,
	example10,
	example11,
	example12,
	example13,
}

hook.Add("PostDrawOpaqueRenderables", "shader_example", function(_, _, sky3d)
	if sky3d then return end	-- avoid rendering in skybox

	local example = examples[switch:GetInt()]
	if example then
		example()
	end
end)