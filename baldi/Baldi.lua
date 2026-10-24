local P=game:GetService("Players")local R=game:GetService("RunService")local W=game:GetService("Workspace")local PF=game:GetService("PathfindingService")local LP=P.LocalPlayer local CAM=W.CurrentCamera
local BASE="https://raw.githubusercontent.com/kongbai2-script/MP3-PNG/main/baldi/"
local function A(n)local r="bw/"..n if not isfile(r)then local ok,data=pcall(function()return game:HttpGet(BASE..n)end)if ok and data and #data>0 then pcall(function()writefile(r,data)end)end end if not isfile(r)then return""end local o,d=pcall(getcustomasset,r)return(o and type(d)=="string")and d or""end
local S={}for i=0,3 do S[i]=A(string.format("s%d.png",i))end
local SFX=A("slap.wav")
local TILE,JUMP,INT,SIZE=4,1.5,1.0,26
local SIZESCALE=160
local MINPX,MAXPX=80,900
local MAXDIST=350
local B={pos=Vector3.zero,slapT=0,fx=-1,wps={},wpi=1,goal=nil,calcAt=0}
local PATH=PF:CreatePath({AgentRadius=1,AgentHeight=4,AgentCanJump=true,AgentCanClimb=true,WaypointSpacing=3,Costs={Water=math.huge}})
local GUI,ROOT,IMG,SOUND
do
GUI=Instance.new("ScreenGui")GUI.Name="\0"GUI.ResetOnSpawn=false GUI.IgnoreGuiInset=true GUI.DisplayOrder=60 GUI.Parent=gethui and gethui()or game:GetService("CoreGui")
ROOT=Instance.new("Frame")ROOT.AnchorPoint=Vector2.new(0.5,1)ROOT.BackgroundTransparency=1 ROOT.Visible=false ROOT.Size=UDim2.fromOffset(100,260)ROOT.Parent=GUI
IMG=Instance.new("ImageLabel")IMG.AnchorPoint=Vector2.new(0.5,1)IMG.Position=UDim2.fromScale(0.5,1)IMG.BackgroundTransparency=1 IMG.Size=UDim2.fromScale(1,1)IMG.ScaleType=Enum.ScaleType.Fit IMG.ImageRectSize=Vector2.zero IMG.ImageRectOffset=Vector2.zero IMG.Image=S[0]IMG.Parent=ROOT
SOUND=Instance.new("Sound")SOUND.SoundId=SFX SOUND.Volume=3 SOUND.Parent=GUI
end
local RP=RaycastParams.new()RP.FilterType=Enum.RaycastFilterType.Exclude
local function snap(p)RP.FilterDescendantsInstances={LP.Character,CAM}local h=W:Raycast(p+Vector3.new(0,20,0),Vector3.new(0,-200,0),RP)return h and h.Position or p end
-- 只修正高度，保留水平坐标
local function ground(p)local r=snap(p)return r and Vector3.new(p.X,r.Y,p.Z)or p end
local function ppos()local r=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")return r and r.Position end
local function repath(g)
  g=snap(g)
  local s=snap(B.pos)
  local ok=pcall(function()PATH:ComputeAsync(s,g)end)
  B.calcAt=os.clock()
  if not ok or PATH.Status~=Enum.PathStatus.Success then
    B.wps,B.wpi=nil,1
    return false
  end
  local w=PATH:GetWaypoints()
  if #w<2 then B.wps,B.wpi=nil,1 return false end
  B.wps,B.wpi,B.goal=w,2,g
  return true
end
local function adv(d)
  if not B.wps then return nil end
  if B.wpi>#B.wps then return nil end
  local p,r,i=B.pos,d,B.wpi
  while r>1e-3 and i<=#B.wps do
    local w=B.wps[i].Position
    local v=w-p
    local m=v.Magnitude
    if m<=r then p=w r=r-m i=i+1
    else p=p+v.Unit*r r=0 end
  end
  B.wpi=i
  return p
end
local function canWalk(from,to)
  local a=from+Vector3.new(0,TILE*0.8,0)
  local d=to-from
  d=Vector3.new(d.X,0,d.Z)
  if d.Magnitude<1e-3 then return false end
  local rp=RaycastParams.new()
  rp.FilterType=Enum.RaycastFilterType.Exclude
  rp.FilterDescendantsInstances={LP.Character,CAM}
  local h=W:Raycast(a,d,rp)
  return h==nil
end
local function slide(pp)
  local d=pp-B.pos
  d=Vector3.new(d.X,0,d.Z)
  if d.Magnitude<1e-3 then return false end
  local step=d.Unit*TILE*JUMP
  if canWalk(B.pos,B.pos+step) then
    B.pos=ground(B.pos+step)
    return true
  end
  local rp=RaycastParams.new()
  rp.FilterType=Enum.RaycastFilterType.Exclude
  rp.FilterDescendantsInstances={LP.Character,CAM}
  local hit=W:Raycast(B.pos+Vector3.new(0,TILE*0.8,0),step,rp)
  if hit then
    local n=Vector3.new(hit.Normal.X,0,hit.Normal.Z)
    if n.Magnitude>1e-3 then
      local t=step-n.Unit*step:Dot(n.Unit)
      if t.Magnitude>1e-3 then
        local off=t.Unit*TILE*JUMP+Vector3.new((math.random()-0.5)*0.6,0,(math.random()-0.5)*0.6)
        if canWalk(B.pos,B.pos+off) then
          B.pos=ground(B.pos+off)
          return true
        end
      end
    end
  end
  local side=Vector3.new(-d.Z,0,d.X).Unit
  for _,s in ipairs({side,-side}) do
    local off=s*TILE*JUMP
    if canWalk(B.pos,B.pos+off) then
      B.pos=ground(B.pos+off)
      return true
    end
  end
  return false
end
local function front(n)
  local cf=CAM.CFrame
  local dir=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
  if dir.Magnitude<1e-3 then dir=Vector3.new(0,0,-1)end
  return cf.Position+n*TILE*dir.Unit
end
local function res()local p=ppos()or Vector3.zero B.pos=snap(front(10))B.slapT=0 B.fx=-1 B.hit=true B.wps,B.wpi,B.goal=nil,1,nil B.stuckT=0 repath(p)end
local function kill()local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")if h and h.Health>0 then h.Health=0 end end
local function los(t)local a=B.pos+Vector3.new(0,TILE*0.8,0)local b=t+Vector3.new(0,TILE*0.8,0)local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={LP.Character,CAM}local h=W:Raycast(a,b-a,rp)return h==nil end
local function needsPath(pp)
  if not B.goal then return true end
  if not B.wps then return true end
  if B.wpi>#B.wps then return true end
  if(pp-B.goal).Magnitude>4 then return true end
  if B.stuckT>0.6 then return true end
  return false
end
local function upd(dt)local pp=ppos()if not pp then return end
if(pp-B.pos).Magnitude<TILE*0.8 then kill()end
B.slapT=B.slapT+dt
if B.slapT>=INT then B.slapT=0 B.fx=0 B.hit=false end
if needsPath(pp)and os.clock()-B.calcAt>0.25 then repath(pp)end
B.pos=ground(B.pos) end
local function draw(dt)
local vis=los(B.pos)
local sp,on=CAM:WorldToViewportPoint(B.pos)
if not vis or not on or sp.Z<=0 or sp.Z>MAXDIST then ROOT.Visible=false else
local s=math.clamp(SIZE*SIZESCALE/math.max(sp.Z,2),MINPX,MAXPX)
ROOT.Visible=true ROOT.Position=UDim2.fromOffset(sp.X,sp.Y)ROOT.Size=UDim2.fromOffset(s*0.62,s)end
if B.fx>=0 then
  B.fx=B.fx+dt*10
  local i=math.floor(B.fx)
  if i>=2 and not B.hit then
    B.hit=true
    local pp=ppos()
    local before=B.pos
    local t=adv(TILE*JUMP)
    if t then B.pos=ground(t) end
    if (B.pos-before).Magnitude<0.3 then
      if not slide(pp) then
        B.stuckT=(B.stuckT or 0)+1
        B.calcAt=0
      else
        B.stuckT=0
      end
    else
      B.stuckT=0
    end
    pcall(function()SOUND:Play()end)
    if pp and(pp-B.pos).Magnitude<TILE*0.8 then kill()end
  end
  if B.fx>=4 then B.fx=-1 else IMG.Image=S[math.min(i,3)]or S[0]end
end
if B.fx<0 then IMG.Image=S[0]end end
res()
LP.CharacterAdded:Connect(function()
  task.wait(0.3)
  B.wps,B.wpi,B.goal={},1,nil B.calcAt=0
  local p=ppos()
  if p then repath(p)end
end)
local RUN=true local CN=R.RenderStepped:Connect(newcclosure(function(dt)if not RUN then return end pcall(upd,dt)pcall(draw,dt)end))
getgenv().KillBaldi=function()RUN=false CN:Disconnect()if GUI then GUI:Destroy()end end
