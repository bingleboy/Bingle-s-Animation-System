#include "export.lua"

function init()
	bodyparts=FindBodies("ragdoll")
	ref=FindBody("reference")
	shapes=FindShapes()
	filterLayer=2
	for i=1,#shapes do
		SetShapeCollisionFilter(shapes[i],filterLayer,255-filterLayer)
		SetTag(shapes[i],"unbreakable")
	end
	t=0
	prevT=0
	
	alignLocal=false
	ragdoll=false
end

function update(dt)
	t=GetTime()*24
	DebugWatch("frame",t)
	
	--refRot=GetBodyTransform(ref).rot
	
	anim=ANIM_epic_test
	markers=ANIM_epic_test_MARKERS
	
	animate_armature(anim["Steve"],"Wave",t)
	--[[for b=1,#bodyparts do
		local partName=GetTagValue(bodyparts[b],"ragdoll")
		SetTag(bodyparts[b],"unbreakable")
		
		if anim[partName]~=nil then
			for k,v in pairs(anim[partName]) do
				local keys=v
				local val=0
				local startKey=-1
				local endKey=-1
				if #keys>0 then
					if #keys==1 then
						startKey=1
						endKey=1
					else
						for i=1,#keys do
							if i==#keys then
								startKey=i
								endKey=i
							elseif keys[i]["t"]<t and keys[i+1]["t"]>t then
								startKey=i
								endKey=i+1
								break
							end
							
						end
					end
				end
				--DebugPrint(startKey.." "..endKey.." "..#keys)
				if startKey<0 or endKey<0 then
					DebugPrint("Property \""..k.."\" ("..partName..") Has no keyframes! If you believe this message to be in error, tell @Bingle!")
				else
					local startTime = keys[startKey]["t"]
					local endTime = keys[endKey]["t"]
					local lerp=0.5
					if endKey~=startKey then
						lerp=(t-startTime)/(endTime-startTime)
					end
					lerp=interpolate_parabolic(lerp)
					
					local v1=keys[startKey]["val"]
					local v2=keys[endKey]["val"]
					
					if k=="rotation_quaternion" then
						
						local rot=QuatSlerp(v1,v2,lerp)
						
						if not ragdoll then
							if alignLocal and not HasTag(bodyparts[b],"independent") then
								ConstrainOrientation(bodyparts[b],ref,GetBodyTransform(bodyparts[b]).rot,QuatRotateQuat(refRot,rot))
							else
								ConstrainOrientation(bodyparts[b],0,GetBodyTransform(bodyparts[b]).rot,rot)
							end
						end
					elseif k=="location" then
						local pos=VecLerp(v1,v2,lerp)
						if not ragdoll then
							ConstrainPosition(bodyparts[b],0,GetBodyTransform(bodyparts[b]).pos,pos)
						end
					end
				end
			end
		end
	end
	for i=1,#markers do
		if markers[i]["frame"]<t and markers[i]["frame"]>=prevT then
			exec_marker(markers[i])
		end
	end
	
	prevT=t]]
end

function animate_armature(armature,animName,t)
	local anim = armature["animations"][animName]
	--DebugPrint(dump(armature))
	local rootName = armature["root"]
	local root = 0
	for _,part in pairs(bodyparts) do
		if GetTagValue(part,"ragdoll")==rootname then
			root=part
		end
	end
	for k,v in pairs(anim) do
		for _,part in pairs(bodyparts) do
			local partName=GetTagValue(part,"ragdoll")
			if partName==k then
				for propName,prop in pairs(v) do
					local startKey,endKey = get_keys(prop,t)
					local startTime = prop[startKey]["t"]
					local endTime = prop[endKey]["t"]
					
					local v1=prop[startKey]["val"]
					local v2=prop[endKey]["val"]
					
					local lerp = 0.5
					if endKey~=startKey then
						lerp=(t-startTime)/(endTime-startTime)
					end
					lerp = interpolate_parabolic(lerp)
					
					DebugPrint(dump(v1))
					DebugPrint(dump(v2))
					
					if propName=="rotation_quaternion" then
						local rot=QuatSlerp(v1,v2,lerp)
						--DebugPrint(dump(rot))
						DebugLine(Vec(),TransformToParentVec(Transform(Vec(),rot),Vec(1,0,0)))
						ConstrainOrientation(part,0,GetBodyTransform(part).rot,rot)
					end
				end
			end
		end
	end
end

function exec_marker(m)
	if m.name=="World Align" then
		alignLocal=false
	elseif m.name=="Local Align" then
		alignLocal=true
	elseif m.name=="Ragdoll" then
		ragdoll=true
		for i=1,#shapes do
			SetShapeCollisionFilter(shapes[i],1,255)
		end
	elseif m.name=="Unragdoll" then
		ragdoll=false
		for i=1,#shapes do
			SetShapeCollisionFilter(shapes[i],filterLayer,255-filterLayer)
		end
	end
end

function get_keys(keys,t)
	local startKey=-1
	local endKey=-1
	if #keys>0 then
		if #keys==1 then
			startKey=1
			endKey=1
		else
			for i=1,#keys do
				if i==#keys then
					startKey=i
					endKey=i
				elseif keys[i]["t"]<t and keys[i+1]["t"]>t then
					startKey=i
					endKey=i+1
					break
				end
				
			end
		end
	end
	return startKey, endKey
end

function interpolate_parabolic(x)
	if x<=0 then
		return 0
	elseif x<0.5 then
		return 2*(x^2)
	elseif x<1 then
		return 1-2*((x-1)^2)
	end
	return 1
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end
