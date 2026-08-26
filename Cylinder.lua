local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera

local RADIUS = 5
local HEIGHT = 10
local SEGMENTS = 16
local COLOR = Color3.fromRGB(255,50,50)

local lines = {}

for i = 1,SEGMENTS * 3 do
	local l = Drawing.new("Line")
	l.Thickness = 2
	l.Transparency = 1
	l.Color = COLOR
	l.Visible = false
	lines[i] = l
end

local cx,cy,cz
local c00,c01,c02,c10,c11,c12,c20,c21,c22
local fL,w,h
local lastFov = -1
local fD = 1

local function updateCamera()
	cam = workspace.CurrentCamera
	if not cam then return false end

	local cf = cam.CFrame
	local vp = cam.ViewportSize
	local fov = cam.FieldOfView

	w = vp.X * .5
	h = vp.Y * .5

	if fov ~= lastFov then
		lastFov = fov
		fD = math.tan(math.rad(fov) * .5)
	end

	fL = h / fD

	cx,cy,cz,
	c00,c01,c02,
	c10,c11,c12,
	c20,c21,c22 = cf:GetComponents()

	return true
end

local function project(x,y,z)
	local dx = x-cx
	local dy = y-cy
	local dz = z-cz

	local lx = c00*dx+c10*dy+c20*dz
	local ly = c01*dx+c11*dy+c21*dz
	local lz = c02*dx+c12*dy+c22*dz

	local depth = -lz
	if depth < .01 then return nil end

	local s = fL/depth

	return Vector2.new(
		w+lx*s,
		h-ly*s
	)
end

local function hide()
	for _,l in ipairs(lines) do
		l.Visible = false
	end
end

RunService.RenderStepped:Connect(function()
	if not updateCamera() then
		hide()
		return
	end

	local char = lp.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")

	if not root then
		hide()
		return
	end

	local cf = root.CFrame
	local center = root.Position

	local up = cf.UpVector
	local right = cf.RightVector
	local forward = cf.LookVector

	local topCenter = center + up * (HEIGHT*.5)
	local bottomCenter = center - up * (HEIGHT*.5)

	local top = {}
	local bottom = {}

	for i = 1,SEGMENTS do
		local a = (i-1)/SEGMENTS * math.pi*2
		local x = math.cos(a)*RADIUS
		local z = math.sin(a)*RADIUS

		local tp =
			topCenter +
			right*x +
			forward*z

		local bp =
			bottomCenter +
			right*x +
			forward*z

		top[i] = project(tp.X,tp.Y,tp.Z)
		bottom[i] = project(bp.X,bp.Y,bp.Z)
	end

	local n = 0

	for i = 1,SEGMENTS do
		local next = i%SEGMENTS+1

		if top[i] and top[next] then
			n += 1
			local l = lines[n]
			l.From = top[i]
			l.To = top[next]
			l.Visible = true
		end
	end

	for i = 1,SEGMENTS do
		local next = i%SEGMENTS+1

		if bottom[i] and bottom[next] then
			n += 1
			local l = lines[n]
			l.From = bottom[i]
			l.To = bottom[next]
			l.Visible = true
		end
	end

	for i = 1,SEGMENTS do
		local a = top[i]
		local b = bottom[i]

		if a and b then
			n += 1
			local l = lines[n]
			l.From = a
			l.To = b
			l.Visible = true
		end
	end

	for i = n+1,#lines do
		lines[i].Visible = false
	end
end)
