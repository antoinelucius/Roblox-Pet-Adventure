-- ============================================================
-- MYTHIC WORLDS SIMULATOR - SERVER (v5 - combat corrige, cristaux aleatoires, portails/mondes, teleportation securisee)
-- A placer dans ServerScriptService (remplace l'ancien script serveur).
-- Les RemoteEvents existants (StateUpdate, BuyEgg, EquipPet, EggInfo,
-- BattleStart, BattleAction, BattleUpdate, RebirthRemote, NPCInfo)
-- sont conserves : ton script client continue de fonctionner.
-- Nouveau RemoteEvent : WorldTeleport (client -> serveur, index du monde).
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local datastoreAvailable = pcall(function()
	_G.MWS_Store = DataStoreService:GetDataStore("MythicWorlds_v3")
end)
if not datastoreAvailable then
	warn("[MWS] DataStore non disponible (jeu non publie). Sauvegarde desactivee.")
end

local V3, CF = Vector3.new, CFrame.new
local M = Enum.Material
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local DARKC = Color3.fromRGB(20, 20, 30)

-- MODE TEST : coûts réduits pour tester vite. METS false AVANT DE PUBLIER LE JEU.
local TEST_MODE = true

local START_COINS = TEST_MODE and 2000 or 100
local MAX_PETS = 200
-- Niveaux des pets (entrainement aux sacs de frappe) : +10 % de revenu et +5 % de force par niveau
local PET_MAX_LVL = 20
local PET_LVL_BONUS = 0.10
local function petLvlMult(pet)
	return 1 + PET_LVL_BONUS * math.clamp(math.floor(tonumber(pet.lvl) or 0), 0, PET_MAX_LVL)
end
local function petXpNeeded(lvl)
	return 30 + 20 * lvl
end
local MAX_EQUIPPED = 6
-- pets equipes : 2 au debut, +1 toutes les 2 renaissances (max MAX_EQUIPPED)
local function maxEquip(s)
	return math.min(MAX_EQUIPPED, 2 + math.floor(((s and s.rebirthLevel) or 0) / 2))
end
local REBIRTH_COST = TEST_MODE and 300 or 250000
local PET_SCALE = 0.7
local SPEED_BOOST_COST = 500
local SPEED_BOOST_DURATION = 60
local SPEED_BOOST_MULT = 2

-- ============================================================
-- MONDES
-- ============================================================

local WORLDS = {
	-- unlock = coins a payer (une fois) | rebirth = nombre de renaissances necessaires pour entrer
	{ name = "Prairie enchantee",  unlock = 0,                              rebirth = 0, offset = V3(0, 0, 0),    crystalReward = 25 },
	{ name = "Royaume volcanique", unlock = TEST_MODE and 0 or 5000,       rebirth = TEST_MODE and 0 or 1, offset = V3(2000, 0, 0), crystalReward = 200 },
	{ name = "Dimension mythique", unlock = TEST_MODE and 0 or 150000,     rebirth = TEST_MODE and 0 or 5, offset = V3(4000, 0, 0), crystalReward = 2000 },
}

local worldOrigin = {}
local TRAIN_PAD_CENTER = { V3(147, 0, 26), V3(-154, 0, 34), V3(10, 0, 80) }   -- centre de la zone d'entrainement de chaque monde

-- ============================================================
-- RARETES
-- ============================================================

local RARITIES = {
	-- glow : couleurs plus vives + lumiere plus forte pour les pets rares
	["Commun"]     = { color = Color3.fromRGB(190, 190, 190), scale = 0.85, rate = 0,  light = false, glow = 0 },
	["Rare"]       = { color = Color3.fromRGB(80, 160, 255),  scale = 0.95, rate = 3,  light = false, glow = 0 },
	["Epique"]     = { color = Color3.fromRGB(170, 90, 255),  scale = 1.0,  rate = 5,  light = false, glow = 0.1 },
	["Legendaire"] = { color = Color3.fromRGB(255, 170, 40),  scale = 1.1,  rate = 8,  light = true,  glow = 0.25 },
	["Mythique"]   = { color = Color3.fromRGB(255, 70, 90),   scale = 1.25, rate = 11, light = true,  glow = 0.35 },
	["Divin"]      = { color = Color3.fromRGB(255, 245, 150), scale = 1.4,  rate = 15, light = true,  glow = 0.45, halo = true },
	["Secret"]     = { color = Color3.fromRGB(255, 60, 200),  scale = 1.6,  rate = 22, light = true,  glow = 0.55, halo = true },
}

local function rarityInfo(name)
	return RARITIES[name] or RARITIES["Commun"]
end

local STYLE_ACCENT = {
	pres = Color3.fromRGB(255, 255, 150), venin = Color3.fromRGB(190, 80, 255),
	solaire = Color3.fromRGB(255, 230, 80), brume = Color3.fromRGB(200, 230, 255),
	violet = Color3.fromRGB(255, 150, 255), mousse = Color3.fromRGB(120, 255, 120),
	argent = Color3.fromRGB(120, 200, 255), astral = Color3.fromRGB(255, 255, 160),
	eclat = Color3.fromRGB(255, 220, 80), jade = Color3.fromRGB(255, 215, 80),
	lave = Color3.fromRGB(255, 140, 30), celeste = Color3.fromRGB(120, 180, 255),
	royal = Color3.fromRGB(255, 210, 70), ether = Color3.fromRGB(120, 255, 230),
	cosmique = Color3.fromRGB(255, 120, 255), orage = Color3.fromRGB(255, 255, 120),
	magma = Color3.fromRGB(255, 160, 30), infernal = Color3.fromRGB(255, 200, 60),
	basalte = Color3.fromRGB(255, 110, 20), lunaire = Color3.fromRGB(255, 255, 255),
	aurore = Color3.fromRGB(255, 255, 200), vide = Color3.fromRGB(200, 90, 255),
	chaos = Color3.fromRGB(255, 60, 200), obsidienne = Color3.fromRGB(180, 60, 255),
	cristal = Color3.fromRGB(255, 255, 255), neant = Color3.fromRGB(255, 255, 255),
	primordial = Color3.fromRGB(255, 255, 100), etoiles = Color3.fromRGB(255, 255, 255),
}

-- ============================================================
-- PETS : 31 animaux (5-6 par oeuf)
-- ============================================================

local PETS = {
	["Poulet"] = { rarity = "Commun", color = {245, 245, 245}, multiplier = 1, income = 1, archetype = "slime", style = "pres" },
	["Chien"] = { rarity = "Commun", color = {160, 110, 70}, multiplier = 1, income = 2, archetype = "slime", style = "venin" },
	["Renard"] = { rarity = "Rare", color = {226, 135, 45}, multiplier = 2, income = 10, archetype = "slime", style = "solaire" },
	["Ours"] = { rarity = "Epique", color = {105, 64, 40}, multiplier = 3, income = 25, archetype = "slime", style = "brume" },
	["Cerf"] = { rarity = "Legendaire", color = {190, 140, 90}, multiplier = 5, income = 40, archetype = "slime", style = "mousse" },
	["Licorne"] = { rarity = "Legendaire", color = {245, 200, 235}, multiplier = 6, income = 60, archetype = "slime", style = "violet" },
	["Tortue"] = { rarity = "Rare", color = {75, 151, 75}, multiplier = 3, income = 15, archetype = "slime", style = "argent" },
	["Hibou des neiges"] = { rarity = "Legendaire", color = {235, 240, 250}, multiplier = 5, income = 50, archetype = "slime", style = "astral" },
	["Panda roux"] = { rarity = "Epique", color = {190, 85, 40}, multiplier = 6, income = 75, archetype = "slime", style = "eclat" },
	["Pterodactyle"] = { rarity = "Mythique", color = {150, 105, 65}, multiplier = 8, income = 120, archetype = "slime", style = "jade" },
	["Dragon de glace"] = { rarity = "Mythique", color = {150, 205, 235}, multiplier = 10, income = 200, archetype = "slime", style = "celeste" },
	["Tigre"] = { rarity = "Mythique", color = {240, 150, 40}, multiplier = 8, income = 100, archetype = "slime", style = "celeste" },
	["Dragon de lave"] = { rarity = "Mythique", color = {215, 75, 28}, multiplier = 12, income = 250, archetype = "slime", style = "royal" },
	["Gorille"] = { rarity = "Mythique", color = {84, 84, 92}, multiplier = 15, income = 400, archetype = "slime", style = "ether" },
	["Mammouth"] = { rarity = "Divin", color = {110, 75, 50}, multiplier = 20, income = 750, archetype = "slime", style = "cosmique" },
	["Phenix"] = { rarity = "Divin", color = {245, 150, 40}, multiplier = 30, income = 1500, archetype = "slime", style = "orage" },
	["Crocodile"] = { rarity = "Epique", color = {75, 151, 75}, multiplier = 15, income = 300, archetype = "slime", style = "magma" },
	["Taureau de feu"] = { rarity = "Epique", color = {120, 40, 30}, multiplier = 20, income = 450, archetype = "slime", style = "infernal" },
	["Salamandre"] = { rarity = "Legendaire", color = {226, 135, 45}, multiplier = 25, income = 700, archetype = "slime", style = "basalte" },
	["Pegase"] = { rarity = "Mythique", color = {205, 228, 248}, multiplier = 40, income = 1200, archetype = "slime", style = "magma" },
	["Dragon des ombres"] = { rarity = "Divin", color = {92, 48, 142}, multiplier = 60, income = 2500, archetype = "slime", style = "lave" },
	["Yeti"] = { rarity = "Mythique", color = {190, 235, 250}, multiplier = 50, income = 2000, archetype = "slime", style = "etoiles" },
	["Kitsune"] = { rarity = "Mythique", color = {245, 245, 255}, multiplier = 60, income = 3000, archetype = "slime", style = "lunaire" },
	["Roi serpent"] = { rarity = "Mythique", color = {245, 205, 48}, multiplier = 75, income = 4500, archetype = "slime", style = "aurore" },
	["Dragon cosmique"] = { rarity = "Divin", color = {55, 100, 225}, multiplier = 100, income = 7000, archetype = "slime", style = "cosmique" },
	["Dragon du vide"] = { rarity = "Divin", color = {170, 40, 160}, multiplier = 140, income = 12000, archetype = "slime", style = "vide" },
	["Tyrannosaure"] = { rarity = "Mythique", color = {70, 140, 90}, multiplier = 120, income = 8000, archetype = "slime", style = "chaos" },
	["Tigre sabre"] = { rarity = "Divin", color = {196, 165, 112}, multiplier = 160, income = 14000, archetype = "slime", style = "obsidienne" },
	["Cerbere"] = { rarity = "Divin", color = {80, 55, 80}, multiplier = 220, income = 22000, archetype = "slime", style = "cristal" },
	["Dragon lunaire"] = { rarity = "Divin", color = {212, 222, 240}, multiplier = 300, income = 35000, archetype = "slime", style = "neant" },
	["Dragon primordial"] = { rarity = "Secret", color = {239, 184, 56}, multiplier = 500, income = 80000, archetype = "slime", style = "primordial" },
}

-- ============================================================
-- OEUFS (world = monde ou l'oeuf est vendu)
-- ============================================================

local EGGS = {
	{
		name = "Oeuf de base", price = 100, world = 1, style = "base",
		color = {180, 120, 255}, standColor = Color3.fromRGB(90, 120, 255),
		pool = {
			{ pet = "Poulet",    chance = 39 },
			{ pet = "Chien",  chance = 28 },
			{ pet = "Renard",    chance = 20 },
			{ pet = "Ours", chance = 10 },
			{ pet = "Cerf",   chance = 2 },
			{ pet = "Licorne",     chance = 1 }
		}
	},
	{
		name = "Oeuf dore", price = 1000, world = 1, style = "dore",
		color = {255, 200, 50}, standColor = Color3.fromRGB(200, 160, 40),
		pool = {
			{ pet = "Tortue",  chance = 28 },
			{ pet = "Hibou des neiges",     chance = 25 },
			{ pet = "Panda roux", chance = 22 },
			{ pet = "Pterodactyle",    chance = 18 },
			{ pet = "Dragon de glace",      chance = 7 }
		}
	},
	{
		name = "Oeuf mythique", price = 5000, world = 2, style = "mythique",
		color = {255, 50, 200}, standColor = Color3.fromRGB(180, 40, 140),
		pool = {
			{ pet = "Tigre",    chance = 28 },
			{ pet = "Dragon de lave",   chance = 25 },
			{ pet = "Gorille",     chance = 22 },
			{ pet = "Mammouth", chance = 18 },
			{ pet = "Phenix",   chance = 7 }
		}
	},
	{
		name = "Oeuf de lave", price = 20000, world = 2, style = "lave",
		color = {255, 100, 20}, standColor = Color3.fromRGB(120, 40, 20),
		pool = {
			{ pet = "Crocodile", chance = 35 },
			{ pet = "Taureau de feu",  chance = 27 },
			{ pet = "Salamandre", chance = 20 },
			{ pet = "Pegase",  chance = 13 },
			{ pet = "Dragon des ombres",   chance = 5 }
		}
	},
	{
		name = "Oeuf celeste", price = 75000, world = 3, style = "celeste",
		color = {120, 160, 255}, standColor = Color3.fromRGB(60, 50, 140),
		pool = {
			{ pet = "Yeti", chance = 33 },
			{ pet = "Kitsune",        chance = 27 },
			{ pet = "Roi serpent",    chance = 20 },
			{ pet = "Dragon cosmique",     chance = 14 },
			{ pet = "Dragon du vide",       chance = 6 }
		}
	},
	{
		name = "Oeuf primordial", price = 400000, world = 3, style = "primordial",
		color = {255, 80, 255}, standColor = Color3.fromRGB(70, 20, 110),
		pool = {
			{ pet = "Tyrannosaure",    chance = 30 },
			{ pet = "Tigre sabre", chance = 28 },
			{ pet = "Cerbere",    chance = 22 },
			{ pet = "Dragon lunaire",     chance = 15 },
			{ pet = "Dragon primordial",   chance = 5 }
		}
	}
}

-- ============================================================
-- DRESSEURS (world = monde ou se trouve le dresseur)
-- ============================================================

local NPC_TRAINERS = {
	{ name = "Gobelin Sauvage", boss = "GobelinSauvage", world = 1, offset = V3(-64, 0, -48), color = {100, 200, 100},
		pets = {
			{ name = "Poulet",    hp = 80,  attack = 10, color = {245, 245, 245} },
			{ name = "Chien",  hp = 100, attack = 12, color = {160, 110, 70} } },
		reward = 200 },
	{ name = "Orque Brutal", boss = "OrqueBrutal", world = 1, offset = V3(-88, 0, 8), color = {255, 160, 50},
		pets = {
			{ name = "Renard",    hp = 150, attack = 20, color = {226, 135, 45} },
			{ name = "Ours", hp = 200, attack = 25, color = {105, 64, 40} },
			{ name = "Cerf",   hp = 300, attack = 30, color = {190, 140, 90} } },
		reward = 500 },
	{ name = "Spectre Errant", boss = "SpectreErrant", world = 1, offset = V3(-72, 0, 64), color = {200, 200, 220},
		pets = {
			{ name = "Tortue",  hp = 250, attack = 35, color = {75, 151, 75} },
			{ name = "Hibou des neiges",     hp = 300, attack = 40, color = {235, 240, 250} },
			{ name = "Panda roux", hp = 400, attack = 50, color = {190, 85, 40} } },
		reward = 1500 },
	{ name = "Chevalier Creux", boss = "ChevalierCreux", world = 1, offset = V3(64, 0, -64), color = {140, 220, 70},
		pets = {
			{ name = "Pterodactyle", hp = 500, attack = 60, color = {150, 105, 65} },
			{ name = "Dragon de glace",   hp = 600, attack = 70, color = {150, 205, 235} },
			{ name = "Tigre",   hp = 550, attack = 65, color = {240, 150, 40} } },
		reward = 3000 },
	{ name = "Grand Sylvain", boss = "GrandSylvain", world = 1, offset = V3(88, 0, 56), color = {90, 200, 90},
		pets = {
			{ name = "Dragon de lave",   hp = 800,  attack = 80,  color = {215, 75, 28} },
			{ name = "Gorille",     hp = 900,  attack = 90,  color = {84, 84, 92} },
			{ name = "Mammouth", hp = 1200, attack = 110, color = {110, 75, 50} },
			{ name = "Phenix",   hp = 1500, attack = 150, color = {245, 150, 40} } },
		reward = 10000 },
	-- Monde 2
	{ name = "Spectre d'Ossuaire", boss = "SpectreOssuaire", world = 2, offset = V3(-110, 0, 50), color = {80, 140, 255},
		pets = {
			{ name = "Crocodile", hp = 1800, attack = 180, color = {75, 151, 75} },
			{ name = "Taureau de feu",  hp = 2200, attack = 220, color = {120, 40, 30} },
			{ name = "Salamandre", hp = 3000, attack = 250, color = {226, 135, 45} } },
		reward = 25000 },
	{ name = "Ignareth", boss = "Ignareth", world = 2, offset = V3(110, 0, -60), color = {255, 110, 30},
		pets = {
			{ name = "Pegase", hp = 3500, attack = 320, color = {205, 228, 248} },
			{ name = "Dragon des ombres",  hp = 5000, attack = 420, color = {92, 48, 142} } },
		reward = 60000 },
	-- Monde 3
	{ name = "Oni Celeste", boss = "OniCeleste", world = 3, offset = V3(-110, 0, 60), color = {255, 90, 190},
		pets = {
			{ name = "Yeti", hp = 6000, attack = 500, color = {190, 235, 250} },
			{ name = "Kitsune",        hp = 6500, attack = 560, color = {245, 245, 255} },
			{ name = "Roi serpent",    hp = 7000, attack = 620, color = {245, 205, 48} },
			{ name = "Dragon cosmique",     hp = 9000, attack = 760, color = {55, 100, 225} } },
		reward = 150000 },
	{ name = "Neant Couronne", boss = "NeantCouronne", world = 3, offset = V3(110, 0, -60), color = {255, 220, 120},
		pets = {
			{ name = "Cerbere",    hp = 12000, attack = 900,  color = {80, 55, 80} },
			{ name = "Dragon lunaire",     hp = 14000, attack = 1100, color = {212, 222, 240} },
			{ name = "Tigre sabre", hp = 15000, attack = 1200, color = {196, 165, 112} },
			{ name = "Dragon primordial",   hp = 25000, attack = 1800, color = {239, 184, 56} } },
		reward = 500000 },
}

-- Classement des boss, du plus faible au plus fort : taille, flotte ou non, puis dialogue
do
	local style = {
		{ 12, false, "Hé hé ! Tu es sûr de vouloir m'affronter, petit ?", "Tes pets vont finir dans ma marmite !" },
		{ 16, false, "Tu oses marcher sur mes terres ? Tu veux vraiment te battre ?", "Alors prépare-toi à être écrasé !" },
		{ 20, true, "Je rôde ici depuis mille ans... Veux-tu vraiment me réveiller ?", "Ton courage va s'éteindre comme ma lanterne." },
		{ 24, false, "Cette armure est vide... mais elle n'a jamais perdu. Es-tu prêt ?", "En garde, voyageur !" },
		{ 28, false, "La forêt t'observe depuis ton arrivée. Oseras-tu me défier ?", "Mes racines vont t'engloutir !" },
		{ 33, true, "Tous ceux qui m'ont défié reposent ici. Tu veux les rejoindre ?", "Ta place est déjà creusée." },
		{ 38, false, "Un mortel devant le Prince des Cendres ? Tu es sûr de ton choix ?", "Brûle, et que tes cendres me servent de trône !" },
		{ 44, false, "Ma lame n'est jamais sortie sans goûter la victoire. Tu insistes ?", "Alors danse avec les pétales !" },
		{ 50, false, "Je suis la fin de toute chose. Tu veux vraiment défier le Néant ?", "Même les étoiles se sont inclinées. À ton tour !" },
	}
	for i, st in ipairs(style) do
		local npc = NPC_TRAINERS[i]
		npc.rank, npc.height, npc.float, npc.lines = i, st[1], st[2], { st[3], st[4] }
	end
end

-- ============================================================
-- ETAT GLOBAL
-- ============================================================

local states = {}
local petVisuals = {}
local battles = {}
local crystals = {}
local eggParts = {}
local staticAnimators = {}
local arenaVis = {}
local decor = { {}, {}, {} }
local activeWorld = { true, false, false }
local worldFolder = {}
local arenaSlots = {}

local ARENA_BASE = V3(0, 200, 1500)
local ARENA_THEME = {
	{ floor = Color3.fromRGB(80, 110, 80),  ring = Color3.fromRGB(200, 220, 90),  mat = M.Slate },
	{ floor = Color3.fromRGB(60, 40, 40),   ring = Color3.fromRGB(255, 110, 30),  mat = M.Basalt },
	{ floor = Color3.fromRGB(40, 30, 80),   ring = Color3.fromRGB(200, 100, 255), mat = M.Slate },
}

local startBattle
local sendState
local sendWorldInfo

-- ============================================================
-- REMOTES
-- ============================================================

local remotes = ReplicatedStorage:FindFirstChild("MWS_Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "MWS_Remotes"
	remotes.Parent = ReplicatedStorage
end

local function getRemote(name)
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remotes
	end
	return r
end

local StateUpdate = getRemote("StateUpdate")
local BuyEgg = getRemote("BuyEgg")
local EquipPet = getRemote("EquipPet")
local EggInfo = getRemote("EggInfo")
local BattleStart = getRemote("BattleStart")
local BattleAction = getRemote("BattleAction")
local BattleUpdate = getRemote("BattleUpdate")
local RebirthRemote = getRemote("RebirthRemote")
local NPCInfo = getRemote("NPCInfo")
local WorldTeleport = getRemote("WorldTeleport")
local BuySpeed = getRemote("BuySpeed")
local BattleRequest = getRemote("BattleRequest")
local WorldInfo = getRemote("WorldInfo")
local EquipBest = getRemote("EquipBest")
local SetAuraColor = getRemote("SetAuraColor")

-- ============================================================
-- OUTILS
-- ============================================================

local function colorFromTable(c)
	if typeof(c) == "Color3" then return c end
	if typeof(c) == "table" then return Color3.fromRGB(c[1] or 255, c[2] or 255, c[3] or 255) end
	return Color3.fromRGB(150, 150, 150)
end

local function fmt(n)
	local str = tostring(math.floor(n))
	local out = str:reverse():gsub("(%d%d%d)", "%1 ")
	out = out:reverse()
	return (out:gsub("^%s+", ""))
end

local world = Instance.new("Folder")
world.Name = "MWS_Generated"
world.Parent = workspace

local petsFolder = Instance.new("Folder")
petsFolder.Name = "Pets"
petsFolder.Parent = world

for i = 1, #WORLDS do
	local f = Instance.new("Folder")
	f.Name = "World" .. i
	f.Parent = world
	worldFolder[i] = f
end

local function makePart(name, size, pos, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent or world
	return p
end

-- cylindre dont l'axe est vertical
local function makeCyl(name, height, diameter, pos, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = V3(height, diameter, diameter)
	p.CFrame = CF(pos) * CFrame.Angles(0, 0, math.pi / 2)
	p.Color = color
	p.Material = material
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent or world
	return p
end

local function emitter(parent, color, rate, size, life, speed, trans)
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(color)
	pe.LightEmission = 0.8
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(life * 0.7, life)
	pe.Rate = rate
	pe.Speed = NumberRange.new(speed * 1, speed)
	pe.SpreadAngle = Vector2.new(25, 25)
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, trans or 0.2), NumberSequenceKeypoint.new(1, 1) })
	pe.Parent = parent
	return pe
end

local function notify(player, text, color)
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then return end
	local gui = Instance.new("ScreenGui")
	gui.Name = "MWS_Toast"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 50
	local lbl = Instance.new("TextLabel")
	lbl.AnchorPoint = Vector2.new(0.5, 0)
	lbl.Position = UDim2.new(0.5, 0, 0.08, 0)
	lbl.Size = UDim2.new(0, 480, 0, 50)
	lbl.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
	lbl.BackgroundTransparency = 0.1
	-- texte blanc lisible ; la couleur du message est seulement sur le contour
	lbl.TextColor3 = WHITE
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 18
	lbl.TextWrapped = true
	lbl.Text = text
	lbl.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = lbl
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or WHITE
	stroke.Thickness = 1.5
	stroke.Transparency = 0.25
	stroke.Parent = lbl
	gui.Parent = pg
	task.delay(2.8, function()
		pcall(function()
			TweenService:Create(lbl, TweenInfo.new(0.4), { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
			TweenService:Create(stroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		end)
	end)
	Debris:AddItem(gui, 3.4)
end

local function popText(parent, pos, text, color)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = V3(0.2, 0.2, 0.2)
	p.Position = pos
	p.Parent = parent
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 160, 0, 40)
	bb.AlwaysOnTop = true
	bb.Parent = p
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, 0, 1, 0)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color or WHITE
	l.Font = Enum.Font.GothamBlack
	l.TextSize = 24
	l.TextStrokeTransparency = 0.3
	l.Parent = bb
	TweenService:Create(p, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = pos + V3(0, 4, 0) }):Play()
	TweenService:Create(l, TweenInfo.new(1, Enum.EasingStyle.Linear), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(p, 1.2)
end

local function worldOfPosition(pos)
	for i, o in ipairs(worldOrigin) do
		local d = (V3(pos.X, 0, pos.Z) - V3(o.X, 0, o.Z)).Magnitude
		if d < 460 then return i end
	end
	return nil
end

-- ============================================================
-- DECOR ANIMES (flottement, rotation, pulsation)
-- ============================================================

local function addDecor(w, part, o)
	o = o or {}
	local d = {
		part = part, base = part.CFrame,
		bob = o.bob or 0, bobSpeed = o.bobSpeed or 1.5,
		spin = o.spin or 0, pulse = o.pulse or 0,
		phase = o.phase or (math.random() * 6.28),
		baseT = part.Transparency, paused = false
	}
	table.insert(decor[w], d)
	return d
end

local function updateDecor(t)
	for w = 1, #WORLDS do
		if activeWorld[w] then
			for _, d in ipairs(decor[w]) do
				local p = d.part
				if p.Parent and not d.paused then
					if d.bob ~= 0 or d.spin ~= 0 then
						p.CFrame = d.base * CF(0, math.sin(t * d.bobSpeed + d.phase) * d.bob, 0) * CFrame.Angles(0, t * d.spin + d.phase, 0)
					end
					if d.pulse ~= 0 then
						p.Transparency = d.baseT + (math.sin(t * d.bobSpeed * 1.7 + d.phase) * 0.5 + 0.5) * d.pulse
					end
				end
			end
		end
	end
end

-- ============================================================
-- CONSTRUCTEUR DE MODELES (pets, dresseurs, accessoires)
-- Convention : l'avant du modele regarde vers -Z.
-- ============================================================

local SHAPES = { b = Enum.PartType.Block, o = Enum.PartType.Ball }

local function ROT(ax, ay, az, amp, speed, phase, pivot)
	return { ax = ax, ay = ay, az = az, amp = amp, speed = speed, phase = phase or 0, pivot = pivot }
end
local function SPIN(speed) return { ax = 0, ay = 1, az = 0, amp = 1, speed = speed, phase = 0, spin = true } end
local function MOVE(vec, speed, phase) return { ax = 0, ay = 0, az = 0, amp = 0, speed = speed, phase = phase or 0, move = vec } end
local function FLICK(speed, phase) return { speed = speed, phase = phase or 0, flicker = true } end

local function animateList(list, t)
	for _, a in ipairs(list) do
		if a.flicker then
			a.part.Transparency = (math.sin(t * a.speed + a.phase) > 0.55) and 0 or 0.9
		else
			local ang
			if a.spin then
				ang = t * a.speed + a.phase
			else
				ang = math.sin(t * a.speed + a.phase) * a.amp
			end
			local c = a.base
			if a.move then c = c * CF(a.move * math.sin(t * a.speed + a.phase)) end
			a.weld.C0 = c * CFrame.Angles(a.ax * ang, a.ay * ang, a.az * ang) * (a.post or CFrame.new())
		end
	end
end

local function add(P, parent, name, shape, size, cf, color, mat, anim, trans)
	local s = P.scale
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = SHAPES[shape] or Enum.PartType.Block
	part.Size = size * s
	part.Color = color or P.col
	part.Material = mat or M.SmoothPlastic
	part.Transparency = trans or 0
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = true
	part.Anchored = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	cf = cf or CF()
	local hinge = CF(cf.Position * s) * cf.Rotation
	local w = Instance.new("Weld")
	w.Part0 = parent or P.rootPart
	w.Part1 = part
	w.C0 = hinge
	if anim and anim.pivot then
		w.C1 = CF(-anim.pivot * s)
	end
	w.Parent = part
	part.Parent = P.model
	if anim then
		table.insert(P.anims, {
			weld = w, base = hinge, part = part,
			ax = anim.ax or 0, ay = anim.ay or 0, az = anim.az or 0,
			amp = anim.amp or 0, speed = anim.speed or 1, phase = anim.phase or 0,
			spin = anim.spin, flicker = anim.flicker,
			move = anim.move and (anim.move * s) or nil
		})
	end
	return part
end

local function makeRoot(P, shape, size, color, mat, trans)
	local part = Instance.new("Part")
	part.Name = "Body"
	part.Shape = SHAPES[shape] or Enum.PartType.Block
	part.Size = size * P.scale
	part.Color = color or P.col
	part.Material = mat or M.SmoothPlastic
	part.Transparency = trans or 0
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Massless = false
	part.Anchored = P.anchoredRoot and true or false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = P.model
	P.model.PrimaryPart = part
	P.rootPart = part
	return part
end

local function eyes(P, parent, y, z, spacing, size, glow)
	for _, side in ipairs({ -1, 1 }) do
		if glow then
			add(P, parent, "Eye", "o", V3(size, size, size), CF(side * spacing, y, z), glow, M.Neon)
		else
			add(P, parent, "Eye", "o", V3(size, size * 1.15, size * 0.7), CF(side * spacing, y, z), WHITE)
			add(P, parent, "Pupil", "o", V3(size * 0.55, size * 0.7, size * 0.4), CF(side * spacing, y, z - size * 0.3), Color3.fromRGB(15, 15, 20))
		end
	end
end

local function wings(P, parent, x, y, z, len, depth, color, mat, trans, amp, speed)
	for _, side in ipairs({ -1, 1 }) do
		local w1 = add(P, parent, "Wing", "b", V3(len, 0.1, depth), CF(side * x, y, z), color, mat,
			ROT(0, 0, side, amp, speed, 0, V3(side * len / 2, 0, 0)), trans)
		add(P, w1, "WingTip", "b", V3(len * 0.85, 0.08, depth * 0.75), CF(side * len / 2, 0, depth * 0.1),
			color:Lerp(P.light, 0.3), mat,
			ROT(0, 0, side, amp * 0.6, speed, -0.7, V3(side * len * 0.85 / 2, 0, 0)), trans)
		add(P, w1, "WingBone", "b", V3(len, 0.14, 0.14), CF(0, 0.02, -depth / 2 + 0.05), P.dark)
	end
end

local function chain(P, parent, hinge, n, w, shrink, len, color, mat, axisVec, amp, speed, phaseStep, shape, onSeg)
	local cur = parent
	local width = w
	local hcf = hinge
	local last = nil
	for i = 1, n do
		local seg = add(P, cur, "Seg" .. i, shape or "o", V3(width, width, len), hcf, color, mat,
			ROT(axisVec.X, axisVec.Y, axisVec.Z, amp, speed, -i * phaseStep, V3(0, 0, len / 2)))
		if onSeg then onSeg(seg, i, width) end
		last = seg
		cur = seg
		hcf = CF(0, 0, len / 2 * 0.95)
		width = width * shrink
	end
	return last
end

local function legs4(P, x, y, zf, w, h, color, amp, speed, mat)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			local phase = (sx * sz > 0) and 0 or math.pi
			add(P, nil, "Leg", "b", V3(w, h, w), CF(sx * x, y, sz * zf), color, mat,
				ROT(1, 0, 0, amp, speed, phase, V3(0, -h / 2, 0)))
		end
	end
end

local function orbit(P, parent, y, radius, count, size, color, speed)
	local hub = add(P, parent, "Hub", "b", V3(0.2, 0.2, 0.2), CF(0, y, 0), color, M.Neon, SPIN(speed), 1)
	for i = 1, count do
		local a = (i / count) * math.pi * 2
		add(P, hub, "Orb", "o", V3(size, size, size), CF(math.cos(a) * radius, math.sin(a * 2) * 0.3, math.sin(a) * radius), color, M.Neon)
	end
end

-- ------------------------------------------------------------
-- ARCHETYPES DE PETS
-- ------------------------------------------------------------

local A = {}

A.slime = function(P)
	makeRoot(P, "o", V3(2.4, 1.9, 2.4), P.col, M.SmoothPlastic, 0.2)
	P.foot = 0.95
	P.hops = true
	add(P, nil, "Core", "o", V3(1, 1, 1), CF(0, -0.1, 0.1), P.acc, M.Neon, MOVE(V3(0, 0.12, 0), 3, 0), 0.1)
	eyes(P, nil, 0.3, -1.02, 0.5, 0.42)
	add(P, nil, "Mouth", "b", V3(0.5, 0.1, 0.1), CF(0, -0.15, -1.15), DARKC)
	add(P, nil, "Blob1", "o", V3(0.7, 0.7, 0.7), CF(0.55, 1.0, 0.1), P.light, M.SmoothPlastic, MOVE(V3(0, 0.15, 0), 4, 0), 0.15)
	add(P, nil, "Blob2", "o", V3(0.5, 0.5, 0.5), CF(-0.6, 0.95, -0.2), P.light, M.SmoothPlastic, MOVE(V3(0, 0.12, 0), 5, 2), 0.15)
	local leaf = Color3.fromRGB(70, 170, 70)
	add(P, nil, "Leaf1", "b", V3(0.15, 0.8, 0.4), CF(0, 1.05, 0) * CFrame.Angles(0, 0, 0.5), leaf, M.Grass, ROT(0, 0, 1, 0.25, 3, 0, V3(0, 0.4, 0)))
	add(P, nil, "Leaf2", "b", V3(0.15, 0.7, 0.35), CF(0, 1.05, 0) * CFrame.Angles(0, 0.8, -0.5), leaf, M.Grass, ROT(0, 0, 1, 0.25, 3, 1.5, V3(0, 0.35, 0)))
end

A.toad = function(P)
	makeRoot(P, "o", V3(2.2, 1.5, 2.4), P.col, M.SmoothPlastic)
	P.foot = 0.9
	P.hops = true
	add(P, nil, "Belly", "o", V3(1.7, 1.0, 2.0), CF(0, -0.3, -0.1), P.light)
	for _, side in ipairs({ -1, 1 }) do
		add(P, nil, "EyeBulge", "o", V3(0.8, 0.8, 0.8), CF(side * 0.6, 0.85, -0.8), P.col)
		add(P, nil, "BackLeg", "b", V3(0.6, 0.5, 1.3), CF(side * 1.0, -0.55, 0.7), P.dark, nil, ROT(1, 0, 0, 0.25, 5, side))
		add(P, nil, "FrontLeg", "b", V3(0.45, 0.5, 0.6), CF(side * 0.8, -0.65, -0.85), P.dark)
	end
	eyes(P, nil, 0.95, -1.1, 0.6, 0.5)
	add(P, nil, "Mouth", "b", V3(1.5, 0.1, 0.1), CF(0, 0.1, -1.18), DARKC)
	add(P, nil, "Throat", "o", V3(0.9, 0.5, 0.7), CF(0, -0.35, -1.0), P.light, nil, MOVE(V3(0, 0, -0.1), 5, 0))
	local warts = { V3(0.4, 0.7, 0.3), V3(-0.5, 0.65, 0.6), V3(0.1, 0.75, 0.9), V3(-0.3, 0.72, -0.1) }
	for i, wp in ipairs(warts) do
		add(P, nil, "Wart" .. i, "o", V3(0.35, 0.3, 0.35), CF(wp), P.acc, (P.style == "magma") and M.Neon or M.SmoothPlastic)
	end
end

A.fox = function(P)
	makeRoot(P, "o", V3(1.8, 1.5, 2.8), P.col, M.SmoothPlastic)
	P.foot = 1.55
	P.top = 1.9
	add(P, nil, "Chest", "o", V3(1.2, 1.1, 1.1), CF(0, -0.15, -0.9), WHITE:Lerp(P.light, 0.4))
	local head = add(P, nil, "Head", "o", V3(1.5, 1.3, 1.4), CF(0, 0.6, -1.7), P.col)
	add(P, head, "Snout", "b", V3(0.6, 0.5, 0.9), CF(0, -0.15, -0.85), P.light)
	add(P, head, "Nose", "o", V3(0.25, 0.22, 0.25), CF(0, -0.05, -1.3), DARKC)
	eyes(P, head, 0.15, -0.62, 0.42, 0.3)
	add(P, head, "Mark", "o", V3(0.3, 0.3, 0.1), CF(0, 0.45, -0.62), P.acc, M.Neon)
	for _, side in ipairs({ -1, 1 }) do
		local ear = add(P, head, "Ear", "b", V3(0.45, 0.9, 0.25), CF(side * 0.5, 0.65, 0.05) * CFrame.Angles(0, 0, side * -0.2), P.col, nil, ROT(0, 0, 1, 0.18, 6, side, V3(0, 0.45, 0)))
		add(P, ear, "EarIn", "b", V3(0.25, 0.6, 0.1), CF(0, -0.05, -0.1), P.dark)
	end
	local tail = add(P, nil, "Tail", "o", V3(0.8, 0.8, 1.6), CF(0, 0.3, 1.3), P.col, nil, ROT(0, 1, 0, 0.4, 3, 0, V3(0, 0, 0.8)))
	add(P, tail, "TailTip", "o", V3(0.7, 0.7, 0.7), CF(0, 0, 0.9), (P.style == "infernal") and P.acc or WHITE, (P.style == "infernal") and M.Neon or M.SmoothPlastic)
	legs4(P, 0.55, -0.5, 0.8, 0.4, 0.8, P.dark, 0.3, 6)
	if P.style == "infernal" then
		emitter(P.rootPart, P.acc, 8, 0.4, 1, 2)
	end
end

A.dragon = function(P)
	local st = P.style
	local c = P.col
	local mat = M.SmoothPlastic
	if st == "obsidienne" then mat = M.Slate end
	if st == "lave" then
		mat = M.Slate
		c = Color3.fromRGB(70, 40, 35)
	end
	makeRoot(P, "o", V3(2.0, 1.8, 3.0), c, mat)
	P.flying = true
	P.foot = 1.2
	P.top = 2.8
	local belly = c:Lerp(P.acc, 0.3)
	add(P, nil, "Belly", "o", V3(1.6, 1.2, 2.5), CF(0, -0.3, -0.05), belly, mat)
	add(P, nil, "Neck", "o", V3(1.0, 1.5, 1.0), CF(0, 0.9, -1.35), c, mat)
	local head = add(P, nil, "Head", "o", V3(1.3, 1.1, 1.5), CF(0, 1.65, -1.9), c, mat)
	local snout = add(P, head, "Snout", "b", V3(0.8, 0.55, 0.85), CF(0, -0.15, -0.85), c:Lerp(WHITE, 0.12), mat)
	for _, side in ipairs({ -1, 1 }) do
		add(P, snout, "Nostril", "o", V3(0.12, 0.12, 0.12), CF(side * 0.2, 0.1, -0.43), DARKC)
		add(P, head, "Horn", "b", V3(0.2, 0.8, 0.2), CF(side * 0.4, 0.6, 0.4) * CFrame.Angles(-0.6, 0, side * -0.2), P.dark:Lerp(P.acc, 0.2), M.Slate)
	end
	eyes(P, head, 0.2, -0.58, 0.42, 0.3, P.acc)
	wings(P, nil, 0.8, 0.8, 0.1, 2.4, 1.5, c:Lerp(P.acc, 0.25), M.SmoothPlastic, 0.1, 0.5, 6)
	local last = chain(P, nil, CF(0, 0, 1.3), 4, 0.9, 0.72, 1.0, c, mat, V3(0, 1, 0), 0.28, 3, 0.7)
	add(P, last, "TailTip", "b", V3(0.25, 0.7, 0.25), CF(0, 0, 0.55) * CFrame.Angles(0, math.pi / 4, 0), P.acc, M.Neon)
	for i = 0, 3 do
		add(P, nil, "Spike", "b", V3(0.22, 0.5, 0.35), CF(0, 0.95, -0.7 + i * 0.55), (st == "obsidienne") and P.acc or P.dark, (st == "obsidienne") and M.Neon or M.Slate)
	end
	legs4(P, 0.7, -0.6, 0.8, 0.5, 0.7, P.dark, 0.2, 5)

	if st == "lave" then
		for i = 1, 4 do
			add(P, nil, "Crack", "b", V3(0.15, 0.05, 0.7), CF((i % 2 == 0) and 0.35 or -0.35, 0.9, -0.9 + i * 0.45) * CFrame.Angles(0, (i % 2 == 0) and 0.3 or -0.3, 0), P.acc, M.Neon)
		end
		emitter(head, P.acc, 14, 0.5, 1, 3)
	elseif st == "cosmique" then
		for i = 1, 7 do
			add(P, nil, "Star", "o", V3(0.15, 0.15, 0.15), CF(math.sin(i * 2.1) * 0.6, 0.6 + math.cos(i * 1.7) * 0.3, -1 + i * 0.35), WHITE, M.Neon, FLICK(2 + i * 0.3, i))
		end
	elseif st == "obsidienne" then
		for i = 1, 3 do
			add(P, nil, "Shard", "b", V3(0.25, 0.9, 0.25), CF((i - 2) * 0.6, 0.8, 0.5 + i * 0.2) * CFrame.Angles(0, 0, (i - 2) * 0.4), P.acc, M.Neon)
		end
	elseif st == "primordial" then
		wings(P, nil, 0.7, 0.4, 0.9, 1.6, 1.0, P.acc, M.Neon, 0.3, 0.45, 6)
		for i = -2, 2 do
			add(P, head, "Crown", "b", V3(0.15, 0.6, 0.15), CF(i * 0.18, 0.7, 0.1), P.acc, M.Neon)
		end
		emitter(P.rootPart, P.acc, 16, 0.5, 1.2, 2)
	elseif st == "brume" then
		emitter(P.rootPart, Color3.fromRGB(200, 210, 255), 6, 1.2, 2, 1, 0.6)
	end
end

A.golem = function(P)
	P.scale = P.scale * 0.8
	local st = P.style
	makeRoot(P, "b", V3(2.4, 2.4, 1.8), P.col, M.Slate)
	P.foot = 2.3
	P.top = 3
	local head = add(P, nil, "Head", "b", V3(1.3, 1.1, 1.2), CF(0, 1.85, -0.1), P.dark, M.Slate)
	add(P, head, "Brow", "b", V3(1.4, 0.2, 0.3), CF(0, 0.3, -0.55), P.dark:Lerp(DARKC, 0.5), M.Slate)
	for _, side in ipairs({ -1, 1 }) do
		add(P, head, "Eye", "b", V3(0.28, 0.2, 0.12), CF(side * 0.32, 0.05, -0.62), P.acc, M.Neon)
		add(P, nil, "Shoulder", "o", V3(1.1, 1.0, 1.1), CF(side * 1.6, 1.0, 0), P.dark, M.Slate)
		local arm = add(P, nil, "Arm", "b", V3(0.8, 1.8, 0.8), CF(side * 1.7, 0.7, 0), P.col, M.Slate, ROT(1, 0, 0, 0.35, 3, side * 1.2, V3(0, -0.9, 0)))
		add(P, arm, "Fist", "o", V3(1.0, 1.0, 1.0), CF(0, -1.05, 0), P.dark, M.Slate)
		add(P, nil, "Leg", "b", V3(0.9, 1.1, 0.9), CF(side * 0.6, -1.2, 0), P.dark, M.Slate, ROT(1, 0, 0, 0.3, 3, -side * 1.2, V3(0, -0.55, 0)))
	end
	add(P, nil, "Core", "o", V3(0.8, 0.8, 0.3), CF(0, 0.3, -0.9), P.acc, M.Neon, MOVE(V3(0, 0, -0.05), 3, 0))
	if st == "mousse" then
		local green = Color3.fromRGB(70, 170, 70)
		add(P, nil, "Moss", "b", V3(1.4, 0.25, 1.2), CF(0.4, 1.25, 0.2), green, M.Grass)
		add(P, nil, "Moss2", "b", V3(1.0, 0.25, 0.9), CF(-0.5, 1.2, -0.3), green, M.Grass)
		add(P, nil, "Flower", "o", V3(0.3, 0.3, 0.3), CF(0.5, 1.5, 0.2), Color3.fromRGB(255, 200, 60), M.Neon)
	elseif st == "basalte" then
		for i = 1, 3 do
			add(P, nil, "Crack", "b", V3(0.1, 0.9, 0.05), CF((i - 2) * 0.7, -0.4, -0.92) * CFrame.Angles(0, 0, (i - 2) * 0.4), P.acc, M.Neon)
		end
		emitter(P.rootPart, P.acc, 6, 0.4, 1, 2)
	end
end

local function snake(P, o)
	local h = o.head
	local mat = o.mat or M.SmoothPlastic
	local bodyCol = o.bodyColor or P.col
	makeRoot(P, "o", V3(h, h * 0.85, h * 1.15), bodyCol, mat)
	P.foot = h * 0.42
	P.flying = o.float or false
	P.top = h * 2
	eyes(P, nil, h * 0.18, -h * 0.48, h * 0.3, h * 0.24, o.eyeGlow or P.acc)
	add(P, nil, "Tongue", "b", V3(0.1, 0.05, h * 0.7), CF(0, -h * 0.2, -h * 0.8), Color3.fromRGB(230, 40, 60), nil, MOVE(V3(0, 0, -0.15), 9, 0))
	if o.hood then
		add(P, nil, "Hood", "o", V3(h * 1.9, h * 1.0, h * 0.25), CF(0, 0, h * 0.55), P.light, nil, nil, 0.05)
	end
	if o.horns then
		for _, side in ipairs({ -1, 1 }) do
			add(P, nil, "Horn", "b", V3(h * 0.12, h * 0.5, h * 0.12), CF(side * h * 0.3, h * 0.4, h * 0.2) * CFrame.Angles(-0.7, 0, side * -0.2), P.acc, M.Neon)
		end
	end
	local function deco(seg, i, w)
		if o.stars then
			add(P, seg, "Star", "o", V3(w * 0.25, w * 0.25, w * 0.25), CF(0, w * 0.5, 0), P.acc, M.Neon, FLICK(2 + i * 0.4, i))
		end
		if o.spikes then
			add(P, seg, "Spike", "b", V3(w * 0.15, w * 0.45, w * 0.2), CF(0, w * 0.5, 0), P.acc, M.Neon)
		end
		if o.stripe then
			add(P, seg, "Stripe", "b", V3(w * 0.65, 0.1, o.len * 0.4), CF(0, w * 0.5, 0), P.acc, M.Neon)
		end
	end
	local last = chain(P, nil, CF(0, -0.05, h * 0.5), o.n, h * 0.95, 0.88, o.len, bodyCol, mat, V3(0, 1, 0), 0.32, 5, 0.8, "o", deco)
	add(P, last, "TailTip", "b", V3(0.2, 0.2, 0.7), CF(0, 0, o.len * 0.5), P.acc, M.Neon)
	if o.flame then
		emitter(P.rootPart, P.acc, 14, 0.6, 1, 3)
	end
end

A.serpent = function(P)
	snake(P, { head = 1.2, n = 7, len = 0.9, hood = true, stars = (P.style == "etoiles") })
end

A.wyrm = function(P)
	snake(P, {
		head = 1.8, n = 9, len = 1.2, horns = true, spikes = true, stripe = true, flame = true,
		mat = M.Slate, bodyColor = P.col:Lerp(BLACK, 0.55), float = true
	})
end

A.phoenix = function(P)
	makeRoot(P, "o", V3(1.5, 1.6, 2.2), P.col, M.SmoothPlastic)
	P.flying = true
	P.foot = 1.0
	P.top = 2.4
	local head = add(P, nil, "Head", "o", V3(1.0, 1.0, 1.0), CF(0, 0.95, -1.1), P.col)
	add(P, head, "Beak", "b", V3(0.3, 0.25, 0.55), CF(0, -0.1, -0.65), Color3.fromRGB(255, 170, 40))
	eyes(P, head, 0.12, -0.42, 0.3, 0.24)
	for i = -1, 1 do
		add(P, head, "Crest", "b", V3(0.18, 0.7, 0.18), CF(i * 0.22, 0.65, 0.15) * CFrame.Angles(-0.4, 0, i * -0.35), P.acc, M.Neon, ROT(1, 0, 0, 0.25, 6, i * 0.8, V3(0, 0.3, 0)))
	end
	add(P, nil, "Breast", "o", V3(1.1, 1.2, 1.4), CF(0, -0.15, -0.5), P.acc:Lerp(P.col, 0.4), M.Neon, nil, 0.15)
	for _, side in ipairs({ -1, 1 }) do
		local w1 = add(P, nil, "Wing", "b", V3(1.5, 0.1, 1.0), CF(side * 0.7, 0.4, 0.1), P.col, M.SmoothPlastic, ROT(0, 0, side, 0.65, 7, 0, V3(side * 0.75, 0, 0)))
		for k = 1, 3 do
			add(P, w1, "Feather", "b", V3(1.3, 0.08, 0.45), CF(side * 0.75, 0, (k - 2) * 0.35) * CFrame.Angles(0, side * (k - 2) * 0.3, 0),
				(k == 2) and P.acc or P.col:Lerp(P.acc, 0.4), M.Neon, ROT(0, 0, side, 0.25, 7, -0.8, V3(side * 0.65, 0, 0)))
		end
	end
	for i = -1, 1 do
		add(P, nil, "TailF", "b", V3(0.3, 0.08, 2.0), CF(0, 0.1, 1.0) * CFrame.Angles(0, i * 0.3, 0), P.acc:Lerp(P.col, 0.3), M.Neon, ROT(0, 1, 0, 0.15, 3, i, V3(0, 0, 1.0)))
	end
	for _, side in ipairs({ -1, 1 }) do
		add(P, nil, "Foot", "b", V3(0.2, 0.5, 0.2), CF(side * 0.3, -0.95, 0.1), Color3.fromRGB(255, 170, 40))
	end
	emitter(P.rootPart, P.acc, 12, 0.5, 1, 2)
end

A.chimera = function(P)
	makeRoot(P, "o", V3(2.0, 1.8, 3.0), P.col, M.SmoothPlastic)
	P.foot = 1.7
	P.top = 2.6
	add(P, nil, "Mane", "o", V3(2.3, 2.2, 1.5), CF(0, 0.7, -1.5), P.acc:Lerp(P.dark, 0.3), M.Fabric)
	local head = add(P, nil, "Head", "o", V3(1.5, 1.4, 1.4), CF(0, 0.7, -1.95), P.col)
	add(P, head, "Snout", "b", V3(0.75, 0.5, 0.6), CF(0, -0.25, -0.75), P.light)
	add(P, head, "Nose", "o", V3(0.3, 0.22, 0.2), CF(0, -0.05, -1.07), DARKC)
	eyes(P, head, 0.15, -0.62, 0.45, 0.3, P.acc)
	for _, side in ipairs({ -1, 1 }) do
		add(P, head, "Fang", "b", V3(0.1, 0.3, 0.1), CF(side * 0.25, -0.55, -0.85), WHITE)
	end
	local goat = add(P, nil, "GoatNeck", "o", V3(0.7, 1.0, 0.7), CF(0, 1.2, 0.3), P.dark)
	local gh = add(P, goat, "GoatHead", "o", V3(0.9, 0.9, 1.0), CF(0, 0.6, -0.1), P.light)
	eyes(P, gh, 0.1, -0.45, 0.25, 0.2)
	for _, side in ipairs({ -1, 1 }) do
		add(P, gh, "GoatHorn", "b", V3(0.15, 0.7, 0.15), CF(side * 0.3, 0.5, 0.1) * CFrame.Angles(-0.3, 0, side * -0.5), WHITE, nil, ROT(0, 0, 1, 0.1, 5, side, V3(0, 0.35, 0)))
	end
	local last = chain(P, nil, CF(0, 0.1, 1.4), 5, 0.7, 0.88, 0.9, P.dark:Lerp(P.acc, 0.3), nil, V3(0, 1, 0), 0.3, 4, 0.6)
	local sh = add(P, last, "SnakeHead", "o", V3(0.6, 0.5, 0.8), CF(0, 0, 0.7), P.col)
	eyes(P, sh, 0.12, 0.3, 0.2, 0.15, P.acc)
	wings(P, nil, 0.8, 0.9, 0.2, 1.8, 1.2, P.dark, M.SmoothPlastic, 0.05, 0.35, 4)
	legs4(P, 0.7, -0.8, 0.9, 0.5, 0.9, P.dark, 0.3, 5)
	if P.style == "chaos" then
		emitter(P.rootPart, P.acc, 10, 0.5, 1.2, 2)
	end
end

A.sphinx = function(P)
	makeRoot(P, "o", V3(1.8, 1.4, 3.0), P.col, M.SmoothPlastic)
	P.flying = true
	P.foot = 0.9
	P.top = 2.4
	for _, side in ipairs({ -1, 1 }) do
		add(P, nil, "Paw", "b", V3(0.5, 0.45, 1.8), CF(side * 0.6, -0.5, -1.6), P.col)
		add(P, nil, "PawTip", "o", V3(0.55, 0.4, 0.5), CF(side * 0.6, -0.5, -2.5), P.light)
	end
	local head = add(P, nil, "Head", "o", V3(1.15, 1.2, 1.15), CF(0, 1.1, -1.3), P.light)
	eyes(P, head, 0.12, -0.5, 0.28, 0.22)
	add(P, head, "Nose", "b", V3(0.15, 0.2, 0.1), CF(0, -0.1, -0.58), P.dark)
	for _, side in ipairs({ -1, 1 }) do
		add(P, head, "Nemes", "b", V3(0.3, 1.5, 0.9), CF(side * 0.72, -0.2, 0.15), P.acc, M.Metal)
	end
	add(P, head, "NemesTop", "b", V3(1.5, 0.3, 1.5), CF(0, 0.62, 0.05), P.acc, M.Metal)
	add(P, head, "Uraeus", "o", V3(0.2, 0.35, 0.2), CF(0, 0.68, -0.62), P.acc, M.Neon)
	add(P, head, "Beard", "b", V3(0.18, 0.55, 0.18), CF(0, -0.75, -0.4), P.acc, M.Metal)
	wings(P, nil, 0.8, 0.8, 0.1, 2.0, 1.4, P.col:Lerp(P.acc, 0.4), M.SmoothPlastic, 0.15, 0.2, 2.5)
	local last = chain(P, nil, CF(0, 0, 1.4), 4, 0.35, 0.95, 0.8, P.col, nil, V3(0, 1, 0), 0.3, 3, 0.7)
	add(P, last, "Tuft", "o", V3(0.5, 0.5, 0.7), CF(0, 0, 0.6), P.acc, M.Neon)
	for i = 1, 3 do
		add(P, nil, "Glyph", "b", V3(0.45, 0.08, 0.18), CF(0, 0.72, -0.4 + i * 0.55), P.acc, M.Neon, FLICK(2, i))
	end
	if P.style == "cosmique" then
		orbit(P, nil, 0.4, 2.2, 4, 0.25, P.acc, 1.2)
	end
end

A.wolf = function(P)
	makeRoot(P, "o", V3(1.7, 1.5, 2.8), P.col, M.SmoothPlastic)
	P.foot = 1.7
	P.top = 2.2
	add(P, nil, "Chest", "o", V3(1.5, 1.4, 1.2), CF(0, -0.05, -0.9), P.light)
	local head = add(P, nil, "Head", "o", V3(1.3, 1.1, 1.3), CF(0, 0.55, -1.75), P.col)
	add(P, head, "Snout", "b", V3(0.55, 0.5, 0.9), CF(0, -0.15, -0.8), P.light:Lerp(P.col, 0.3))
	add(P, head, "Nose", "o", V3(0.24, 0.2, 0.24), CF(0, -0.02, -1.27), DARKC)
	eyes(P, head, 0.15, -0.55, 0.4, 0.28, P.acc)
	for _, side in ipairs({ -1, 1 }) do
		add(P, head, "Ear", "b", V3(0.4, 0.8, 0.22), CF(side * 0.42, 0.65, 0.1) * CFrame.Angles(0, 0, side * -0.15), P.col, nil, ROT(0, 0, 1, 0.15, 5, side * 2, V3(0, 0.4, 0)))
		add(P, head, "Fang", "b", V3(0.08, 0.2, 0.08), CF(side * 0.17, -0.4, -1.0), WHITE)
	end
	for i = 0, 3 do
		add(P, nil, "Fur", "b", V3(0.2, 0.4, 0.3), CF(0, 0.8, -0.9 + i * 0.6), P.dark)
	end
	legs4(P, 0.55, -0.5, 0.9, 0.4, 1.0, P.dark, 0.45, 8)
	local last = chain(P, nil, CF(0, 0.35, 1.3), 3, 0.55, 0.8, 0.8, P.col, nil, V3(0, 1, 0), 0.25, 3, 0.6)
	add(P, last, "Tuft", "o", V3(0.5, 0.5, 0.6), CF(0, 0, 0.5), P.light)
	if P.style == "celeste" or P.style == "lunaire" then
		for i = 1, 5 do
			add(P, nil, "Star", "o", V3(0.16, 0.16, 0.16), CF(math.sin(i * 2.3) * 0.6, 0.7, -0.9 + i * 0.4), P.acc, M.Neon, FLICK(2 + i * 0.3, i))
		end
	end
end

A.griffon = function(P)
	makeRoot(P, "o", V3(1.8, 1.7, 3.0), P.col, M.SmoothPlastic)
	P.flying = true
	P.foot = 1.2
	P.top = 2.8
	add(P, nil, "Ruff", "o", V3(1.7, 1.5, 1.3), CF(0, 0.55, -1.0), P.light)
	local head = add(P, nil, "Head", "o", V3(1.1, 1.1, 1.2), CF(0, 1.45, -1.6), WHITE:Lerp(P.light, 0.5))
	add(P, head, "Beak", "b", V3(0.4, 0.45, 0.8), CF(0, -0.2, -0.75) * CFrame.Angles(0.25, 0, 0), P.acc, M.Metal)
	add(P, head, "BeakTip", "b", V3(0.28, 0.3, 0.4), CF(0, -0.42, -1.1), P.acc:Lerp(DARKC, 0.3), M.Metal)
	eyes(P, head, 0.2, -0.5, 0.38, 0.26, Color3.fromRGB(255, 200, 40))
	for i = -1, 1 do
		add(P, head, "Crest", "b", V3(0.15, 0.55, 0.12), CF(i * 0.22, 0.62, 0.15) * CFrame.Angles(-0.5, 0, i * -0.3), P.col, nil, ROT(1, 0, 0, 0.2, 5, i, V3(0, 0.28, 0)))
	end
	wings(P, nil, 0.9, 0.9, 0, 3.0, 1.8, P.light, M.SmoothPlastic, 0, 0.5, 5)
	for _, side in ipairs({ -1, 1 }) do
		add(P, nil, "Talon", "b", V3(0.4, 0.9, 0.4), CF(side * 0.5, -0.55, -0.9), P.acc, M.Metal, ROT(1, 0, 0, 0.2, 5, side, V3(0, -0.4, 0)))
		add(P, nil, "HindLeg", "b", V3(0.5, 0.9, 0.5), CF(side * 0.6, -0.55, 0.9), P.dark, nil, ROT(1, 0, 0, 0.2, 5, -side, V3(0, -0.4, 0)))
	end
	local last = chain(P, nil, CF(0, 0, 1.4), 3, 0.5, 0.9, 0.9, P.col, nil, V3(0, 1, 0), 0.25, 3, 0.6)
	add(P, last, "Tuft", "o", V3(0.6, 0.6, 0.8), CF(0, 0, 0.6), P.acc, M.Neon)
end

A.hydra = function(P)
	makeRoot(P, "o", V3(2.4, 1.8, 3.0), P.col, M.SmoothPlastic)
	P.foot = 1.4
	P.top = 4
	add(P, nil, "Belly", "o", V3(1.9, 1.2, 2.4), CF(0, -0.3, -0.1), P.light)
	legs4(P, 0.9, -0.6, 0.9, 0.6, 0.9, P.dark, 0.25, 4)
	for idx, k in ipairs({ -1, 0, 1 }) do
		local hinge = CF(k * 0.75, 0.7, -0.9) * CFrame.Angles(0, -k * 0.3, 0) * CFrame.Angles(-math.pi / 2 - 0.2, 0, 0)
		local last = chain(P, nil, hinge, 3, 0.75, 0.92, 0.95, P.col, nil, V3(0.7, 0.7, 0), 0.22, 3 + idx * 0.6, 0.7)
		local head = add(P, last, "Head", "o", V3(1.0, 1.0, 1.1), CF(0, 0.15, 0.6), P.col)
		add(P, head, "Snout", "b", V3(0.6, 0.8, 0.5), CF(0, 0.65, -0.1), P.light)
		eyes(P, head, 0.4, 0.2, 0.3, 0.22, P.acc)
		for _, side in ipairs({ -1, 1 }) do
			add(P, head, "Horn", "b", V3(0.12, 0.12, 0.5), CF(side * 0.35, -0.2, 0.5), P.dark)
		end
	end
	local last = chain(P, nil, CF(0, 0.1, 1.4), 4, 0.9, 0.78, 1.0, P.dark, nil, V3(0, 1, 0), 0.25, 3, 0.7)
	add(P, last, "TailTip", "b", V3(0.2, 0.2, 0.7), CF(0, 0, 0.5), P.acc, M.Neon)
	for i = 0, 3 do
		add(P, nil, "Spike", "b", V3(0.2, 0.4, 0.3), CF(0, 0.95, -0.7 + i * 0.55), P.acc, M.Neon)
	end
end

A.titan = function(P)
	P.scale = P.scale * 0.6
	local st = P.style
	local mat = (st == "cristal") and M.Ice or M.Slate
	makeRoot(P, "b", V3(3.0, 3.2, 2.0), P.col, mat, (st == "cristal") and 0.15 or 0)
	P.foot = 3.0
	P.top = 4.4
	P.flying = false
	local head = add(P, nil, "Head", "b", V3(1.5, 1.4, 1.3), CF(0, 2.5, -0.1), P.dark, mat)
	eyes(P, head, 0.1, -0.67, 0.4, 0.3, P.acc)
	for i = -2, 2 do
		add(P, head, "Crown", "b", V3(0.18, 0.7 + 0.2 * (2 - math.abs(i)), 0.18), CF(i * 0.3, 0.95, 0), P.acc, M.Neon)
	end
	add(P, nil, "Plate", "b", V3(1.6, 1.3, 0.25), CF(0, 0.5, -1.05), P.acc, M.Neon, (st == "orage") and FLICK(1.5, 0) or MOVE(V3(0, 0, -0.05), 2, 0))
	for _, side in ipairs({ -1, 1 }) do
		add(P, nil, "Shoulder", "o", V3(1.3, 1.2, 1.3), CF(side * 2.0, 1.3, 0), P.dark, mat)
		local arm = add(P, nil, "Arm", "b", V3(1.0, 2.4, 1.0), CF(side * 2.1, 1.2, 0), P.col, mat, ROT(1, 0, 0, 0.3, 2.5, side * 1.5, V3(0, -1.2, 0)))
		add(P, arm, "Fist", "o", V3(1.3, 1.3, 1.3), CF(0, -1.4, 0), P.dark, mat)
		add(P, nil, "Leg", "b", V3(1.2, 1.7, 1.2), CF(side * 0.8, -1.6, 0), P.col, mat, ROT(1, 0, 0, 0.2, 2.5, -side * 1.5, V3(0, -0.85, 0)))
		if st == "cristal" then
			add(P, nil, "Shard", "b", V3(0.4, 1.4, 0.4), CF(side * 2.0, 2.1, 0) * CFrame.Angles(0, 0, side * -0.4), P.acc, M.Neon)
		end
	end
	if st == "orage" then
		for i = 1, 3 do
			add(P, head, "Cloud", "o", V3(1.2, 0.7, 1.2), CF((i - 2) * 0.9, 1.9 + 0.2 * (i % 2), 0), Color3.fromRGB(70, 70, 85), M.Fabric, MOVE(V3(0, 0.2, 0), 2 + i * 0.3, i))
		end
		for _, side in ipairs({ -1, 1 }) do
			add(P, nil, "Bolt", "b", V3(0.18, 1.2, 0.18), CF(side * 1.2, 2.2, -0.4) * CFrame.Angles(0, 0, side * 0.5), P.acc, M.Neon, FLICK(7, side))
		end
	end
end

-- Animaux en briques lego (Plastic + studs) : voir ReplicatedStorage.MWS_PetBricks
local Bricks = require(ReplicatedStorage:WaitForChild("MWS_PetBricks"))
-- tailles (Grand, Geant, Titan) et mutations (Dore, Cristal, Ombre, Arc-en-ciel)
local Traits = require(ReplicatedStorage:WaitForChild("MWS_PetTraits"))
local EggModels = require(ReplicatedStorage:WaitForChild("MWS_EggModels"))

local function createPetModel(petName, anchoredRoot, extraScale, mutation)
	local info = PETS[petName] or PETS["Poulet"]
	local rar = rarityInfo(info.rarity)
	local scale = PET_SCALE * rar.scale * (extraScale or 1)
	local col = colorFromTable(info.color)
	local model = Instance.new("Model")
	model.Name = petName
	local P = {
		model = model, anims = {}, anchoredRoot = anchoredRoot and true or false,
		col = col, light = col:Lerp(WHITE, 0.45), dark = col:Lerp(BLACK, 0.45),
		style = info.style, flying = false, hops = false, foot = 1.2, top = 2.4, scale = scale
	}
	P.acc = STYLE_ACCENT[info.style] or P.light

	local imported = false
	if Bricks.has(petName) then
		local bi = Bricks.measure(petName)
		local H = 8.5 * scale * (bi.hmul or 1)
		local k = H / bi.Hd
		local root = Instance.new("Part")
		root.Name = "Body"
		root.Size = V3(1, 1, 1)
		root.Transparency = 1
		root.Anchored = P.anchoredRoot
		root.CanCollide = false
		root.CanTouch = false
		root.CanQuery = false
		root.Parent = model
		model.PrimaryPart = root
		P.rootPart = root
		local anims, _, rig = Bricks.assemble(petName, { model = model, root = root, k = k, bright = rar.glow })
		P.rig = rig
		for _, a in ipairs(anims or {}) do table.insert(P.anims, a) end
		P.flying = bi.flyer and true or false
		P.hops = bi.hops and true or false
		P.foot = (H / 2) / scale
		P.top = H / scale
		P.labelY = H / 2 + 1.5
		P.flyY = math.max(1.2, H / 2 - 1.2)
		P.spread = math.min(math.max(bi.L, bi.W * 0.7) * k, 9)
		P.ext = V3(bi.W, bi.Hd, bi.L) * k
		if mutation then
			Traits.paint(model, mutation)
			Traits.decorate(root, mutation, math.max(P.ext.X, P.ext.Y, P.ext.Z) * 0.6)
		end
		imported = true
	end
	if not imported then
		(A[info.archetype] or A.slime)(P)
	end

	local root = P.rootPart
	-- aura de rarete
	if rar.rate > 0 then
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(rar.color)
		pe.LightEmission = 1
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35 * scale / 0.7), NumberSequenceKeypoint.new(1, 0) })
		pe.Lifetime = NumberRange.new(0.8, 1.4)
		pe.Rate = rar.rate
		pe.Speed = NumberRange.new(0.5, 1.5)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		pe.Parent = root
	end
	if rar.light then
		local pl = Instance.new("PointLight")
		pl.Color = rar.color
		pl.Brightness = 1 + (rar.glow or 0) * 3
		pl.Range = 10 + (rar.glow or 0) * 8
		pl.Parent = root
	end
	if rar.halo and not imported then
		orbit(P, nil, P.top + 0.4, 1.3, 6, 0.25, rar.color, 1.5)
	end
	return model, root, P
end

-- ------------------------------------------------------------
-- DRESSEURS
-- ------------------------------------------------------------

-- Boss : modeles ranges dans ServerStorage.MWS_Boss. Taille reelle sur la carte (scale = 1),
-- reduite dans l'arene. Plus le boss est fort (npc.rank), plus il a d'effets. Meme retour
-- que l'ancien createTrainerModel. Chaque piece du modele bouge selon son nom.
local function createBossModel(npc, scale)
	local folder = ServerStorage:FindFirstChild("MWS_Boss")
	local template = folder and folder:FindFirstChild(npc.boss)
	if not template then
		warn("[MWS] Boss introuvable : " .. tostring(npc.boss))
		return nil
	end
	local model = template:Clone()
	local inArena = scale ~= 1
	local rank = npc.rank or 1
	local height = npc.height or 30
	if inArena then height = math.max(8, height * 0.4) end
	local _, startSize = model:GetBoundingBox()
	model:ScaleTo(model:GetScale() * height / startSize.Y)
	local boxCF, size = model:GetBoundingBox()

	local function groupOf(name)
		local n = string.lower(name)
		if n:find("left arm") then return "left" end
		if n:find("right arm") then return "right" end
		for _, key in ipairs({ "head", "skull", "helmet", "horn", "antler" }) do
			if n:find(key) then return "head" end
		end
		for _, key in ipairs({ "sword", "scythe", "club", "axe", "staff", "lantern" }) do
			if n:find(key) then return "weapon" end
		end
		if n:find("wing") then return "wings" end
		if n:find("cape") then return "cape" end
		if n:find("halo") then return "halo" end
		return "body"
	end
	local meshes, neck, shoulder = {}, nil, {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local group = groupOf(d.Name)
			table.insert(meshes, { part = d, group = group })
			if group == "head" then
				local bottom = d.Position - V3(0, d.Size.Y / 2, 0)
				if not neck or bottom.Y < neck.Y then neck = bottom end
			elseif group == "left" or group == "right" then
				shoulder[group] = d.Position + V3(0, d.Size.Y * 0.4, 0)
			end
		end
	end

	local function helper(name, partSize, cf)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = partSize
		part.CFrame = cf
		part.Transparency = 1
		part.Anchored = false
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		part.Parent = model
		return part
	end
	local center = boxCF.Position
	local feetY = center.Y - size.Y / 2
	local root = helper("HumanoidRootPart", V3(1, 1, 1), CFrame.new(center.X, feetY + 2.1 * scale, center.Z))
	root.Anchored = true
	root.CanQuery = true
	local head = helper("Head", V3(1, 1, 1), CFrame.new(center.X, feetY + size.Y, center.Z))
	-- volume du corps : bloque le joueur sur la carte et sert de zone d'emission a l'aura
	local bodyBox = helper("BossBody", V3(size.Y * 0.32, size.Y, size.Y * 0.27), CFrame.new(center))

	local function attach(part, pivot)
		part.Anchored = false
		part.CanCollide = part == bodyBox and not inArena
		part.CanTouch = false
		part.CanQuery = false
		part.Massless = true
		local at = CFrame.new(pivot or part.Position)
		local weld = Instance.new("Weld")
		weld.Part0 = root
		weld.Part1 = part
		weld.C0 = root.CFrame:Inverse() * at
		weld.C1 = part.CFrame:Inverse() * at
		weld.Parent = root
		return weld
	end
	attach(head)
	attach(bodyBox)

	-- respiration pour tous, flottement pour les fantomes, petits gestes selon la piece
	local anims = {}
	local phase = math.random() * 6
	local speed = npc.float and 1.2 or 1.6
	local bob = V3(0, size.Y * (npc.float and 0.035 or 0.008), 0)
	for _, entry in ipairs(meshes) do
		local part, group = entry.part, entry.group
		local pivot, ax, ay, az, amp = nil, 0, 0, 0, 0
		if group == "head" then
			pivot, ax, ay, amp = neck, 0.5, 1, 0.07
		elseif group == "left" then
			pivot, az, amp = shoulder.left, 1, 0.06
		elseif group == "right" or (group == "weapon" and shoulder.right) then
			pivot, az, amp = shoulder.right, -1, 0.06
		elseif group == "weapon" then
			ax, amp = 1, 0.02
		elseif group == "wings" then
			pivot, ax, amp = V3(center.X, part.Position.Y, center.Z), 1, 0.06
		elseif group == "cape" then
			pivot, ax, amp = part.Position + V3(0, part.Size.Y / 2, 0), 1, 0.03
		end
		local weld = attach(part, pivot)
		if group == "halo" then
			table.insert(anims, { weld = weld, base = weld.C0, part = part, ax = 0, ay = 0, az = 1, amp = 1, speed = 0.4, phase = phase, spin = true })
		else
			table.insert(anims, { weld = weld, base = weld.C0, part = part, ax = ax, ay = ay, az = az, amp = amp, speed = speed, phase = phase, move = bob })
		end
	end
	model.PrimaryPart = root

	local col = colorFromTable(npc.color)
	local aura = Instance.new("ParticleEmitter")
	aura.Color = ColorSequence.new(col)
	aura.LightEmission = 0.6
	aura.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size.Y * 0.02), NumberSequenceKeypoint.new(1, 0) })
	aura.Lifetime = NumberRange.new(1.5, 2.5)
	aura.Rate = 4 + rank * 3
	aura.Speed = NumberRange.new(1, 3)
	aura.SpreadAngle = Vector2.new(180, 180)
	aura.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	aura.Parent = bodyBox
	local light = Instance.new("PointLight")
	light.Color = col
	light.Brightness = 0.6 + rank * 0.2
	light.Range = math.min(size.Y, 40)
	light.Parent = bodyBox
	if rank >= 5 then
		-- etincelles qui montent
		local sparks = Instance.new("ParticleEmitter")
		sparks.Color = ColorSequence.new(col:Lerp(WHITE, 0.5))
		sparks.LightEmission = 1
		sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size.Y * 0.012), NumberSequenceKeypoint.new(1, 0) })
		sparks.Lifetime = NumberRange.new(2, 3)
		sparks.Rate = rank * 2
		sparks.Speed = NumberRange.new(size.Y * 0.1, size.Y * 0.2)
		sparks.EmissionDirection = Enum.NormalId.Top
		sparks.Parent = bodyBox
	end
	-- orbes en orbite autour des boss les plus forts
	local orbCount = rank >= 8 and 10 or (rank >= 6 and 6 or 0)
	for k = 1, orbCount do
		local orb = helper("BossOrb", V3(1, 1, 1) * size.Y * 0.035, root.CFrame)
		orb.Shape = Enum.PartType.Ball
		orb.Material = M.Neon
		orb.Color = col
		orb.Transparency = 0
		orb.Anchored = false
		local weld = Instance.new("Weld")
		weld.Part0 = root
		weld.Part1 = orb
		weld.C0 = CFrame.new(0, size.Y * 0.45, 0)
		weld.C1 = CFrame.new(-size.Y * 0.42, 0, 0)
		weld.Parent = root
		table.insert(anims, { weld = weld, base = weld.C0, part = orb, ax = 0, ay = 1, az = 0, amp = 1, speed = 0.7, phase = k / orbCount * math.pi * 2, spin = true })
	end

	return model, root, head, { anims = anims, scale = scale }
end

local function createTrainerModel(npc, scale)
	if npc.boss then
		local bossModel, bossRoot, bossHead, bossP = createBossModel(npc, scale or 1)
		if bossModel then return bossModel, bossRoot, bossHead, bossP end
	end
	local model = Instance.new("Model")
	model.Name = "Monster"
	local col = colorFromTable(npc.color)
	local P = {
		model = model, anims = {}, anchoredRoot = true, scale = scale or 1,
		col = col, light = col:Lerp(WHITE, 0.3), dark = col:Lerp(BLACK, 0.6), acc = col:Lerp(WHITE, 0.5)
	}
	local skinCol = col:Lerp(BLACK, 0.3)
	local root = makeRoot(P, "b", V3(2.0, 2.4, 1.2), skinCol, M.Slate)
	root.Name = "HumanoidRootPart"
	root.CanCollide = true
	root.CanQuery = true
	local head = add(P, nil, "Head", "b", V3(1.4, 1.2, 1.5), CF(0, 1.8, -0.1), skinCol, M.Slate)
	-- yeux rouge glow
	eyes(P, head, 0.15, -0.65, 0.35, 0.28, Color3.fromRGB(255, 30, 30))
	-- crocs
	for _, side in ipairs({ -1, 1 }) do
		add(P, head, "Fang", "b", V3(0.12, 0.45, 0.12), CF(side * 0.3, -0.55, -0.6), WHITE)
	end
	-- cornes
	for _, side in ipairs({ -1, 1 }) do
		add(P, head, "Horn", "b", V3(0.22, 1.0, 0.22), CF(side * 0.5, 0.7, 0.2) * CFrame.Angles(-0.5, 0, side * -0.25), P.dark, M.Slate)
		add(P, head, "HornTip", "o", V3(0.18, 0.25, 0.18), CF(side * 0.5, 1.15, 0.35) * CFrame.Angles(-0.5, 0, side * -0.25), P.acc, M.Neon)
	end
	-- machoire / bouche
	add(P, head, "Jaw", "b", V3(1.2, 0.35, 0.6), CF(0, -0.5, -0.4), BLACK, M.Slate)
	-- epines dorsales
	for i = 0, 4 do
		add(P, nil, "Spike", "b", V3(0.2, 0.8, 0.2), CF(0, 0.8 + (4-i) * 0.3, 0.55 + i * 0.15) * CFrame.Angles(0.4, 0, 0), P.acc, M.Neon)
	end
	add(P, nil, "ChestGlow", "o", V3(0.7, 0.7, 0.3), CF(0, 0.2, -0.55), P.acc, M.Neon, MOVE(V3(0, 0, -0.05), 3, 0))
	for _, side in ipairs({ -1, 1 }) do
		add(P, nil, "Shoulder", "o", V3(0.9, 0.8, 0.9), CF(side * 1.25, 1.0, 0), P.dark, M.Slate)
		local arm = add(P, nil, "Arm", "b", V3(0.55, 1.8, 0.55), CF(side * 1.35, 0.7, 0), P.col, M.Slate, ROT(1, 0, 0, 0.12, 2, side, V3(0, -0.9, 0)))
		-- griffes
		add(P, arm, "Claw1", "b", V3(0.1, 0.5, 0.1), CF(side * 0.15, -1.0, -0.15) * CFrame.Angles(0.4, 0, 0), WHITE, M.Slate)
		add(P, arm, "Claw2", "b", V3(0.1, 0.5, 0.1), CF(0, -1.0, -0.15) * CFrame.Angles(0.4, 0, 0), WHITE, M.Slate)
		add(P, arm, "Claw3", "b", V3(0.1, 0.5, 0.1), CF(-side * 0.15, -1.0, -0.15) * CFrame.Angles(0.4, 0, 0), WHITE, M.Slate)
		add(P, nil, "Leg", "b", V3(0.7, 1.5, 0.7), CF(side * 0.5, -1.1, 0), P.dark, M.Slate, ROT(1, 0, 0, 0.08, 1.5, side, V3(0, -0.75, 0)))
	end
	-- aura menacante
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 30, 30))
	pe.LightEmission = 0.5
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(0.8, 1.2)
	pe.Rate = 4
	pe.Speed = NumberRange.new(0.5, 1.5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	pe.Parent = root
	return model, root, head, P
end

-- ============================================================
-- ETAT JOUEUR
-- ============================================================

local function newState()
	return { coins = START_COINS, pets = {}, equipped = {}, defeatedNPCs = {}, rebirthLevel = 0, unlockedWorld = 1, nextPetId = 1, speedBoostUntil = 0, luckUntil = 0, luckMult = 1, receipts = {}, bought = {} }
end

local function getEquippedPets(s)
	local list = {}
	for _, id in ipairs(s.equipped) do
		for _, pet in ipairs(s.pets) do
			if pet.id == id then
				table.insert(list, pet)
				break
			end
		end
	end
	return list
end

local function getIncome(player)
	local s = states[player.UserId]
	if not s then return 0 end
	local total = 0
	for _, pet in ipairs(getEquippedPets(s)) do
		local info = PETS[pet.name]
		if info then total = total + (pet.income or info.income) * petLvlMult(pet) end
	end
	local multiplier = (1 + (s.rebirthLevel or 0) * 0.5) * (s.coinMult or 1)
	return math.floor(total * multiplier)
end

sendState = function(player)
	local s = states[player.UserId]
	if s then
		StateUpdate:FireClient(player, s, getIncome(player))
	end
end

local function sendEggInfo(player)
	local eggData = {}
	for i, egg in ipairs(EGGS) do
		eggData[i] = { name = egg.name, price = egg.price, color = egg.color, world = egg.world, pool = {} }
		for _, entry in ipairs(egg.pool) do
			local info = PETS[entry.pet]
			table.insert(eggData[i].pool, {
				name = entry.pet, chance = entry.chance, rarity = info.rarity,
				color = info.color, income = info.income
			})
		end
	end
	EggInfo:FireClient(player, eggData)
end

-- Renaissance : il faut avoir battu tous les dresseurs des mondes deja debloques
-- (en MODE TEST : un seul dresseur suffit). Renvoie (necessaire, accompli).
local function rebirthRequirement(s)
	local defeated = {}
	for _, idx in ipairs(s.defeatedNPCs or {}) do defeated[idx] = true end
	local needed, done = 0, 0
	for i, npc in ipairs(NPC_TRAINERS) do
		if npc.world <= (s.unlockedWorld or 1) then
			needed = needed + 1
			if defeated[i] then done = done + 1 end
		end
	end
	if TEST_MODE then
		needed = math.min(needed, 1)
		done = math.min(done, needed)
	end
	return needed, done
end

local function sendNPCInfo(player)
	local s = states[player.UserId]
	local npcData = {}
	for i, npc in ipairs(NPC_TRAINERS) do
		local defeated = false
		if s and s.defeatedNPCs then
			for _, idx in ipairs(s.defeatedNPCs) do
				if idx == i then defeated = true break end
			end
		end
		npcData[i] = { name = npc.name, color = npc.color, reward = npc.reward, petCount = #npc.pets, defeated = defeated, world = npc.world, lines = npc.lines }
	end
	local needed, done = 0, 0
	if s then needed, done = rebirthRequirement(s) end
	NPCInfo:FireClient(player, npcData, #NPC_TRAINERS, { needed = needed, done = done, cost = REBIRTH_COST })
end

local function finiteNumber(value, fallback, minimum, maximum)
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	if minimum then value = math.max(minimum, value) end
	if maximum then value = math.min(maximum, value) end
	return value
end

-- Sauvegardes : chaque session possede le profil du joueur (verrou + numero de version verifies
-- dans UpdateAsync). Une session perimee ne peut plus ecrire, et les ecritures d'un joueur passent
-- une par une, avec un instantane pris au moment d'ecrire : une ancienne sauvegarde n'en ecrase pas une recente.
local Saves = {
	meta = setmetatable({}, { __mode = "k" }), -- etat du joueur -> { session, version, saved (recus durables), released, lost }
	busy = {},                                 -- UserId -> ecriture en cours
	LOCK_TTL = 180,                            -- verrou perime apres 3 min sans sauvegarde (serveur plante)
}

-- Prend le verrou du profil et renvoie (donnees, session, version). Renvoie nil si le profil
-- reste verrouille ou illisible : on ne cree alors PAS de sauvegarde vide.
function Saves.claim(player)
	local session = game:GetService("HttpService"):GenerateGUID(false)
	for attempt = 1, 10 do
		local data, locked
		local ok, err = pcall(function()
			_G.MWS_Store:UpdateAsync("player_" .. player.UserId, function(current)
				data, locked = nil, false
				if type(current) ~= "table" then current = {} end
				if current.sessionId and os.time() - finiteNumber(current.sessionLockAt, 0, 0) < Saves.LOCK_TTL then
					locked = true
					return nil
				end
				current.sessionId = session
				current.sessionLockAt = os.time()
				current.saveVersion = finiteNumber(current.saveVersion, 0, 0) + 1
				data = current
				return current
			end)
		end)
		if ok and data then return data, session, data.saveVersion end
		if not ok then
			warn("[MWS] Echec de chargement (essai " .. attempt .. ") pour " .. player.UserId .. ": " .. tostring(err))
		end
		if not player.Parent then return nil end
		task.wait(3)
	end
	return nil
end

-- Rend le verrou d'un joueur parti pendant son chargement
function Saves.release(player, session)
	pcall(function()
		_G.MWS_Store:UpdateAsync("player_" .. player.UserId, function(current)
			if type(current) ~= "table" or current.sessionId ~= session then return nil end
			current.sessionId = nil
			return current
		end)
	end)
end

-- Copie complete : une sauvegarde en attente ne doit jamais suivre les changements du jeu.
function Saves.deepCopy(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for k, v in pairs(value) do copy[k] = Saves.deepCopy(v) end
	return copy
end

-- Uniquement les champs persistants, pas les objets Roblox temporaires.
function Saves.snapshot(s)
	local petsCopy, equippedCopy, defeatedCopy = {}, {}, {}
	for i, pet in ipairs(s.pets) do
		petsCopy[i] = { id = pet.id, name = pet.name, rarity = pet.rarity, color = pet.color, multiplier = pet.multiplier, income = pet.income, tier = pet.tier or 0, lvl = pet.lvl or 0, xp = pet.xp or 0, size = pet.size, mutation = pet.mutation }
	end
	for i, id in ipairs(s.equipped) do equippedCopy[i] = id end
	for i, id in ipairs(s.defeatedNPCs) do defeatedCopy[i] = id end
	return {
		coins = s.coins, pets = petsCopy, equipped = equippedCopy,
		defeatedNPCs = defeatedCopy, rebirthLevel = s.rebirthLevel,
		unlockedWorld = s.unlockedWorld, nextPetId = s.nextPetId,
		speedBoostUntil = s.speedBoostUntil or 0,
		luckUntil = s.luckUntil or 0, luckMult = s.luckMult or 1,
		receipts = table.clone(s.receipts or {}), bought = Saves.deepCopy(s.bought or {}),
		pendingPets = table.clone(s.pendingPets or {}),
		tut = s.tut, tutProg = s.tutProg, dex = Saves.deepCopy(s.dex), dexClaimed = Saves.deepCopy(s.dexClaimed),
		daily = Saves.deepCopy(s.daily), quests = Saves.deepCopy(s.quests),
		auraColor = s.auraColor,
		lastSeen = os.time(),
	}
end

local OFFLINE_RATE, OFFLINE_MAX = 0.25, 8 * 3600
local function loadPlayer(player)
	local data, session, version
	if datastoreAvailable then
		data, session, version = Saves.claim(player)
		if not data then
			if player.Parent then player:Kick("Impossible de charger ta sauvegarde. Reconnecte-toi dans un instant !") end
			return
		end
		if not player.Parent then
			Saves.release(player, session)
			return
		end
	end
	-- un nouveau joueur n'a que le verrou dans son profil
	local s = (data and data.coins ~= nil) and data or newState()
	s.sessionId, s.sessionLockAt, s.saveVersion = nil, nil, nil
	-- Valide les donnees sauvegardees avant de les utiliser (migration / donnees corrompues).
	if type(s.pets) ~= "table" then s.pets = {} end
	if type(s.equipped) ~= "table" then s.equipped = {} end
	if type(s.defeatedNPCs) ~= "table" then s.defeatedNPCs = {} end
	s.coins = math.floor(finiteNumber(s.coins, START_COINS, 0, 9e15))
	s.rebirthLevel = math.floor(finiteNumber(s.rebirthLevel, 0, 0, 1000000))
	s.unlockedWorld = math.floor(finiteNumber(s.unlockedWorld, 1, 1, #WORLDS))
	s.speedBoostUntil = finiteNumber(s.speedBoostUntil, 0, 0)
	s.luckUntil = finiteNumber(s.luckUntil, 0, 0)
	s.luckMult = finiteNumber(s.luckMult, 1, 1, 10)
	if type(s.receipts) ~= "table" then s.receipts = {} end
	if session then
		local saved = {}
		for _, rid in ipairs(s.receipts) do saved[rid] = true end
		Saves.meta[s] = { session = session, version = version, saved = saved }
	end
	if type(s.bought) ~= "table" then s.bought = {} end
	-- pets achetes avec l'inventaire plein, en attente d'une place libre
	local pendingPets = {}
	if type(s.pendingPets) == "table" then
		for _, name in ipairs(s.pendingPets) do
			if PETS[name] then table.insert(pendingPets, name) end
		end
	end
	s.pendingPets = pendingPets
	if type(s.auraColor) ~= "string" then s.auraColor = "auto" end
	local cleanPets, ownedIds, maxId = {}, {}, 0
	for _, pet in ipairs(s.pets) do
		if type(pet) == "table" and PETS[pet.name] and type(pet.id) == "number" then
			pet.id = math.floor(finiteNumber(pet.id, 0, 1, 9e15))
			if pet.id > 0 and not ownedIds[pet.id] and #cleanPets < MAX_PETS then
				local info = PETS[pet.name]
				pet.rarity = info.rarity
				pet.color = info.color
				-- fusion : chaque palier (tier) = revenu x4 et force de combat x1.5
				local tier = math.floor(finiteNumber(pet.tier, 0, 0, 3))
				pet.tier = tier
				if not Traits.SIZE[pet.size or ""] then pet.size = nil end
				if not Traits.MUTATION[pet.mutation or ""] then pet.mutation = nil end
				local tm = Traits.mult(pet)
				pet.multiplier = info.multiplier * (1.5 ^ tier) * tm
				pet.income = math.floor(info.income * (4 ^ tier) * tm)
				pet.lvl = math.floor(finiteNumber(pet.lvl, 0, 0, PET_MAX_LVL))
				pet.xp = math.floor(finiteNumber(pet.xp, 0, 0, 1e9))
				table.insert(cleanPets, pet)
				ownedIds[pet.id] = true
				maxId = math.max(maxId, pet.id)
			end
		end
	end
	s.pets = cleanPets
	local cleanEquipped, equippedSet = {}, {}
	for _, id in ipairs(s.equipped) do
		if type(id) == "number" and ownedIds[id] and not equippedSet[id] and #cleanEquipped < maxEquip(s) then
			table.insert(cleanEquipped, id)
			equippedSet[id] = true
		end
	end
	s.equipped = cleanEquipped
	local cleanDefeated, defeatedSet = {}, {}
	for _, idx in ipairs(s.defeatedNPCs) do
		if type(idx) == "number" and idx == math.floor(idx) and idx >= 1 and idx <= #NPC_TRAINERS and not defeatedSet[idx] then
			table.insert(cleanDefeated, idx)
			defeatedSet[idx] = true
		end
	end
	s.defeatedNPCs = cleanDefeated
	s.nextPetId = math.max(math.floor(finiteNumber(s.nextPetId, 1, 1, 9e15)), maxId + 1)
	states[player.UserId] = s
	-- gains hors ligne : tes pets equipes rapportent 25 % de leurs gains pendant ton absence (8 h max)
	local away = math.clamp(os.time() - finiteNumber(s.lastSeen, os.time(), 0), 0, OFFLINE_MAX)
	s.lastSeen = nil
	if away >= 60 then
		local earned = math.floor(getIncome(player) * away * OFFLINE_RATE)
		if earned > 0 then
			s.coins = s.coins + earned
			local h, m = math.floor(away / 3600), math.floor((away % 3600) / 60)
			local txt = (h > 0 and (h .. " h ") or "") .. m .. " min"
			task.delay(4, function()
				if player.Parent then
					notify(player, "Bon retour ! Tes pets ont gagne " .. fmt(earned) .. " coins pendant ton absence (" .. txt .. ")", Color3.fromRGB(255, 220, 80))
				end
			end)
		end
	end
	sendState(player)
	sendEggInfo(player)
	sendNPCInfo(player)
	sendWorldInfo(player)
end

-- Renvoie true seulement si l'ecriture est durable. final = true : rend aussi le verrou du profil.
local function savePlayer(player, final)
	local uid = player.UserId
	local s = states[uid]
	if not s or not datastoreAvailable then return false end
	local meta = Saves.meta[s]
	if not meta then return false end
	while Saves.busy[uid] do
		task.wait(0.05)
	end
	if meta.released then return true end
	if meta.lost then return false end
	Saves.busy[uid] = true
	local ok, err, written, lost
	for attempt = 1, 3 do
		ok, err = pcall(function()
			local snapshot = Saves.snapshot(s) -- pris apres l'attente : toujours l'etat le plus recent
			_G.MWS_Store:UpdateAsync("player_" .. uid, function(current)
				written, lost = false, false
				local stored = 0
				if type(current) == "table" then
					stored = finiteNumber(current.saveVersion, 0, 0)
					if current.sessionId ~= meta.session and (current.sessionId ~= nil or stored > meta.version) then
						lost = true
						return nil
					end
				end
				snapshot.sessionId = not final and meta.session or nil
				snapshot.sessionLockAt = os.time()
				snapshot.saveVersion = math.max(stored, meta.version) + 1
				written = true
				return snapshot
			end)
			if written then
				meta.version = snapshot.saveVersion
				meta.saved = {}
				for _, rid in ipairs(snapshot.receipts) do meta.saved[rid] = true end
			end
		end)
		if (ok and written) or lost then break end
		if attempt < 3 then task.wait(1.5 * attempt) end
	end
	Saves.busy[uid] = nil
	if lost then
		meta.lost = true
		warn("[MWS] Sauvegarde refusee pour " .. uid .. " : session perimee")
		if player.Parent then player:Kick("Ta partie a ete ouverte ailleurs. Reconnecte-toi dans un instant !") end
		return false
	end
	if not (ok and written) then
		warn("[MWS] Echec de sauvegarde pour " .. uid .. ": " .. tostring(err))
		return false
	end
	if final then meta.released = true end
	return true
end

local function rollPet(s, eggPool)
	-- Potion de chance : les animaux rares (chance <= 10 %) sont plus probables
	local luck = ((s.luckUntil or 0) > os.time()) and (s.luckMult or 1) or 1
	local weights, total = {}, 0
	for i, entry in ipairs(eggPool) do
		local w = entry.chance
		if luck > 1 and entry.chance <= 10 then w = w * luck end
		weights[i] = w
		total = total + w
	end
	local roll = math.random() * total
	local cumul = 0
	local chosen = eggPool[1].pet
	for i, entry in ipairs(eggPool) do
		cumul = cumul + weights[i]
		if roll <= cumul then
			chosen = entry.pet
			break
		end
	end
	local info = PETS[chosen]
	local id = s.nextPetId
	s.nextPetId = id + 1
	local pet = { id = id, name = chosen, rarity = info.rarity, color = info.color }
	pet.size, pet.mutation = Traits.roll(luck)
	local tm = Traits.mult(pet)
	pet.multiplier = info.multiplier * tm
	pet.income = math.floor(info.income * tm)
	return pet
end

-- ============================================================
-- VISUELS DES PETS (suivi du joueur)
-- ============================================================

local function visualKey(player, petId)
	return player.UserId .. ":" .. petId
end

local function despawnPetVisual(key)
	local v = petVisuals[key]
	if v then
		petVisuals[key] = nil
		pcall(function() v.model:Destroy() end)
	end
end

-- Aura des pets fusionnes : flammes autour du corps, fumee sombre, yeux qui brillent.
-- Plus le niveau de fusion (tier 1 a 3) est haut, plus l'aura est grande et lumineuse.
-- Couleurs que le joueur peut choisir ("auto" = couleur du pet)
local AURA_PRESETS = {
	violet = Color3.fromRGB(150, 60, 255), bleu = Color3.fromRGB(40, 130, 255), cyan = Color3.fromRGB(40, 220, 255),
	vert = Color3.fromRGB(50, 220, 90), dore = Color3.fromRGB(255, 190, 40), rouge = Color3.fromRGB(255, 50, 50),
	rose = Color3.fromRGB(255, 80, 200), blanc = Color3.fromRGB(235, 240, 255),
}

-- couleur "auto" : celle du pet, rendue plus vive ; les pets blancs ou gris prennent la couleur de leur rarete
local function autoAuraColor(petData)
	local info = PETS[petData.name]
	local col = info and colorFromTable(info.color) or WHITE
	local _, sat = col:ToHSV()
	if sat < 0.2 then col = rarityInfo(info and info.rarity).color end
	return col
end

local function auraTones(base, tier)
	local h, sat, v = base:ToHSV()
	local edge = (sat < 0.15) and base or Color3.fromHSV(h, math.max(sat, 0.75), math.max(v, 0.85))
	return { core = edge:Lerp(WHITE, 0.3 + 0.1 * tier), edge = edge }
end

local function addFusionAura(model, root, tier, ext, base)
	tier = math.clamp(tier, 1, 3)
	local c = auraTones(base, tier)
	local shell = Instance.new("Part")
	shell.Name = "FusionAura"
	shell.Size = ext * (0.9 + 0.1 * tier)
	shell.Transparency = 1
	shell.CanCollide = false
	shell.CanTouch = false
	shell.CanQuery = false
	shell.Massless = true
	shell.CFrame = root.CFrame
	local w = Instance.new("WeldConstraint")
	w.Part0 = root
	w.Part1 = shell
	w.Parent = shell
	shell.Parent = model
	local big = math.max(ext.X, ext.Y, ext.Z)

	-- flammes qui montent sur toute la silhouette
	local fl = Instance.new("ParticleEmitter")
	fl.Name = "AuraFlames"
	fl.Texture = "rbxasset://textures/particles/fire_main.dds"
	fl.Color = ColorSequence.new(c.core, c.edge)
	fl.LightEmission = 0.6
	fl.LightInfluence = 0
	fl.Brightness = 2.5
	fl.Shape = Enum.ParticleEmitterShape.Box
	fl.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	fl.EmissionDirection = Enum.NormalId.Top
	fl.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, big * (0.18 + 0.04 * tier)), NumberSequenceKeypoint.new(1, 0) })
	fl.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.6, 0.3), NumberSequenceKeypoint.new(1, 1) })
	fl.Lifetime = NumberRange.new(0.4, 0.7)
	fl.Rate = 40 + 20 * tier
	fl.Speed = NumberRange.new(0.8, 1.8)
	fl.Acceleration = V3(0, 3 + tier, 0)
	fl.Rotation = NumberRange.new(-30, 30)
	fl.RotSpeed = NumberRange.new(-40, 40)
	fl.Parent = shell

	-- fumee sombre autour
	local sm = Instance.new("ParticleEmitter")
	sm.Name = "AuraSmoke"
	sm.Texture = "rbxasset://textures/particles/smoke_main.dds"
	sm.Color = ColorSequence.new(c.edge:Lerp(BLACK, 0.8))
	sm.LightEmission = 0
	sm.LightInfluence = 0
	sm.Shape = Enum.ParticleEmitterShape.Box
	sm.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	sm.EmissionDirection = Enum.NormalId.Top
	sm.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, big * 0.15), NumberSequenceKeypoint.new(1, big * 0.28) })
	sm.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	sm.Lifetime = NumberRange.new(0.8, 1.3)
	sm.Rate = 4 + 2 * tier
	sm.Speed = NumberRange.new(0.5, 1.2)
	sm.Parent = shell

	-- etincelles
	local sp = Instance.new("ParticleEmitter")
	sp.Name = "AuraSparks"
	sp.Color = ColorSequence.new(c.core)
	sp.LightEmission = 1
	sp.Shape = Enum.ParticleEmitterShape.Box
	sp.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
	sp.Lifetime = NumberRange.new(0.6, 1.1)
	sp.Rate = 6 * tier
	sp.Speed = NumberRange.new(2, 4)
	sp.SpreadAngle = Vector2.new(30, 30)
	sp.Parent = shell

	local pl = Instance.new("PointLight")
	pl.Name = "AuraLight"
	pl.Color = c.edge
	pl.Range = 6 + 2 * tier
	pl.Brightness = 0.8 + 0.3 * tier
	pl.Parent = shell

	-- les yeux s'illuminent
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "Eye" then
			d.Material = Enum.Material.Neon
			d.Color = c.core
		end
	end
end

local function spawnPetVisual(player, petData, slot)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local key = visualKey(player, petData.id)
	despawnPetVisual(key)

	local model, root, P = createPetModel(petData.name, false, (1 + 0.12 * (petData.tier or 0)) * Traits.scale(petData), petData.mutation)
	root.CFrame = hrp.CFrame * CF(0, 0, 5)

	local att = Instance.new("Attachment")
	att.Parent = root
	local align = Instance.new("AlignOrientation")
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = att
	align.RigidityEnabled = false
	align.MaxTorque = math.huge
	align.Responsiveness = 25
	align.CFrame = root.CFrame.Rotation
	align.Parent = root

	local info = PETS[petData.name]
	local rar = rarityInfo(info and info.rarity)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 200, 0, 22)
	bb.StudsOffset = V3(0, P.labelY or (2 + P.scale * 2), 0)
	bb.MaxDistance = 60
	bb.Adornee = root
	bb.Parent = root
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = Traits.fullName(petData) .. ((petData.lvl or 0) > 0 and (" Nv." .. petData.lvl) or "")
	lbl.TextColor3 = Traits.accent(petData) or rar.color
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13
	lbl.TextStrokeTransparency = 0.4
	lbl.Parent = bb

	-- aura : les pets puissants brillent, les pets fusionnes encore plus
	if (petData.income or 0) >= 100 or (petData.tier or 0) > 0 then
		local aura = emitter(root, rar.color, 3 + (petData.tier or 0) * 3, 0.45, 1.3, 1.2)
		aura.SpreadAngle = Vector2.new(180, 180)
		aura.LightEmission = 1
	end
	if (petData.tier or 0) > 0 then
		local st = states[player.UserId]
		local base = AURA_PRESETS[st and st.auraColor or ""] or autoAuraColor(petData)
		addFusionAura(model, root, petData.tier, P.ext or V3(3, 3, 3) * P.scale, base)
	end

	model.Parent = petsFolder
	pcall(function() root:SetNetworkOwner(nil) end)

	petVisuals[key] = {
		model = model, body = root, hrp = hrp, owner = player, anims = P.anims, align = align,
		slot = slot or 1, flying = P.flying, hops = P.hops, flyY = P.flyY, spread = P.spread,
		groundY = -3 + P.foot * P.scale + 0.15
	}
end

local function reslot(player)
	local s = states[player.UserId]
	if not s then return end
	for i, id in ipairs(s.equipped) do
		local v = petVisuals[visualKey(player, id)]
		if v then v.slot = i end
	end
end

local function clearPlayerVisuals(player)
	for key, v in pairs(petVisuals) do
		if v.owner == player then despawnPetVisual(key) end
	end
end

local function refreshPetVisuals(player)
	local s = states[player.UserId]
	if not s then return end
	clearPlayerVisuals(player)
	for i, pet in ipairs(getEquippedPets(s)) do
		spawnPetVisual(player, pet, i)
	end
end

-- ============================================================
-- HEARTBEAT : suivi des pets, animations, decor
-- ============================================================

-- promenade des pets : distance max au joueur avant qu'ils le rejoignent, rayon de promenade
local PET_LEASH = 20
local PET_WANDER = 7
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.RespectCanCollide = true
local function petGroundY(p, fallback)
	local ex = { petsFolder }
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl.Character then table.insert(ex, pl.Character) end
	end
	groundParams.FilterDescendantsInstances = ex
	local hit = workspace:Raycast(V3(p.X, fallback + 8, p.Z), V3(0, -20, 0), groundParams)
	-- pas sur les arbres ni dans les trous : on reste proche du niveau du joueur
	if hit and math.abs(hit.Position.Y - fallback) < 3.5 then return hit.Position.Y end
	return fallback
end

local decorAccum = 0

RunService.Heartbeat:Connect(function(dt)
	local t = os.clock()

	for key, data in pairs(petVisuals) do
		local model, body, hrp = data.model, data.body, data.hrp
		if model.Parent and body.Parent and hrp and hrp.Parent then
			-- Pets autonomes : chacun se promene tout seul autour de son coin ("home"),
			-- sans suivre les mouvements ni le regard du joueur. Si le joueur s'eloigne
			-- trop (laisse), le pet le rejoint en courant puis recommence a se promener.
			local slot = data.slot or 1
			local hp = hrp.Position
			local floorH = data.groundY + 3 -- hauteur du centre du pet au-dessus du sol
			if not data.followOff then
				local ang = slot * 2.4 + math.random() * 0.8
				local r = 5 + math.min(data.spread or 0, 8) * 0.5 + math.random() * 2
				data.followOff = V3(math.cos(ang) * r, 0, math.sin(ang) * r)
			end
			if not data.home then
				data.home = hp + data.followOff
				data.homeY = hp.Y - 3
				data.mode = "idle"
				data.nextWander = t + math.random() * 2
			end
			local distToPlayer = (V3(body.Position.X, 0, body.Position.Z) - V3(hp.X, 0, hp.Z)).Magnitude
			local leash = PET_LEASH + math.min(data.spread or 0, 8)
			if data.mode ~= "follow" and distToPlayer > leash then
				data.mode = "follow"
			end
			local target, speed
			local moving = true
			if data.mode == "follow" then
				local fp = hp + data.followOff
				target = V3(fp.X, hp.Y - 3 + floorH, fp.Z)
				local hum = hrp.Parent:FindFirstChildOfClass("Humanoid")
				speed = math.max(22, (hum and hum.WalkSpeed or 16) * 1.35)
				if (V3(target.X, 0, target.Z) - V3(body.Position.X, 0, body.Position.Z)).Magnitude < 2.5 then
					-- arrive pres du joueur : nouveau coin de promenade ici
					data.mode = "idle"
					data.home = V3(fp.X, 0, fp.Z)
					data.homeY = hp.Y - 3
					data.walkTarget = nil
					data.nextWander = t + 0.8 + math.random() * 1.5
				end
			else
				if data.mode == "walk" and data.walkTarget then
					local wt = data.walkTarget
					if (V3(wt.X, 0, wt.Z) - V3(body.Position.X, 0, body.Position.Z)).Magnitude < 0.8 then
						data.mode = "idle"
						data.nextWander = t + 1.5 + math.random() * 3
					end
				end
				if data.mode == "idle" and t >= (data.nextWander or 0) then
					-- choisit un petit trajet au hasard autour de son coin
					local ang = math.random() * math.pi * 2
					local r = 2 + math.random() * PET_WANDER
					local p = V3(data.home.X + math.cos(ang) * r, 0, data.home.Z + math.sin(ang) * r)
					data.walkTarget = V3(p.X, petGroundY(p, data.homeY), p.Z)
					data.mode = "walk"
				end
				if data.mode == "walk" and data.walkTarget then
					target = data.walkTarget + V3(0, floorH, 0)
					speed = data.flying and 7 or 5.5
				else
					moving = false
					local wt = data.walkTarget or V3(body.Position.X, data.homeY, body.Position.Z)
					target = V3(body.Position.X, wt.Y + floorH, body.Position.Z)
					speed = 4
				end
			end
			-- hauteur : vol avec un leger bob, sautillement pendant la marche
			if data.flying then
				target = target + V3(0, (data.flyY or 1.2) + math.sin(t * 2 + slot * 1.3) * 0.35, 0)
			elseif data.hops and moving then
				target = target + V3(0, math.abs(math.sin(t * 5 + slot)) * 0.9, 0)
			end
			if data.harvestUntil and t < data.harvestUntil and data.harvestPos then
				target = data.harvestPos
				speed = 40
				moving = true
			end
			local diff = target - body.Position
			if diff.Magnitude > 70 then
				-- teleportation du joueur : le pet reapparait a cote de lui
				body.CFrame = CF(hp + data.followOff)
				body.AssemblyLinearVelocity = V3(0, 0, 0)
				data.home = nil
			else
				local flatDiff = V3(diff.X, 0, diff.Z)
				local vel = flatDiff.Magnitude > 0.05 and flatDiff.Unit * math.min(speed, flatDiff.Magnitude * 6) or V3(0, 0, 0)
				vel = vel + V3(0, math.clamp(diff.Y * 8, -40, 40), 0)
				body.AssemblyLinearVelocity = vel
			end
			local flat = V3(diff.X, 0, diff.Z)
			local look = data.lastLook or V3(0, 0, -1)
			if moving and flat.Magnitude > 0.4 then
				look = flat.Unit
				data.lastLook = look
			end
			if data.faceTarget and t < (data.faceUntil or 0) then
				local fd = V3(data.faceTarget.X - body.Position.X, 0, data.faceTarget.Z - body.Position.Z)
				if fd.Magnitude > 0.1 then look = fd.Unit end
			end
			local tilt = data.flying and math.clamp(diff.Magnitude / 10, 0, 0.3) or 0
			data.align.CFrame = CFrame.lookAt(V3(0, 0, 0), look) * CFrame.Angles(tilt, 0, 0)
			animateList(data.anims, t)
		else
			despawnPetVisual(key)
		end
	end

	for model, list in pairs(staticAnimators) do
		if model.Parent then
			animateList(list, t)
		else
			staticAnimators[model] = nil
		end
	end

	for vis in pairs(arenaVis) do
		if vis.root and vis.root.Parent then
			local off = V3(0, 0, 0)
			local lt = (t - (vis.lungeStart or -10)) / 0.4
			if lt >= 0 and lt <= 1 then off = off + vis.dir * (math.sin(lt * math.pi) * 7) end
			if vis.shakeUntil and t < vis.shakeUntil then
				off = off + V3(math.random() - 0.5, 0, math.random() - 0.5) * 1.2
			end
			local spawnK = math.clamp((t - vis.spawnT) / 0.5, 0, 1)
			off = off + V3(0, -3 * (1 - spawnK), 0)
			if vis.dead then
				off = off + V3(0, -math.clamp((t - vis.dead) / 0.8, 0, 1) * 3, 0)
			end
			local bobv = math.sin(t * 2 + vis.phase) * 0.3
			vis.root.CFrame = vis.base * CF(0, bobv, 0) + off
		else
			arenaVis[vis] = nil
		end
	end

	decorAccum = decorAccum + dt
	if decorAccum >= 0.05 then
		decorAccum = 0
		updateDecor(t)
	end
end)

-- ============================================================
-- CONSTRUCTION DES MONDES
-- ============================================================

local function makeSign(F, pos, title, subtitle, color)
	local p = Instance.new("Part")
	p.Name = "Sign"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.Transparency = 1
	p.Size = V3(1, 1, 1)
	p.Position = pos
	p.Parent = F
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 420, 0, 90)
	bb.MaxDistance = 300
	bb.Parent = p
	local t1 = Instance.new("TextLabel")
	t1.Size = UDim2.new(1, 0, 0.6, 0)
	t1.BackgroundTransparency = 1
	t1.Text = title
	t1.TextScaled = true
	t1.Font = Enum.Font.GothamBlack
	t1.TextColor3 = color
	t1.TextStrokeTransparency = 0.3
	t1.Parent = bb
	local t2 = Instance.new("TextLabel")
	t2.Size = UDim2.new(1, 0, 0.35, 0)
	t2.Position = UDim2.new(0, 0, 0.62, 0)
	t2.BackgroundTransparency = 1
	t2.Text = subtitle
	t2.TextScaled = true
	t2.Font = Enum.Font.GothamBold
	t2.TextColor3 = WHITE
	t2.TextStrokeTransparency = 0.5
	t2.Parent = bb
end

local function makeWalls(F, center, half, height, halfZ)
	halfZ = halfZ or half
	for _, d in ipairs({ { 0, halfZ, 2 * half, 1 }, { 0, -halfZ, 2 * half, 1 }, { half, 0, 1, 2 * halfZ }, { -half, 0, 1, 2 * halfZ } }) do
		local w = Instance.new("Part")
		w.Name = "Wall"
		w.Size = V3(d[3], height, d[4])
		w.Position = center + V3(d[1], height / 2, d[2])
		w.Transparency = 1
		w.Anchored = true
		w.CanCollide = true
		w.Parent = F
	end
end

local function makeRingStatic(F, center, radius, segments, size, color, mat)
	for i = 1, segments do
		local a = (i / segments) * math.pi * 2
		local p = makePart("RingSeg", size, center + V3(math.cos(a) * radius, 0, math.sin(a) * radius), color, mat, F)
		p.CFrame = CF(p.Position) * CFrame.Angles(0, -(a + math.pi / 2), 0)
		p.CanCollide = false
	end
end

local function newProp(F, name, shape, size, pos, color, mat, trans)
	local model = Instance.new("Model")
	model.Name = name
	local P = {
		model = model, anims = {}, anchoredRoot = true, scale = 1,
		col = color, light = color:Lerp(WHITE, 0.4), dark = color:Lerp(BLACK, 0.4)
	}
	local root = makeRoot(P, shape, size, color, mat, trans)
	root.CFrame = CF(pos)
	model.Parent = F
	return P, root
end

local function getOrigin()
	local sp = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	return sp and sp.Position or V3(0, 5, 0)
end

-- ---------- MONDE 1 : Prairie enchantee ----------

local function createWorld1()
	local o = worldOrigin[1]
	local F = worldFolder[1]
	-- la map remplit tout l'espace entoure par les montagnes
	local mapC = o + V3(9, 0, -10)
	makePart("Island", V3(435, 5, 403), mapC + V3(0, -3, 0), Color3.fromRGB(90, 160, 80), M.Grass, F)
	makePart("SandBorder", V3(467, 3, 435), mapC + V3(0, -4, 0), Color3.fromRGB(220, 200, 140), M.Sand, F)
	local water = makePart("Water", V3(700, 1, 680), mapC + V3(0, -5.5, 0), Color3.fromRGB(60, 140, 220), M.Glass, F)
	water.Transparency = 0.3
	water.CanCollide = false
	makeWalls(F, mapC, 222, 60, 212)

	if not workspace:FindFirstChildWhichIsA("SpawnLocation", true) then
		local sp = Instance.new("SpawnLocation")
		sp.Name = "Spawn"
		sp.Size = V3(6, 1, 6)
		sp.Position = o
		sp.Anchored = true
		sp.Parent = F
	end

	-- arbres : tronc + feuillage ameliore (couches + balles laterales + accents)
	local treeColorVariants = {
		{ base = Color3.fromRGB(45, 130, 45), light = Color3.fromRGB(80, 180, 60), accent = Color3.fromRGB(255, 200, 80) },
		{ base = Color3.fromRGB(55, 140, 50), light = Color3.fromRGB(100, 190, 70), accent = Color3.fromRGB(255, 120, 160) },
		{ base = Color3.fromRGB(40, 120, 55), light = Color3.fromRGB(70, 170, 80), accent = Color3.fromRGB(180, 220, 255) },
		{ base = Color3.fromRGB(50, 135, 40), light = Color3.fromRGB(90, 175, 50), accent = Color3.fromRGB(255, 230, 100) },
	}
	for i = 1, 12 do
		local a = (i / 12) * math.pi * 2
		local r = 96 + (i % 3) * 24
		local pos = o + V3(math.cos(a) * r, 0, math.sin(a) * r)
		local tc = treeColorVariants[(i % #treeColorVariants) + 1]
		makePart("Trunk" .. i, V3(3, 10, 3), pos + V3(0, 5, 0), Color3.fromRGB(110, 70, 40), M.Wood, F)
		-- couches principales de feuillage (balles empilees, plus grandes)
		for k = 1, 3 do
			local f = makePart("Foliage" .. i .. "_" .. k, V3(11 - k * 2, 8 - k, 11 - k * 2), pos + V3(0, 9 + k * 3, 0), k == 3 and tc.light or tc.base, M.LeafyGrass, F)
			f.Shape = Enum.PartType.Ball
		end
		-- balles laterales pour un canopy plus plein et organique
		local sideOffsets = {
			{ V3(3, 0, 1), 5 }, { V3(-2.5, 0.5, -2), 4.5 }, { V3(1, 0, -3), 5 }, { V3(-3, 0, 2), 4 },
			{ V3(0, 3, 3), 4 }, { V3(-2, 3, 1), 3.5 }, { V3(2.5, 2.5, -1), 4 },
		}
		for j, sd in ipairs(sideOffsets) do
			local f = makePart("Foliage" .. i .. "_S" .. j, V3(sd[2], sd[2], sd[2]), pos + V3(0, 11, 0) + sd[1], j <= 3 and tc.base or tc.light, M.LeafyGrass, F)
			f.Shape = Enum.PartType.Ball
			f.CanCollide = false
		end
		-- petits accents (fruits/fleurs) sur certains arbres
		if i % 3 == 0 then
			for j = 1, 5 do
				local ang = j * 1.2
				local fr = makePart("Fruit" .. i .. "_" .. j, V3(1.2, 1.2, 1.2), pos + V3(math.cos(ang) * 3, 12 + math.sin(ang) * 1.5, math.sin(ang) * 3), tc.accent, M.Neon, F)
				fr.Shape = Enum.PartType.Ball
				fr.CanCollide = false
			end
		end
	end
	for i = 1, 8 do
		local a = ((i + 4) / 8) * math.pi * 2
		local r = 72 + (i % 4) * 19
		local pos = o + V3(math.cos(a) * r, 0, math.sin(a) * r)
		local rock = makePart("Rock" .. i, V3(4, 3, 4), pos + V3(0, 1, 0), Color3.fromRGB(130, 130, 130), M.Rock, F)
		rock.Shape = Enum.PartType.Ball
	end
	makeSign(F, o + V3(0, 24, -30), "Monde 1", WORLDS[1].name, Color3.fromRGB(120, 255, 140))
end

-- ---------- MONDE 2 : Royaume volcanique ----------

local volcanoPos

-- Volcan modelise a la main (workspace.Valcano, range dans ServerStorage au lancement)
-- copie pour le monde 2, avec feu, fumee et lumiere au sommet.
local volcanoTemplate
local function placeVolcano(F, pos, scale, yaw, smoke, solid)
	if not volcanoTemplate then
		local SS = game:GetService("ServerStorage")
		volcanoTemplate = workspace:FindFirstChild("Valcano") or SS:FindFirstChild("Valcano")
		if volcanoTemplate then volcanoTemplate.Parent = SS end
	end
	if not volcanoTemplate then return nil end
	local m = volcanoTemplate:Clone()
	m.Name = "Volcan"
	for _, d in ipairs(m:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = solid == true
			d.CanQuery = solid == true
		end
	end
	m:ScaleTo(m:GetScale() * scale)
	m:PivotTo(CF(pos) * CFrame.Angles(0, yaw, 0))
	local cf, size = m:GetBoundingBox()
	m:PivotTo(m:GetPivot() + V3(pos.X - cf.X, pos.Y - (cf.Y - size.Y / 2), pos.Z - cf.Z))
	m.Parent = F
	-- sommet : point le plus haut du modele
	cf, size = m:GetBoundingBox()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { m }
	local wasQ = {}
	for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then wasQ[d] = d.CanQuery d.CanQuery = true end end
	local peak, best = cf.Position + V3(0, size.Y / 2, 0), -math.huge
	for gx = -3, 3 do
		for gz = -3, 3 do
			local p = cf.Position + V3(gx * size.X * 0.06, size.Y, gz * size.Z * 0.06)
			local hit = workspace:Raycast(p, V3(0, -size.Y * 2, 0), params)
			if hit and hit.Position.Y > best then best, peak = hit.Position.Y, hit.Position end
		end
	end
	for d, q in pairs(wasQ) do d.CanQuery = q end
	local vtop = makePart("VolcanoTop", V3(1, 1, 1), peak + V3(0, 2, 0), WHITE, M.SmoothPlastic, F)
	vtop.Transparency = 1
	vtop.CanCollide = false
	vtop.CanQuery = false
	local fire = emitter(vtop, Color3.fromRGB(255, 120, 30), 10 * scale, 2 * scale, 3, 9 * scale)
	fire.SpreadAngle = Vector2.new(25, 25)
	if smoke then
		local sm = emitter(vtop, Color3.fromRGB(60, 55, 60), 4, 6 * scale, 8, 5 * scale, 0.5)
		sm.LightEmission = 0
	end
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(255, 120, 40)
	pl.Range = 60
	pl.Brightness = 3
	pl.Parent = vtop
	return m, peak
end

local function createWorld2()
	local o = worldOrigin[2]
	local F = worldFolder[2]
	local rockCol = Color3.fromRGB(45, 40, 45)
	makePart("Island", V3(440, 5, 440), o + V3(0, -3, 0), rockCol, M.Basalt, F)
	makePart("Border", V3(470, 3, 470), o + V3(0, -4, 0), Color3.fromRGB(30, 25, 30), M.Slate, F)
	local lava = makePart("LavaSea", V3(1100, 1, 1100), o + V3(0, -5.5, 0), Color3.fromRGB(255, 90, 20), M.Neon, F)
	lava.CanCollide = false
	local dl = addDecor(2, lava, { pulse = 0.25, bobSpeed = 0.8 })
	makeWalls(F, o, 228, 60)

	-- grand volcan (le volcan modele, en grand)
	volcanoPos = o + V3(-150, 0, -150)
	placeVolcano(F, volcanoPos + V3(0, -0.5, 0), 2.6, 0.6, true, true)

	-- flaques de lave
	local poolPos = { V3(110, 0, 110), V3(-110, 0, 130), V3(130, 0, -80), V3(0, 0, -100), V3(-60, 0, 60), V3(170, 0, 20) }
	for i, pp in ipairs(poolPos) do
		local pool = makeCyl("LavaPool" .. i, 0.4, 16 + (i % 3) * 4, o + pp + V3(0, -0.3, 0), Color3.fromRGB(255, 90, 20), M.Neon, F)
		pool.CanCollide = false
		addDecor(2, pool, { pulse = 0.3, bobSpeed = 1.2 })
		local pe = emitter(pool, Color3.fromRGB(255, 160, 50), 4, 0.5, 2, 4)
		pe.SpreadAngle = Vector2.new(15, 15)
		local pl = Instance.new("PointLight")
		pl.Color = Color3.fromRGB(255, 120, 40)
		pl.Range = 22
		pl.Brightness = 2
		pl.Parent = pool
	end

	-- pics d'obsidienne
	for i = 1, 32 do
		local a = (i / 32) * math.pi * 2 + 0.2
		local r = 140 + (i % 4) * 20
		local pos = o + V3(math.cos(a) * r, 0, math.sin(a) * r)
		if (V3(pos.X, 0, pos.Z) - V3(volcanoPos.X, 0, volcanoPos.Z)).Magnitude > 95 then
			local h = 8 + (i % 5) * 3
			local sp = makePart("Obsidian" .. i, V3(3, h, 3), pos + V3(0, h / 2 - 0.5, 0), Color3.fromRGB(20, 15, 30), M.Slate, F)
			sp.CFrame = sp.CFrame * CFrame.Angles(math.rad((i % 3 - 1) * 8), math.rad(i * 30), math.rad((i % 2) * 6))
			local glow = makePart("ObsidianGlow", V3(0.4, h * 0.6, 3.1), pos + V3(0, h / 2 - 0.5, 0), Color3.fromRGB(180, 60, 255), M.Neon, F)
			glow.CFrame = sp.CFrame
			glow.CanCollide = false
		end
	end
	-- arbres calcines
	for i = 1, 20 do
		local a = (i / 20) * math.pi * 2 + 0.7
		local r = 80 + (i % 3) * 28
		local pos = o + V3(math.cos(a) * r, 0, math.sin(a) * r)
		makePart("DeadTrunk", V3(1.6, 11, 1.6), pos + V3(0, 5, 0), Color3.fromRGB(25, 20, 20), M.Wood, F)
		local br = makePart("DeadBranch", V3(0.8, 5, 0.8), pos + V3(1.5, 9, 0), Color3.fromRGB(25, 20, 20), M.Wood, F)
		br.CFrame = br.CFrame * CFrame.Angles(0, 0, math.rad(-50))
		br.CanCollide = false
		local crackle = makePart("EmberTree", V3(0.3, 4, 0.3), pos + V3(0.6, 4, 0.5), Color3.fromRGB(255, 110, 30), M.Neon, F)
		crackle.CanCollide = false
	end
	-- braises dans l'air
	for i = 1, 16 do
		local pos = o + V3(math.random(-200, 200), 4, math.random(-200, 200))
		local p = makePart("Embers", V3(1, 1, 1), pos, WHITE, M.SmoothPlastic, F)
		p.Transparency = 1
		p.CanCollide = false
		local pe = emitter(p, Color3.fromRGB(255, 150, 40), 5, 0.3, 4, 3)
		pe.SpreadAngle = Vector2.new(80, 80)
	end
	-- couronne de volcans (le volcan modele) tout autour de la map, dans la mer de lave
	local rngV = Random.new(202)
	for i = 1, 14 do
		local a = (i / 14) * math.pi * 2 + rngV:NextNumber(-0.08, 0.08)
		local dist = 335 + rngV:NextNumber(0, 45)
		placeVolcano(F, o + V3(math.cos(a) * dist, -6, math.sin(a) * dist), rngV:NextNumber(1.5, 2.6), rngV:NextNumber(0, math.pi * 2), i % 2 == 0)
	end
	makeSign(F, o + V3(0, 24, -30), "Monde 2", WORLDS[2].name, Color3.fromRGB(255, 140, 50))
end

-- ---------- MONDE 3 : Dimension mythique ----------

local function createWorld3()
	local o = worldOrigin[3]
	local F = worldFolder[3]
	-- ciel etoile
	for i = 1, 220 do
		local dir = V3(math.random() - 0.5, math.random() * 0.8 - 0.2, math.random() - 0.5)
		if dir.Magnitude < 0.05 then dir = V3(1, 0.3, 0) end
		local pos = o + dir.Unit * math.random(480, 950)
		local sz = math.random(10, 35) / 10
		local star = makePart("Star", V3(sz, sz, sz), pos, (i % 3 == 0) and Color3.fromRGB(180, 200, 255) or ((i % 3 == 1) and WHITE or Color3.fromRGB(255, 180, 255)), M.Neon, F)
		star.Shape = Enum.PartType.Ball
		star.CanCollide = false
		star.CanQuery = false
	end
	-- plateforme principale + base suspendue
	makeCyl("Platform", 5, 440, o + V3(0, -3, 0), Color3.fromRGB(60, 40, 110), M.SmoothPlastic, F)
	for k = 1, 6 do
		makeCyl("Under" .. k, 12, 400 - k * 60, o + V3(0, -5.5 - k * 6, 0), Color3.fromRGB(40 - k * 3, 28 - k * 2, 80 - k * 5), M.Slate, F)
	end
	makeRingStatic(F, o + V3(0, -0.4, 0), 216, 112, V3(8, 0.8, 1.4), Color3.fromRGB(200, 100, 255), M.Neon)
	makeRingStatic(F, o + V3(0, -0.4, 0), 190, 100, V3(8, 0.3, 0.6), Color3.fromRGB(100, 140, 255), M.Neon)
	for i = 1, 90 do
		local a = (i / 90) * math.pi * 2
		local wpos = o + V3(math.cos(a) * 221, 30, math.sin(a) * 221)
		local wall = Instance.new("Part")
		wall.Name = "Wall"
		wall.Size = V3(17, 80, 2)
		wall.CFrame = CFrame.lookAt(wpos, V3(o.X, wpos.Y, o.Z))
		wall.Transparency = 1
		wall.Anchored = true
		wall.CanCollide = true
		wall.CanQuery = false
		wall.Parent = F
	end

	-- monolithes
	for i = 1, 12 do
		local a = (i / 12) * math.pi * 2 + 0.4
		local pos = o + V3(math.cos(a) * (130 + (i % 2) * 40), 10, math.sin(a) * (130 + (i % 2) * 40))
		local P, root = newProp(F, "Monolith" .. i, "b", V3(3, 12, 3), pos, Color3.fromRGB(40, 30, 90), M.SmoothPlastic)
		add(P, nil, "Rune", "b", V3(3.1, 1, 3.1), CF(0, 2 + (i % 3), 0), Color3.fromRGB(200, 120, 255), M.Neon, FLICK(1.5, i))
		add(P, nil, "Cap", "b", V3(3.6, 0.8, 3.6), CF(0, 6.4, 0), Color3.fromRGB(150, 100, 255), M.Neon)
		root.CanCollide = true
		addDecor(3, root, { bob = 1.2, bobSpeed = 0.9, spin = 0.5 })
	end
	-- anneaux orbitaux
	for ringIdx = 1, 2 do
		local hub = makePart("RingHub" .. ringIdx, V3(1, 1, 1), o + V3(0, 55 + ringIdx * 12, 0), WHITE, M.SmoothPlastic, F)
		hub.Transparency = 1
		hub.CanCollide = false
		hub.CFrame = CF(hub.Position) * CFrame.Angles(math.rad(ringIdx * 18), 0, math.rad(-ringIdx * 12))
		local count = 64
		local radius = 250 + ringIdx * 40
		for i = 1, count do
			local a = (i / count) * math.pi * 2
			local seg = Instance.new("Part")
			seg.Name = "RingSeg"
			seg.Size = V3(14, 1.6, 3)
			seg.Color = (ringIdx == 1) and Color3.fromRGB(120, 180, 255) or Color3.fromRGB(255, 120, 220)
			seg.Material = M.Neon
			seg.Anchored = false
			seg.CanCollide = false
			seg.CanTouch = false
			seg.CanQuery = false
			seg.Massless = true
			local w = Instance.new("Weld")
			w.Part0 = hub
			w.Part1 = seg
			w.C0 = CF(math.cos(a) * radius, 0, math.sin(a) * radius) * CFrame.Angles(0, -(a + math.pi / 2), 0)
			w.Parent = seg
			seg.Parent = F
		end
		addDecor(3, hub, { spin = (ringIdx == 1) and 0.12 or -0.08 })
	end
	-- Nexus : grand cristal central
	local P, nexus = newProp(F, "Nexus", "b", V3(10, 10, 10), o + V3(0, 60, -140), Color3.fromRGB(190, 100, 255), M.Neon, 0.1)
	nexus.CFrame = CF(nexus.Position) * CFrame.Angles(math.rad(45), math.rad(45), 0)
	nexus.CanCollide = false
	add(P, nil, "NexusCore", "o", V3(6, 6, 6), CF(0, 0, 0), WHITE, M.Neon)
	local nl = Instance.new("PointLight")
	nl.Color = Color3.fromRGB(200, 120, 255)
	nl.Range = 60
	nl.Brightness = 3
	nl.Parent = nexus
	addDecor(3, nexus, { bob = 3, bobSpeed = 0.5, spin = 0.4 })
	-- couronne d'iles flottantes avec des cerisiers lego et des chutes d'eau
	local treeT = workspace:FindFirstChild("Arbre")
	local rngC = Random.new(303)
	local PINKS = { Color3.fromRGB(255, 183, 213), Color3.fromRGB(255, 150, 195), Color3.fromRGB(255, 220, 235) }
	local WATER = Color3.fromRGB(120, 205, 255)
	for i = 1, 12 do
		local a = (i / 12) * math.pi * 2 + rngC:NextNumber(-0.08, 0.08)
		local dist = 285 + rngC:NextNumber(0, 45)
		local ipos = o + V3(math.cos(a) * dist, rngC:NextNumber(-6, 16), math.sin(a) * dist)
		local toC = V3(o.X - ipos.X, 0, o.Z - ipos.Z).Unit
		local W, D = rngC:NextNumber(44, 56), rngC:NextNumber(38, 48)
		local base = CFrame.lookAt(ipos, ipos + toC) -- l'avant de l'ile regarde la map
		local top = makePart("IsleTop", V3(W, 4, D), ipos, Color3.fromRGB(125, 205, 135), M.Grass, F)
		top.CFrame = base
		local layers = { { 0.85, 7, -5.5 }, { 0.6, 9, -13 }, { 0.32, 9, -21.5 } }
		for k, L in ipairs(layers) do
			local r = makePart("IsleRock", V3(W * L[1], L[2], D * L[1]), ipos, Color3.fromRGB(80 - k * 8, 62 - k * 6, 112 - k * 10), M.Slate, F)
			r.CFrame = base * CF(0, L[3], 0) * CFrame.Angles(0, k * 0.35, 0)
			r.CanCollide = false
		end
		-- riviere sur l'ile puis chute d'eau sur le bord cote map
		local topY = ipos.Y + 2
		local river = makePart("IsleRiver", V3(9, 0.4, D * 0.55), ipos, WATER, M.Glass, F)
		river.CFrame = base * CF(0, 2.05, -D * 0.22)
		river.Transparency = 0.25
		river.CanCollide = false
		local fallH = rngC:NextNumber(45, 70)
		local edge = base * CF(0, 0, -D / 2 - 0.7)
		local fall = makePart("Waterfall", V3(10, fallH, 1), edge.Position, WATER, M.Glass, F)
		fall.CFrame = edge * CF(0, 2 - fallH / 2, 0)
		fall.Transparency = 0.35
		fall.CanCollide = false
		fall.CanQuery = false
		local a0 = Instance.new("Attachment")
		a0.Position = V3(0, fallH / 2, -0.6)
		a0.Parent = fall
		local a1 = Instance.new("Attachment")
		a1.Position = V3(0, -fallH / 2, -0.6)
		a1.Parent = fall
		local beam = Instance.new("Beam")
		beam.Attachment0, beam.Attachment1 = a0, a1
		beam.Texture = "rbxasset://textures/particles/smoke_main.dds"
		beam.TextureMode = Enum.TextureMode.Wrap
		beam.TextureLength = 10
		beam.TextureSpeed = 1.2
		beam.Width0, beam.Width1 = 10.5, 13
		beam.Color = ColorSequence.new(Color3.new(1, 1, 1), WATER)
		beam.LightEmission = 0.6
		beam.Transparency = NumberSequence.new(0.25)
		beam.FaceCamera = true
		beam.Parent = fall
		-- brume en bas de la chute
		local mist = makePart("WaterfallMist", V3(1, 1, 1), (edge * CF(0, 2 - fallH, 0)).Position, WHITE, M.SmoothPlastic, F)
		mist.Transparency = 1
		mist.CanCollide = false
		mist.CanQuery = false
		local pm = Instance.new("ParticleEmitter")
		pm.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pm.Color = ColorSequence.new(Color3.fromRGB(230, 245, 255))
		pm.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
		pm.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 9) })
		pm.Lifetime = NumberRange.new(1.5, 2.5)
		pm.Speed = NumberRange.new(2, 5)
		pm.SpreadAngle = Vector2.new(70, 70)
		pm.Rate = 8
		pm.LightInfluence = 0.5
		pm.Parent = mist
		-- gouttes qui tombent le long de la chute
		local drops = Instance.new("ParticleEmitter")
		drops.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		drops.Color = ColorSequence.new(Color3.new(1, 1, 1), WATER)
		drops.Size = NumberSequence.new(0.6)
		drops.Lifetime = NumberRange.new(1.2, 1.8)
		drops.Speed = NumberRange.new(fallH * 0.6, fallH * 0.8)
		drops.EmissionDirection = Enum.NormalId.Bottom
		drops.SpreadAngle = Vector2.new(4, 4)
		drops.Rate = 25
		drops.LightEmission = 0.6
		drops.Parent = a0
		-- cerisiers (copies de l'arbre lego, feuillage rose)
		if treeT then
			for t = 1, rngC:NextInteger(2, 3) do
				local tree = treeT:Clone()
				tree.Name = "Cerisier"
				local leafIdx = 0
				for _, p in ipairs(tree:GetDescendants()) do
					if p:IsA("BasePart") then
						p.Anchored = true
						local c = p.Color
						if c.G > c.R * 1.1 and c.G >= c.B then
							leafIdx = leafIdx + 1
							p.Color = PINKS[(leafIdx % #PINKS) + 1]
							if leafIdx % 5 == 0 then p.Material = M.Neon end
						else
							p.Color = Color3.fromRGB(95, 58, 52)
						end
					end
				end
				pcall(function() tree:ScaleTo(tree:GetScale() * rngC:NextNumber(0.85, 1.05)) end)
				local side = (t == 1) and -1 or ((t == 2) and 1 or 0)
				local spot = base * CF(side * W * 0.28, 2, (t == 3) and D * 0.25 or D * 0.1)
				tree:PivotTo(CF(spot.Position) * CFrame.Angles(0, rngC:NextNumber(0, math.pi * 2), 0))
				local cf, size = tree:GetBoundingBox()
				tree:PivotTo(tree:GetPivot() + V3(spot.X - cf.X, topY - (cf.Y - size.Y / 2), spot.Z - cf.Z))
				tree.Parent = F
				-- petales qui tombent
				local cf2, size2 = tree:GetBoundingBox()
				local pet = makePart("Petals", V3(size2.X * 0.8, 1, size2.Z * 0.8), cf2.Position + V3(0, size2.Y * 0.2, 0), WHITE, M.SmoothPlastic, F)
				pet.Transparency = 1
				pet.CanCollide = false
				pet.CanQuery = false
				local pp = Instance.new("ParticleEmitter")
				pp.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				pp.Color = ColorSequence.new(PINKS[1], PINKS[3])
				pp.Size = NumberSequence.new(0.5)
				pp.Lifetime = NumberRange.new(3, 5)
				pp.Speed = NumberRange.new(0.5, 1.5)
				pp.Acceleration = V3(0.6, -1.5, 0.3)
				pp.RotSpeed = NumberRange.new(-90, 90)
				pp.Rate = 3
				pp.LightEmission = 0.4
				pp.Parent = pet
			end
		end
	end
	makeSign(F, o + V3(0, 24, -30), "Monde 3", WORLDS[3].name, Color3.fromRGB(220, 140, 255))
end

-- ---------- PORTAILS ----------

-- Teleportation securisee. Indispensable avec StreamingEnabled : sans cela le joueur
-- arrive avant que le sol soit charge chez lui et tombe dans le vide.
local teleporting = {}

-- Une seule teleportation a la fois par joueur : le verrou n'est jamais franchi.
-- waitTurn = true (retour d'arene) : attend la fin de celle en cours ; sinon la demande est refusee.
local function safeTeleport(player, targetCF, waitTurn)
	if teleporting[player] then
		if not waitTurn then return false end
		while teleporting[player] and player.Parent do
			task.wait(0.05)
		end
		if not player.Parent then return false end
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	teleporting[player] = true
	local wasAnchored = hrp.Anchored
	hrp.Anchored = true
	pcall(function() char:PivotTo(targetCF) end)
	if workspace.StreamingEnabled then
		pcall(function() player:RequestStreamAroundAsync(targetCF.Position, 8) end)
	end
	task.wait(0.25)
	if hrp.Parent then
		hrp.AssemblyLinearVelocity = V3(0, 0, 0)
		hrp.Anchored = wasAnchored
	end
	teleporting[player] = nil
	return true
end

local function teleportToWorld(player, w)
	local o = worldOrigin[w]
	if not o then return false end
	local pos = o + V3(0, 6, 14)
	return safeTeleport(player, CFrame.lookAt(pos, o + V3(0, 6, -20)))
end

sendWorldInfo = function(player)
	local s = states[player.UserId]
	if not s then return end
	local list = {}
	for i, wd in ipairs(WORLDS) do
		list[i] = { name = wd.name, unlock = wd.unlock, rebirth = wd.rebirth or 0, unlocked = i <= (s.unlockedWorld or 1) }
	end
	WorldInfo:FireClient(player, list)
end

local function usePortal(player, target)
	local s = states[player.UserId]
	if not s then return end
	if teleporting[player] then return end -- avant tout paiement : rien ne cede entre ce test et le depart
	if _G.MWS_TutLock and _G.MWS_TutLock(player, "portal", target) then return end
	if battles[player.UserId] then
		notify(player, "Termine ton combat avant de voyager !", Color3.fromRGB(255, 120, 120))
		return
	end
	if target > s.unlockedWorld then
		if target ~= s.unlockedWorld + 1 and not TEST_MODE then -- mode test : on peut sauter un monde
			notify(player, "Debloque d'abord le monde precedent !", Color3.fromRGB(255, 120, 120))
			return
		end
		local needRb = WORLDS[target].rebirth or 0
		if (s.rebirthLevel or 0) < needRb then
			notify(player, "Il te faut " .. needRb .. " renaissance(s) pour entrer ici ! (tu en as " .. (s.rebirthLevel or 0) .. ")", Color3.fromRGB(255, 120, 120))
			return
		end
		local price = WORLDS[target].unlock
		if s.coins < price then
			notify(player, "Il te faut " .. fmt(price) .. " coins pour debloquer " .. WORLDS[target].name .. " !", Color3.fromRGB(255, 120, 120))
			return
		end
		s.coins = s.coins - price
		s.unlockedWorld = target
		notify(player, "Nouveau monde debloque : " .. WORLDS[target].name .. " !", Color3.fromRGB(255, 220, 80))
		sendState(player)
	end
	sendWorldInfo(player)
	sendNPCInfo(player)
	if teleportToWorld(player, target) then
		notify(player, "Bienvenue : " .. WORLDS[target].name, Color3.fromRGB(120, 255, 180))
		if _G.MWS_Track then _G.MWS_Track(player, "world", target) end
	end
end

local function createPortal(w, localPos, target, color)
	local F = worldFolder[w]
	local base = worldOrigin[w] + localPos
	local y0 = worldOrigin[w].Y
	local stone = Color3.fromRGB(70, 70, 90)
	for _, side in ipairs({ -1, 1 }) do
		makePart("PortalPillar", V3(4, 15, 4), V3(base.X + side * 7, y0 + 7, base.Z), stone, M.Slate, F)
		local rune = makePart("PortalRune", V3(4.2, 1.2, 4.2), V3(base.X + side * 7, y0 + 4 + (side + 1), base.Z), color, M.Neon, F)
		rune.CanCollide = false
		addDecor(w, rune, { pulse = 0.5, bobSpeed = 2 })
	end
	makePart("PortalBeam", V3(18, 3, 4), V3(base.X, y0 + 15.5, base.Z), stone, M.Slate, F)
	makePart("PortalKey", V3(3, 3, 4.2), V3(base.X, y0 + 15.5, base.Z), color, M.Neon, F).CanCollide = false

	local disc = Instance.new("Part")
	disc.Name = "PortalDisc"
	disc.Shape = Enum.PartType.Cylinder
	disc.Size = V3(0.6, 11, 11)
	disc.CFrame = CF(base.X, y0 + 7, base.Z) * CFrame.Angles(0, math.pi / 2, 0)
	disc.Color = color
	disc.Material = M.Neon
	disc.Transparency = 0.35
	disc.Anchored = true
	disc.CanCollide = false
	disc.Parent = F
	addDecor(w, disc, { pulse = 0.25, bobSpeed = 1.4 })
	local inner = Instance.new("Part")
	inner.Name = "PortalInner"
	inner.Shape = Enum.PartType.Cylinder
	inner.Size = V3(0.8, 7, 7)
	inner.CFrame = disc.CFrame
	inner.Color = WHITE
	inner.Material = M.Neon
	inner.Transparency = 0.5
	inner.Anchored = true
	inner.CanCollide = false
	inner.Parent = F
	addDecor(w, inner, { pulse = 0.3, bobSpeed = 2.4 })

	-- colonne de lumiere visible de tres loin pour trouver le portail
	local lightBeam = makePart("PortalLightBeam", V3(5, 90, 5), V3(base.X, y0 + 45, base.Z), color, M.Neon, F)
	lightBeam.Transparency = 0.82
	lightBeam.CanCollide = false
	lightBeam.CanQuery = false
	lightBeam.CanTouch = false
	addDecor(w, lightBeam, { pulse = 0.12, bobSpeed = 1 })

	local swirl = emitter(disc, color, 40, 0.6, 1.5, 4)
	swirl.SpreadAngle = Vector2.new(180, 180)
	swirl.LightEmission = 1
	local pl = Instance.new("PointLight")
	pl.Color = color
	pl.Range = 25
	pl.Brightness = 2
	pl.Parent = disc

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 320, 0, 70)
	bb.StudsOffset = V3(0, 11, 0)
	bb.MaxDistance = 200
	bb.Adornee = disc
	bb.Parent = disc
	local l1 = Instance.new("TextLabel")
	l1.Size = UDim2.new(1, 0, 0.55, 0)
	l1.BackgroundTransparency = 1
	l1.Text = ((target > w) and "-> " or "<- ") .. WORLDS[target].name
	l1.TextScaled = true
	l1.Font = Enum.Font.GothamBlack
	l1.TextColor3 = color
	l1.TextStrokeTransparency = 0.3
	l1.Parent = bb
	local l2 = Instance.new("TextLabel")
	l2.Size = UDim2.new(1, 0, 0.4, 0)
	l2.Position = UDim2.new(0, 0, 0.58, 0)
	l2.BackgroundTransparency = 1
	l2.Text = (target > w) and (fmt(WORLDS[target].unlock) .. " coins + " .. (WORLDS[target].rebirth or 0) .. " renaissance(s)") or "Retour"
	l2.TextScaled = true
	l2.Font = Enum.Font.GothamBold
	l2.TextColor3 = WHITE
	l2.TextStrokeTransparency = 0.5
	l2.Parent = bb

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = (target > w) and "Entrer / Debloquer" or "Retourner"
	prompt.ObjectText = WORLDS[target].name
	prompt.Name = "PortalPrompt"
	prompt.HoldDuration = 0.5
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 18
	prompt.Parent = disc
	prompt.Triggered:Connect(function(player)
		usePortal(player, target)
	end)
end

-- ---------- CRISTAUX ----------

local CRYSTAL_THEME = {
	{ color = Color3.fromRGB(100, 200, 255), mat = M.Ice, trans = 0.1 },
	{ color = Color3.fromRGB(255, 80, 40),   mat = M.Neon, trans = 0.05 },
	{ color = Color3.fromRGB(210, 100, 255), mat = M.Neon, trans = 0.05 },
}

-- Apparition ALEATOIRE : chaque cristal ramasse reapparait ailleurs, avec une rarete au hasard
local CRYSTAL_COUNT = { 40, 40, 40 }   -- cristaux presents en meme temps par monde
local CRYSTAL_AREA = { 175, 165, 170 }    -- rayon maximum de la zone d'apparition de chaque monde
local CRYSTAL_RESPAWN_MIN, CRYSTAL_RESPAWN_MAX = 6, 14   -- delai aleatoire avant reapparition (secondes)
local crystalRng = Random.new()

local CRYSTAL_TIERS = {
	{ name = "Cristal",       weight = 78, mult = 1,  tint = nil },
	{ name = "Cristal dore",  weight = 17, mult = 5,  tint = Color3.fromRGB(255, 215, 70) },
	{ name = "Cristal royal", weight = 5,  mult = 25, tint = Color3.fromRGB(255, 90, 255) },
}

local function rollCrystalTier()
	local total = 0
	for _, t in ipairs(CRYSTAL_TIERS) do total = total + t.weight end
	local roll = crystalRng:NextNumber() * total
	for _, t in ipairs(CRYSTAL_TIERS) do
		roll = roll - t.weight
		if roll <= 0 then return t end
	end
	return CRYSTAL_TIERS[1]
end

-- zones interdites (oeufs, dresseurs, spawn, volcan, lave) : les cristaux ne bloquent rien
local crystalKeepOut = {}

local function buildCrystalKeepOut()
	if crystalKeepOut[1] then return end
	for w = 1, #WORLDS do
		local o = worldOrigin[w]
		local list = { { pos = o, r = 14 }, { pos = o + V3(-48, 0, -35), r = 18 } }   -- spawn + machine de fusion
		local eggsHere = {}
		for _, def in ipairs(EGGS) do
			if def.world == w then table.insert(eggsHere, def) end
		end
		for j = 1, #eggsHere do
			table.insert(list, { pos = o + V3(18, 0, (j - (#eggsHere + 1) / 2) * 20), r = 13 })
		end
		for _, npc in ipairs(NPC_TRAINERS) do
			if npc.world == w then table.insert(list, { pos = o + npc.offset, r = npc.boss and 22 or 12 }) end
		end
		if TRAIN_PAD_CENTER[w] then table.insert(list, { pos = o + TRAIN_PAD_CENTER[w], r = 34 }) end
		crystalKeepOut[w] = list
	end
	if volcanoPos then
		table.insert(crystalKeepOut[2], { pos = volcanoPos, r = 95 })
	end
	for _, p in ipairs({ V3(110, 0, 110), V3(-110, 0, 130), V3(130, 0, -80), V3(0, 0, -100), V3(-60, 0, 60), V3(170, 0, 20) }) do
		table.insert(crystalKeepOut[2], { pos = worldOrigin[2] + p, r = 16 })
	end
end

local function crystalSpotOk(w, pos, ignore)
	local flat = V3(pos.X, 0, pos.Z)
	for _, k in ipairs(crystalKeepOut[w]) do
		if (flat - V3(k.pos.X, 0, k.pos.Z)).Magnitude < k.r then return false end
	end
	for _, c in ipairs(crystals) do
		if c ~= ignore and c.world == w and not c.busy and c.pos then
			if (flat - V3(c.pos.X, 0, c.pos.Z)).Magnitude < 9 then return false end
		end
	end
	return true
end

local function randomCrystalPos(w, ignore)
	local o = worldOrigin[w]
	for _ = 1, 40 do
		local a = crystalRng:NextNumber() * math.pi * 2
		local r = 10 + math.sqrt(crystalRng:NextNumber()) * (CRYSTAL_AREA[w] - 10)
		local pos = o + V3(math.cos(a) * r, 0, math.sin(a) * r)
		if crystalSpotOk(w, pos, ignore) then return pos end
	end
	return nil
end

local function applyCrystalTier(info, tier)
	info.tier = tier
	info.reward = WORLDS[info.world].crystalReward * tier.mult
	for part, col in pairs(info.baseColor) do
		if tier.tint then
			part.Color = col:Lerp(tier.tint, 0.75)
			part.Material = M.Neon
		else
			part.Color = col
			part.Material = info.baseMat[part]
		end
	end
	info.emitter.Color = ColorSequence.new(tier.tint or CRYSTAL_THEME[info.world].color)
	info.emitter.Rate = tier.tint and 10 or 2
	info.label.Enabled = tier.tint ~= nil
	info.labelText.Text = tier.name .. " x" .. tier.mult
	if tier.tint then info.labelText.TextColor3 = tier.tint end
end

local function placeCrystal(info, pos)
	local base = CF(pos + V3(0, 3, 0)) * CFrame.Angles(0, math.rad(crystalRng:NextInteger(0, 90)), 0)
	info.pos = pos
	info.decor.base = base
	info.root.CFrame = base
end

local function setCrystalVisible(info, visible)
	for part, orig in pairs(info.trans) do
		if visible then
			TweenService:Create(part, TweenInfo.new(0.5), { Transparency = orig }):Play()
		else
			part.Transparency = 1
		end
	end
	info.decor.paused = not visible
	info.emitter.Enabled = visible
end

local function collectCrystal(info, player, byPet)
	if info.busy then return end
	local s = states[player.UserId]
	if not s then return end
	if (s.unlockedWorld or 1) < info.world then return end -- la position du personnage n'autorise pas le gain
	info.busy = true
	local mult = 1 + (s.rebirthLevel or 0) * 0.5
	local petBonus = 1
	for _, pet in ipairs(getEquippedPets(s)) do
		local pi = PETS[pet.name]
		if pi then petBonus = petBonus + pi.multiplier * 0.05 end
	end
	local reward = math.floor(info.reward * mult * petBonus * (s.coinMult or 1))
	s.coins = s.coins + reward
	sendState(player)
	if _G.MWS_Track then _G.MWS_Track(player, "crystal") end
	popText(worldFolder[info.world], info.root.Position + V3(0, 3, 0), "+" .. fmt(reward), byPet and Color3.fromRGB(255, 220, 80) or WHITE)
	info.emitter:Emit(25)
	setCrystalVisible(info, false)
	task.delay(crystalRng:NextNumber(CRYSTAL_RESPAWN_MIN, CRYSTAL_RESPAWN_MAX), function()
		-- reapparait a un NOUVEL endroit aleatoire, avec une rarete tiree au hasard
		local pos = randomCrystalPos(info.world, info)
		if pos then placeCrystal(info, pos) end
		applyCrystalTier(info, rollCrystalTier())
		setCrystalVisible(info, true)
		info.busy = false
	end)
end

local function createCrystals(w, avoid)
	local o = worldOrigin[w]
	local th = CRYSTAL_THEME[w]
	local F = worldFolder[w]
	buildCrystalKeepOut()
	for i = 1, CRYSTAL_COUNT[w] do
		local pos = randomCrystalPos(w, nil)
		if pos then
			local P, root = newProp(F, "Crystal" .. i, "b", V3(1, 1, 1), pos + V3(0, 3, 0), th.color, th.mat, 1)
			root.CFrame = CF(pos + V3(0, 3, 0)) * CFrame.Angles(0, math.rad(45), 0)
			-- eclat : colonne + pointe faite de deux biseaux qui se rejoignent au milieu
			local function shard(cf, w, h, col)
				add(P, nil, "Shard", "b", V3(w, h, w), cf, col, th.mat, nil, th.trans)
				local tipH = w * 1.2
				for _, front in ipairs({ true, false }) do
					local wd = Instance.new("WedgePart")
					wd.Name = "ShardTip"
					wd.Size = V3(w, tipH, w / 2)
					wd.Color = col
					wd.Material = th.mat or M.SmoothPlastic
					wd.Transparency = th.trans or 0
					wd.CanCollide = false
					wd.CanQuery = false
					wd.Massless = true
					wd.TopSurface = Enum.SurfaceType.Smooth
					wd.BottomSurface = Enum.SurfaceType.Smooth
					local off = cf * CF(0, h / 2 + tipH / 2, front and -w / 4 or w / 4) * (front and CF() or CFrame.Angles(0, math.pi, 0))
					local wl = Instance.new("Weld")
					wl.Part0 = root
					wl.Part1 = wd
					wl.C0 = off
					wl.Parent = wd
					wd.Parent = P.model
				end
			end
			shard(CF(0, -0.4, 0), 1.3, 3, th.color)
			for k = 0, 3 do
				local a = k * math.pi / 2 + 0.4
				local tilt = CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.rad(-28))
				shard(CF(math.cos(a) * 0.75, -1.3, math.sin(a) * 0.75) * tilt, 0.75, 1.6 + (k % 2) * 0.5,
					(k % 2 == 0) and th.color:Lerp(WHITE, 0.25) or th.color:Lerp(BLACK, 0.15))
			end
			add(P, nil, "Glow", "o", V3(0.9, 0.9, 0.9), CF(0, -0.6, 0), WHITE, M.Neon, nil, 0.35)
			local pe = emitter(root, th.color, 2, 0.35, 1.5, 1.5)
			pe.SpreadAngle = Vector2.new(180, 180)
			pe.LightEmission = 1
			local d = addDecor(w, root, { bob = 0.6, bobSpeed = 1.6, spin = 0.7 })
			local info = {
				model = P.model, root = root, world = w, reward = WORLDS[w].crystalReward,
				busy = false, decor = d, emitter = pe, trans = {}, baseColor = {}, baseMat = {}, pos = pos
			}
			for _, part in ipairs(P.model:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanTouch = true
					info.trans[part] = part.Transparency
						info.baseColor[part] = part.Color
						info.baseMat[part] = part.Material
					part.Touched:Connect(function(hit)
						local ch = hit.Parent
						local hum = ch and ch:FindFirstChildOfClass("Humanoid")
						local pl = hum and Players:GetPlayerFromCharacter(ch)
						if pl then collectCrystal(info, pl, false) end
					end)
				end
			end
			-- etiquette de rarete (visible seulement pour les cristaux rares)
				local lbb = Instance.new("BillboardGui")
				lbb.Size = UDim2.new(0, 160, 0, 30)
				lbb.StudsOffset = V3(0, 4, 0)
				lbb.AlwaysOnTop = true
				lbb.MaxDistance = 120
				lbb.Enabled = false
				lbb.Adornee = root
				lbb.Parent = root
				local ltxt = Instance.new("TextLabel")
				ltxt.Size = UDim2.new(1, 0, 1, 0)
				ltxt.BackgroundTransparency = 1
				ltxt.Font = Enum.Font.GothamBlack
				ltxt.TextSize = 16
				ltxt.TextStrokeTransparency = 0.3
				ltxt.TextColor3 = WHITE
				ltxt.Parent = lbb
				info.label = lbb
				info.labelText = ltxt
				applyCrystalTier(info, rollCrystalTier())
				table.insert(crystals, info)
		end
	end
end

-- ---------- OEUFS + ANIMATION D'ECLOSION ----------

local function playHatch(eggIndex, pet)
	local e = eggParts[eggIndex]
	if not e or e.busy then return end
	e.busy = true
	local root = e.root
	local d = e.decor
	d.paused = true
	local base = d.base
	local info = PETS[pet.name]
	local rar = rarityInfo(info.rarity)
	local F = worldFolder[EGGS[eggIndex].world]

	-- secousses
	for i = 1, 12 do
		local k = (i % 2 == 0) and 1 or -1
		root.CFrame = base * CF(0, 0.3 + i * 0.03, 0) * CFrame.Angles(0, 0, k * math.rad(5 + i * 1.6))
		task.wait(0.07)
	end
	root.CFrame = base

	-- flash + eclats de coquille
	local flash = Instance.new("Part")
	flash.Shape = Enum.PartType.Ball
	flash.Size = V3(3, 3, 3)
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanTouch = false
	flash.CanQuery = false
	flash.Material = M.Neon
	flash.Color = rar.color
	flash.Position = base.Position
	flash.Parent = F
	TweenService:Create(flash, TweenInfo.new(0.6), { Size = V3(22, 22, 22), Transparency = 1 }):Play()
	Debris:AddItem(flash, 0.8)
	for part in pairs(e.trans) do part.Transparency = 1 end
	for i = 1, 10 do
		local shard = Instance.new("Part")
		shard.Size = V3(0.8, 0.5, 1.1)
		shard.Color = e.color
		shard.Material = M.Neon
		shard.Anchored = true
		shard.CanCollide = false
		shard.CanTouch = false
		shard.CanQuery = false
		shard.Position = base.Position
		shard.Parent = F
		local dir = V3(math.random() - 0.5, math.random() * 0.8 + 0.2, math.random() - 0.5).Unit
		TweenService:Create(shard, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = base.Position + dir * math.random(6, 11), Transparency = 1,
			Orientation = V3(math.random(0, 360), math.random(0, 360), math.random(0, 360))
		}):Play()
		Debris:AddItem(shard, 1)
	end

	-- apparition du pet
	local model, proot, P = createPetModel(pet.name, true, 1.5)
	proot.CFrame = CF(base.Position + V3(0, 1.5, 0))
	model.Parent = F
	staticAnimators[model] = P.anims
	local burst = emitter(proot, rar.color, 0, 0.9, 1.4, 9)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.LightEmission = 1
	burst:Emit(45)

	-- etiquette sobre et lisible : fond sombre, nom en blanc, rarete en petit
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 190, 0, 46)
	bb.StudsOffset = V3(0, 4 + P.scale * 2, 0)
	bb.MaxDistance = 70
	bb.Adornee = proot
	bb.Parent = proot
	local bgf = Instance.new("Frame")
	bgf.Size = UDim2.new(1, 0, 1, 0)
	bgf.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
	bgf.BackgroundTransparency = 0.25
	bgf.Parent = bb
	local bgc = Instance.new("UICorner")
	bgc.CornerRadius = UDim.new(0, 10)
	bgc.Parent = bgf
	local nameL = Instance.new("TextLabel")
	nameL.Size = UDim2.new(1, 0, 0.58, 0)
	nameL.BackgroundTransparency = 1
	nameL.Text = pet.name
	nameL.TextSize = 18
	nameL.Font = Enum.Font.GothamBold
	nameL.TextColor3 = WHITE
	nameL.Parent = bgf
	local rarL = Instance.new("TextLabel")
	rarL.Size = UDim2.new(1, 0, 0.4, 0)
	rarL.Position = UDim2.new(0, 0, 0.55, 0)
	rarL.BackgroundTransparency = 1
	rarL.Text = info.rarity
	rarL.TextSize = 14
	rarL.Font = Enum.Font.GothamMedium
	rarL.TextColor3 = rar.color:Lerp(WHITE, 0.35)
	rarL.Parent = bgf

	local t0 = os.clock()
	while os.clock() - t0 < 3.2 do
		local k = math.clamp((os.clock() - t0) / 0.8, 0, 1)
		local ease = 1 - (1 - k) * (1 - k)
		proot.CFrame = CF(base.Position + V3(0, 1.5 + 3.5 * ease, 0)) * CFrame.Angles(0, (os.clock() - t0) * 2, 0)
		task.wait(0.03)
	end
	model:Destroy()
	staticAnimators[model] = nil

	for part, orig in pairs(e.trans) do part.Transparency = orig end
	d.paused = false
	e.busy = false
end

local function createEggsForWorld(w)
	local o = worldOrigin[w]
	local F = worldFolder[w]
	local list = {}
	for i, def in ipairs(EGGS) do
		if def.world == w then table.insert(list, i) end
	end
	for j, eggIndex in ipairs(list) do
		local def = EGGS[eggIndex]
		local offsetZ = (j - (#list + 1) / 2) * 20
		local standPos = o + V3(26, 0, offsetZ * 1.2)
		local eggColor = colorFromTable(def.color)

		local base = makeCyl("EggStand_" .. eggIndex, 1.2, 8, standPos + V3(0, 0.1, 0), def.standColor, M.Slate, F)
		local ring = makeCyl("EggRing_" .. eggIndex, 0.3, 8.6, standPos + V3(0, 0.75, 0), eggColor, M.Neon, F)
		ring.CanCollide = false
		addDecor(w, ring, { pulse = 0.4, bobSpeed = 2 })

		-- oeuf en briques lego, un style par oeuf (MWS_EggModels)
		local eggModel, root = EggModels.build(def.style, { k = 1.15 })
		eggModel.Name = "EggDeco_" .. eggIndex
		root.CFrame = CF(standPos + V3(0, 4.2, 0))
		eggModel.Parent = F
		local P = { model = eggModel }
		local pe = emitter(root, eggColor, 6, 0.4, 2, 2)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.LightEmission = 1
		local pl = Instance.new("PointLight")
		pl.Color = eggColor
		pl.Range = 14
		pl.Brightness = 1.5
		pl.Parent = root
		local d = addDecor(w, root, { bob = 0.5, bobSpeed = 1.5, spin = 0.8 })

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 220, 0, 50)
		bb.StudsOffset = V3(0, 5.5, 0)
		bb.MaxDistance = 90
		bb.Adornee = root
		bb.Parent = root
		local nl = Instance.new("TextLabel")
		nl.Size = UDim2.new(1, 0, 0.55, 0)
		nl.BackgroundTransparency = 1
		nl.Text = def.name
		nl.TextScaled = true
		nl.Font = Enum.Font.GothamBlack
		nl.TextColor3 = eggColor
		nl.TextStrokeTransparency = 0.3
		nl.Parent = bb
		local pl2 = Instance.new("TextLabel")
		pl2.Size = UDim2.new(1, 0, 0.4, 0)
		pl2.Position = UDim2.new(0, 0, 0.58, 0)
		pl2.BackgroundTransparency = 1
		pl2.Text = fmt(def.price) .. " Coins"
		pl2.TextScaled = true
		pl2.Font = Enum.Font.GothamBold
		pl2.TextColor3 = Color3.fromRGB(255, 230, 120)
		pl2.TextStrokeTransparency = 0.4
		pl2.Parent = bb

		local transTable = {}
		for _, part in ipairs(P.model:GetDescendants()) do
			if part:IsA("BasePart") then transTable[part] = part.Transparency end
		end
		eggParts[eggIndex] = { root = root, decor = d, trans = transTable, color = eggColor }

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "BuyEggPrompt_" .. eggIndex
		prompt.ActionText = "Acheter (" .. fmt(def.price) .. " Coins)"
		prompt.ObjectText = def.name
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.HoldDuration = 0.25
		prompt.MaxActivationDistance = 16
		prompt.RequiresLineOfSight = false
		prompt.Enabled = true
		prompt.Style = Enum.ProximityPromptStyle.Default
		prompt.Parent = base

		local lastBuy = {}
		prompt.Triggered:Connect(function(player)
			local s = states[player.UserId]
			if not s then return end
			if lastBuy[player] and os.clock() - lastBuy[player] < 0.6 then return end
			-- une seule eclosion a la fois : on attend la fin de l'animation en cours
			if s.hatchBusyUntil and os.clock() < s.hatchBusyUntil then return end
			if _G.MWS_TutLock and _G.MWS_TutLock(player, "egg", eggIndex) then return end
			lastBuy[player] = os.clock()
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local playerWorld = hrp and worldOfPosition(hrp.Position)
			if not hrp or playerWorld ~= def.world or (s.unlockedWorld or 1) < def.world then
				notify(player, "Tu dois etre dans le monde debloque correspondant pour acheter cet oeuf.", Color3.fromRGB(255, 120, 120))
				return
			end
			if s.coins < def.price then
				BuyEgg:FireClient(player, { success = false, message = "Pas assez de coins ! (" .. def.price .. " requis)" })
				notify(player, "Pas assez de coins ! (" .. fmt(def.price) .. " requis)", Color3.fromRGB(255, 120, 120))
				return
			end
			if #s.pets >= MAX_PETS then
				BuyEgg:FireClient(player, { success = false, message = "Inventaire plein !" })
				notify(player, "Inventaire plein !", Color3.fromRGB(255, 120, 120))
				return
			end
			s.coins = s.coins - def.price
			local newPet = rollPet(s, def.pool)
			local strong = def.style == "lave" or def.style == "primordial" or newPet.rarity == "Divin" or newPet.rarity == "Secret"
			local medium = def.style == "mythique" or def.style == "celeste"
			s.hatchBusyUntil = os.clock() + (strong and 7.5 or (medium and 5.5 or 4.3))
			table.insert(s.pets, newPet)
			if _G.MWS_Track then
				_G.MWS_Track(player, "pet", newPet.name)
				_G.MWS_Track(player, "egg")
			end
			-- l'animation d'eclosion se joue chez le joueur, sur le socle ; le nom du pet
			-- n'apparait qu'a la fin de l'animation (plus de message envoye trop tot)
			local e = eggParts[eggIndex]
			BuyEgg:FireClient(player, { success = true, pet = newPet, eggName = def.name, style = def.style, eggIndex = eggIndex,
				eggPos = e and e.decor and e.decor.base.Position })
			sendState(player)
		end)
	end
end

-- ---------- DRESSEURS DANS LE MONDE ----------

local function createNPCs()
	local BossDialog = getRemote("BossDialog")
	for i, npc in ipairs(NPC_TRAINERS) do
		local o = worldOrigin[npc.world]
		local pos = o + npc.offset + V3(0, 2.1, 0)
		local model, root, head, P = createTrainerModel(npc, 1)
		root.CFrame = CFrame.lookAt(pos, V3(o.X, pos.Y, o.Z))
		model.Name = "NPC_" .. i
		model.Parent = worldFolder[npc.world]
		staticAnimators[model] = P.anims

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 220, 0, 50)
		bb.StudsOffset = V3(0, 3.2, 0)
		bb.MaxDistance = npc.boss and 220 or 80
		bb.Adornee = head
		bb.Parent = head
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, 0, 0, 25)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = npc.name
		nameLabel.TextColor3 = WHITE
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 16
		nameLabel.TextStrokeTransparency = 0.4
		nameLabel.Parent = bb
		local info = Instance.new("TextLabel")
		info.Size = UDim2.new(1, 0, 0, 18)
		info.Position = UDim2.new(0, 0, 0, 28)
		info.BackgroundTransparency = 1
		info.Text = #npc.pets .. " monstres - " .. fmt(npc.reward) .. " coins"
		info.TextColor3 = Color3.fromRGB(220, 220, 220)
		info.Font = Enum.Font.Gotham
		info.TextSize = 12
		info.TextStrokeTransparency = 0.5
		info.Parent = bb

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Combattre le monstre"
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.ObjectText = npc.name
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = npc.boss and (12 + (npc.height or 30) * 0.4) or 15
		prompt.Parent = root
		local npcIndex = i
		prompt.Triggered:Connect(function(player)
			if _G.MWS_TutLock and _G.MWS_TutLock(player, "battle", npcIndex) then return end
			-- le boss parle d'abord : le client relance le combat par BattleRequest
			if npc.lines and not battles[player.UserId] then
				BossDialog:FireClient(player, npcIndex)
			else
				startBattle(player, npcIndex)
			end
		end)
	end
end

-- ============================================================
-- ARENES (une par combat en cours : plusieurs joueurs en meme temps)
-- ============================================================

local function buildArenaSlot(i)
	local origin = ARENA_BASE + V3((i - 1) * 120, 0, 0)
	local folder = Instance.new("Folder")
	folder.Name = "MWS_Arena_" .. i
	folder.Parent = workspace
	local floor = makePart("ArenaFloor", V3(60, 2, 60), origin + V3(0, -1, 0), Color3.fromRGB(80, 80, 90), M.Slate, folder)
	local ring = makePart("ArenaRing", V3(56, 0.5, 56), origin + V3(0, 0.5, 0), Color3.fromRGB(200, 180, 60), M.Neon, folder)
	ring.CanCollide = false
	for k = 1, 4 do
		local a = ((k - 0.5) / 4) * math.pi * 2
		makePart("ArenaPillar" .. k, V3(3, 14, 3), origin + V3(math.cos(a) * 27, 7, math.sin(a) * 27), Color3.fromRGB(60, 60, 70), M.Slate, folder)
	end
	makeWalls(folder, origin, 29, 20)
	return { origin = origin, folder = folder, floor = floor, ring = ring, inUse = false }
end

local function acquireArena(w)
	local slot = nil
	for i = 1, 60 do
		if not arenaSlots[i] then arenaSlots[i] = buildArenaSlot(i) end
		if not arenaSlots[i].inUse then
			slot = arenaSlots[i]
			break
		end
	end
	if not slot then return nil end
	slot.inUse = true
	local th = ARENA_THEME[w] or ARENA_THEME[1]
	slot.floor.Color = th.floor
	slot.floor.Material = th.mat
	slot.ring.Color = th.ring
	return slot
end

local function hitBurst(folder, pos, color)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Ball
	p.Size = V3(2, 2, 2)
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Material = M.Neon
	p.Color = color
	p.Position = pos
	p.Parent = folder
	TweenService:Create(p, TweenInfo.new(0.35), { Size = V3(9, 9, 9), Transparency = 1 }):Play()
	Debris:AddItem(p, 0.45)
end

local function spawnAttackEffect(folder, effectName, startPos, endPos, color)
	if effectName == "FireSlash" then
		local slash = Instance.new("Part")
		slash.Anchored = true
		slash.CanCollide = false
		slash.CanTouch = false
		slash.CanQuery = false
		slash.Material = M.Neon
		slash.Color = color
		slash.Size = V3(0.5, 8, 0.5)
		slash.CFrame = CFrame.lookAt(startPos, endPos) * CF(0, 0, -3)
		slash.Parent = folder
		TweenService:Create(slash, TweenInfo.new(0.35), { Size = V3(6, 12, 6), Transparency = 1, CFrame = slash.CFrame * CFrame.Angles(0, math.rad(45), 0) }):Play()
		Debris:AddItem(slash, 0.5)
		local fire = Instance.new("Part")
		fire.Anchored = true
		fire.CanCollide = false
		fire.CanTouch = false
		fire.CanQuery = false
		fire.Material = M.Neon
		fire.Color = Color3.fromRGB(255, 150, 50)
		fire.Size = V3(4, 4, 4)
		fire.Shape = Enum.PartType.Ball
		fire.Position = endPos
		fire.Parent = folder
		TweenService:Create(fire, TweenInfo.new(0.5), { Size = V3(11, 11, 11), Transparency = 1 }):Play()
		Debris:AddItem(fire, 0.6)
	elseif effectName == "IceStorm" then
		for i = 1, 8 do
			local shard = Instance.new("Part")
			shard.Anchored = true
			shard.CanCollide = false
			shard.CanTouch = false
			shard.CanQuery = false
			shard.Material = M.Ice
			shard.Color = Color3.fromRGB(150, 220, 255)
			shard.Size = V3(2, 6, 2)
			shard.Position = endPos + V3(math.random(-4, 4), math.random(6, 11), math.random(-4, 4))
			shard.Parent = folder
			TweenService:Create(shard, TweenInfo.new(0.4), { Position = endPos, Size = V3(4, 8, 4), Transparency = 1 }):Play()
			Debris:AddItem(shard, 0.5)
		end
		local circle = Instance.new("Part")
		circle.Anchored = true
		circle.CanCollide = false
		circle.CanTouch = false
		circle.CanQuery = false
		circle.Material = M.Ice
		circle.Color = Color3.fromRGB(100, 200, 255)
		circle.Size = V3(1, 0.2, 1)
		circle.Position = endPos - V3(0, 2, 0)
		circle.Parent = folder
		TweenService:Create(circle, TweenInfo.new(0.5), { Size = V3(14, 0.2, 14), Transparency = 1 }):Play()
		Debris:AddItem(circle, 0.6)
	elseif effectName == "DivineStrike" then
		local col = Instance.new("Part")
		col.Anchored = true
		col.CanCollide = false
		col.CanTouch = false
		col.CanQuery = false
		col.Material = M.Neon
		col.Color = color
		col.Shape = Enum.PartType.Cylinder
		col.Size = V3(2, 2, 20)
		col.CFrame = CF(endPos + V3(0, 8, 0)) * CFrame.Angles(0, 0, math.rad(90))
		col.Parent = folder
		TweenService:Create(col, TweenInfo.new(0.6), { Size = V3(30, 12, 12), Transparency = 1 }):Play()
		Debris:AddItem(col, 0.7)
		for i = 1, 3 do
			task.delay(i * 0.1, function()
				local ring = Instance.new("Part")
				ring.Anchored = true
				ring.CanCollide = false
				ring.CanTouch = false
				ring.CanQuery = false
				ring.Material = M.Neon
				ring.Color = Color3.fromRGB(255, 240, 100)
				ring.Shape = Enum.PartType.Ball
				ring.Size = V3(2, 2, 2)
				ring.Position = endPos
				ring.Parent = folder
				TweenService:Create(ring, TweenInfo.new(0.4), { Size = V3(16, 16, 16), Transparency = 1 }):Play()
				Debris:AddItem(ring, 0.5)
			end)
		end
	end
end

-- ------------------------------------------------------------
-- EFFETS D'ATTAQUE : l'element depend du pet, la taille depend de la puissance (1 a 5)
-- ------------------------------------------------------------
local PET_ELEMENT = {
	["Phenix"] = "fire", ["Dragon de lave"] = "fire", ["Taureau de feu"] = "fire", ["Salamandre"] = "fire", ["Cerbere"] = "fire",
	["Dragon de glace"] = "ice", ["Hibou des neiges"] = "ice", ["Yeti"] = "ice", ["Mammouth"] = "ice",
	["Dragon des ombres"] = "shadow", ["Dragon du vide"] = "shadow", ["Roi serpent"] = "shadow",
	["Dragon cosmique"] = "cosmic", ["Dragon lunaire"] = "cosmic", ["Licorne"] = "cosmic", ["Pegase"] = "cosmic", ["Kitsune"] = "cosmic",
	["Dragon primordial"] = "divine",
}
local ELEMENT_FX = {
	fire   = { main = Color3.fromRGB(255, 110, 30),  light = Color3.fromRGB(255, 220, 90),  tex = "rbxasset://textures/particles/fire_main.dds" },
	ice    = { main = Color3.fromRGB(110, 200, 255), light = Color3.fromRGB(230, 250, 255), tex = "rbxasset://textures/particles/sparkles_main.dds" },
	shadow = { main = Color3.fromRGB(140, 50, 210),  light = Color3.fromRGB(60, 15, 90),    tex = "rbxasset://textures/particles/smoke_main.dds" },
	cosmic = { main = Color3.fromRGB(110, 140, 255), light = Color3.fromRGB(255, 240, 160), tex = "rbxasset://textures/particles/sparkles_main.dds" },
	nature = { main = Color3.fromRGB(110, 225, 90),  light = Color3.fromRGB(240, 255, 200), tex = "rbxasset://textures/particles/sparkles_main.dds" },
	divine = { main = Color3.fromRGB(255, 215, 90),  light = Color3.fromRGB(255, 255, 235), tex = "rbxasset://textures/particles/sparkles_main.dds" },
}

local function fxPart(folder, size, color, shape, cf)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Material = M.Neon
	p.Color = color
	if shape then p.Shape = shape end
	p.Size = size
	p.CFrame = cf
	p.Parent = folder
	return p
end

local function fxGrowFade(p, size, t, extra)
	local goal = { Size = size, Transparency = 1 }
	if extra then for k, v in pairs(extra) do goal[k] = v end end
	TweenService:Create(p, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
	Debris:AddItem(p, t + 0.1)
end

local function fxBurst(parent, fx, count, size, speed)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = fx.tex
	pe.Color = ColorSequence.new(fx.light, fx.main)
	pe.LightEmission = 0.8
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(0.4, 0.8)
	pe.Speed = NumberRange.new(speed * 0.5, speed)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Rate = 0
	pe.Parent = parent
	pe:Emit(count)
end

local function elementOf(name)
	return PET_ELEMENT[name] or "nature"
end

-- temps entre le lancement d'une attaque et l'impact (doit suivre la camera cote client)
local function impactDelay(power)
	if power >= 4 then return 1.75 elseif power >= 3 then return 0.85 end
	return 0.5
end

local TEX = {
	fire = "rbxasset://textures/particles/fire_main.dds",
	spark = "rbxasset://textures/particles/sparkles_main.dds",
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	core = "rbxasset://textures/particles/explosion01_core_main.dds",
	shock = "rbxasset://textures/particles/explosion01_shockwave_main.dds",
	implode = "rbxasset://textures/particles/explosion01_implosion_main.dds",
	glow = "rbxasset://textures/particles/forcefield_glow_main.dds",
}

-- point invisible qui emet des particules (count = rafale, rate/dur = flux continu)
local function emitAt(folder, pos, o)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanTouch = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = o.area or V3(1, 1, 1)
	holder.CFrame = CF(pos)
	holder.Parent = folder
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = o.tex
	pe.Color = ColorSequence.new(o.c1, o.c2 or o.c1)
	pe.LightEmission = o.light or 0.8
	pe.LightInfluence = 0
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, o.size0 or o.size), NumberSequenceKeypoint.new(1, o.size1 or 0) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, o.trans or 0.1), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime = NumberRange.new(o.life * 0.7, o.life)
	pe.Speed = NumberRange.new(o.speed * 0.5, o.speed)
	pe.SpreadAngle = o.spread or Vector2.new(180, 180)
	pe.Acceleration = o.accel or V3(0, 0, 0)
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-(o.rot or 60), o.rot or 60)
	pe.Drag = o.drag or 0
	if o.dir then pe.EmissionDirection = o.dir end
	if o.area then pe.Shape = Enum.ParticleEmitterShape.Box end
	pe.Rate = o.rate or 0
	pe.Parent = holder
	if o.count then pe:Emit(o.count) end
	local dur = o.dur or 0
	if dur > 0 then task.delay(dur, function() pe.Enabled = false end) else pe.Enabled = false end
	Debris:AddItem(holder, dur + o.life + 0.3)
	return holder, pe
end

-- pic de glace pointu : colonne + pointe en deux biseaux, sort du sol puis se brise
local function iceSpike(folder, groundPos, h, w, lean)
	local col = Color3.fromRGB(175, 225, 255)
	local parts = {}
	local function mk(cls, size, cf)
		local p = Instance.new(cls)
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
		p.Material = M.Glass
		p.Color = col
		p.Transparency = 0.15
		p.Reflectance = 0.2
		p.Size = size
		p.CFrame = cf
		p.Parent = folder
		table.insert(parts, p)
		return p
	end
	local base = CF(groundPos) * lean
	local tipH = w * 1.6
	local final = {
		{ "Part", V3(w, h, w), CF(0, h / 2, 0) },
		{ "WedgePart", V3(w, tipH, w / 2), CF(0, h + tipH / 2, -w / 4) },
		{ "WedgePart", V3(w, tipH, w / 2), CF(0, h + tipH / 2, w / 4) * CFrame.Angles(0, math.pi, 0) },
	}
	for _, f in ipairs(final) do
		local p = mk(f[1], f[2], base * CF(0, -(h + tipH), 0) * f[3])
		TweenService:Create(p, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = base * f[3] }):Play()
	end
	return parts
end

-- temps entre le lancement d'une attaque et l'impact (doit suivre la camera cote client)
local function impactDelay(power)
	if power >= 4 then return 1.75 elseif power >= 3 then return 0.85 end
	return 0.5
end

-- attaque animee : charge (l'energie converge), projectile(s) avec trainee de particules,
-- impact propre a l'element, onde de choc. power 4-5 = longue charge filmee par la camera.
-- position de la bouche d'un pet du combat (sinon le centre)
local function mouthOf(vis)
	local rig = vis and vis.rig
	if rig and rig.part and rig.part.Parent then
		return (rig.part.CFrame * CF(rig.mouth)).Position
	end
	return vis and vis.root and vis.root.Position or V3(0, 0, 0)
end

local function setHeadPitch(vis, deg)
	local head = vis and vis.rig and vis.rig.head
	if head then head.post = (deg ~= 0) and CFrame.Angles(math.rad(deg), 0, 0) or nil end
end

local function playAttackFx(folder, fromVis, toPos, element, power)
	local fx = ELEMENT_FX[element] or ELEMENT_FX.nature
	power = math.clamp(power or 1, 1, 5)
	local cine = power >= 4
	local fromPos = mouthOf(fromVis)
	task.spawn(function()
		local chargeT = cine and 1.2 or (power >= 3 and 0.4 or 0.1)
		local travel = cine and 0.5 or 0.38
		local tex = (element == "fire") and TEX.fire or ((element == "shadow") and TEX.smoke or TEX.spark)
		-- 1) charge
		if cine then
			-- attaque ultime : le pet leve la tete, une boule de l'element grossit dans sa gueule
			local orb = fxPart(folder, V3(0.3, 0.3, 0.3), fx.light, Enum.PartType.Ball, CF(fromPos))
			orb.Transparency = 0.05
			local inner = Instance.new("ParticleEmitter")
			inner.Texture = tex
			inner.Color = ColorSequence.new(fx.light, fx.main)
			inner.LightEmission = 0.9
			inner.LightInfluence = 0
			inner.Shape = Enum.ParticleEmitterShape.Sphere
			inner.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward
			inner.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
			inner.Lifetime = NumberRange.new(0.25, 0.4)
			inner.Speed = NumberRange.new(8, 12)
			inner.Rate = 150
			inner.Parent = orb
			local flames = Instance.new("ParticleEmitter")
			flames.Texture = tex
			flames.Color = ColorSequence.new(fx.light, fx.main)
			flames.LightEmission = 0.9
			flames.LightInfluence = 0
			flames.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0) })
			flames.Lifetime = NumberRange.new(0.2, 0.35)
			flames.Speed = NumberRange.new(1, 3)
			flames.SpreadAngle = Vector2.new(180, 180)
			flames.Rate = 80
			flames.Parent = orb
			local light = Instance.new("PointLight")
			light.Color = fx.main
			light.Range = 14
			light.Brightness = 3
			light.Parent = orb
			local t0 = os.clock()
			while os.clock() - t0 < chargeT do
				local k = (os.clock() - t0) / chargeT
				setHeadPitch(fromVis, 38 * math.min(1, k / 0.35))
				local sz = 0.4 + 2.4 * k * (power / 4)
				orb.Size = V3(sz, sz, sz)
				local fwd = fromVis and fromVis.root and fromVis.root.CFrame.LookVector or V3(0, 0, 0)
				orb.CFrame = CF(mouthOf(fromVis) + fwd * sz * 0.45)
				task.wait()
			end
			-- la tete s'abaisse d'un coup et crache la boule
			setHeadPitch(fromVis, -14)
			task.delay(0.5, function() setHeadPitch(fromVis, 0) end)
			if fromVis then fromVis.lungeStart = os.clock() end
			inner.Enabled = false
			flames.Enabled = false
			light:Destroy()
			orb.Transparency = 1
			Debris:AddItem(orb, 0.5)
			emitAt(folder, mouthOf(fromVis), { tex = tex, c1 = fx.light, c2 = fx.main, size = 1.6, life = 0.4, speed = 10, count = 40, drag = 3 })
		elseif power >= 3 then
			local orb = fxPart(folder, V3(0.6, 0.6, 0.6), fx.light, Enum.PartType.Ball, CF(fromPos))
			orb.Transparency = 0.1
			TweenService:Create(orb, TweenInfo.new(chargeT), { Size = V3(2, 2, 2) }):Play()
			emitAt(folder, fromPos, { tex = TEX.glow, c1 = fx.main, size = 4, size1 = 1, life = chargeT, speed = 0.1, count = 1, trans = 0.4 })
			task.wait(chargeT)
			TweenService:Create(orb, TweenInfo.new(0.2), { Transparency = 1 }):Play()
			Debris:AddItem(orb, 0.3)
		else
			task.wait(chargeT)
		end
		fromPos = mouthOf(fromVis)

		-- 2) projectile(s) : petite boule lumineuse + longue trainee de particules de l'element
		local n = cine and 1 or ((power >= 3) and 3 or 1)
		local sz = cine and 2.6 * (power / 4) or (0.6 + power * 0.25)
		for i = 1, n do
			local side = (i - (n + 1) / 2) * 1.8
			local ball = fxPart(folder, V3(sz, sz, sz), fx.light, Enum.PartType.Ball, CF(fromPos))
			local trail = Instance.new("ParticleEmitter")
			trail.Texture = tex
			trail.Color = ColorSequence.new(fx.light, fx.main)
			trail.LightEmission = 0.9
			trail.LightInfluence = 0
			trail.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, sz * 2), NumberSequenceKeypoint.new(1, 0) })
			trail.Lifetime = NumberRange.new(0.3, 0.5)
			trail.Rate = 120
			trail.Speed = NumberRange.new(0.5, 1.5)
			trail.Rotation = NumberRange.new(0, 360)
			trail.Parent = ball
			task.spawn(function()
				local t0 = os.clock()
				while true do
					local a = math.clamp((os.clock() - t0) / travel, 0, 1)
					local p = fromPos:Lerp(toPos, a) + V3(0, math.sin(a * math.pi) * (2 + side * 0.5), side * math.sin(a * math.pi))
					ball.CFrame = CF(p)
					if a >= 1 then break end
					task.wait()
				end
				trail.Enabled = false
				ball.Transparency = 1
				Debris:AddItem(ball, 0.6)
			end)
			task.wait(cine and 0.04 or 0.06)
		end
		task.wait(travel)

		-- 3) impact
		local s = (1 + (power - 1) * 0.5) * 1.4
		local dur = 0.6 + power * 0.15
		local ground = toPos - V3(0, 2, 0)
		emitAt(folder, toPos, { tex = TEX.glow, c1 = fx.light, c2 = fx.main, size = 4 * s, size1 = 9 * s, life = 0.35, speed = 0.1, count = 1, trans = 0.2 })
		if element == "fire" then
			emitAt(folder, toPos, { tex = TEX.core, c1 = Color3.fromRGB(255, 230, 120), c2 = Color3.fromRGB(255, 80, 20), size = 3 * s, size1 = 7 * s, life = 0.6, speed = 3, count = 4 + power * 2 })
			emitAt(folder, toPos, { tex = TEX.fire, c1 = Color3.fromRGB(255, 220, 90), c2 = Color3.fromRGB(255, 60, 10), size = 2.2 * s, life = 0.9, speed = 8 + power * 3, count = 30 * power, accel = V3(0, 10, 0), drag = 2 })
			emitAt(folder, ground, { tex = TEX.fire, c1 = Color3.fromRGB(255, 200, 80), c2 = Color3.fromRGB(255, 50, 10), size = 1.8 * s, life = 0.7, speed = 6, rate = 60 * power, dur = dur, area = V3(5 * s, 0.5, 5 * s), dir = Enum.NormalId.Top, spread = Vector2.new(15, 15) })
			emitAt(folder, toPos + V3(0, 2, 0), { tex = TEX.smoke, c1 = Color3.fromRGB(70, 50, 45), size = 2.5 * s, size1 = 5 * s, life = 1.4, speed = 3, count = 6 * power, accel = V3(0, 4, 0), light = 0, trans = 0.4 })
		elseif element == "ice" then
			-- de vrais pics pointus qui sortent du sol en cercle
			local spikes = {}
			for i = 1, 4 + power * 2 do
				local a = i * 2.39
				local r = 1.2 + (i % 4) * 0.9 * s
				local h = (1.8 + math.random() * 2.2) * s
				local w = (0.5 + math.random() * 0.35) * math.min(s, 2.5)
				local lean = CFrame.Angles(0, -a, 0) * CFrame.Angles(0, 0, math.rad(-12 - math.random(0, 18)))
				for _, p in ipairs(iceSpike(folder, ground + V3(math.cos(a) * r, 0, math.sin(a) * r), h, w, lean)) do
					table.insert(spikes, p)
				end
			end
			-- flocons et paillettes de givre
			emitAt(folder, toPos + V3(0, 3, 0), { tex = TEX.spark, c1 = Color3.fromRGB(255, 255, 255), c2 = Color3.fromRGB(170, 220, 255), size = 0.6, size1 = 0.4, life = 2, speed = 4, rate = 40 * power, dur = dur + 0.4, area = V3(10 * s, 1, 10 * s), accel = V3(0, -3, 0), drag = 1, rot = 120, light = 1 })
			emitAt(folder, toPos, { tex = TEX.spark, c1 = Color3.fromRGB(230, 250, 255), size = 1.2 * s, life = 0.7, speed = 14 + power * 2, count = 40 * power, drag = 3, light = 1 })
			emitAt(folder, ground + V3(0, 0.5, 0), { tex = TEX.smoke, c1 = Color3.fromRGB(220, 240, 255), size = 3 * s, size1 = 6 * s, life = 1.3, speed = 3, count = 10 * power, light = 0.3, trans = 0.5, spread = Vector2.new(80, 80) })
			task.delay(dur + 0.25, function()
				for _, p in ipairs(spikes) do
					TweenService:Create(p, TweenInfo.new(0.35), { Transparency = 1 }):Play()
					Debris:AddItem(p, 0.4)
				end
				emitAt(folder, toPos, { tex = TEX.spark, c1 = Color3.fromRGB(200, 240, 255), size = 0.8 * s, life = 0.8, speed = 10, count = 30 * power, accel = V3(0, -20, 0), light = 1 })
			end)
		elseif element == "shadow" then
			emitAt(folder, toPos, { tex = TEX.implode, c1 = Color3.fromRGB(190, 110, 255), c2 = Color3.fromRGB(60, 10, 90), size = 8 * s, size1 = 1, life = 0.35, speed = 0.1, count = 2 })
			task.delay(0.3, function()
				emitAt(folder, toPos, { tex = TEX.smoke, c1 = Color3.fromRGB(45, 10, 70), c2 = Color3.fromRGB(10, 0, 20), size = 3 * s, size1 = 6 * s, life = 1.2, speed = 9 + power * 2, count = 20 * power, drag = 2, light = 0, trans = 0.2 })
				emitAt(folder, toPos, { tex = TEX.spark, c1 = Color3.fromRGB(220, 140, 255), size = 1 * s, life = 0.8, speed = 16, count = 25 * power, drag = 2 })
				emitAt(folder, ground, { tex = TEX.smoke, c1 = Color3.fromRGB(60, 15, 90), size = 2 * s, size1 = 3.5 * s, life = 1, speed = 2, rate = 30 * power, dur = dur, area = V3(6 * s, 0.5, 6 * s), dir = Enum.NormalId.Top, light = 0.2, trans = 0.3 })
			end)
		elseif element == "cosmic" or element == "divine" then
			-- rayon de lumiere qui tombe du ciel (Beam) + etoiles
			local top = fxPart(folder, V3(0.2, 0.2, 0.2), fx.light, nil, CF(toPos + V3(0, 30, 0)))
			local bot = fxPart(folder, V3(0.2, 0.2, 0.2), fx.light, nil, CF(ground))
			top.Transparency, bot.Transparency = 1, 1
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.Parent, a1.Parent = top, bot
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = a0, a1
			beam.Texture = TEX.glow
			beam.TextureSpeed = 2
			beam.Color = ColorSequence.new(fx.light, fx.main)
			beam.LightEmission = 1
			beam.FaceCamera = true
			beam.Width0, beam.Width1 = 2 * s, 3 * s
			beam.Parent = top
			TweenService:Create(beam, TweenInfo.new(dur + 0.3), { Width0 = 0, Width1 = 0 }):Play()
			Debris:AddItem(top, dur + 0.4)
			Debris:AddItem(bot, dur + 0.4)
			emitAt(folder, toPos, { tex = TEX.spark, c1 = fx.light, c2 = fx.main, size = 1.6 * s, life = 1, speed = 12 + power * 2, count = 35 * power, drag = 2, light = 1 })
			emitAt(folder, toPos + V3(0, 6, 0), { tex = TEX.spark, c1 = Color3.fromRGB(255, 255, 230), size = 0.7, life = 1.5, speed = 2, rate = 30 * power, dur = dur, area = V3(8 * s, 6, 8 * s), accel = V3(0, -6, 0), light = 1 })
			if element == "divine" then
				emitAt(folder, ground, { tex = TEX.shock, c1 = fx.light, size = 4, size1 = 18 * s, life = 0.6, speed = 0.1, count = 2 })
			end
		else
			-- nature / betes : trois griffures (Beam courbes) + feuilles et etincelles vertes
			for i = -1, 1 do
				local p0 = toPos + V3(-2.5 * s, 2 + i * 1.2, -1.5)
				local p1 = toPos + V3(2.5 * s, -2 + i * 1.2, 1.5)
				local h0 = fxPart(folder, V3(0.2, 0.2, 0.2), fx.light, nil, CF(p0))
				local h1 = fxPart(folder, V3(0.2, 0.2, 0.2), fx.light, nil, CF(p1))
				h0.Transparency, h1.Transparency = 1, 1
				local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
				a0.Parent, a1.Parent = h0, h1
				local beam = Instance.new("Beam")
				beam.Attachment0, beam.Attachment1 = a0, a1
				beam.Color = ColorSequence.new(Color3.new(1, 1, 1), fx.light)
				beam.LightEmission = 1
				beam.FaceCamera = true
				beam.CurveSize0, beam.CurveSize1 = 1.5, -1.5
				beam.Width0, beam.Width1 = 0.1, 0.8 * s
				beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0), NumberSequenceKeypoint.new(1, 0.2) })
				beam.Parent = h0
				TweenService:Create(beam, TweenInfo.new(dur), { Width0 = 0, Width1 = 0 }):Play()
				Debris:AddItem(h0, dur + 0.1)
				Debris:AddItem(h1, dur + 0.1)
			end
			emitAt(folder, toPos, { tex = TEX.spark, c1 = fx.light, c2 = fx.main, size = 1.2 * s, life = 0.9, speed = 12 + power * 2, count = 30 * power, drag = 2, accel = V3(0, -6, 0), light = 1 })
		end
		-- 4) super attaques : enorme explosion en plusieurs temps
		if power >= 4 then
			local big = power / 4 -- 1 (ultime) a 1.25 (super)
			-- boule d'explosion qui gonfle puis s'efface
			local boom = fxPart(folder, V3(2, 2, 2), fx.light, Enum.PartType.Ball, CF(toPos))
			boom.Transparency = 0.05
			local boomLight = Instance.new("PointLight")
			boomLight.Color = fx.main
			boomLight.Range = 40
			boomLight.Brightness = 6
			boomLight.Parent = boom
			TweenService:Create(boom, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = V3(16, 16, 16) * big }):Play()
			task.delay(0.35, function()
				TweenService:Create(boom, TweenInfo.new(0.6), { Transparency = 1, Size = V3(20, 20, 20) * big, Color = fx.main }):Play()
				TweenService:Create(boomLight, TweenInfo.new(0.9), { Brightness = 0 }):Play()
			end)
			Debris:AddItem(boom, 1.1)
			-- coeur de l'explosion + gerbe de particules
			emitAt(folder, toPos, { tex = TEX.core, c1 = Color3.fromRGB(255, 255, 255), c2 = fx.main, size = 8 * big, size1 = 26 * big, life = 0.7, speed = 2, count = 8 })
			emitAt(folder, toPos, { tex = tex, c1 = fx.light, c2 = fx.main, size = 3.5 * big, life = 1.2, speed = 40, count = 200, drag = 2.5 })
			emitAt(folder, toPos, { tex = TEX.spark, c1 = Color3.fromRGB(255, 255, 255), c2 = fx.light, size = 1.2, life = 1.5, speed = 55, count = 120, drag = 1.5, accel = V3(0, -25, 0), light = 1 })
			-- trois ondes de choc au sol, de plus en plus larges
			for k = 0, 2 do
				task.delay(k * 0.18, function()
					emitAt(folder, ground + V3(0, 0.5, 0), { tex = TEX.shock, c1 = fx.light, c2 = fx.main, size = 4, size1 = (40 + k * 18) * big, life = 0.9, speed = 0.1, count = 1, trans = 0.05 })
				end)
			end
			-- colonne d'energie qui monte vers le ciel
			emitAt(folder, ground, { tex = tex, c1 = fx.light, c2 = fx.main, size = 4 * big, size1 = 1, life = 1.1, speed = 30, rate = 140, dur = 0.8, area = V3(3, 0.5, 3) * big, dir = Enum.NormalId.Top, spread = Vector2.new(8, 8) })
			-- 2e explosion, puis un gros nuage qui retombe lentement
			task.delay(0.4, function()
				emitAt(folder, toPos, { tex = TEX.core, c1 = fx.light, c2 = fx.main, size = 6 * big, size1 = 22 * big, life = 0.8, speed = 3, count = 6 })
				emitAt(folder, toPos, { tex = tex, c1 = fx.light, c2 = fx.main, size = 2.8, life = 1.1, speed = 32, count = 140, drag = 3 })
				emitAt(folder, ground + V3(0, 1, 0), { tex = TEX.smoke, c1 = fx.main, c2 = Color3.fromRGB(40, 35, 45), size = 6 * big, size1 = 12 * big, life = 2.2, speed = 8, count = 30, drag = 1.5, light = 0.2, trans = 0.3, spread = Vector2.new(90, 90) })
			end)
			emitAt(folder, toPos, { tex = tex, c1 = fx.light, c2 = fx.main, size = 1.8, life = 0.9, speed = 5, rate = 90, dur = 1.6, area = V3(10, 8, 10) * big })
		end
	end)
end

local function killVis(b, side)
	local vis = b.vis[side]
	if not vis then return end
	b.vis[side] = nil
	vis.dead = os.clock()
	for _, d in ipairs(vis.model:GetDescendants()) do
		if d:IsA("BasePart") then
			TweenService:Create(d, TweenInfo.new(0.8), { Transparency = 1 }):Play()
		elseif d:IsA("BillboardGui") or d:IsA("ParticleEmitter") then
			d:Destroy()
		end
	end
	task.delay(1, function()
		arenaVis[vis] = nil
		staticAnimators[vis.model] = nil
		pcall(function() vis.model:Destroy() end)
	end)
end

local function cleanupArena(b)
	if not b then return end
	if b.vis then
		for _, side in ipairs({ "player", "npc" }) do
			local vis = b.vis[side]
			if vis then
				arenaVis[vis] = nil
				staticAnimators[vis.model] = nil
				pcall(function() vis.model:Destroy() end)
				b.vis[side] = nil
			end
		end
	end
	if b.trainerModel then
		staticAnimators[b.trainerModel] = nil
		pcall(function() b.trainerModel:Destroy() end)
		b.trainerModel = nil
	end
	if b.arena then b.arena.inUse = false end
end

local function updateArenaVisuals(b)
	if not b or not b.arena then return end
	local origin = b.arena.origin
	local sides = {
		player = { st = b.playerPets[b.playerCurrent], pos = origin + V3(-10, 0, 0), face = V3(1, 0, 0) },
		npc = { st = b.npcPets[b.npcCurrent], pos = origin + V3(10, 0, 0), face = V3(-1, 0, 0) },
	}
	for side, sd in pairs(sides) do
		local st = sd.st
		local vis = b.vis[side]
		if vis and vis.ref ~= st then
			killVis(b, side)
			vis = nil
		end
		if st and not vis and st.hp > 0 then
			local model, root, P = createPetModel(st.name, true, 1.6 * Traits.scale(st), st.mutation)
			local y = origin.Y + 0.9 + P.foot * P.scale + (P.flying and 2.5 or 0)
			local pos = V3(sd.pos.X, y, sd.pos.Z)
			local base = CFrame.lookAt(pos, pos + sd.face)
			root.CFrame = base
			model.Parent = b.arena.folder
			staticAnimators[model] = P.anims

			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.new(0, 170, 0, 46)
			bb.StudsOffset = V3(0, 3 + P.scale * 2, 0)
			bb.AlwaysOnTop = true
			bb.Adornee = root
			bb.Parent = root
			local nameL = Instance.new("TextLabel")
			nameL.Size = UDim2.new(1, 0, 0, 22)
			nameL.BackgroundTransparency = 1
			nameL.Text = st.name
			nameL.TextColor3 = rarityInfo(st.rarity).color
			nameL.Font = Enum.Font.GothamBold
			nameL.TextSize = 16
			nameL.TextStrokeTransparency = 0.3
			nameL.Parent = bb
			local bg = Instance.new("Frame")
			bg.Size = UDim2.new(1, -20, 0, 10)
			bg.Position = UDim2.new(0, 10, 0, 28)
			bg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
			bg.BorderSizePixel = 0
			bg.Parent = bb
			local bgc = Instance.new("UICorner")
			bgc.CornerRadius = UDim.new(0, 5)
			bgc.Parent = bg
			local fill = Instance.new("Frame")
			fill.Size = UDim2.new(1, 0, 1, 0)
			fill.BackgroundColor3 = Color3.fromRGB(80, 220, 100)
			fill.BorderSizePixel = 0
			fill.Parent = bg
			local fc = Instance.new("UICorner")
			fc.CornerRadius = UDim.new(0, 5)
			fc.Parent = fill

			vis = {
				model = model, root = root, base = base, ref = st, fill = fill, rig = P.rig,
				dir = sd.face, phase = math.random() * 6, spawnT = os.clock()
			}
			b.vis[side] = vis
			arenaVis[vis] = true
		end
		if vis and st then
			local ratio = math.clamp(st.hp / st.maxHp, 0, 1)
			TweenService:Create(vis.fill, TweenInfo.new(0.3), {
				Size = UDim2.new(ratio, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(255 * (1 - ratio) + 60, 200 * ratio + 30, 60)
			}):Play()
		end
	end
end

local function returnPlayerFromArena(player, b)
	if not b then return end
	local target = b.originalCFrame
	task.spawn(function()
		if target and player.Parent and player.Character then
			safeTeleport(player, target, true)
		end
		cleanupArena(b)
		if player.Parent then refreshPetVisuals(player) end
	end)
end

-- ============================================================
-- COMBAT
-- ============================================================

local function sendBattleUpdate(player)
	local b = battles[player.UserId]
	if not b then return end
	updateArenaVisuals(b)
	local myPet = b.playerPets[b.playerCurrent]
	BattleUpdate:FireClient(player, {
		playerPets = b.playerPets, npcPets = b.npcPets,
		playerCurrent = b.playerCurrent, npcCurrent = b.npcCurrent,
		turn = b.turn, log = b.log, active = b.active,
		playerCharge = myPet and myPet.charge or 0,
		playerMaxCharge = myPet and myPet.maxCharge or 100,
		playerCanSuper = myPet and myPet.charge >= myPet.maxCharge or false,
		fxId = b.fxId, fxPower = b.fxPower, fxFrom = b.fxFrom, fxTo = b.fxTo,
	})
end

local function finishBattle(player, b, delaySec)
	if b.finishing then return end
	b.finishing = true
	task.delay(delaySec, function()
		returnPlayerFromArena(player, b)
		if battles[player.UserId] == b then battles[player.UserId] = nil end
	end)
end

local function battlePayload(b)
	local myPet = b.playerPets[b.playerCurrent]
	return {
		success = true, npcName = NPC_TRAINERS[b.npcIndex].name, npcIndex = b.npcIndex,
		playerPets = b.playerPets, npcPets = b.npcPets,
		playerCurrent = b.playerCurrent, npcCurrent = b.npcCurrent,
		turn = b.turn, log = b.log, active = b.active,
		playerCharge = myPet and myPet.charge or 0,
		playerMaxCharge = myPet and myPet.maxCharge or 100,
		playerCanSuper = myPet and myPet.charge >= myPet.maxCharge or false,
	}
end

-- Termine proprement un combat (fuite, respawn, inactivite...) et ramene le joueur
local function abortBattle(player, reason, silent)
	local b = battles[player.UserId]
	if not b or b.finishing then return end
	b.active = false
	b.log = reason or "Defaite... Combat interrompu."
	sendBattleUpdate(player) -- toujours : l'interface du client se ferme sur cet etat final
	finishBattle(player, b, silent and 0 or 1.5)
end

local function firstAlive(list, exclude)
	for i, p in ipairs(list) do
		if p.hp > 0 and i ~= exclude then return i end
	end
	return nil
end

local function processNPCAttack(player, expected)
	local b = battles[player.UserId]
	if not b or b ~= expected or not b.active then return end
	if b.turn ~= "npc" then return end

	local enemyPet = b.npcPets[b.npcCurrent]
	local myPet = b.playerPets[b.playerCurrent]
	if not enemyPet or not myPet then return end

	local isSuper = enemyPet.charge >= enemyPet.maxCharge
	local baseDamage = math.floor(enemyPet.attack * (0.8 + math.random() * 0.4))
	local damage = isSuper and baseDamage * 3 or baseDamage
	local crit = (not isSuper) and math.random() < 0.1
	if crit then damage = math.floor(damage * 1.5) end

	if isSuper then
		enemyPet.charge = 0
		b.log = enemyPet.name .. " lance sa SUPER ATTAQUE ! " .. damage .. " degats !"
	else
		enemyPet.charge = math.min(enemyPet.maxCharge, enemyPet.charge + 33)
		b.log = enemyPet.name .. " inflige " .. damage .. " degats !" .. (crit and " COUP CRITIQUE !" or "")
	end
	local ev, pv = b.vis.npc, b.vis.player
	local power = isSuper and 4 or (crit and 2 or 1)
	local hit = impactDelay(power)
	if ev and power < 4 then task.delay(hit - 0.4, function() ev.lungeStart = os.clock() end) end
	if pv then
		if ev then playAttackFx(b.arena.folder, ev, pv.root.Position, elementOf(enemyPet.name), power) end
		task.delay(hit, function()
			pv.shakeUntil = os.clock() + 0.35 + power * 0.12
			if pv.root.Parent then popText(b.arena.folder, pv.root.Position + V3(0, 4, 0), "-" .. damage, Color3.fromRGB(255, 90, 90)) end
		end)
	end
	b.fxId = (b.fxId or 0) + 1
	b.fxPower = power
	b.fxFrom = ev and ev.root.Position
	b.fxTo = pv and pv.root.Position
	b.turn = "wait"
	sendBattleUpdate(player)

	task.delay(hit, function()
		if battles[player.UserId] ~= b or not b.active then return end
		myPet.hp = math.max(0, myPet.hp - damage)
		sendBattleUpdate(player)
	end)
	task.delay(hit + 0.5, function()
		if battles[player.UserId] ~= b or not b.active then return end
		if myPet.hp <= 0 then
			b.log = b.log .. " " .. myPet.name .. " est K.O. !"
			killVis(b, "player")
			local nxt = firstAlive(b.playerPets)
			if nxt then
				b.playerCurrent = nxt
				b.log = b.log .. " Tu envoies " .. b.playerPets[nxt].name .. " !"
				b.turn = "player"
			else
				b.active = false
				b.log = "Defaite... Reessaie quand tu seras plus fort !"
				sendBattleUpdate(player)
				finishBattle(player, b, 2.5)
				return
			end
		else
			b.turn = "player"
		end
		sendBattleUpdate(player)
	end)
end

local function winBattle(player, b)
	local s = states[player.UserId]
	local npc = NPC_TRAINERS[b.npcIndex]
	if s then
		local already = false
		for _, idx in ipairs(s.defeatedNPCs) do
			if idx == b.npcIndex then already = true break end
		end
		if not already then table.insert(s.defeatedNPCs, b.npcIndex) end
		s.coins = s.coins + npc.reward
		b.log = "VICTOIRE ! Tu gagnes " .. npc.reward .. " coins !"
		if _G.MWS_Track then _G.MWS_Track(player, "battle") end
	end
	b.active = false
	local pv = b.vis.player
	if pv then
		local conf = emitter(pv.root, Color3.fromRGB(255, 230, 100), 0, 0.8, 2, 14)
		conf.SpreadAngle = Vector2.new(180, 180)
		conf:Emit(80)
		popText(b.arena.folder, pv.root.Position + V3(0, 5, 0), "VICTOIRE !", Color3.fromRGB(255, 230, 100))
	end
	sendBattleUpdate(player)
	sendState(player)
	sendNPCInfo(player)
	finishBattle(player, b, 3)
end

-- power : 1 attaque normale, 2 critique, 2-4 attaques speciales, 5 super attaque
local function resolvePlayerStrike(player, b, damage, text, power)
	local myPet = b.playerPets[b.playerCurrent]
	local enemyPet = b.npcPets[b.npcCurrent]
	b.log = text
	power = power or 1
	local hit = impactDelay(power)

	local pv, ev = b.vis.player, b.vis.npc
	if pv and power < 4 then task.delay(hit - 0.4, function() pv.lungeStart = os.clock() end) end
	if ev then
		if pv then playAttackFx(b.arena.folder, pv, ev.root.Position, elementOf(myPet.name), power) end
		local evRoot = ev.root
		task.delay(hit, function()
			ev.shakeUntil = os.clock() + 0.35 + power * 0.12
			if evRoot.Parent then popText(b.arena.folder, evRoot.Position + V3(0, 4, 0), "-" .. damage, Color3.fromRGB(255, 240, 120)) end
		end)
	end
	b.fxId = (b.fxId or 0) + 1
	b.fxPower = power
	b.fxFrom = pv and pv.root.Position
	b.fxTo = ev and ev.root.Position
	-- pendant l'animation, personne ne joue (le K.O. arrive au moment de l'impact)
	b.turn = "wait"
	sendBattleUpdate(player)

	-- les PV baissent au moment de l'impact (pas avant l'animation)
	task.delay(hit, function()
		if battles[player.UserId] ~= b or not b.active then return end
		enemyPet.hp = math.max(0, enemyPet.hp - damage)
		sendBattleUpdate(player)
	end)
	task.delay(hit + 0.5, function()
		if battles[player.UserId] ~= b or not b.active then return end
		if enemyPet.hp <= 0 then
			b.log = b.log .. " " .. enemyPet.name .. " est K.O. !"
			killVis(b, "npc")
			if b.npcCurrent < #b.npcPets then
				b.npcCurrent = b.npcCurrent + 1
				b.log = b.log .. " " .. NPC_TRAINERS[b.npcIndex].name .. " envoie " .. b.npcPets[b.npcCurrent].name .. " !"
				b.turn = "npc"
			else
				winBattle(player, b)
				return
			end
		else
			b.turn = "npc"
		end
		sendBattleUpdate(player)
		if b.active and b.turn == "npc" then
			task.delay(1, function() processNPCAttack(player, b) end)
		end
	end)
end

local function processPlayerAttack(player)
	local b = battles[player.UserId]
	if not b or not b.active or b.turn ~= "player" then return end
	local myPet = b.playerPets[b.playerCurrent]
	local enemyPet = b.npcPets[b.npcCurrent]
	if not myPet or not enemyPet then return end
	local damage = math.floor(myPet.attack * (0.8 + math.random() * 0.4))
	myPet.charge = math.min(myPet.maxCharge, myPet.charge + 33)
	local crit = math.random() < 0.12
	if crit then damage = math.floor(damage * 1.5) end
	resolvePlayerStrike(player, b, damage, myPet.name .. " inflige " .. damage .. " degats !" .. (crit and " Coup critique !" or ""), crit and 2 or 1)
end

local SPECIAL_ATTACKS = {
	-- l'effet visuel prend l'element du pet ; power = taille de l'animation
	[1] = { name = "Coup charge",     chargeRequired = 50,  damageMult = 2, power = 2 },
	[2] = { name = "Assaut puissant", chargeRequired = 75,  damageMult = 3, power = 3 },
	[3] = { name = "Attaque ultime",  chargeRequired = 100, damageMult = 5, power = 4 }
}

local function processPlayerSpecial(player, specialIndex)
	local b = battles[player.UserId]
	if not b or not b.active or b.turn ~= "player" then return end
	local myPet = b.playerPets[b.playerCurrent]
	local enemyPet = b.npcPets[b.npcCurrent]
	if not myPet or not enemyPet then return end
	local special = SPECIAL_ATTACKS[specialIndex]
	if not special or myPet.charge < special.chargeRequired then return end
	local damage = math.floor(myPet.attack * special.damageMult * (0.9 + math.random() * 0.2))
	myPet.charge = math.max(0, myPet.charge - special.chargeRequired)
	resolvePlayerStrike(player, b, damage, myPet.name .. " : " .. special.name .. " ! " .. damage .. " degats !", special.power)
end

local function processPlayerSuper(player)
	local b = battles[player.UserId]
	if not b or not b.active or b.turn ~= "player" then return end
	local myPet = b.playerPets[b.playerCurrent]
	local enemyPet = b.npcPets[b.npcCurrent]
	if not myPet or not enemyPet then return end
	if myPet.charge < myPet.maxCharge then return end
	local damage = math.floor(myPet.attack * 3 * (0.9 + math.random() * 0.2))
	myPet.charge = 0
	resolvePlayerStrike(player, b, damage, myPet.name .. " lance sa SUPER ATTAQUE ! " .. damage .. " degats !", 5)
end

local function processPlayerSwitch(player)
	local b = battles[player.UserId]
	if not b or not b.active or b.turn ~= "player" then return end
	local nxt = nil
	for step = 1, #b.playerPets do
		local idx = ((b.playerCurrent - 1 + step) % #b.playerPets) + 1
		if idx ~= b.playerCurrent and b.playerPets[idx].hp > 0 then
			nxt = idx
			break
		end
	end
	if not nxt then return end
	b.playerCurrent = nxt
	b.log = "Tu changes pour " .. b.playerPets[nxt].name .. " !"
	b.turn = "npc"
	sendBattleUpdate(player)
	task.delay(1.2, function() processNPCAttack(player, b) end)
end

startBattle = function(player, npcIndex)
	local s = states[player.UserId]
	if not s then return end
	if teleporting[player] then return end
	if battles[player.UserId] then

		-- Combat deja en cours : on resynchronise l'interface au lieu de planter
		local existing = battles[player.UserId]
		if existing.active and os.clock() - (existing.lastAction or 0) < 180 then
			BattleStart:FireClient(player, battlePayload(existing))
		else
			-- combat bloque (plus d'activite) : on le termine, le joueur peut relancer
			abortBattle(player, "Defaite... Ancien combat termine.", true)
			notify(player, "Ancien combat termine, relance le combat !", Color3.fromRGB(255, 220, 80))
		end

		return
	end
	if #s.equipped == 0 then
		BattleStart:FireClient(player, { success = false, message = "Tu dois equiper au moins un pet !" })
		return
	end
	local npc = NPC_TRAINERS[npcIndex]
	if not npc then return end
	if (s.unlockedWorld or 1) < npc.world then
		notify(player, "Monde non debloque !", Color3.fromRGB(255, 120, 120))
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local playerPets = {}
	for _, pet in ipairs(getEquippedPets(s)) do
		local info = PETS[pet.name]
		local mult = (pet.multiplier or (info and info.multiplier) or 1) * (1 + 0.05 * math.clamp(math.floor(tonumber(pet.lvl) or 0), 0, PET_MAX_LVL))
		table.insert(playerPets, {
			name = pet.name, color = pet.color, rarity = pet.rarity, size = pet.size, mutation = pet.mutation,
			hp = mult * 100, maxHp = mult * 100, attack = mult * 20, charge = 0, maxCharge = 100
		})
	end
	if #playerPets == 0 then
		BattleStart:FireClient(player, { success = false, message = "Aucun pet valide equipe !" })
		return
	end

	local npcPets = {}
	for _, p in ipairs(npc.pets) do
		local info = PETS[p.name]
		table.insert(npcPets, {
			name = p.name, color = p.color, rarity = info and info.rarity or "Commun",
			hp = p.hp, maxHp = p.hp, attack = p.attack, charge = 0, maxCharge = 100
		})
	end

	local arena = acquireArena(npc.world)
	if not arena then
		notify(player, "Toutes les arenes sont occupees, reessaie !", Color3.fromRGB(255, 120, 120))
		return
	end

	local b = {
		npcIndex = npcIndex, playerPets = playerPets, npcPets = npcPets,
		playerCurrent = 1, npcCurrent = 1, turn = "player", active = true,
		log = "Le combat commence ! " .. npc.name .. " t'attend !",
		originalCFrame = hrp.CFrame, arena = arena, vis = {}, lastAction = os.clock()
	}
	battles[player.UserId] = b

	local tModel, tRoot, _, tP = createTrainerModel(npc, 1.3)
	local tPos = arena.origin + V3(21, 3.6, 0)
	tRoot.CFrame = CFrame.lookAt(tPos, tPos + V3(-1, 0, 0))
	tModel.Parent = arena.folder
	staticAnimators[tModel] = tP.anims
	b.trainerModel = tModel

	-- les pets qui suivent le joueur sont caches pendant le combat (ils bouchaient la vue)
	clearPlayerVisuals(player)
	local pPos = arena.origin + V3(-19, 4, 0)
	local arrived = safeTeleport(player, CFrame.lookAt(pPos, pPos + V3(1, 0, 0)))
	if not player.Parent or battles[player.UserId] ~= b then return end
	if not arrived then
		abortBattle(player, "Defaite... Combat interrompu.", true)
		return
	end

	updateArenaVisuals(b)
	BattleStart:FireClient(player, battlePayload(b))
end

-- ============================================================
-- EVENEMENTS
-- ============================================================

local equipRequestAt = {}
EquipPet.OnServerEvent:Connect(function(player, petId)
	local now = os.clock()
	if equipRequestAt[player.UserId] and now - equipRequestAt[player.UserId] < 0.15 then return end
	equipRequestAt[player.UserId] = now
	if type(petId) ~= "number" then return end
	petId = math.floor(petId)
	local s = states[player.UserId]
	if not s then return end
	local found = false
	for _, pet in ipairs(s.pets) do
		if pet.id == petId then found = true break end
	end
	if not found then return end

	local already = false
	for i, id in ipairs(s.equipped) do
		if id == petId then
			table.remove(s.equipped, i)
			despawnPetVisual(visualKey(player, petId))
			already = true
			break
		end
	end
	if not already then
		if #s.equipped >= maxEquip(s) then
			local nextAt = (maxEquip(s) < MAX_EQUIPPED) and (" Prochain emplacement a " .. ((maxEquip(s) - 1) * 2) .. " renaissances.") or ""
			notify(player, "Maximum " .. maxEquip(s) .. " pets equipes." .. nextAt, Color3.fromRGB(255, 170, 80))
			return
		end
		table.insert(s.equipped, petId)
		for _, pet in ipairs(s.pets) do
			if pet.id == petId then spawnPetVisual(player, pet, #s.equipped) end
		end
		if _G.MWS_Track then _G.MWS_Track(player, "equip") end
	end
	reslot(player)
	sendState(player)
end)

local battleActionAt = {}
BattleAction.OnServerEvent:Connect(function(player, action)
	local now = os.clock()
	if battleActionAt[player.UserId] and now - battleActionAt[player.UserId] < 0.12 then return end
	battleActionAt[player.UserId] = now
	local activeBattle = battles[player.UserId]
	if activeBattle then activeBattle.lastAction = now end
	if type(action) ~= "string" then return end
	if action == "attack" then processPlayerAttack(player)
	elseif action == "flee" then abortBattle(player, "Defaite... Tu as fui le combat.")
	elseif action == "switch" then processPlayerSwitch(player)
	elseif action == "super" then processPlayerSuper(player)
	elseif action == "special1" then processPlayerSpecial(player, 1)
	elseif action == "special2" then processPlayerSpecial(player, 2)
	elseif action == "special3" then processPlayerSpecial(player, 3)
	end
end)

RebirthRemote.OnServerEvent:Connect(function(player)
	local s = states[player.UserId]
	if not s then return end
	if _G.MWS_TutLock and _G.MWS_TutLock(player, "rebirth") then return end
	if battles[player.UserId] then return end
	local needed, done = rebirthRequirement(s)
	if done < needed then
		RebirthRemote:FireClient(player, { success = false, message = "Tu dois battre les dresseurs de tes mondes ! (" .. done .. "/" .. needed .. ")" })
		return
	end
	if s.coins < REBIRTH_COST then
		RebirthRemote:FireClient(player, { success = false, message = "Il te faut " .. REBIRTH_COST .. " coins pour renaitre !" })
		return
	end
	s.rebirthLevel = (s.rebirthLevel or 0) + 1
	s.coins = START_COINS
	s.defeatedNPCs = {}
	RebirthRemote:FireClient(player, { success = true, rebirthLevel = s.rebirthLevel })
	sendState(player)
	sendNPCInfo(player)
end)

-- choix de la couleur d'aura des pets fusionnes
local auraColorAt = {}
SetAuraColor.OnServerEvent:Connect(function(player, key)
	if type(key) ~= "string" or (key ~= "auto" and not AURA_PRESETS[key]) then return end
	local now = os.clock()
	if auraColorAt[player.UserId] and now - auraColorAt[player.UserId] < 0.5 then return end
	auraColorAt[player.UserId] = now
	local s = states[player.UserId]
	if not s or s.auraColor == key then return end
	s.auraColor = key
	if not battles[player.UserId] then refreshPetVisuals(player) end
	sendState(player)
end)

local worldTeleportAt = {}
WorldTeleport.OnServerEvent:Connect(function(player, w)
	local now = os.clock()
	if worldTeleportAt[player.UserId] and now - worldTeleportAt[player.UserId] < 1 then return end
	worldTeleportAt[player.UserId] = now
	local s = states[player.UserId]
	if not s or type(w) ~= "number" then return end
	w = math.floor(w)
	if w < 1 or w > #WORLDS then return end
	task.spawn(usePortal, player, w)   -- debloque le monde (si assez de coins) puis teleporte
end)

local battleRequestAt = {}
BattleRequest.OnServerEvent:Connect(function(player, npcIndex)
	local now = os.clock()
	if battleRequestAt[player.UserId] and now - battleRequestAt[player.UserId] < 1 then return end
	battleRequestAt[player.UserId] = now
	if type(npcIndex) ~= "number" or npcIndex ~= math.floor(npcIndex) then return end
	if npcIndex < 1 or npcIndex > #NPC_TRAINERS then return end
	if _G.MWS_TutLock and _G.MWS_TutLock(player, "battle", npcIndex) then return end
	startBattle(player, npcIndex)
end)

EquipBest.OnServerEvent:Connect(function(player)
	local s = states[player.UserId]
	if not s or battles[player.UserId] then return end
	local sorted = {}
	for _, pet in ipairs(s.pets) do table.insert(sorted, pet) end
	table.sort(sorted, function(a, c)
		local ia = a.income or 0
		local ic = c.income or 0
		if ia ~= ic then return ia > ic end
		return a.id < c.id
	end)
	clearPlayerVisuals(player)
	s.equipped = {}
	for i = 1, math.min(maxEquip(s), #sorted) do
		table.insert(s.equipped, sorted[i].id)
	end
	if #s.equipped > 0 and _G.MWS_Track then _G.MWS_Track(player, "equip") end
	refreshPetVisuals(player)
	sendState(player)
end)

local speedBuyAt = {}
local BASE_WALKSPEED = 26 -- tout le monde court plus vite (16 = vitesse Roblox normale)
local function applySpeedBoost(player)
	local s = states[player.UserId]
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not s or not hum then return end
	local boosted = (s.speedBoostUntil or 0) > os.time()
	hum.WalkSpeed = BASE_WALKSPEED * (boosted and SPEED_BOOST_MULT or 1)
end

BuySpeed.OnServerEvent:Connect(function(player)
	local now = os.clock()
	if speedBuyAt[player.UserId] and now - speedBuyAt[player.UserId] < 0.5 then return end
	speedBuyAt[player.UserId] = now
	if _G.MWS_TutLock and _G.MWS_TutLock(player, "speed") then return end
	local s = states[player.UserId]
	if not s then return end
	if (s.speedBoostUntil or 0) > os.time() then
		notify(player, "Ton boost de vitesse est deja actif !", Color3.fromRGB(255, 220, 80))
		return
	end
	if s.coins < SPEED_BOOST_COST then
		notify(player, "Il te faut " .. fmt(SPEED_BOOST_COST) .. " coins pour acheter le boost !", Color3.fromRGB(255, 120, 120))
		return
	end
	s.coins = s.coins - SPEED_BOOST_COST
	s.speedBoostUntil = os.time() + SPEED_BOOST_DURATION
	applySpeedBoost(player)
	notify(player, "Boost de vitesse x" .. SPEED_BOOST_MULT .. " active pendant " .. SPEED_BOOST_DURATION .. " secondes !", Color3.fromRGB(120, 220, 255))
	sendState(player)
	task.delay(SPEED_BOOST_DURATION + 0.1, function()
		if player.Parent and states[player.UserId] and (states[player.UserId].speedBoostUntil or 0) <= os.time() then
			applySpeedBoost(player)
			sendState(player)
		end
	end)
end)

-- ============================================================
-- BOUTIQUE ROBUX (la config des articles est dans ReplicatedStorage.MWS_ShopConfig)
-- ============================================================

do
	local MarketplaceService = game:GetService("MarketplaceService")
	local ShopConfig = require(ReplicatedStorage:WaitForChild("MWS_ShopConfig"))
	local ShopInfo = getRemote("ShopInfo")
	local ShopBuy = getRemote("ShopBuy")

	local byKey, byProduct, byPass = {}, {}, {}
	for _, item in ipairs(ShopConfig.Items) do
		byKey[item.key] = item
		if type(item.id) == "number" and item.id > 0 then
			if item.kind == "gamepass" then byPass[item.id] = item else byProduct[item.id] = item end
		end
	end

	-- prix reel lu chez Roblox (sinon le prix "price" de la config est affiche)
	local priceCache = {}
	local function fetchPrice(item)
		if type(item.id) ~= "number" or item.id <= 0 then return nil end
		if priceCache[item.key] then return priceCache[item.key] end
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(item.id, item.kind == "gamepass" and Enum.InfoType.GamePass or Enum.InfoType.Product)
		end)
		if ok and type(info) == "table" and info.PriceInRobux then
			priceCache[item.key] = info.PriceInRobux
			return info.PriceInRobux
		end
		return nil
	end

	local function sendShopInfo(player)
		local s = states[player.UserId]
		if not s then return end
		local list = {}
		local myWorld = player:GetAttribute("MWS_World")
		for _, item in ipairs(ShopConfig.Items) do
			-- article propre a un monde : visible uniquement dans ce monde
			if not item.world or item.world == myWorld then
				table.insert(list, {
					key = item.key, name = item.name, desc = item.desc, icon = item.icon, kind = item.kind,
					available = type(item.id) == "number" and item.id > 0,
					price = fetchPrice(item) or item.price,
					owned = (item.kind == "gamepass" and s.passes ~= nil and s.passes[item.key] == true)
						or (item.limit ~= nil and (s.bought[item.key] or 0) >= item.limit) or false,
				})
			end
		end
		if not player.Parent then return end
		ShopInfo:FireClient(player, list, { speedUntil = s.speedBoostUntil or 0, luckUntil = s.luckUntil or 0, now = os.time() })
	end

	local function scheduleSpeedEnd(player)
		local s = states[player.UserId]
		if not s then return end
		task.delay(math.max(0, (s.speedBoostUntil or 0) - os.time()) + 0.2, function()
			local st = states[player.UserId]
			if player.Parent and st and (st.speedBoostUntil or 0) <= os.time() then
				applySpeedBoost(player)
				sendState(player)
			end
		end)
	end

	local function applyPass(s, item)
		s.passes = s.passes or {}
		s.passes[item.key] = true
		local r = item.reward
		if type(r) == "table" and r.type == "coinsmult" then
			s.coinMult = math.max(s.coinMult or 1, r.mult or 2)
		end
	end

	local function addShopPet(player, s, name)
		local info = PETS[name]
		local id = s.nextPetId
		s.nextPetId = id + 1
		table.insert(s.pets, { id = id, name = name, rarity = info.rarity, color = info.color, multiplier = info.multiplier, income = info.income })
		if _G.MWS_Track then _G.MWS_Track(player, "pet", name) end
	end

	-- livre les pets en attente des qu'une place se libere (fusion...)
	local function deliverPendingPets(player, s)
		local delivered = false
		while #s.pendingPets > 0 and #s.pets < MAX_PETS do
			local name = table.remove(s.pendingPets, 1)
			addShopPet(player, s, name)
			notify(player, name .. " est arrive dans ton inventaire !", Color3.fromRGB(120, 255, 180))
			delivered = true
		end
		if delivered then sendState(player) end
	end

	-- donne la recompense d'un produit ; renvoie false si impossible, puis true si elle est mise en attente
	local function grantReward(player, s, item)
		local r = item.reward
		if type(r) ~= "table" then return false end
		if r.type == "coins" then
			s.coins = s.coins + math.floor(r.amount or 0)
		elseif r.type == "speed" then
			s.speedBoostUntil = math.max(os.time(), s.speedBoostUntil or 0) + (r.seconds or 60)
			applySpeedBoost(player)
			scheduleSpeedEnd(player)
		elseif r.type == "luck" then
			s.luckUntil = math.max(os.time(), s.luckUntil or 0) + (r.seconds or 60)
			s.luckMult = r.mult or 2
		elseif r.type == "pet" then
			local info = PETS[r.pet]
			if not info then warn("[MWS] Boutique : animal inconnu " .. tostring(r.pet)); return false end
			-- deja paye : on ne perd rien, il est sauvegarde en attente d'une place
			if #s.pets >= MAX_PETS then
				table.insert(s.pendingPets, r.pet)
				return true, true
			end
			addShopPet(player, s, r.pet)
		else
			return false
		end
		return true, false
	end

	-- achats de produits (Robux) : appele par Roblox apres chaque paiement
	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local s = states[player.UserId]
		if not s then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local rid = tostring(receipt.PurchaseId)
		local function durable()
			local meta = Saves.meta[s]
			return meta ~= nil and meta.saved[rid] == true
		end
		-- recu deja en memoire : la recompense est donnee, il reste seulement a la rendre durable
		if not table.find(s.receipts, rid) then
			local item = byProduct[receipt.ProductId]
			if not item then
				warn("[MWS] Produit inconnu dans MWS_ShopConfig : " .. tostring(receipt.ProductId))
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
			local granted, queued = grantReward(player, s, item)
			if not granted then
				notify(player, "Achat recu, mais pas encore livre : il sera retente a ta prochaine connexion.", Color3.fromRGB(255, 200, 90))
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
			if item.limit then s.bought[item.key] = (s.bought[item.key] or 0) + 1 end
			-- jamais d'eviction : Roblox peut rejouer un ancien recu dans n'importe quel ordre
			table.insert(s.receipts, rid)
			sendState(player)
			refreshPetVisuals(player)
			if queued then
				notify(player, "Inventaire plein : " .. item.name .. " arrivera des qu'une place se libere.", Color3.fromRGB(255, 220, 80))
			else
				notify(player, "Merci ! " .. item.name .. " ajoute !", Color3.fromRGB(120, 255, 180))
			end
			task.spawn(sendShopInfo, player)
		end
		-- Roblox ne doit considerer l'achat livre qu'une fois recompense + recu sauvegardes ensemble.
		-- Sinon il repropose ce recu : a la reconnexion, un recu non sauvegarde redonne la recompense perdue.
		if durable() or (savePlayer(player) and durable()) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		warn("[MWS] Achat non sauvegarde pour " .. player.UserId .. " : recu " .. rid .. " en attente")
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- achats de passes
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local s = states[player.UserId]
		local item = byPass[passId]
		if not (purchased and s and item) then return end
		applyPass(s, item)
		savePlayer(player)
		sendState(player)
		notify(player, "Merci ! " .. item.name .. " active !", Color3.fromRGB(120, 255, 180))
		task.spawn(sendShopInfo, player)
	end)

	local shopBuyAt = {}
	ShopBuy.OnServerEvent:Connect(function(player, key)
		if type(key) ~= "string" then return end
		local now = os.clock()
		if shopBuyAt[player.UserId] and now - shopBuyAt[player.UserId] < 0.5 then return end
		shopBuyAt[player.UserId] = now
		local s = states[player.UserId]
		if not s then return end
		if key == "__info" then
			sendWorldInfo(player)
			task.spawn(sendShopInfo, player)
			return
		end
		local item = byKey[key]
		if not item then return end
		if type(item.id) ~= "number" or item.id <= 0 then
			notify(player, "Cet article sera bientot disponible !", Color3.fromRGB(255, 220, 80))
			return
		end
		if item.world and item.world ~= player:GetAttribute("MWS_World") then
			notify(player, "Cet article n'est disponible que dans le monde " .. item.world .. " !", Color3.fromRGB(255, 220, 80))
			return
		end
		if item.limit and (s.bought[item.key] or 0) >= item.limit then
			notify(player, "Limite atteinte : un seul exemplaire par joueur !", Color3.fromRGB(255, 220, 80))
			return
		end
		if type(item.reward) == "table" and item.reward.type == "pet" and #s.pets >= MAX_PETS then
			notify(player, "Ton inventaire est plein : libere une place avant d'acheter ce pet.", Color3.fromRGB(255, 220, 80))
			return
		end
		if item.kind == "gamepass" then
			if s.passes and s.passes[item.key] then
				notify(player, "Tu possedes deja cet article !", Color3.fromRGB(255, 220, 80))
				return
			end
			pcall(function() MarketplaceService:PromptGamePassPurchase(player, item.id) end)
		else
			pcall(function() MarketplaceService:PromptProductPurchase(player, item.id) end)
		end
	end)

	-- au chargement du joueur : retrouve ses passes deja achetes + envoie la boutique
	local function onShopPlayer(player)
		task.spawn(function()
			local waited = 0
			while not states[player.UserId] and player.Parent and waited < 30 do
				task.wait(0.25)
				waited = waited + 0.25
			end
			local s = states[player.UserId]
			if not s or not player.Parent then return end
			for _, item in ipairs(ShopConfig.Items) do
				if item.kind == "gamepass" and type(item.id) == "number" and item.id > 0 then
					local ok, owns = pcall(function()
						return MarketplaceService:UserOwnsGamePassAsync(player.UserId, item.id)
					end)
					if ok and owns then applyPass(s, item) end
				end
			end
			if (s.speedBoostUntil or 0) > os.time() then scheduleSpeedEnd(player) end
			deliverPendingPets(player, s)
			sendState(player)
			sendWorldInfo(player)
			sendShopInfo(player)
		end)
	end
	Players.PlayerAdded:Connect(onShopPlayer)
	for _, p in ipairs(Players:GetPlayers()) do onShopPlayer(p) end

	task.spawn(function()
		while task.wait(15) do
			for _, p in ipairs(Players:GetPlayers()) do
				local s = states[p.UserId]
				if s then deliverPendingPets(p, s) end
			end
		end
	end)
end

-- ============================================================
-- BOUCLES : revenus, recolte par les pets, mondes actifs
-- ============================================================

task.spawn(function()
	while task.wait(1) do
		for _, player in ipairs(Players:GetPlayers()) do
			local income = getIncome(player)
			if income > 0 then
				local s = states[player.UserId]
				if s then
					s.coins = s.coins + income
					sendState(player)
				end
			end
		end
	end
end)

-- les pets equipes recoltent les cristaux proches (1 cristal / pet / 3 s)
task.spawn(function()
	while task.wait(3) do
		for _, player in ipairs(Players:GetPlayers()) do
			local s = states[player.UserId]
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if s and hrp and not battles[player.UserId] then
				local w = worldOfPosition(hrp.Position)
				if w and w <= (s.unlockedWorld or 1) then
					local used = {}
					for _, pet in ipairs(getEquippedPets(s)) do
						local best, bd = nil, 40
						for _, c in ipairs(crystals) do
							if c.world == w and not c.busy and not used[c] then
								local d = (c.root.Position - hrp.Position).Magnitude
								if d < bd then best, bd = c, d end
							end
						end
						if best then
							used[best] = true
							local pv = petVisuals[visualKey(player, pet.id)]
							if pv then
								pv.harvestPos = best.root.Position + V3(0, 1, 0)
								pv.harvestUntil = os.clock() + 1.2
							end
							local target = best
							task.delay(0.9, function()
								if player.Parent and not target.busy then collectCrystal(target, player, true) end
							end)
						end
					end
				end
			end
		end
	end
end)

-- seuls les mondes ou se trouve un joueur sont animes
task.spawn(function()
	while task.wait(0.5) do
		local active = { false, false, false }
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local w = worldOfPosition(hrp.Position)
				if w then
					active[w] = true
					if player:GetAttribute("MWS_World") ~= w then player:SetAttribute("MWS_World", w) end
				end
			end
		end
		for i = 1, #WORLDS do activeWorld[i] = active[i] end
	end
end)

-- ============================================================
-- JOUEURS
-- ============================================================

-- combats abandonnes (aucune action depuis 3 minutes) : on les termine pour ne jamais rester bloque
task.spawn(function()
	while task.wait(10) do
		for _, player in ipairs(Players:GetPlayers()) do
			local b = battles[player.UserId]
			if b and b.active and os.clock() - (b.lastAction or 0) > 180 then
				abortBattle(player, "Defaite... Combat expire (inactivite).")
			end
		end
	end
end)

local function onPlayerAdded(player)
	loadPlayer(player)
	player.CharacterAdded:Connect(function()
		-- mort / respawn pendant un combat : on termine le combat proprement
		if battles[player.UserId] then
			abortBattle(player, "Defaite... Combat interrompu.", true)
		end
		task.wait(1)
		applySpeedBoost(player)
		refreshPetVisuals(player)
		-- renvoie les infos (le client n'est pas toujours pret lors du premier envoi)
		sendState(player)
		sendEggInfo(player)
		sendNPCInfo(player)
		sendWorldInfo(player)
		task.delay(3, function()
			if player.Parent and states[player.UserId] then
				sendState(player)
				sendEggInfo(player)
				sendNPCInfo(player)
				sendWorldInfo(player)
			end
		end)
	end)
	if player.Character then
		task.defer(function()
			applySpeedBoost(player)
			refreshPetVisuals(player)
		end)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end

Players.PlayerRemoving:Connect(function(player)
	clearPlayerVisuals(player)
	local b = battles[player.UserId]
	if b then returnPlayerFromArena(player, b) end
	battles[player.UserId] = nil
	local leaving = states[player.UserId]
	savePlayer(player, true)
	if states[player.UserId] == leaving then states[player.UserId] = nil end -- pas celui d'une reconnexion
	equipRequestAt[player.UserId] = nil
	battleActionAt[player.UserId] = nil
	speedBuyAt[player.UserId] = nil
	battleRequestAt[player.UserId] = nil
	worldTeleportAt[player.UserId] = nil
	teleporting[player] = nil
end)

task.spawn(function()
	while task.wait(60) do
		for _, p in ipairs(Players:GetPlayers()) do savePlayer(p) end
	end
end)

game:BindToClose(function()
	local pending = 0
	for _, p in ipairs(Players:GetPlayers()) do
		pending = pending + 1
		task.spawn(function()
			pcall(savePlayer, p, true)
			pending = pending - 1
		end)
	end
	while pending > 0 do
		task.wait(0.1)
	end
end)

-- ============================================================
-- INIT
-- ============================================================

worldOrigin[1] = getOrigin()
for i = 2, #WORLDS do
	worldOrigin[i] = worldOrigin[1] + WORLDS[i].offset
end

createWorld1()
createWorld2()
createWorld3()

createPortal(1, V3(0, 0, -144), 2, Color3.fromRGB(255, 120, 40))
createPortal(2, V3(0, 0, 180),  1, Color3.fromRGB(100, 255, 140))
createPortal(2, V3(0, 0, -180), 3, Color3.fromRGB(200, 100, 255))
createPortal(3, V3(0, 0, 180),  2, Color3.fromRGB(255, 120, 40))

createCrystals(1)
createCrystals(2, function(pos)
	return (V3(pos.X, 0, pos.Z) - V3(volcanoPos.X, 0, volcanoPos.Z)).Magnitude < 95
end)
createCrystals(3)

-- Arbres lego : copies de l'arbre "Arbre" du monde 1, adaptees a chaque monde
do
	local template = workspace:FindFirstChild("Arbre")
	local TREE_STYLE = {
		[2] = { trunk = Color3.fromRGB(45, 30, 28), leaves = { Color3.fromRGB(55, 45, 45), Color3.fromRGB(75, 55, 50) },
			glow = Color3.fromRGB(235, 95, 30), glowEvery = 3, count = 30 },
		[3] = { trunk = Color3.fromRGB(70, 45, 100), leaves = { Color3.fromRGB(150, 95, 255), Color3.fromRGB(95, 215, 255), Color3.fromRGB(255, 125, 220) },
			glow = Color3.fromRGB(200, 160, 255), glowEvery = 4, count = 30 },
	}
	local function isLeaf(c) return c.G > c.R * 1.1 and c.G >= c.B end
	local function plantTrees(w)
		local st = TREE_STYLE[w]
		local F = worldFolder[w]
		local o = worldOrigin[w]
		local rng = Random.new(1000 + w)
		local planted, tries = 0, 0
		while planted < st.count and tries < 400 do
			tries = tries + 1
			local pos = randomCrystalPos(w, nil)
			if pos and (V3(pos.X, 0, pos.Z) - V3(o.X, 0, o.Z)).Magnitude > 60 then
				local tree = template:Clone()
				tree.Name = "Tree_W" .. w
				local i = 0
				for _, p in ipairs(tree:GetDescendants()) do
					if p:IsA("BasePart") then
						if isLeaf(p.Color) then
							i = i + 1
							if i % st.glowEvery == 0 then
								p.Color = st.glow
								p.Material = Enum.Material.Neon
							else
								p.Color = st.leaves[(i % #st.leaves) + 1]
							end
						else
							p.Color = st.trunk
						end
						p.Anchored = true
					end
				end
				tree:PivotTo(CF(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
				local s = rng:NextNumber(0.8, 1.15)
				pcall(function() tree:ScaleTo(tree:GetScale() * s) end)
				local cf, size = tree:GetBoundingBox()
				tree:PivotTo(tree:GetPivot() + V3(0, pos.Y - (cf.Position.Y - size.Y / 2), 0))
				tree.Parent = F
				planted = planted + 1
			end
		end
		return planted
	end
	if template then
		print("[MWS] Arbres lego : " .. plantTrees(2) .. " (monde 2), " .. plantTrees(3) .. " (monde 3)")
	end
end

-- Buissons de la boite a outils (ServerStorage.MWS_Toolbox) recolores pour les mondes 2 et 3
-- (le monde 1 a les siens, poses a la main dans workspace.Decor_Buissons)
do
	local TB = game:GetService("ServerStorage"):FindFirstChild("MWS_Toolbox")
	local BUSH_STYLE = {
		[2] = { leaves = { Color3.fromRGB(58, 48, 46), Color3.fromRGB(80, 60, 52) }, flower = Color3.fromRGB(255, 120, 30), count = 34 },
		[3] = { leaves = { Color3.fromRGB(120, 80, 220), Color3.fromRGB(70, 180, 230) }, flower = Color3.fromRGB(255, 130, 230), count = 34 },
	}
	local function plantBushes(w)
		local st = BUSH_STYLE[w]
		local bush = TB and TB:FindFirstChild("Bush")
		local flower = TB and TB:FindFirstChild("FlowerBush")
		if not (st and bush and flower) then return 0 end
		local o = worldOrigin[w]
		local rng = Random.new(2000 + w)
		local planted, tries = 0, 0
		while planted < st.count and tries < 200 do
			tries = tries + 1
			local pos = randomCrystalPos(w, nil)
			if pos and (V3(pos.X, 0, pos.Z) - V3(o.X, 0, o.Z)).Magnitude > 40 then
				local isFlower = planted % 3 == 0
				local m = (isFlower and flower or bush):Clone()
				m.Name = "Bush_W" .. w
				local k = 0
				for _, p in ipairs(m:GetDescendants()) do
					if p:IsA("BasePart") then
						k = k + 1
						p.Anchored = true
						p.CanCollide = false
						if p.Name == "Flower" then
							p.Color = st.flower
							p.Material = Enum.Material.Neon
						else
							p.Color = st.leaves[(k % #st.leaves) + 1]
							if p:IsA("MeshPart") then p.TextureID = "" end
						end
					end
				end
				pcall(function() m:ScaleTo(rng:NextNumber(0.75, 1.2) * (isFlower and 0.9 or 1.3)) end)
				m:PivotTo(CF(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
				local cf, size = m:GetBoundingBox()
				m:PivotTo(m:GetPivot() + V3(0, pos.Y - (cf.Position.Y - size.Y / 2) - 0.2, 0))
				m.Parent = worldFolder[w]
				planted = planted + 1
			end
		end
		return planted
	end
	print("[MWS] Buissons : " .. plantBushes(2) .. " (monde 2), " .. plantBushes(3) .. " (monde 3)")
end

for w = 1, #WORLDS do createEggsForWorld(w) end
createNPCs()

-- ============================================================
-- MACHINES DE FUSION : 3 pets identiques -> 1 oeuf qui eclot en version amelioree
-- (chaque palier = revenu x4, force de combat x1.5, 3 paliers maximum)
-- ============================================================
do
	local FusionInfo = getRemote("FusionInfo")
	local FusionDo = getRemote("FusionDo")
	local FUSION_OFFSET = V3(-26, 0, -16)   -- meme position que dans buildCrystalKeepOut
	local FUSION_MAX_TIER = 3
	local ACCENTS = { Color3.fromRGB(190, 120, 255), Color3.fromRGB(255, 140, 60), Color3.fromRGB(120, 255, 220) }
	local machinePos = {}

	local function fusionGroups(s)
		local groups, order = {}, {}
		for _, pet in ipairs(s.pets) do
			local tier = pet.tier or 0
			local key = pet.name .. "|" .. tier
			local g = groups[key]
			if not g then
				local info = PETS[pet.name]
				g = {
					name = pet.name, tier = tier, count = 0, rarity = pet.rarity, color = pet.color,
					income = pet.income, nextIncome = math.floor(info.income * (4 ^ (tier + 1))),
					maxed = tier >= FUSION_MAX_TIER,
				}
				groups[key] = g
				table.insert(order, g)
			end
			g.count = g.count + 1
		end
		table.sort(order, function(a, b)
			local fa = (a.count >= 3 and not a.maxed)
			local fb = (b.count >= 3 and not b.maxed)
			if fa ~= fb then return fa end
			if a.income ~= b.income then return a.income > b.income end
			return a.name < b.name
		end)
		return order
	end

	local function sendFusion(player, open)
		local s = states[player.UserId]
		if not s or not player.Parent then return end
		FusionInfo:FireClient(player, fusionGroups(s), open == true)
	end

	-- Machine de fusion : le modele place a la main dans le monde 1 ("Hacker_Fusion_Machine_Roblox")
	-- sert de modele ; il est copie dans chaque monde, a la meme place par rapport au spawn.
	-- Bouton rouge / joystick = ouvrir le menu de fusion. L'ecran affiche l'etat de la machine.
	local machineTemplate = workspace:FindFirstChild("Hacker_Fusion_Machine_Roblox")
	local templatePivot
	if machineTemplate then
		templatePivot = machineTemplate:GetPivot()
		machineTemplate.Parent = game:GetService("ServerStorage")
	end
	local NEON_TINT = {
		nil,
		{ Color3.fromRGB(255, 120, 30), Color3.fromRGB(255, 200, 60) },   -- monde 2 : lave
		{ Color3.fromRGB(80, 230, 255), Color3.fromRGB(210, 120, 255) },  -- monde 3 : cosmique
	}

	local function marker(name, size, cf, folder, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		if shape then p.Shape = shape end
		p.Parent = folder
		return p
	end

	-- face d'une piece la plus tournee vers 'dir'
	local function faceToward(part, dir)
		local best, bd = Enum.NormalId.Front, -2
		for _, n in ipairs(Enum.NormalId:GetEnumItems()) do
			local v = part.CFrame:VectorToWorldSpace(Vector3.FromNormalId(n))
			local d = v:Dot(dir)
			if d > bd then best, bd = n, d end
		end
		return best
	end

	local function buildMachine(w)
		if not machineTemplate then
			warn("[MWS] Machine de fusion introuvable (Hacker_Fusion_Machine_Roblox)")
			return
		end
		local model = machineTemplate:Clone()
		model.Name = "FusionMachine"
		local shift = worldOrigin[w] - worldOrigin[1]
		model:PivotTo(templatePivot + shift)
		-- pose la machine sur le sol de ce monde
		local cf, size = model:GetBoundingBox()
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { petsFolder, model }
		params.FilterType = Enum.RaycastFilterType.Exclude
		local hit = workspace:Raycast(cf.Position + V3(0, 60, 0), V3(0, -160, 0), params)
		if hit then model:PivotTo(model:GetPivot() + V3(0, hit.Position.Y - (cf.Position.Y - size.Y / 2), 0)) end
		cf, size = model:GetBoundingBox()
		local front = cf.LookVector -- cote console + reacteur
		local base = cf.Position - V3(0, size.Y / 2, 0)
		machinePos[w] = base

		-- couleurs des neons adaptees au monde
		local tint = NEON_TINT[w]
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				if tint and (d.Material == Enum.Material.Neon or d.Material == Enum.Material.Glass) then
					local h, sat = d.Color:ToHSV()
					if sat > 0.4 and h > 0.12 and h < 0.45 then
						d.Color = (h < 0.2) and tint[2] or tint[1]
					end
				end
			elseif d:IsA("ParticleEmitter") and tint then
				d.Color = ColorSequence.new(tint[1], tint[2])
			end
		end
		model.Parent = worldFolder[w]

		-- reperes pour l'animation de fusion du client (3 reservoirs + orbe au-dessus)
		local tanks = {}
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d.Name:find("liquid_core_chamber_core") then table.insert(tanks, d) end
		end
		table.sort(tanks, function(x, y) return cf:PointToObjectSpace(x.Position).X < cf:PointToObjectSpace(y.Position).X end)
		for i, t in ipairs(tanks) do
			marker("PodGlass" .. i, V3(t.Size.Y, t.Size.X, t.Size.Z), CF(t.Position) * CFrame.Angles(0, 0, math.rad(90)), model, Enum.PartType.Cylinder)
		end
		marker("FusionBase", V3(1, 1, 1), CF(base), model)
		local orb = marker("FusionOrb", V3(1, 1, 1), CF(cf.Position + V3(0, size.Y / 2 + 3, 0)), model)

		-- ecran de la console
		local screen, button, joystick
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				if d.Name:find("black_screen_screen") then screen = d end
				if d.Name:find("physical_red_button") then button = d end
				if d.Name:find("joystick_knob") then joystick = d end
			end
		end
		local screenLbl
		if screen then
			-- panneau invisible colle devant l'ecran (le texte s'affiche dessus)
			local panel = marker("ScreenText", V3(screen.Size.X * 0.92, screen.Size.Y * 0.85, 0.05),
				CFrame.lookAt(screen.Position + front * (screen.Size.Z / 2 + 0.45), screen.Position + front * 2), model)
			local sg = Instance.new("SurfaceGui")
			sg.Face = Enum.NormalId.Front
			sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
			sg.CanvasSize = Vector2.new(300, 100)
			sg.Parent = panel
			screenLbl = Instance.new("TextLabel")
			screenLbl.Size = UDim2.new(1, 0, 1, 0)
			screenLbl.BackgroundColor3 = Color3.fromRGB(5, 15, 10)
			screenLbl.Text = "FUSION PRETE"
			screenLbl.TextScaled = true
			screenLbl.Font = Enum.Font.Arcade
			screenLbl.TextColor3 = tint and tint[1] or Color3.fromRGB(90, 255, 120)
			screenLbl.Parent = sg
			task.spawn(function()
				local msgs = { "FUSION PRETE", "3 PETS = 1", "APPUIE >>", "EVOLUTION" }
				local k = 0
				while screenLbl.Parent do
					k = k % #msgs + 1
					if not screenLbl:GetAttribute("Busy") then screenLbl.Text = msgs[k] end
					task.wait(1.6)
				end
			end)
		end

		local function open(player)
			if battles[player.UserId] then return end
			if _G.MWS_TutLock and _G.MWS_TutLock(player, "fusion") then return end
			sendFusion(player, true)
		end
		-- bouton rouge : s'enfonce, s'allume, puis ouvre le menu
		local pressing = false
		local function press(player)
			if button and not pressing then
				pressing = true
				local home = button.CFrame
				local col = button.Color
				local down = home - front * 0.12 * model:GetScale() + V3(0, -0.08, 0) * model:GetScale()
				TweenService:Create(button, TweenInfo.new(0.08), { CFrame = down, Color = Color3.fromRGB(255, 240, 120) }):Play()
				task.delay(0.18, function()
					TweenService:Create(button, TweenInfo.new(0.15), { CFrame = home, Color = col }):Play()
					pressing = false
				end)
			end
			if screenLbl then
				screenLbl:SetAttribute("Busy", true)
				screenLbl.Text = "ACCES OK"
				task.delay(1.2, function() if screenLbl.Parent then screenLbl:SetAttribute("Busy", nil) end end)
			end
			open(player)
		end
		local promptHost = button or orb
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "FusionPrompt"
		prompt.ActionText = "Appuyer : fusionner des pets"
		prompt.ObjectText = "Machine de fusion"
		prompt.HoldDuration = 0.3
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = 16
		prompt.Parent = promptHost
		prompt.Triggered:Connect(press)
		for _, part in ipairs({ button, joystick }) do
			if part then
				local cd = Instance.new("ClickDetector")
				cd.MaxActivationDistance = 24
				cd.Parent = part
				cd.MouseClick:Connect(function(player)
					if part == joystick then
						local home = part.CFrame
						TweenService:Create(part, TweenInfo.new(0.1), { CFrame = home * CFrame.Angles(math.rad(20), 0, 0) }):Play()
						task.delay(0.15, function() TweenService:Create(part, TweenInfo.new(0.15), { CFrame = home }):Play() end)
					end
					press(player)
				end)
			end
		end
	end

	local lastFuse = {}
	FusionDo.OnServerEvent:Connect(function(player, name, tier)
		if type(name) ~= "string" or type(tier) ~= "number" then return end
		tier = math.floor(tier)
		local now = os.clock()
		if lastFuse[player.UserId] and now - lastFuse[player.UserId] < 1 then return end
		lastFuse[player.UserId] = now
		local s = states[player.UserId]
		if not s or battles[player.UserId] then return end
		if s.hatchBusyUntil and os.clock() < s.hatchBusyUntil then return end
		if _G.MWS_TutLock and _G.MWS_TutLock(player, "fusion") then return end
		local info = PETS[name]
		if not info or tier < 0 or tier >= FUSION_MAX_TIER then return end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local nearW, nearD = nil, 45
		for w, mp in pairs(machinePos) do
			local d = (mp - hrp.Position).Magnitude
			if d < nearD then nearW, nearD = w, d end
		end
		if not nearW then
			notify(player, "Approche-toi d'une machine de fusion !", Color3.fromRGB(255, 120, 120))
			return
		end

		-- 3 pets identiques (meme animal, meme niveau) ; on consomme d'abord ceux qui ne sont pas equipes
		local eq = {}
		for _, id in ipairs(s.equipped) do eq[id] = true end
		local cands = {}
		for _, pet in ipairs(s.pets) do
			if pet.name == name and (pet.tier or 0) == tier then table.insert(cands, pet) end
		end
		if #cands < 3 then
			notify(player, "Il te faut 3 pets identiques (meme niveau) !", Color3.fromRGB(255, 120, 120))
			return
		end
		table.sort(cands, function(a, b)
			if (eq[a.id] or false) ~= (eq[b.id] or false) then return not eq[a.id] end
			return a.id < b.id
		end)
		local used = {}
		for i = 1, 3 do used[cands[i].id] = true end
		local keep, keepEq = {}, {}
		for _, pet in ipairs(s.pets) do
			if not used[pet.id] then table.insert(keep, pet) end
		end
		for _, id in ipairs(s.equipped) do
			if not used[id] then table.insert(keepEq, id) end
		end
		s.pets, s.equipped = keep, keepEq

		local id = s.nextPetId
		s.nextPetId = id + 1
		local nt = tier + 1
		local bestSize, bestMut
		for k = 1, 3 do
			local c = cands[k]
			local cs, cm = Traits.SIZE[c.size or ""], Traits.MUTATION[c.mutation or ""]
			if cs and (not bestSize or cs.mult > Traits.SIZE[bestSize].mult) then bestSize = c.size end
			if cm and (not bestMut or cm.mult > Traits.MUTATION[bestMut].mult) then bestMut = c.mutation end
		end
		local newPet = { id = id, name = name, rarity = info.rarity, color = info.color, tier = nt, size = bestSize, mutation = bestMut }
		local tm = Traits.mult(newPet)
		newPet.multiplier = info.multiplier * (1.5 ^ nt) * tm
		newPet.income = math.floor(info.income * (4 ^ nt) * tm)
		table.insert(s.pets, newPet)
		if #s.equipped < maxEquip(s) then table.insert(s.equipped, id) end
		while #s.equipped > maxEquip(s) do table.remove(s.equipped) end
		if _G.MWS_Track then _G.MWS_Track(player, "fusion") end

		-- le pet fusionne n'apparait a cote du joueur qu'a la fin de l'animation de fusion
		clearPlayerVisuals(player)
		s.hatchBusyUntil = os.clock() + 7
		task.delay(7, function()
			if player.Parent and states[player.UserId] == s and not battles[player.UserId] then
				refreshPetVisuals(player)
			end
		end)
		BuyEgg:FireClient(player, { success = true, pet = newPet, eggName = "Oeuf de fusion", fusion = true })
		sendState(player)
		sendFusion(player, false)

		local mp = machinePos[nearW]
		popText(world, mp + V3(0, 15, 0), "FUSION !", ACCENTS[nearW] or WHITE)
		local burst = Instance.new("Part")
		burst.Shape = Enum.PartType.Ball
		burst.Anchored = true
		burst.CanCollide = false
		burst.CanQuery = false
		burst.Material = Enum.Material.Neon
		burst.Color = ACCENTS[nearW] or WHITE
		burst.Transparency = 0.3
		burst.Size = V3(4, 4, 4)
		burst.Position = mp + V3(0, 12.5, 0)
		burst.Parent = world
		TweenService:Create(burst, TweenInfo.new(0.9), { Size = V3(26, 26, 26), Transparency = 1 }):Play()
		Debris:AddItem(burst, 1)
		savePlayer(player)
	end)

	for w = 1, #WORLDS do buildMachine(w) end
end

-- ============================================================
-- PROGRESSION : tutoriel guide, pokedex, recompense quotidienne, quetes du jour, classement
-- ============================================================
do
	local MetaInfo = getRemote("MetaInfo")
	local MetaAction = getRemote("MetaAction")
	local DexInfo = getRemote("DexInfo")
	local BoardInfo = getRemote("BoardInfo")
	local GOLD = Color3.fromRGB(255, 220, 80)

	-- objectifs du tutoriel (dans l'ordre)
	-- Tant que le tutoriel n'est pas fini, le joueur ne peut faire que l'etape en cours
	-- (voir _G.MWS_TutLock). target = fleche dans le monde, ui = fleche vers un bouton.
	local TUT = {
		{ event = "egg",     need = 1, reward = 100, target = "egg",     text = "Suis la fleche jusqu'a l'Oeuf de base et appuie sur E" },
		{ event = "equip",   need = 1, reward = 150, ui = "pets",        text = "Ouvre le menu Pets et equipe ton nouvel animal" },
		{ event = "crystal", need = 3, reward = 250, target = "crystal", text = "Approche-toi des cristaux : tes pets les ramassent" },
		{ event = "train",   need = 1, reward = 300, target = "bag",     text = "Entraine tes pets au sac de frappe (appuie sur E)" },
		{ event = "battle",  need = 1, reward = 500, ui = "combat",      text = "Bats ton premier dresseur : ouvre le menu Combat" },
	}
	local TUT_BONUS = 1000 -- bonus de fin de tutoriel (+ potion de chance x2 pendant 5 min)

	-- quetes : 3 tirees chaque jour (meme tirage pour tout le monde)
	local QUEST_POOL = {
		{ id = "eggs5",    event = "egg",     need = 5,  base = 400,  text = "Acheter 5 oeufs" },
		{ id = "eggs15",   event = "egg",     need = 15, base = 1500, text = "Acheter 15 oeufs" },
		{ id = "crys20",   event = "crystal", need = 20, base = 600,  text = "Ramasser 20 cristaux" },
		{ id = "crys60",   event = "crystal", need = 60, base = 1800, text = "Ramasser 60 cristaux" },
		{ id = "battle1",  event = "battle",  need = 1,  base = 500,  text = "Gagner 1 combat" },
		{ id = "battle3",  event = "battle",  need = 3,  base = 1500, text = "Gagner 3 combats" },
		{ id = "fusion1",  event = "fusion",  need = 1,  base = 2000, text = "Fusionner des pets (1 fois)" },
		{ id = "equip3",   event = "equip",   need = 3,  base = 300,  text = "Equiper des pets (3 fois)" },
		{ id = "train3",   event = "train",   need = 3,  base = 800,  text = "Entrainer tes pets (3 fois)" },
		{ id = "train8",   event = "train",   need = 8,  base = 2200, text = "Entrainer tes pets (8 fois)" },
	}
	local DAILY = { 500, 1000, 2000, 3500, 5000, 8000, 15000 }   -- le jour 7 donne aussi une potion de chance

	local totalPets = 0
	for _ in pairs(PETS) do totalPets = totalPets + 1 end

	local function scale(s)
		return (3 ^ ((s.unlockedWorld or 1) - 1)) * (1 + (s.rebirthLevel or 0))
	end

	local function ensure(s)
		s.tut = math.floor(finiteNumber(s.tut, 1, 1, #TUT + 1))
		s.tutProg = math.floor(finiteNumber(s.tutProg, 0, 0, 1e6))
		if type(s.dex) ~= "table" then s.dex = {} end
		if type(s.dexClaimed) ~= "table" then s.dexClaimed = {} end
		if type(s.daily) ~= "table" then s.daily = {} end
		s.daily.day = math.floor(finiteNumber(s.daily.day, 0, 0, 1e9))
		s.daily.streak = math.floor(finiteNumber(s.daily.streak, 0, 0, 1e6))
		if type(s.quests) ~= "table" then s.quests = {} end
		s.quests.day = math.floor(finiteNumber(s.quests.day, 0, 0, 1e9))
		if type(s.quests.prog) ~= "table" then s.quests.prog = {} end
		if type(s.quests.claimed) ~= "table" then s.quests.claimed = {} end
	end

	local function today() return os.time() // 86400 end

	local function rollQuests(s)
		local d = today()
		if s.quests.day ~= d then
			s.quests.day = d
			s.quests.prog = {}
			s.quests.claimed = {}
		end
	end

	local function todaysQuests(d)
		local rng = Random.new(d)
		local idx = {}
		for i = 1, #QUEST_POOL do idx[i] = i end
		for i = #idx, 2, -1 do
			local j = rng:NextInteger(1, i)
			idx[i], idx[j] = idx[j], idx[i]
		end
		local out = {}
		for i = 1, 3 do out[i] = QUEST_POOL[idx[i]] end
		return out
	end

	local function countDex(s)
		local n = 0
		for name in pairs(s.dex) do
			if PETS[name] then n = n + 1 end
		end
		return n
	end

	local function markDex(player, s, name)
		if type(name) == "string" and PETS[name] and not s.dex[name] then
			s.dex[name] = true
			-- attendu apres l'animation d'eclosion, pour ne pas devoiler le pet trop tot
			local msg = "Pokedex : " .. name .. " decouvert ! (" .. countDex(s) .. "/" .. totalPets .. ")"
			task.delay(7, function()
				if player.Parent then notify(player, msg, Color3.fromRGB(150, 220, 255)) end
			end)
		end
	end

	-- cibles du tutoriel (fleche dans le monde)
	local eggSpots = {}
	local function eggStands(w)
		if not eggSpots[w] then
			local list = {}
			for _, d in ipairs(worldFolder[w]:GetDescendants()) do
				if d:IsA("ProximityPrompt") and d.Name == "BuyEggPrompt_1" and d.Parent:IsA("BasePart") then
					table.insert(list, d.Parent.Position)
				end
			end
			eggSpots[w] = list
		end
		return eggSpots[w]
	end

	local function tutTarget(player, s)
		local step = TUT[s.tut]
		if not step or not step.target then return nil end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return nil end
		local w = player:GetAttribute("MWS_World") or 1
		local best, bd = nil, math.huge
		local function consider(p)
			local dist = (p - hrp.Position).Magnitude
			if dist < bd then best, bd = p, dist end
		end
		if step.target == "egg" then
			for _, p in ipairs(eggStands(w)) do consider(p) end
		elseif step.target == "crystal" then
			for _, c in ipairs(crystals) do
				if c.world == w and not c.busy and c.pos then consider(c.pos) end
			end
		elseif step.target == "bag" then
			for _, d in ipairs(workspace:GetDescendants()) do
				if d:IsA("Model") and d.Name == "Punching Bag" and worldOfPosition(d:GetPivot().Position) == w then
					consider(d:GetPivot().Position)
				end
			end
		end
		return best
	end

	local function sendMeta(player)
		local s = states[player.UserId]
		if not s or not player.Parent then return end
		ensure(s)
		rollQuests(s)
		local d = today()
		local sc = scale(s)

		local tut
		local step = TUT[s.tut]
		if step and not TEST_MODE then
			tut = { step = s.tut, total = #TUT, text = step.text, prog = s.tutProg, need = step.need, reward = step.reward, target = tutTarget(player, s), ui = step.ui, event = step.event }
		end

		local quests = {}
		for i, q in ipairs(todaysQuests(d)) do
			quests[i] = {
				id = q.id, text = q.text, need = q.need,
				prog = math.min(q.need, s.quests.prog[q.id] or 0),
				reward = math.floor(q.base * sc),
				claimed = s.quests.claimed[q.id] == true,
			}
		end

		local claimedToday = s.daily.day == d
		local streak = claimedToday and s.daily.streak or ((s.daily.day == d - 1) and (s.daily.streak + 1) or 1)
		local rewards = {}
		for i = 1, #DAILY do rewards[i] = math.floor(DAILY[i] * sc) end
		local daily = { claimed = claimedToday, streak = streak, index = ((streak - 1) % 7) + 1, rewards = rewards }

		MetaInfo:FireClient(player, { tut = tut, daily = daily, quests = quests, secondsLeft = 86400 - (os.time() % 86400) })
	end

	local function satisfied(s, step)
		if step.event == "egg" then return #s.pets > 0 end
		if step.event == "equip" then return #s.equipped > 0 end
		if step.event == "battle" then return #s.defeatedNPCs > 0 end
		if step.event == "world" then return (s.unlockedWorld or 1) >= step.need end
		return false
	end

	local function advanceTut(player, s)
		while true do
			local step = TUT[s.tut]
			if not step then return end
			if s.tutProg >= step.need or satisfied(s, step) then
				s.coins = s.coins + step.reward
				notify(player, "Objectif termine : +" .. fmt(step.reward) .. " coins !", GOLD)
				s.tut = s.tut + 1
				s.tutProg = 0
				if s.tut > #TUT then
					s.coins = s.coins + TUT_BONUS
					s.luckUntil = math.max(os.time(), s.luckUntil or 0) + 300
					s.luckMult = math.max(s.luckMult or 1, 2)
					task.delay(1.5, function()
						if player.Parent then notify(player, "Tutoriel termine ! Tout est debloque : +" .. fmt(TUT_BONUS) .. " coins et chance x2 (5 min)", GOLD) end
					end)
				end
				sendState(player)
				sendMeta(player)
			else
				return
			end
		end
	end

	-- verrou du tutoriel : renvoie true (et previent le joueur) si l'action est bloquee
	local lockMsgAt = {}
	_G.MWS_TutLock = function(player, action, arg)
		if TEST_MODE then return false end -- mode test : tout est accessible tout de suite
		local s = states[player.UserId]
		if not s then return false end
		ensure(s)
		local step = TUT[s.tut]
		if not step then return false end
		local ok = (action == "egg" and step.event == "egg" and arg == 1)
			or (action == "battle" and step.event == "battle" and arg == 1)
			or (action == "train" and step.event == "train")
		if ok then return false end
		local now = os.clock()
		if not lockMsgAt[player.UserId] or now - lockMsgAt[player.UserId] > 2 then
			lockMsgAt[player.UserId] = now
			notify(player, "Termine d'abord le tutoriel : " .. step.text, Color3.fromRGB(255, 200, 90))
		end
		return true
	end

	-- appele par le reste du jeu : egg / pet / equip / crystal / battle / world / fusion
	_G.MWS_Track = function(player, event, arg)
		local s = states[player.UserId]
		if not s then return end
		ensure(s)
		if event == "pet" then
			markDex(player, s, arg)
			return
		end
		local step = TUT[s.tut]
		if step and step.event == event then
			if event == "world" then
				if (tonumber(arg) or 0) >= step.need then s.tutProg = step.need end
			else
				s.tutProg = s.tutProg + 1
			end
		end
		advanceTut(player, s)
		rollQuests(s)
		for _, q in ipairs(todaysQuests(today())) do
			if q.event == event then s.quests.prog[q.id] = (s.quests.prog[q.id] or 0) + 1 end
		end
		sendMeta(player)
	end

	-- ---------- pokedex ----------
	local function sendDex(player)
		local s = states[player.UserId]
		if not s then return end
		ensure(s)
		local eggs = {}
		for i, def in ipairs(EGGS) do
			local pets, found = {}, 0
			for _, entry in ipairs(def.pool) do
				local info = PETS[entry.pet]
				local ok = s.dex[entry.pet] == true
				if ok then found = found + 1 end
				pets[#pets + 1] = { name = entry.pet, rarity = info.rarity, color = info.color, income = info.income, discovered = ok }
			end
			eggs[i] = {
				idx = i, name = def.name, color = def.color, reward = def.price * 10,
				count = found, total = #def.pool, complete = found == #def.pool,
				claimed = s.dexClaimed[tostring(i)] == true, pets = pets,
			}
		end
		DexInfo:FireClient(player, { eggs = eggs, found = countDex(s), total = totalPets })
	end

	local function claimDex(player, s, idx)
		local def = EGGS[idx]
		if not def or s.dexClaimed[tostring(idx)] then return end
		for _, entry in ipairs(def.pool) do
			if not s.dex[entry.pet] then return end
		end
		s.dexClaimed[tostring(idx)] = true
		local reward = def.price * 10
		s.coins = s.coins + reward
		notify(player, "Collection " .. def.name .. " complete ! +" .. fmt(reward) .. " coins", GOLD)
		sendState(player)
		savePlayer(player)
		sendDex(player)
	end

	-- ---------- quotidien / quetes ----------
	local function claimDaily(player, s)
		local d = today()
		if s.daily.day == d then
			notify(player, "Recompense du jour deja reclamee, reviens demain !", GOLD)
			return
		end
		local streak = (s.daily.day == d - 1) and (s.daily.streak + 1) or 1
		local idx = ((streak - 1) % 7) + 1
		local reward = math.floor(DAILY[idx] * scale(s))
		s.coins = s.coins + reward
		local extra = ""
		if idx == 7 then
			s.luckUntil = math.max(os.time(), s.luckUntil or 0) + 900
			s.luckMult = math.max(s.luckMult or 1, 2)
			extra = " + potion de chance 15 min"
		end
		s.daily.day, s.daily.streak = d, streak
		notify(player, "Jour " .. streak .. " : +" .. fmt(reward) .. " coins" .. extra .. " !", GOLD)
		sendState(player)
		savePlayer(player)
		sendMeta(player)
	end

	local function claimQuest(player, s, id)
		rollQuests(s)
		for _, q in ipairs(todaysQuests(today())) do
			if q.id == id then
				if s.quests.claimed[id] or (s.quests.prog[id] or 0) < q.need then return end
				s.quests.claimed[id] = true
				local reward = math.floor(q.base * scale(s))
				s.coins = s.coins + reward
				notify(player, "Quete terminee : +" .. fmt(reward) .. " coins !", GOLD)
				sendState(player)
				savePlayer(player)
				sendMeta(player)
				return
			end
		end
	end

	-- ---------- classement du serveur ----------
	local function sendBoard(player)
		local rows = {}
		for _, p in ipairs(Players:GetPlayers()) do
			local s = states[p.UserId]
			if s then
				local best = 0
				for _, pet in ipairs(s.pets) do best = math.max(best, pet.income or 0) end
				rows[#rows + 1] = { name = p.DisplayName, income = getIncome(p), pets = #s.pets, rebirth = s.rebirthLevel or 0, best = best }
			end
		end
		table.sort(rows, function(a, b) return a.income > b.income end)
		while #rows > 10 do table.remove(rows) end
		BoardInfo:FireClient(player, rows)
	end

	local lastAct = {}
	MetaAction.OnServerEvent:Connect(function(player, kind, arg)
		if type(kind) ~= "string" then return end
		local now = os.clock()
		if lastAct[player.UserId] and now - lastAct[player.UserId] < 0.2 then return end
		lastAct[player.UserId] = now
		local s = states[player.UserId]
		if not s then return end
		ensure(s)
		if kind == "meta" then
			sendMeta(player)
		elseif kind == "daily" then
			claimDaily(player, s)
		elseif kind == "quest" then
			if type(arg) == "string" and #arg <= 20 then claimQuest(player, s, arg) end
		elseif kind == "dexinfo" then
			sendDex(player)
		elseif kind == "dex" then
			if type(arg) == "number" and arg == math.floor(arg) and arg >= 1 and arg <= #EGGS then claimDex(player, s, arg) end
		elseif kind == "board" then
			sendBoard(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player) lastAct[player.UserId] = nil end)

	-- au chargement : rattrape le tutoriel / pokedex des anciennes sauvegardes
	local function onMetaPlayer(player)
		task.spawn(function()
			local waited = 0
			while not states[player.UserId] and player.Parent and waited < 30 do
				task.wait(0.25)
				waited = waited + 0.25
			end
			local s = states[player.UserId]
			if not s or not player.Parent then return end
			ensure(s)
			for _, pet in ipairs(s.pets) do
				if PETS[pet.name] then s.dex[pet.name] = true end
			end
			advanceTut(player, s)
			sendMeta(player)
		end)
	end
	Players.PlayerAdded:Connect(onMetaPlayer)
	for _, p in ipairs(Players:GetPlayers()) do onMetaPlayer(p) end

	-- la fleche du tutoriel suit la cible la plus proche
	task.spawn(function()
		while task.wait(2) do
			for _, p in ipairs(Players:GetPlayers()) do
				local s = states[p.UserId]
				if s and (s.tut or 1) <= #TUT then sendMeta(p) end
			end
		end
	end)
end

-- ============================================================
-- ENTRAINEMENT : sacs de frappe (les pets gagnent des niveaux)
-- ============================================================
-- TRAINING_START
do
	local TRAIN_TIME = 10                 -- intervalle entre deux gains d'XP (l'entrainement n'a plus de limite de duree)
	local TRAIN_XP = { 20, 50, 120 }      -- XP gagnee par pet toutes les TRAIN_TIME secondes, selon le monde
	local TRAIN_CAP = { 5, 12, 20 }       -- niveau maximum atteignable dans chaque monde
	local RED = Color3.fromRGB(255, 120, 120)
	local GOLD = Color3.fromRGB(255, 215, 90)
	local GREEN = Color3.fromRGB(120, 255, 140)

	local trainSessions = {}
	local bagInfo = {}

	local function setupBag(model)
		if bagInfo[model] then return end
		local pivot = model:GetPivot().Position
		local w = worldOfPosition(pivot)
		if not w then return end

		local hang = model:FindFirstChild("Bag")
		local hangPart = hang and hang:FindFirstChildWhichIsA("BasePart", true)
		local hangRoot = hangPart and (hangPart.AssemblyRootPart or hangPart)
		if hangRoot and not hangRoot.Anchored then
			pcall(function() hangRoot:SetNetworkOwner(nil) end)
		end

		local anchor = Instance.new("Part")
		anchor.Name = "TrainAnchor"
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Transparency = 1
		anchor.Size = V3(1, 1, 1)
		anchor.Position = V3(pivot.X, pivot.Y - 2.5, pivot.Z)
		anchor.Parent = model

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 240, 0, 52)
		bb.StudsOffset = V3(0, 10, 0)
		bb.MaxDistance = 80
		bb.Adornee = anchor
		bb.Parent = anchor
		-- panneau sobre : fond sombre, texte blanc de taille fixe (lisible)
		local bgf = Instance.new("Frame")
		bgf.Size = UDim2.new(1, 0, 1, 0)
		bgf.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
		bgf.BackgroundTransparency = 0.3
		bgf.Parent = bb
		local bgc = Instance.new("UICorner")
		bgc.CornerRadius = UDim.new(0, 10)
		bgc.Parent = bgf
		local t1 = Instance.new("TextLabel")
		t1.Size = UDim2.new(1, 0, 0.52, 0)
		t1.BackgroundTransparency = 1
		t1.Text = "Sac d'entrainement"
		t1.TextColor3 = Color3.fromRGB(255, 220, 140)
		t1.Font = Enum.Font.GothamBold
		t1.TextSize = 17
		t1.Parent = bgf
		local t2 = Instance.new("TextLabel")
		t2.Size = UDim2.new(1, 0, 0.42, 0)
		t2.Position = UDim2.new(0, 0, 0.52, 0)
		t2.BackgroundTransparency = 1
		t2.Text = "Niveau max des pets : " .. TRAIN_CAP[w]
		t2.TextColor3 = Color3.fromRGB(230, 230, 240)
		t2.Font = Enum.Font.GothamMedium
		t2.TextSize = 14
		t2.Parent = bgf

		local burst
		if hangRoot then
			burst = Instance.new("ParticleEmitter")
			burst.Rate = 0
			burst.Lifetime = NumberRange.new(0.3, 0.6)
			burst.Speed = NumberRange.new(8, 16)
			burst.SpreadAngle = Vector2.new(180, 180)
			burst.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
			burst.Color = ColorSequence.new(Color3.fromRGB(255, 230, 120))
			burst.LightEmission = 1
			burst.Parent = hangRoot
		end

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "TrainPrompt"
		prompt.ActionText = "Entrainer tes pets"
		prompt.ObjectText = "Sac de frappe - Monde " .. w
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.HoldDuration = 0.3
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = anchor

		local info = { model = model, world = w, anchor = anchor, prompt = prompt, hangRoot = hangRoot, burst = burst, sub = t2, busy = false }
		bagInfo[model] = info
		prompt.Triggered:Connect(function(player)
			if _G.MWS_TutLock and _G.MWS_TutLock(player, "train") then return end
			if _G.MWS_StartTraining then _G.MWS_StartTraining(player, info) end
		end)
	end

	local function bagPosition(info)
		if info.hangRoot and info.hangRoot.Parent then return info.hangRoot.Position end
		return info.anchor.Position + V3(0, 3, 0)
	end

	_G.MWS_StartTraining = function(player, info)
		local uid = player.UserId
		local s = states[uid]
		if not s then return end
		-- deja en train de s'entrainer sur ce sac : un 2e appui arrete l'entrainement
		if info.busy and info.owner == uid then
			info.stop = true
			return
		end
		if info.busy or trainSessions[uid] or battles[uid] then return end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then return end
		if (hrp.Position - info.anchor.Position).Magnitude > 30 then return end
		if worldOfPosition(hrp.Position) ~= info.world then return end
		if (s.unlockedWorld or 1) < info.world then
			notify(player, "Debloque d'abord ce monde pour t'entrainer ici !", RED)
			return
		end

		local pets = getEquippedPets(s)
		if #pets == 0 then
			notify(player, "Equipe au moins un pet pour l'entrainer !", RED)
			return
		end
		local cap = TRAIN_CAP[info.world]
		local canGrow = false
		for _, p in ipairs(pets) do
			if (p.lvl or 0) < cap then canGrow = true break end
		end
		if not canGrow then
			notify(player, "Tes pets ont atteint le niveau max de ce monde (Niv " .. cap .. "). Va dans un monde plus avance !", GOLD)
			return
		end

		info.busy = true
		info.owner = uid
		info.stop = false
		info.prompt.ActionText = "Arreter l'entrainement"
		trainSessions[uid] = true
		local worldN = info.world

		task.spawn(function()
			local reason = "Entrainement termine"
			local ok, err = pcall(function()
				local t0 = os.clock()
				local lastTick = t0
				local totalGain = 0
				local hitting = {}
				notify(player, "Entrainement en cours ! Appuie de nouveau sur E pres du sac pour arreter.", GREEN)
				while true do
					local now = os.clock()
					local elapsed = now - t0
					if info.stop then reason = "Entrainement arrete" break end
					if not player.Parent or not states[uid] then reason = nil break end
					if not hrp.Parent or hum.Health <= 0 or battles[uid]
						or (hrp.Position - info.anchor.Position).Magnitude > 60 then
						reason = "Tu t'es eloigne : entrainement arrete"
						break
					end
					pets = getEquippedPets(s)
					local n = #pets
					if n == 0 then reason = "Plus aucun pet equipe : entrainement arrete" break end

					local bagPos = bagPosition(info)
					local ang0 = math.atan2(hrp.Position.Z - bagPos.Z, hrp.Position.X - bagPos.X)
					local running = false
					for i, pet in ipairs(pets) do
						if (pet.lvl or 0) < cap then running = true end
						local pv = petVisuals[visualKey(player, pet.id)]
						if pv then
							local angle = ang0 + (i - (n + 1) / 2) * 0.5
							local radius = 9 + (pv.spread or 5) * 0.35
							local dir = V3(math.cos(angle), 0, math.sin(angle))
							local y = hrp.Position.Y + (pv.flying and (pv.flyY or 1.2) or pv.groundY)
							local flat = V3(bagPos.X, y, bagPos.Z)
							local ringPos = flat + dir * radius
							local isHit = ((elapsed + i * 0.23) % 1.3) < 0.42
							local target = ringPos
							if isHit then
								target = flat + dir * (3 + (pv.spread or 5) * 0.25)
								if not hitting[i] then
									hitting[i] = true
									task.delay(0.14, function()
										if info.hangRoot and info.hangRoot.Parent and not info.hangRoot.Anchored then
											local away = V3(-dir.X, 0.12, -dir.Z)
											info.hangRoot.AssemblyLinearVelocity = info.hangRoot.AssemblyLinearVelocity + away * 26
										end
										if info.burst then info.burst:Emit(8) end
									end)
								end
							else
								hitting[i] = false
							end
							pv.harvestPos = target
							pv.harvestUntil = now + 0.5
							pv.faceTarget = flat
							pv.faceUntil = now + 0.5
						end
					end

					-- gain d'XP toutes les TRAIN_TIME secondes (sans limite de duree)
					local untilTick = TRAIN_TIME - (now - lastTick)
					info.sub.Text = "Entrainement... prochain gain dans " .. math.max(0, math.ceil(untilTick)) .. " s"
					if now - lastTick >= TRAIN_TIME then
						lastTick = now
						if (s.unlockedWorld or 1) < worldN then
							reason = "Monde non debloque : entrainement arrete"
							break
						end
						local gain = TRAIN_XP[worldN]
						local levelUps = {}
						for _, pet in ipairs(pets) do
							if table.find(s.pets, pet) then
								local lvl = pet.lvl or 0
								if lvl < cap then
									pet.xp = (pet.xp or 0) + gain
									local up = false
									while lvl < cap and pet.xp >= petXpNeeded(lvl) do
										pet.xp = pet.xp - petXpNeeded(lvl)
										lvl = lvl + 1
										up = true
									end
									pet.lvl = lvl
									if lvl >= cap then pet.xp = 0 end
									if up then table.insert(levelUps, pet.name .. " : Niv " .. lvl) end
								end
							end
						end
						totalGain = totalGain + gain
						if _G.MWS_Track then _G.MWS_Track(player, "train") end
						sendState(player)
						for _, msg in ipairs(levelUps) do
							notify(player, "NIVEAU SUPERIEUR ! " .. msg, GOLD)
						end
						if #levelUps > 0 then refreshPetVisuals(player) end
						running = false
						for _, pet in ipairs(getEquippedPets(s)) do
							if (pet.lvl or 0) < cap then running = true end
						end
						if not running then
							reason = "Tes pets ont atteint le niveau max de ce monde (Niv " .. cap .. ")"
							break
						end
					end
					task.wait(0.1)
				end

				-- fin : on libere les pets
				for _, pet in ipairs(pets) do
					local pv = petVisuals[visualKey(player, pet.id)]
					if pv then
						pv.harvestUntil = nil
						pv.faceUntil = nil
					end
				end
				if reason and player.Parent then
					notify(player, reason .. (totalGain > 0 and (" (+" .. totalGain .. " XP par pet au total)") or ""), GREEN)
				end
			end)
			if not ok then warn("[MWS] Erreur entrainement : " .. tostring(err)) end
			trainSessions[uid] = nil
			info.busy = false
			info.owner = nil
			info.stop = false
			info.sub.Text = "Niveau max des pets : " .. TRAIN_CAP[info.world]
			info.prompt.ActionText = "Entrainer tes pets"
		end)
	end

	local count = 0
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Model") and d.Name == "Punching Bag" then
			setupBag(d)
			count = count + 1
		end
	end
	print("[MWS] Entrainement : " .. count .. " sacs de frappe actifs.")
end
-- TRAINING_END

-- DEBUGHOOK_START
do
	local ev = Instance.new("BindableEvent")
	ev.Name = "MWS_Debug"
	ev.Parent = game:GetService("ServerStorage")
	ev.Event:Connect(function(names)
		local player = Players:GetPlayers()[1]
		local s = player and states[player.UserId]
		if not s then return end
		for _, n in ipairs(names) do
			-- n = "Nom" ou { "Nom", size, mutation }
			local size, mutation
			if type(n) == "table" then n, size, mutation = n[1], n[2], n[3] end
			local info = PETS[n]
			if info then
				local id = s.nextPetId
				s.nextPetId = id + 1
				local p = { id = id, name = n, rarity = info.rarity, color = info.color, tier = 0, size = size, mutation = mutation }
				local tm = Traits.mult(p)
				p.multiplier, p.income = info.multiplier * tm, math.floor(info.income * tm)
				table.insert(s.pets, p)
				if #s.equipped < maxEquip(s) then table.insert(s.equipped, id) end
		while #s.equipped > maxEquip(s) do table.remove(s.equipped) end
			end
		end
		sendState(player)
		refreshPetVisuals(player)
	end)
end
-- DEBUGHOOK_END
print("[MWS] Mythic Worlds Simulator v5 initialise : 3 mondes, 31 pets, 6 oeufs, 9 monstres.")

