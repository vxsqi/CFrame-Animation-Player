-- "CFrame" Animator V3
-- by vxsqi
-- updated version: v3.04a

--/ Services
local keyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local tween = game:GetService("TweenService")

--/ Module
local c0Saves = {}
local anims = {}

local module = {}
module.__index = module

function module:Destroy(welds:{}?)
	anims[self.char] = {}

	self:stop(welds)
	self.char = nil
	self.looped = nil
	self.autostop = nil
	self.data = nil
	self.speed = nil
	self = nil
end

function module:getWeldsAndC0()
	local t = {}
    print(self.char)

	for i,v: Motor6D in pairs(self.char:GetDescendants()) do
		if v:IsA("Motor6D") and (not v:FindFirstAncestorOfClass("Accessory")) then
			local normal = (c0Saves[v] or (function()
				local a = v.C0
				c0Saves[v]=a
				return a
			end)())

			if v.Part1 then
				t[v.Part1.Name]={v, normal}
			end
		end
	end

	return t
end

function module:stop(welds:{}) 
	welds = welds or self:getWeldsAndC0()
	anims[self.char] = {}

	for i,v in pairs(welds) do
		tween:Create(v[1], TweenInfo.new(0.06), {C0=v[2]}):Play()
	end
end

local function getSequenceLength(keyframeSequence:KeyframeSequence) -- sample from https://developer.roblox.com/en-us/api-reference/property/Keyframe/Time
	local length = 0
	for _, keyframe in pairs(keyframeSequence:GetKeyframes()) do 
		if keyframe.Time > length then 
			length = keyframe.Time 
		end
	end
	return length
end


function module:playv2(welds:{})
	welds = welds or self:getWeldsAndC0()
	local char:Model, data:KeyframeSequence = self.char, self.data

	local id = {}
	anims[char] = id

	local threads = {}

	local kfs = data:GetKeyframes()

	self.time = getSequenceLength(data)

	for ind = 0, (#kfs) do
		local v = kfs[ind]

		if anims[char] ~= id then return end

		task.spawn(function()
			wait((v and v.Time or 0)/(tonumber(self.speed) or 1))
			if anims[char] ~= id then return end

			for _, a in pairs(((v or kfs[ind+1] or kfs[1])):GetDescendants()) do
				if a:IsA("Pose") then
					local d = welds[a.Name]
					if d then
						if anims[char] ~= id then return end

						local timeDiff = (kfs[ind+1] and (kfs[ind+1].Time-(v and v.Time or 0)) or kfs[1].Time)/(tonumber(self.speed) or 1)
						local easingStyle = (a.EasingStyle or Enum.EasingStyle.Linear)
						local easingDirection = (a.EasingDirection or Enum.EasingDirection.In)

						local tInfo = TweenInfo.new(timeDiff, Enum.EasingStyle[(easingStyle.Name == "Constant" and "Linear" or easingStyle.Name)], Enum.EasingDirection[easingDirection.Name])

						tween:Create(d[1], tInfo, {
							C0 = d[2] * a.CFrame
						}):Play()

					end
				end
			end

		end)
	end

	task.spawn(function()
		if anims[char] ~= id then return end
		wait(self.time/(tonumber(self.speed) or 1))
		if anims[char] ~= id then return end

		if self.looped == true then
			if anims[char] ~= id then return end
			self:play(welds)
		elseif self.looped == false and self.autostop == true then
			if anims[char] ~= id then return end
			self:stop(welds)
		end

	end)

end


function module:play(welds:{})
	welds = welds or self:getWeldsAndC0()
	local char:Model, data:KeyframeSequence = self.char, self.data

	local id = {}
	anims[char] = id

	local threads = {}

	local kfs = data:GetKeyframes()

	self.time = getSequenceLength(data)

	for ind,v in pairs(kfs) do
		if anims[char] ~= id then return end

		task.spawn(function()
			wait(v.Time/(tonumber(self.speed) or 1))
			if anims[char] ~= id then return end

			for _, a in pairs(v:GetDescendants()) do
				if a:IsA("Pose") then
					local d = welds[a.Name]
					if d then
						if anims[char] ~= id then return end

						local timeDiff = (kfs[ind+1] and (kfs[ind+1].Time-v.Time) or kfs[1].Time)/(tonumber(self.speed) or 1)
						local easingStyle = (a.EasingStyle or Enum.EasingStyle.Linear)
						local easingDirection = (a.EasingDirection or Enum.EasingDirection.In)

						local tInfo = TweenInfo.new(timeDiff, Enum.EasingStyle[(easingStyle.Name == "Constant" and "Linear" or easingStyle.Name)], Enum.EasingDirection[easingDirection.Name])

						tween:Create(d[1], tInfo, {
							C0 = d[2] * a.CFrame
						}):Play()


					end
				end
			end

		end)
	end

	task.spawn(function()
		if anims[char] ~= id then return end
		wait(self.time/(tonumber(self.speed) or 1))
		if anims[char] ~= id then return end

		if self.looped == true then
			if anims[char] ~= id then return end
			self:play(welds)
		elseif self.looped == false and self.autostop == true then
			if anims[char] ~= id then return end
			self:stop(welds)
		end

	end)
end


function round(n, decimals)
	decimals = decimals or 0
	return math.floor(n * 10^decimals) / 10^decimals
end

function cutCFrame(cf:CFrame)
	local c = {cf:GetComponents()}
	local res = {}
	for i,v in pairs(c) do
		table.insert(res, round(v, 3))
	end
	return string.format("%s",table.concat(res, ","))
end

function module.keyframeToString(kf:KeyframeSequence)
	if not kf:IsA("KeyframeSequence") then
		return "{}"
	end
	local res = "local c=CFrame.new; return{"..string.format('["l"]=%s;',tostring(kf.Loop))
	local current = 0
	local children = kf:GetChildren();
	table.sort(children, function(a, b) return a.Time < b.Time end)
	for index, keyframe in pairs(children) do
		if keyframe:IsA("Keyframe") then
			current = round(keyframe.Time, 3)

			res = res .. "\n[".. tostring(current) .. "]={"

			local poses = keyframe:GetDescendants()
			for i,v in pairs(poses) do
				if v:IsA("Pose") then
					res = res .. ('["'..string.format(v.Name, '"','\"') ..'"]={c('.. string.gsub(tostring(cutCFrame(v.CFrame)), " ", "") .. ")" .. string.format(",'%s','%s'", v.EasingStyle.Name,v.EasingDirection.Name)..'}'.. (i == #poses and "" or ";")) 
				end
			end

			res = (res .. "}" .. (index == #children and "" or ";"))
		end
	end
	res = res .. "}"
	return res
end

function module.tableToKeyframe(keyframeData:{})
	local inst = Instance.new("KeyframeSequence")
	inst.Loop = (keyframeData["l"])

	for time, data in pairs(keyframeData) do
		if time ~= "l" then
			local keyfram = Instance.new("Keyframe")
			keyfram.Time = tonumber(time)

			for a,b in pairs(data) do

				local pose = Instance.new("Pose")
				pose.Name = a
				pose.CFrame = b[1]
				pose.EasingStyle = Enum.PoseEasingStyle[b[2]]
				pose.EasingDirection = Enum.PoseEasingDirection[b[3]]
				pose.Parent = keyfram
			end

			keyfram.Parent = inst

		end
	end

	return inst

	--local main = Instance.new("KeyframeSequence")

	--for time, data in pairs(keyframeData) do
	--	if tonumber(time) then
	--		local a = Instance.new("Keyframe")
	--		a.Time = tonumber(time)

	--		for i,v in pairs(data) do
	--			local pose = Instance.new("Pose", a)
	--			pose.Name = i
	--			pose.CFrame = v[1]
	--			pose.EasingStyle = Enum.PoseEasingStyle v[2]
	--			pose.EasingDirection = Enum.PoseEasingDirection v[3]
	--		end

	--		a.Parent = main
	--	elseif time == "Properties" then
	--		main.Loop = data.Looped
	--	end
	--end

	--return main
end

function module.new(character: Model, keyframeSequence:KeyframeSequence|any|{}, looped)
	assert(keyframeSequence, "<KeyframeSequence|string>keyframeSequence is nil.")

	if typeof(keyframeSequence) == "string" then
		keyframeSequence = (keyframeSequenceProvider:GetKeyframeSequenceAsync(keyframeSequence) or error("Couldn't download keyframesequence data from id."))
	end

	if typeof(keyframeSequence) == "table" then
		keyframeSequence = module.tableToKeyframe(keyframeSequence)
	end

	if typeof(keyframeSequence) == "Instance" then
		if not keyframeSequence:IsA("KeyframeSequence") then
			error("Couldn't get keyframesequence.")
		end
	end

	local selfmodule = {}
	selfmodule.data = keyframeSequence
	selfmodule.char = character
	selfmodule.looped = (keyframeSequence.Loop)
	if looped ~= nil then
		selfmodule.looped = looped
	end
	selfmodule.speed = 1
	selfmodule.autostop = true
	setmetatable(selfmodule, module)

	return selfmodule
end

return module