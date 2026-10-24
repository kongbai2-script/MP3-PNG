local P=game:GetService("Players")local R=game:GetService("RunService")local W=game:GetService("Workspace")local LP=P.LocalPlayer local CAM=W.CurrentCamera
local BASE="https://cdn.jsdelivr.net/gh/kongbai2-script/MP3-PNG@main/baldi/"
local function A(n)local r="bw/"..n if not isfile(r)then local ok,data=pcall(function()return game:HttpGet(BASE..n)end)if ok and data and #data>0 then pcall(function()writefile(r,data)end)end end if not isfile(r)then return""end local o,d=pcall(getcustomasset,r)return(o and type(d)=="string")and d or""end
local SHEET=A("BaldiSlap_Sheet.png")
local FW,FH=142,256
local SFX=A("slap.wav")
local TILE,JUMP,INT,SIZE=4,2.0,0.6,90
local SIZESCALE=160
local MINPX,MAXPX=30,1100
local WORLD_H=6.5
local MAXDIST=350
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
local GRID=4
local MAX_ITER=600
local SQRT2=1.41421356
local function newHeap()
  local a,n={},0
  local function less(i,j) return a[i].f<a[j].f end
  local function swap(i,j) a[i],a[j]=a[j],a[i] end
  local function up(i) while i>1 do local p=i//2 if less(i,p) then swap(i,p) i=p else break end end end
  local function down(i) while true do local l,r,s=i*2,i*2+1,i if l<=n and less(l,s) then s=l end if r<=n and less(r,s) then s=r end if s==i then break end swap(i,s) i=s end end
  return{
    push=function(v) n=n+1 a[n]=v up(n) end,
    pop=function() if n==0 then return nil end local t=a[1] a[1]=a[n] a[n]=nil n=n-1 if n>0 then down(1) end return t end,
    empty=function() return n==0 end,
  }
end
local RAY=RaycastParams.new()
RAY.FilterType=Enum.RaycastFilterType.Exclude
local function rayGround(p)
  RAY.FilterDescendantsInstances={LP.Character,CAM}
  local h=W:Raycast(p+Vector3.new(0,8,0),Vector3.new(0,-40,0),RAY)
  return h and h.Position or nil
end
local GRIDSTATE={origin=Vector3.zero,cache={},nodes={}}
local function cellOf(pos)
  local o=GRIDSTATE.origin
  return math.floor((pos.X-o.X)/GRID+0.5),math.floor((pos.Z-o.Z)/GRID+0.5)
end
local function worldOf(cx,cz)
  local o=GRIDSTATE.origin
  return rayGround(o+Vector3.new(cx*GRID,0,cz*GRID))
end
local function walkable(cx,cz)
  local k=cx*100000+cz
  local v=GRIDSTATE.cache[k]
  if v~=nil then return v end
  local wp=worldOf(cx,cz)
  if not wp then GRIDSTATE.cache[k]=false return false end
  local o=GRIDSTATE.origin
  local a=Vector3.new(o.X,wp.Y+2.5,o.Z)
  local b=Vector3.new(wp.X,wp.Y+2.5,wp.Z)
  RAY.FilterDescendantsInstances={LP.Character,CAM}
  local h=W:Raycast(a,b-a,RAY)
  local ok=(h==nil)
  GRIDSTATE.cache[k]=ok
  return ok
end
local function gnode(cx,cz)
  local k=cx*100000+cz
  local n=GRIDSTATE.nodes[k]
  if not n then
    n={x=cx,z=cz,g=math.huge,h=0,f=0,parent=nil,closed=false}
    GRIDSTATE.nodes[k]=n
  end
  return n
end
local function astar(sx,sz,gx,gz)
  local open=newHeap()
  local st=gnode(sx,sz)
  st.g=0
  st.h=math.sqrt((gx-sx)^2+(gz-sz)^2)
  st.f=st.h
  open.push(st)
  local best,bestH=st,st.h
  local iter=0
  while not open.empty() and iter<MAX_ITER do
    iter=iter+1
    local cur=open.pop()
    if not cur.closed then
      cur.closed=true
      if cur.h<bestH then best,bestH=cur,cur.h end
      if cur.x==gx and cur.z==gz then best=cur break end
      for dx=-1,1 do
        for dz=-1,1 do
          if dx~=0 or dz~=0 then
            local nx,nz=cur.x+dx,cur.z+dz
            if walkable(nx,nz) then
              local nb=gnode(nx,nz)
              if not nb.closed then
                local stp=(dx~=0 and dz~=0) and SQRT2 or 1
                local ng=cur.g+stp
                if ng<nb.g then
                  nb.g=ng
                  nb.parent=cur
                  nb.h=math.sqrt((gx-nx)^2+(gz-nz)^2)
                  nb.f=nb.g+nb.h
                  open.push(nb)
                end
              end
            end
          end
        end
      end
    end
  end
  local path={}
  local n=best
  while n do table.insert(path,1,{x=n.x,z=n.z}) n=n.parent end
  if #path<2 then return nil end
  return path
end
local function findPath(from,to)
  GRIDSTATE.origin=from
  GRIDSTATE.cache={}
  GRIDSTATE.nodes={}
  local sx,sz=0,0
  local gx,gz=cellOf(to)
  local path=astar(sx,sz,gx,gz)
  if not path then return nil end
  local wp={}
  for i=2,#path do
    local w=worldOf(path[i].x,path[i].z)
    if w then table.insert(wp,w) end
  end
  return wp
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
  local path=findPath(B.pos,target)
  if not path then
    local d=target-B.pos
    d=Vector3.new(d.X,0,d.Z)
    if d.Magnitude>1e-3 then
      local gh=ground(B.pos+d.Unit*TILE*JUMP)
      if gh then B.pos=gh end
    end
    return(B.pos-before).Magnitude>0.2
  end
  local remain=TILE*JUMP
  local cur=B.pos
  for _,w in ipairs(path) do
    local seg=w-cur
    local m=seg.Magnitude
    if m<1e-3 then
      cur=w
    elseif m<=remain then
      cur=w
      remain=remain-m
      B.pos=w
      if remain<=0 then break end
    else
      local nxt=cur+seg.Unit*remain
      B.pos=nxt
      remain=0
      break
    end
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
local LOS=RaycastParams.new()
LOS.FilterType=Enum.RaycastFilterType.Exclude
B.vis=true
B.visTick=0
local function visible(pos)
  local camPos=CAM.CFrame.Position
  local target=pos+Vector3.new(0,WORLD_H*0.5,0)
  local d=target-camPos
  local dist=d.Magnitude
  if dist<1 then return true end
  LOS.FilterDescendantsInstances={LP.Character,CAM}
  local h=W:Raycast(camPos,d,LOS)
  if not h then return true end
  return h.Distance>=dist-0.8
end
local function draw(dt)
  B.visTick=B.visTick+1
  if B.visTick%3==0 then
    B.vis=visible(B.pos)
  end
  local sp,on=CAM:WorldToViewportPoint(B.pos)
  if not B.vis or not on or sp.Z<=0 or sp.Z>MAXDIST then
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
    B.fx=B.fx+dt*16
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
