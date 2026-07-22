local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer

local User = (getgenv and getgenv().Config) or {}
local UserSettings = User.Settings or {}

local function pick(v, default)
	if v == nil then
		return default
	end
	return v
end

local FOLDER = pick(User.Folder, "no1toolchangeacc")
local LOOP_INTERVAL = 5

local TeamAlias = {
	pirates = "Pirates",
	pirate = "Pirates",
	marines = "Marines",
	marine = "Marines"
}

local AUTO_TEAM = TeamAlias[tostring(pick(User.Team, "Pirates")):lower()] or "Pirates"

local DEFAULT = {
	godhuman = false,
	sanguine_art = false,
	cursed_dual_katana = false,
	true_triple_katana = false,
	shark_anchor = false,
	skull_guitar = false,
	mirror_fractal = false,
	valkyrie_helm = false,
	fragment = 0,
	beli = 0,
	level = 0,
	bounty_honor = 0,
	race_ver = 0,
	tier = 0,
	race_draco = false,
	race_mink = false,
	race_human = false,
	race_cyborg = false,
	race_ghoul = false,
	race_fishman = false,
	race_skypiea = false
}

local CONFIG = {}
for k, v in pairs(DEFAULT) do
	CONFIG[k] = pick(UserSettings[k], v)
end

local RaceFlagMap = {
	race_draco = "draco",
	race_mink = "mink",
	race_human = "human",
	race_cyborg = "cyborg",
	race_ghoul = "ghoul",
	race_fishman = "fishman",
	race_skypiea = "skypiea"
}

local CommF = nil

local function getCommF()
	if CommF then
		return CommF
	end
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
	if not remotes then
		return nil
	end
	CommF = remotes:WaitForChild("CommF_", 15)
	return CommF
end

local function invoke(...)
	local c = getCommF()
	if not c then
		return nil
	end
	local args = { ... }
	local ok, res = pcall(function()
		return c:InvokeServer(unpack(args))
	end)
	if ok then
		return res
	end
	return nil
end

local function getData()
	local d = plr:FindFirstChild("Data")
	if d then
		return d
	end
	return plr:WaitForChild("Data", 20)
end

local function readValue(folder, name, default)
	if not folder then
		return default
	end
	local node = folder:FindFirstChild(name)
	if not node then
		return default
	end
	return node.Value
end

local function autoSelectTeam()
	pcall(function()
		ReplicatedStorage.Remotes.CommF_:InvokeServer("SetTeam", AUTO_TEAM)
	end)
end

local function getInventory()
	local inv = invoke("getInventory")
	if type(inv) == "table" then
		return inv
	end
	return {}
end

local function hasItem(inv, itemName, itemType)
	local target = tostring(itemName):lower()
	for _, v in ipairs(inv) do
		if type(v) == "table" and tostring(v.Name or ""):lower() == target then
			if not itemType or v.Type == itemType then
				return true
			end
		end
	end
	return false
end

local function hasTool(toolName)
	local target = tostring(toolName):lower()
	local function scan(container)
		if not container then
			return false
		end
		for _, t in ipairs(container:GetChildren()) do
			if t:IsA("Tool") and t.Name:lower() == target then
				return true
			end
		end
		return false
	end
	if scan(plr.Character) then
		return true
	end
	return scan(plr:FindFirstChild("Backpack"))
end

local function getTierLegacy()
	local tier = 0
	pcall(function()
		local data = plr:FindFirstChild("Data")
		local raceFolder = data and data:FindFirstChild("Race")
		local cValue = raceFolder and raceFolder:FindFirstChild("C")
		if cValue then
			tier = tonumber(cValue.Value) or 0
		end
	end)
	return tier
end

local function isV4()
	local char = plr.Character
	if char and char:FindFirstChild("RaceTransformed") then
		return true
	end
	local bp = plr:FindFirstChild("Backpack")
	if bp and bp:FindFirstChild("Awakening") then
		return true
	end
	if getTierLegacy() >= 1 then
		return true
	end
	return false
end

local function getRaceVer()
	local ver = 1

	if invoke("Alchemist", "1") == -2 then
		ver = 2
	end
	if invoke("Wenlocktoad", "1") == -2 then
		ver = 3
	end
	if isV4() then
		ver = 4
	end

	return ver
end

local function getV4Tier()
	if not isV4() then
		return 0
	end

	local tier = getTierLegacy()

	if tier < 1 then
		tier = 1
	end
	if tier > 10 then
		tier = 10
	end

	return tier
end

local function collect()
	local data = getData()
	if not data then
		return nil
	end

	local inv = getInventory()

	local race = tostring(readValue(data, "Race", "Human"))
	local raceVer = getRaceVer()

	local v4Tier = 0
	if raceVer >= 4 then
		v4Tier = getV4Tier()
	end

	local trueTriple = hasItem(inv, "True Triple Katana", "Sword")
		or hasItem(inv, "True Triple Katana")
		or hasTool("True Triple Katana")

	local bounty = 0
	local ls = plr:FindFirstChild("leaderstats")
	if ls and ls:FindFirstChild("Bounty/Honor") then
		bounty = tonumber(ls["Bounty/Honor"].Value) or 0
	else
		bounty = tonumber(readValue(data, "Bounty", 0)) or 0
	end

	return {
		race = race:lower(),
		race_ver = raceVer,
		tier = v4Tier,
		godhuman = hasItem(inv, "God Human") or hasItem(inv, "Godhuman") or hasTool("Godhuman"),
		sanguine_art = hasItem(inv, "Sanguine Art") or hasTool("Sanguine Art"),
		cursed_dual_katana = hasItem(inv, "Cursed Dual Katana", "Sword"),
		true_triple_katana = trueTriple,
		shark_anchor = hasItem(inv, "Shark Anchor", "Sword"),
		skull_guitar = hasItem(inv, "Skull Guitar") or hasTool("Skull Guitar"),
		mirror_fractal = hasItem(inv, "Mirror Fractal"),
		valkyrie_helm = hasItem(inv, "Valkyrie Helm"),
		fragment = tonumber(readValue(data, "Fragments", 0)) or 0,
		beli = tonumber(readValue(data, "Beli", 0)) or 0,
		level = tonumber(readValue(data, "Level", 0)) or 0,
		bounty_honor = bounty
	}
end

local BoolKeys = {
	"godhuman", "sanguine_art", "cursed_dual_katana", "true_triple_katana",
	"shark_anchor", "skull_guitar", "mirror_fractal", "valkyrie_helm"
}

local NumKeys = { "fragment", "beli", "level", "bounty_honor", "race_ver" }


local function evaluate(stats)
	local missing = {}

	for _, k in ipairs(BoolKeys) do
		if CONFIG[k] == true and stats[k] ~= true then
			table.insert(missing, k)
		end
	end

	for _, k in ipairs(NumKeys) do
		local need = tonumber(CONFIG[k]) or 0
		if need > 0 and (tonumber(stats[k]) or 0) < need then
			table.insert(missing, k .. " (" .. tostring(stats[k]) .. "/" .. tostring(need) .. ")")
		end
	end

	local needTier = tonumber(CONFIG.tier) or 0
	if needTier > 0 and (tonumber(CONFIG.race_ver) or 0) >= 4 then
		if stats.race_ver < 4 then
			table.insert(missing, "tier (chua co V4)")
		elseif stats.tier < needTier then
			table.insert(missing, "tier (" .. stats.tier .. "/" .. needTier .. ")")
		end
	end

	local anyRace = false
	local matchRace = false
	for flag, name in pairs(RaceFlagMap) do
		if CONFIG[flag] == true then
			anyRace = true
			if stats.race == name then
				matchRace = true
			end
		end
	end
	if anyRace and not matchRace then
		table.insert(missing, "race (" .. stats.race .. ")")
	end

	return #missing == 0, missing
end

local function writeResult(status)
	pcall(function()
		if not isfolder(FOLDER) then
			makefolder(FOLDER)
		end
		writefile(FOLDER .. "/" .. plr.Name .. ".json", '{\n  "' .. plr.Name .. '": "' .. status .. '"\n}')
	end)
end

local function check()
	local stats = collect()
	if not stats then
		return
	end
	local passed = evaluate(stats)
	writeResult(passed and "completed" or "uncompleted")
end

autoSelectTeam()

if not plr.Character then
	plr.CharacterAdded:Wait()
end

task.wait(5)

task.spawn(function()
	while true do
		pcall(check)
		task.wait(LOOP_INTERVAL)
	end
end)