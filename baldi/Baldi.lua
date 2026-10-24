-- Baldi 射线探路版：完全不依赖 PathfindingService
local P=game:GetService("Players")local R=game:GetService("RunService")local W=game:GetService("Workspace")local LP=P.LocalPlayer local CAM=W.CurrentCamera
local BASE="https://raw.githubusercontent.com/kongbai2-script/MP3-PNG/main/baldi/"
local function A(n)local r="bw/"..n if not isfile(r)then local ok,data=pcall(function()return game:HttpGet(BASE..n)end)if ok and data and #data>0 then pcall(function()writefile(r,data)end)end end if not isfile(r)then return""end local o,d=pcall(getcustomasset,r)return(o and type(d)=="string")and d or""end
local SHEET=A("BaldiSlap_Sheet.png")
local FW,FH=142,256
local SFX=A("slap.wav")
local TILE,JUMP,INT,SIZE=4,1.5,1.0,90
local SIZESCALE=160
local MINPX,MAXPX=30,1100
local WORLD_H=6.5
local MAXDIST=350
local STEPH=TILE*0.8
local DIRS=16
local B={pos=Vector3.zero,slapT=0,fx=-1,hit=true,lastPos=Vector3.zero,tries=0}
local GUI,ROOT,IMG,SOUND
do
GUI=Instance.new("ScreenGui")GUI.Name="\0"GUI.ResetOnSpawn=false GUI.IgnoreGuiInset=true GUI.DisplayOrder=60 GUI.Parent=gethui and gethui()or game:GetService("CoreGui")
ROOT=Instance.new("Frame")ROOT.AnchorPoint=Vector2.new(0.5,1)ROOT.BackgroundTransparency=1 ROOT.Visible=false ROOT.Size=UDim2.fromOffset(100,260)ROOT.Parent=GUI
IMG=Instance.new("ImageLabel")IMG.AnchorPoint=Vector2.new(0.5,1)IMG.Position=UDim2.fromScale(0.5,1)IMG.BackgroundTransparency=1 IMG.Size=UDim2.fromScale(1,1)IMG.ScaleType=Enum.ScaleType.Fit IMG.ImageRectSize=Vector2.new(FW,FH)IMG.ImageRectOffset=Vector2.zero IMG.Image=SHEET IMG.Parent=ROOT
SOUND=Instance.new("Sound")SOUND.SoundId=SFX SOUND.Volume=3 SOUND.Parent=GUI
end
for i=0,4 do
  local tmp=Instance.new("ImageLabel")
  tmp.Image=SHEET
  tmp.ImageRectSize=Vector2.new(FW,FH)
  tmp.ImageRectOffset=Vector2.new(i*FW,0)
  tmp.Visible=false
  tmp.Size=UDim2.fromOffset(FW,FH)
  tmp.Parent=GUI
  task.delay(3,function() pcall(function() tmp:Destroy() end) end)
end
local FLOOR=nil
local function floorPart(p)
  local rp=RaycastParams.new()
  rp.FilterType=Enum.RaycastFilterType.Exclude
  rp.FilterDescendantsInstances={LP.Character,CAM}
  local h=W:Raycast(p+Vector3.new(0,6,0),Vector3.new(0,-30,0),rp)
  return h
end
local function ground(p)
  local h=floorPart(p)
  if h then return h.Position end
  return nil
end
local function ppos()
  local r=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
  return r and r.Position
end
-- 检测从 from 走到 to 是否可行（不撞墙 + 有地面）
local function canGo(from,to)
  local gh=ground(to)
  if not gh then return false end
  if math.abs(to.Y-gh.Y)>2.5 then
    if gh.Y>to.Y+0.5 then return false end
  end
  local rp=RaycastParams.new()
  rp.FilterType=Enum.RaycastFilterType.Exclude
  rp.FilterDescendantsInstances={LP.Character,CAM}
  local a=Vector3.new(from.X,gh.Y+2,from.Z)
  local d=to-from
  local flat=Vector3.new(d.X,0,d.Z)
  if flat.Magnitude<1e-3 then return true end
  local h=W:Raycast(a,flat,rp)
  return h==nil
end
-- 用射线找最接近目标方向的可走方向
local function pickDir(target)
  local d=target-B.pos
  d=Vector3.new(d.X,0,d.Z)
  if d.Magnitude<1e-3 then return nil end
  local base=math.atan2(d.Z,d.X)
  local best,bestScore=nil,-1e9
  for i=0,DIRS-1 do
    local a=base+(i%2==0 and 1 or -1)*math.floor((i+1)/2)*(math.pi*2/DIRS)
    local dir=Vector3.new(math.cos(a),0,math.sin(a))
    local to=B.pos+dir*STEPH
    local gh=ground(to)
    if gh then
      local rp=RaycastParams.new()
      rp.FilterType=Enum.RaycastFilterType.Exclude
      rp.FilterDescendantsInstances={LP.Character,CAM}
      local h=W:Raycast(Vector3.new(B.pos.X,gh.Y+2,B.pos.Z),Vector3.new(dir.X,0,dir.Z)*STEPH,rp)
      if not h then
        local score=dir:Dot(d.Unit)
        if gh.Y>B.pos.Y+0.5 then score=score-2 end
        if gh.Y<B.pos.Y-4 then score=score-3 end
        if score>bestScore then bestScore,best=score,to end
      end
    end
  end
  return best
end
local function front(n)
  local cf=CAM.CFrame
  local dir=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
  if dir.Magnitude<1e-3 then dir=Vector3.new(0,0,-1)end
  return cf.Position+n*TILE*dir.Unit
end
local function res()
  local pp=ppos()or Vector3.zero
  local aim=front(8)
  local ok=ground(aim)
  while not ok and math.abs(aim.Y-pp.Y)<40 do
    aim=aim+Vector3.new(0,-4,0)
    ok=ground(aim)
  end
  B.pos=ok or pp
  B.lastPos=B.pos
  B.slapT=0
  B.tries=0
end
local function kill()
  local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
  if h and h.Health>0 then h.Health=0 end
end
local function los(t)
  local a=B.pos+Vector3.new(0,3,0)
  local b=t+Vector3.new(0,1,0)
  local d=b-a
  if d.Magnitude<1 then return true end
  local rp=RaycastParams.new()
  rp.FilterType=Enum.RaycastFilterType.Exclude
  rp.FilterDescendantsInstances={LP.Character,CAM}
  local h=W:Raycast(a,d,rp)
  if not h then return true end
  return (h.Position-t).Magnitude<2
end
local function moveToward(target)
  local before=B.pos
  for s=1,3 do
    local d=(B.pos-target).Magnitude
    if d<TILE*1.0 then break end
    local nxt=pickDir(target)
    if not nxt then break end
    if (nxt-target).Magnitude>d-TILE*0.2 then break end
    B.pos=nxt
  end
  return(B.pos-before).Magnitude>0.2
end
local function upd(dt)
  local pp=ppos()
  if not pp then return end
  local gh=ground(B.pos)
  if gh then B.pos=Vector3.new(B.pos.X,gh.Y,B.pos.Z)end
  if(B.pos-pp).Magnitude>300 then res()end
  B.slapT=B.slapT+dt
  if B.slapT>=INT then B.slapT=0 B.fx=0 B.hit=false end
end
local function draw(dt)
  local sp,on=CAM:WorldToViewportPoint(B.pos)
  if not on or sp.Z<=0 or sp.Z>MAXDIST then
    ROOT.Visible=false
    B.dbg=(B.dbg or 0)+1
    if B.dbg%20==0 then
      print(string.format("[DBG] HIDDEN pos=(%.1f,%.1f,%.1f) on=%s Z=%.1f dist=%.1f",
        B.pos.X,B.pos.Y,B.pos.Z,tostring(on),sp.Z,(B.pos-CAM.CFrame.Position).Magnitude))
    end
  else
    local vpY=CAM.ViewportSize.Y
    local fov=math.rad(CAM.FieldOfView)
    local proj=(WORLD_H/math.max(sp.Z,1))*(vpY*0.5)/math.tan(fov*0.5)
    local s=math.clamp(proj,MINPX,MAXPX)
    ROOT.Visible=true
    ROOT.Position=UDim2.fromOffset(sp.X,sp.Y)
    ROOT.Size=UDim2.fromOffset(s*0.555,s)
    B.dbg=(B.dbg or 0)+1
    if B.dbg%20==0 then
      print(string.format("[DBG] SHOWN Z=%.1f proj=%.0f size=%.0f",sp.Z,proj,s))
    end
  end
  if B.fx>=0 then
    B.fx=B.fx+dt*13
    local i=math.floor(B.fx)
    if i>=5 then
      B.fx=-1
      IMG.ImageRectOffset=Vector2.zero
    else
      IMG.ImageRectOffset=Vector2.new(i*FW,0)
    end
    if i>=3 and not B.hit then
      B.hit=true
      local pp=ppos()
      local dead=false
      if pp then
        if (B.pos-pp).Magnitude<TILE*1.0 then
          kill()
          dead=true
        else
          local moved=moveToward(pp)
          if moved then B.tries=0 else B.tries=B.tries+1 end
          if (B.pos-pp).Magnitude<TILE*1.0 then
            kill()
            dead=true
          end
          if not dead and B.tries>=4 then
            B.tries=0
            local d=pp-B.pos
            d=Vector3.new(d.X,0,d.Z)
            if d.Magnitude>1e-3 then
              local gh=ground(B.pos+d.Unit*TILE)
              if gh then B.pos=gh else res() end
            end
          end
        end
      end
      pcall(function()SOUND:Play()end)
    end
  end
  if B.fx<0 then IMG.ImageRectOffset=Vector2.zero end
end
res()
B.fx=-1
B.hit=true
LP.CharacterAdded:Connect(function()
  task.wait(0.3)
  res()
end)
local RUN=true local CN=R.RenderStepped:Connect(newcclosure(function(dt)if not RUN then return end pcall(upd,dt)pcall(draw,dt)end))
getgenv().KillBaldi=function()RUN=false CN:Disconnect()if GUI then GUI:Destroy()end end
