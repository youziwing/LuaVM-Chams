local FPS=60
local Players,RunService=game:GetService("Players"),game:GetService("RunService")
local lp,cam=Players.LocalPlayer,workspace.CurrentCamera
local ESP_SCALE=1.9
local COL=Color3.fromRGB(255,50,50)
local TPG,TC=10,60

local function getGroups(c)
	if c:FindFirstChild("UpperTorso") then
		return {
			{"Head"},{"UpperTorso","LowerTorso"},
			{"LeftUpperArm","LeftLowerArm","LeftHand"},
			{"RightUpperArm","RightLowerArm","RightHand"},
			{"LeftUpperLeg","LeftLowerLeg","LeftFoot"},
			{"RightUpperLeg","RightLowerLeg","RightFoot"}
		}
	end
	return {{"Head"},{"Torso"},{"Left Arm"},{"Right Arm"},{"Left Leg"},{"Right Leg"}}
end

local tris={}
for i=1,TC do
	local t=Drawing.new("Triangle")
	t.Filled,t.Visible,t.Transparency,t.Color=true,false,.35,COL
	tris[i]=t
end

local CX={.5,-.5,.5,-.5,.5,-.5,.5,-.5}
local CY={.5,.5,-.5,-.5,.5,.5,-.5,-.5}
local CZ={.5,.5,.5,.5,-.5,-.5,-.5,-.5}
local pp,sb,hb={},{},{}
for i=1,24 do pp[i]={0,0} hb[i]={0,0} end

local cX,cY,cZ,c00,c01,c02,c10,c11,c12,c20,c21,c22,fL,hW,hH
local pFOV,fD=-1,1
local lastChar,groups

local function setupChar(c) groups=getGroups(c) lastChar=c end

local function updCam()
	local cf,vp,fov=cam.CFrame,cam.ViewportSize,cam.FieldOfView
	hW,hH=vp.X*.5,vp.Y*.5
	if fov~=pFOV then pFOV=fov fD=math.tan(math.rad(fov)*.5) end
	fL=hH/fD
	cX,cY,cZ,c00,c01,c02,c10,c11,c12,c20,c21,c22=cf:GetComponents()
end

local function proj(x,y,z)
	local dx,dy,dz=x-cX,y-cY,z-cZ
	local lx=c00*dx+c10*dy+c20*dz
	local ly=c01*dx+c11*dy+c21*dz
	local lz=c02*dx+c12*dy+c22*dz
	local d=-lz
	if d<.01 then return 0,0,false end
	local s=fL/d
	return hW+lx*s,hH-ly*s,true
end

local function ptLt(a,b)
	return a[1]==b[1] and a[2]<b[2] or a[1]<b[1]
end

local function cross(ax,ay,bx,by,px,py)
	return (bx-ax)*(py-ay)-(by-ay)*(px-ax)
end

local function hull(n)
	local sz=0
	for i=1,n do
		local x,y=sb[i][1],sb[i][2]
		while sz>=2 and cross(hb[sz-1][1],hb[sz-1][2],hb[sz][1],hb[sz][2],x,y)<=0 do sz-=1 end
		sz+=1
		hb[sz][1],hb[sz][2]=x,y
	end
	local le=sz+1
	for i=n-1,1,-1 do
		local x,y=sb[i][1],sb[i][2]
		while sz>=le and cross(hb[sz-1][1],hb[sz-1][2],hb[sz][1],hb[sz][2],x,y)<=0 do sz-=1 end
		sz+=1
		hb[sz][1],hb[sz][2]=x,y
	end
	return sz-1
end

local function hideGroup(gi)
	local a=(gi-1)*TPG+1
	for i=a,a+TPG-1 do tris[i].Visible=false end
end

local function procGroup(char,g,gi)
	local tb=(gi-1)*TPG+1
	local te=tb+TPG-1
	local pc=0

	for _,nm in ipairs(g) do
		local p=char:FindFirstChild(nm)
		if p and p:IsA("BasePart") then
			local x,y,z,r00,r01,r02,r10,r11,r12,r20,r21,r22=p.CFrame:GetComponents()
			local s=p.Size
			local hx,hy,hz=s.X*.5*ESP_SCALE,s.Y*.5*ESP_SCALE,s.Z*.5*ESP_SCALE

			for c=1,8 do
				local lx,ly,lz=CX[c]*hx,CY[c]*hy,CZ[c]*hz
				local sx,sy,o=proj(
					x+r00*lx+r01*ly+r02*lz,
					y+r10*lx+r11*ly+r12*lz,
					z+r20*lx+r21*ly+r22*lz
				)
				if o then
					pc+=1
					pp[pc][1],pp[pc][2]=sx,sy
					sb[pc]=pp[pc]
				end
			end
		end
	end

	if pc<3 then hideGroup(gi) return end
	table.sort(sb,ptLt)

	local hs=hull(pc)
	if hs<3 then hideGroup(gi) return end

	local cx,cy=0,0
	for i=1,hs do cx+=hb[i][1] cy+=hb[i][2] end
	cx,cy=cx/hs,cy/hs

	local w=0
	for i=1,hs do
		local ni=i%hs+1
		local idx=tb+w
		if idx>te then break end
		local t=tris[idx]
		t.PointA=Vector2.new(cx,cy)
		t.PointB=Vector2.new(hb[i][1],hb[i][2])
		t.PointC=Vector2.new(hb[ni][1],hb[ni][2])
		t.Visible=true
		w+=1
	end

	for i=tb+w,te do tris[i].Visible=false end
end

local function hideAll()
	for i=1,TC do tris[i].Visible=false end
end

function cleanup()
	hideAll()
	for _,t in ipairs(tris) do pcall(function() t:Remove() end) end
	if conn then pcall(function() conn:Disconnect() end) end
end

local step,acc=1/FPS,0
conn=RunService.RenderStepped:Connect(function(dt)
	acc+=dt
	if acc<step then return end
	acc-=step

	local char=lp.Character
	if not char then hideAll() return end
	if char~=lastChar then setupChar(char) end

	cam=workspace.CurrentCamera
	updCam()

	for gi,g in ipairs(groups) do procGroup(char,g,gi) end
end)
