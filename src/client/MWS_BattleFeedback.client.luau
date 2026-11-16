-- MWS_BattleFeedback : retours visuels et sonores cote joueur (combat et recompenses).
-- Script a part pour ne rien ajouter au gros script client (limite de 200 variables locales).
-- Il ecoute les memes evenements que l'interface et n'affiche que des effets courts :
--   combat      : flash d'ecran quand ton pet est touche, bandeau CRITIQUE / BLOQUE / RATE
--   recompenses : "+coins" pour les gros gains, niveau de pet ou de maitrise gagne
-- Rien ici ne retarde le jeu : tout est joue au moment ou le serveur annonce le resultat.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("MWS_Remotes")
local Mastery = require(ReplicatedStorage:WaitForChild("MWS_Mastery"))

local screen = Instance.new("ScreenGui")
screen.Name = "MWS_BattleFeedback"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.DisplayOrder = 6
screen.Parent = player:WaitForChild("PlayerGui")

-- reglage "Secousses de l'ecran" : s'il est coupe, on coupe aussi les flashs plein ecran
local function flashesAllowed()
	return player:GetAttribute("MWS_SetShake") ~= false
end

-- sons deja charges par MWS_Sounds (ils suivent le volume des effets regle par le joueur)
local function playSound(name)
	local folder = SoundService:FindFirstChild("MWS_Sounds")
	local sound = folder and folder:FindFirstChild(name)
	if sound and sound:IsA("Sound") then sound:Play() end
end

local flash = Instance.new("Frame")
flash.Name = "Flash"
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundTransparency = 1
flash.BorderSizePixel = 0
flash.Active = false
flash.Parent = screen
local flashTween = nil

local function screenFlash(color, strength, seconds)
	if not flashesAllowed() then return end
	if flashTween then flashTween:Cancel() end
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = 1 - strength
	flashTween = TweenService:Create(flash, TweenInfo.new(seconds), { BackgroundTransparency = 1 })
	flashTween:Play()
end

-- un seul bandeau a la fois, court et lisible sur telephone (taille bornee)
local banner = Instance.new("TextLabel")
banner.Name = "Banner"
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.fromScale(0.5, 0.2)
banner.Size = UDim2.new(0.8, 0, 0.07, 0)
banner.BackgroundTransparency = 1
banner.Text = ""
banner.Font = Enum.Font.FredokaOne
banner.TextScaled = true
banner.TextTransparency = 1
banner.TextStrokeTransparency = 1
banner.Parent = screen
local bannerLimit = Instance.new("UITextSizeConstraint")
bannerLimit.MaxTextSize = 44
bannerLimit.MinTextSize = 16
bannerLimit.Parent = banner
local bannerScale = Instance.new("UIScale")
bannerScale.Parent = banner
local bannerTweens = {}

local function showBanner(text, color, seconds)
	for _, tw in ipairs(bannerTweens) do tw:Cancel() end
	banner.Text = text
	banner.TextColor3 = color
	banner.TextTransparency = 0
	banner.TextStrokeTransparency = 0
	bannerScale.Scale = 1.8
	local hold = seconds or 0.7
	bannerTweens = {
		TweenService:Create(bannerScale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }),
		TweenService:Create(banner, TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, hold),
			{ TextTransparency = 1, TextStrokeTransparency = 1 }),
	}
	for _, tw in ipairs(bannerTweens) do tw:Play() end
end

-- petit texte qui monte puis s'efface (gains de coins)
local function floatText(text, color)
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.12)
	label.Size = UDim2.new(0.5, 0, 0.045, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.2
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = 30
	limit.Parent = label
	label.Parent = screen
	TweenService:Create(label, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.5, 0.07) }):Play()
	TweenService:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0.55),
		{ TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1, function() label:Destroy() end)
end

-- ---------- combat ----------

local lastHit = nil
remotes:WaitForChild("BattleUpdate").OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then return end
	local hit = data.hitFx
	if type(hit) ~= "table" or hit.id == nil then return end
	local key = tostring(hit.id) .. tostring(hit.side)
	if key == lastHit then return end
	lastHit = key
	local damage = tonumber(hit.damage) or 0
	if hit.side == "player" then
		-- ton pet encaisse : rouge, ou bleu si la garde a tenu
		if hit.guarded then
			screenFlash(Color3.fromRGB(90, 160, 255), 0.22, 0.4)
			showBanner("\u{1F6E1} BLOQUÉ !", Color3.fromRGB(140, 200, 255))
		elseif damage > 0 then
			screenFlash(Color3.fromRGB(255, 40, 40), (hit.heavy or hit.crit) and 0.3 or 0.16, 0.35)
			if hit.crit then showBanner("AÏE ! COUP CRITIQUE", Color3.fromRGB(255, 120, 100)) end
		end
	elseif damage <= 0 then
		showBanner("RATÉ !", Color3.fromRGB(210, 210, 220))
	elseif hit.crit then
		screenFlash(Color3.fromRGB(255, 255, 255), 0.18, 0.25)
		showBanner("COUP CRITIQUE !", Color3.fromRGB(255, 220, 80))
	end
end)
remotes:WaitForChild("BattleStart").OnClientEvent:Connect(function()
	lastHit = nil
end)

-- ---------- recompenses ----------

local known = nil   -- dernier etat vu : { coins, petLevels = { [id] = niveau }, mastery = { [cle] = niveau } }
local lastReward = 0

local function snapshot(state)
	local snap = { coins = tonumber(state.coins) or 0, petLevels = {}, mastery = {} }
	if type(state.pets) == "table" then
		for _, pet in ipairs(state.pets) do
			if type(pet) == "table" and pet.id ~= nil then snap.petLevels[pet.id] = tonumber(pet.lvl) or 0 end
		end
	end
	if type(state.mastery) == "table" then
		for key, total in pairs(state.mastery) do
			snap.mastery[key] = Mastery.levelOf(total)
		end
	end
	return snap
end

remotes:WaitForChild("StateUpdate").OnClientEvent:Connect(function(state, income)
	if type(state) ~= "table" then return end
	local ok, snap = pcall(snapshot, state)
	if not ok then return end
	local before = known
	known = snap
	if not before then return end

	-- gros gain de coins (cristal, combat, quete) : pas le revenu de chaque seconde
	local gain = snap.coins - before.coins
	if gain > (tonumber(income) or 0) * 2 + 1 and gain >= 10 then
		floatText("+" .. tostring(math.floor(gain)) .. " coins", Color3.fromRGB(255, 225, 100))
	end

	-- niveau gagne : pet (sac de frappe) ou maitrise
	local petUp, masteryUp = false, false
	for id, lvl in pairs(snap.petLevels) do
		local old = before.petLevels[id]
		if old ~= nil and lvl > old then petUp = true end
	end
	for key, lvl in pairs(snap.mastery) do
		if lvl > (before.mastery[key] or 0) then masteryUp = true end
	end
	if (petUp or masteryUp) and os.clock() - lastReward > 1 then
		lastReward = os.clock()
		playSound("reveal")
		screenFlash(Color3.fromRGB(255, 220, 90), 0.14, 0.5)
		showBanner(masteryUp and "\u{2B50} MAÎTRISE : NIVEAU GAGNÉ !" or "\u{2B06} NIVEAU GAGNÉ !", Color3.fromRGB(255, 225, 100), 1)
	end
end)
