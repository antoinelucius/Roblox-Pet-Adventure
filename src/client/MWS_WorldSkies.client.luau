-- Un ciel et une ambiance par monde, cote client (chaque joueur voit le ciel de son monde).
-- Le serveur donne le monde du joueur dans l'attribut "MWS_World".
-- Ciels : ReplicatedStorage.MWS_WorldSkies (W1, W2, W3).
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local skies = RS:WaitForChild("MWS_WorldSkies")

local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Parent = Lighting
local cc = Lighting:FindFirstChild("MWS_WorldTint") or Instance.new("ColorCorrectionEffect")
cc.Name = "MWS_WorldTint"
cc.Parent = Lighting

-- monde 1 = reglages actuels du jeu
local BASE = {
	lighting = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient },
	atmosphere = { Density = atmosphere.Density, Haze = atmosphere.Haze, Color = atmosphere.Color, Decay = atmosphere.Decay, Offset = atmosphere.Offset, Glare = atmosphere.Glare },
	tint = { TintColor = Color3.new(1, 1, 1), Saturation = 0, Contrast = 0, Brightness = 0 },
}

local WORLD_LOOK = {
	[1] = BASE,
	-- volcan : ciel enfume, brume orange-rouge, lumiere chaude et plus sombre
	[2] = {
		lighting = { Brightness = 2, ClockTime = 17.4, Ambient = Color3.fromRGB(95, 55, 45), OutdoorAmbient = Color3.fromRGB(130, 75, 60) },
		atmosphere = { Density = 0.38, Haze = 2.2, Color = Color3.fromRGB(255, 130, 70), Decay = Color3.fromRGB(120, 40, 25), Offset = 0.2, Glare = 0.4 },
		tint = { TintColor = Color3.fromRGB(255, 222, 200), Saturation = 0.12, Contrast = 0.1, Brightness = -0.03 },
	},
	-- dimension mythique : espace violet, brume legere violette
	[3] = {
		lighting = { Brightness = 2.2, ClockTime = 14.5, Ambient = Color3.fromRGB(90, 70, 130), OutdoorAmbient = Color3.fromRGB(140, 115, 200) },
		atmosphere = { Density = 0.22, Haze = 1, Color = Color3.fromRGB(170, 130, 255), Decay = Color3.fromRGB(70, 40, 140), Offset = 0.1, Glare = 0.3 },
		tint = { TintColor = Color3.fromRGB(238, 228, 255), Saturation = 0.15, Contrast = 0.06, Brightness = 0 },
	},
}

-- fondu au noir pendant le changement
local fadeGui = Instance.new("ScreenGui")
fadeGui.Name = "MWS_WorldFade"
fadeGui.IgnoreGuiInset = true
fadeGui.DisplayOrder = 50
fadeGui.ResetOnSpawn = false
fadeGui.Parent = player:WaitForChild("PlayerGui")
local fade = Instance.new("Frame")
fade.Size = UDim2.new(1, 0, 1, 0)
fade.BackgroundColor3 = Color3.new(0, 0, 0)
fade.BackgroundTransparency = 1
fade.BorderSizePixel = 0
fade.Parent = fadeGui

local function setProps(obj, props)
	for k, v in pairs(props) do obj[k] = v end
end

local current
local function applyWorld(w, instant)
	w = WORLD_LOOK[w] and w or 1
	if w == current then return end
	current = w
	local look = WORLD_LOOK[w]
	if not instant then
		TweenService:Create(fade, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
		task.wait(0.27)
	end
	for _, s in ipairs(Lighting:GetChildren()) do
		if s:IsA("Sky") then s:Destroy() end
	end
	local sky = skies:FindFirstChild("W" .. w) or skies:FindFirstChild("W1")
	if sky then sky:Clone().Parent = Lighting end
	setProps(Lighting, look.lighting)
	setProps(atmosphere, look.atmosphere)
	setProps(cc, look.tint)
	if not instant then
		TweenService:Create(fade, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	end
end

applyWorld(player:GetAttribute("MWS_World") or 1, true)
player:GetAttributeChangedSignal("MWS_World"):Connect(function()
	applyWorld(player:GetAttribute("MWS_World") or 1, false)
end)
