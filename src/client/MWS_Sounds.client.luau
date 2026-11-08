-- MWS_Sounds : effets sonores et musique (joue uniquement sur le client du joueur)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("MWS_Remotes")

local SOUNDS = {
	click = { id = 88442833509532, volume = 0.35 },
	coin = { id = 113730061669739, volume = 0.3 },
	hit = { id = 126976659766267, volume = 0.6 },
	strong = { id = 132555084427990, volume = 0.65 },
	boom = { id = 122258480286280, volume = 0.5 },
	win = { id = 9067124098, volume = 0.5 },
	egg = { id = 9113959343, volume = 0.7 },
	reveal = { id = 80777027985562, volume = 0.6 },
	shield = { id = 9125819216, volume = 0.7 },
	charge = { id = 114129417539712, volume = 0.6 },
	machine = { id = 130100705024717, volume = 0.5 },
	laugh = { id = 133951199201598, volume = 0.8 },
}
local MUSIC_ID, MUSIC_VOLUME = 1843098018, 0.15
local BATTLE_MUSIC_ID, BOSS_MUSIC_ID, BATTLE_VOLUME = 9043602056, 9046506025, 0.22

local folder = Instance.new("Folder")
folder.Name = "MWS_Sounds"
folder.Parent = SoundService
local bank = {}
for name, def in pairs(SOUNDS) do
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = "rbxassetid://" .. def.id
	sound.Volume = def.volume
	sound.Parent = folder
	bank[name] = sound
end
local music = Instance.new("Sound")
music.Name = "music"
music.SoundId = "rbxassetid://" .. MUSIC_ID
music.Volume = MUSIC_VOLUME
music.Looped = true
music.Parent = folder
music:Play()

local function makeTrack(name, id)
	local track = Instance.new("Sound")
	track.Name = name
	track.SoundId = "rbxassetid://" .. id
	track.Volume = 0
	track.Looped = true
	track.Parent = folder
	return track
end
local battleMusic = makeTrack("battleMusic", BATTLE_MUSIC_ID)
local bossMusic = makeTrack("bossMusic", BOSS_MUSIC_ID)

-- volumes choisis dans les parametres (MWS_Settings) : attributs du joueur, de 0 a 100
local function level(attribute)
	return (player:GetAttribute(attribute) or 100) / 100
end
local sfxGroup = Instance.new("SoundGroup")
sfxGroup.Name = "MWS_Sfx"
sfxGroup.Parent = SoundService
for _, sound in pairs(bank) do sound.SoundGroup = sfxGroup end

local currentTrack = music
local fades = {}
local function trackVolume(track)
	if track ~= currentTrack then return 0 end
	return (track == music and MUSIC_VOLUME or BATTLE_VOLUME) * level("MWS_SetMusic")
end
-- passe d'une musique a l'autre en fondu
local function setMusic(track)
	currentTrack = track
	if track ~= music then
		track.TimePosition = 0
		track:Play()
	end
	for _, item in ipairs({ music, battleMusic, bossMusic }) do
		if fades[item] then fades[item]:Cancel() end
		fades[item] = TweenService:Create(item, TweenInfo.new(0.8), { Volume = trackVolume(item) })
		fades[item]:Play()
	end
end

local function play(name, delaySeconds)
	if delaySeconds and delaySeconds > 0 then
		task.delay(delaySeconds, function()
			bank[name]:Play()
		end)
	else
		bank[name]:Play()
	end
end

local screen = Instance.new("ScreenGui")
screen.Name = "MWS_SoundUI"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.DisplayOrder = 5
screen.Parent = player:WaitForChild("PlayerGui")

local function applyMusic()
	for _, item in ipairs({ music, battleMusic, bossMusic }) do
		if fades[item] then fades[item]:Cancel() end
		item.Volume = trackVolume(item)
	end
end
local function applySfx()
	sfxGroup.Volume = level("MWS_SetSfx")
	-- sons joues dans le monde (sacs de frappe)
	local worldGroup = SoundService:FindFirstChild("MWS_WorldSounds")
	if worldGroup then worldGroup.Volume = level("MWS_SetSfx") end
end
player:GetAttributeChangedSignal("MWS_SetMusic"):Connect(applyMusic)
player:GetAttributeChangedSignal("MWS_SetSfx"):Connect(applySfx)
applyMusic()
applySfx()

-- le groupe des sacs de frappe peut arriver apres le reglage du volume
SoundService.ChildAdded:Connect(function(child)
	if child.Name == "MWS_WorldSounds" and child:IsA("SoundGroup") then child.Volume = level("MWS_SetSfx") end
end)

-- clic sur tous les boutons de l'interface
local function hookButton(button)
	if button:IsA("GuiButton") then
		button.Activated:Connect(function() play("click") end)
	end
end
local playerGui = player:WaitForChild("PlayerGui")
for _, item in ipairs(playerGui:GetDescendants()) do hookButton(item) end
playerGui.DescendantAdded:Connect(hookButton)

-- combat : le son arrive au moment de l'impact (memes delais que le serveur)
local lastFx, battleOver = nil, false
local dangerWarned = false
local function onBattle(data)
	if type(data) ~= "table" then return end
	if data.fxId and data.fxId ~= lastFx then
		lastFx = data.fxId
		local power = data.fxPower or 1
		if power >= 4 then
			-- le pet charge dans sa bouche : le son finit au moment de l'explosion
			local charge = bank.charge
			if charge.TimeLength > 0 then charge.PlaybackSpeed = math.clamp(charge.TimeLength / 1.75, 0.6, 2) end
			play("charge")
			play("boom", 1.75)
		elseif power >= 3 then
			play("strong", 0.85)
		elseif power >= 2 then
			play("strong", 0.5)
		else
			play("hit", 0.5)
		end
	end
	local log = data.log or ""
	if log:find("BOUCLIER", 1, true) or log:find("bouclier encaisse", 1, true) or log:find("en garde", 1, true) then
		play("shield")
	end
	-- boss : grondement quand il annonce un coup dangereux (une fois par annonce)
	if data.danger then
		if not dangerWarned then
			dangerWarned = true
			play("charge")
		end
	else
		dangerWarned = false
	end
	if data.active == false and not battleOver then
		battleOver = true
		if log:find("VICTOIRE", 1, true) then play("win") end
		task.delay(3, function()
			if battleOver then setMusic(music) end
		end)
	end
end
remotes:WaitForChild("BattleUpdate").OnClientEvent:Connect(onBattle)
remotes:WaitForChild("BattleStart").OnClientEvent:Connect(function(data)
	if type(data) ~= "table" or not data.success then return end
	battleOver = false
	local intro = data.bossIntro
	setMusic(intro and bossMusic or battleMusic)
	if not intro then return end
	-- entree du dernier boss : la camera se tourne vers lui pendant qu'il rit
	play("laugh", 0.3)
	local camera = workspace.CurrentCamera
	local focus = intro.focus + Vector3.new(0, intro.height * 0.45, 0)
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(intro.focus + Vector3.new(-intro.height * 1.5, intro.height * 0.5, intro.height * 0.5), focus)
	local caption = Instance.new("TextLabel")
	caption.AnchorPoint = Vector2.new(0.5, 0.5)
	caption.Position = UDim2.new(0.5, 0, 0.16, 0)
	caption.Size = UDim2.new(0.8, 0, 0, 70)
	caption.BackgroundTransparency = 1
	caption.Text = "HA HA HA !"
	caption.TextColor3 = Color3.fromRGB(255, 80, 60)
	caption.TextStrokeTransparency = 0
	caption.Font = Enum.Font.FredokaOne
	caption.TextSize = 54
	caption.Parent = screen
	task.delay(intro.seconds or 3.4, function()
		caption:Destroy()
		camera.CameraType = Enum.CameraType.Custom
	end)
end)

-- oeufs : l'oeuf craque, puis eclate (signal envoye par l'animation)
remotes:WaitForChild("BuyEgg").OnClientEvent:Connect(function(data)
	if type(data) ~= "table" or not data.success then return end
	if data.fusion then
		-- machine de fusion : memes etapes que l'animation
		play("machine", 0.2)
		play("charge", 2.5)
		play("boom", 3.5)
		play("reveal", 3.8)
	elseif player:GetAttribute("MWS_SetEggs") == false then
		play("reveal")   -- pas d'animation d'oeuf : juste le son du resultat
	else
		play("egg", 0.5)
		play("egg", 1.2)
	end
end)
SoundService:GetAttributeChangedSignal("MWS_EggBurst"):Connect(function()
	play("reveal")
end)

-- gains ponctuels (cristaux, recompenses) ; pas le revenu de chaque seconde
local lastCoins, lastCoinSound = nil, 0
remotes:WaitForChild("StateUpdate").OnClientEvent:Connect(function(state, income)
	local coins = type(state) == "table" and state.coins
	if type(coins) ~= "number" then return end
	if lastCoins and coins - lastCoins > (tonumber(income) or 0) * 2 + 1 and os.clock() - lastCoinSound > 0.25 then
		lastCoinSound = os.clock()
		play("coin")
	end
	lastCoins = coins
end)
