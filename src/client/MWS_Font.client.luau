-- MWS_Font : une seule police ronde et epaisse pour tous les textes du jeu, avec un contour
-- sombre. Les textes grossissent un peu, seulement s'ils tiennent encore dans leur case.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local FONT = Enum.Font.FredokaOne
local GROW = 1.15
local INK = Color3.fromRGB(20, 22, 30)
local GUIS = { MWS_Gui = true, MWS_Settings = true, MWS_SoundUI = true, MWS_FlashGui = true }

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local done = setmetatable({}, { __mode = "k" })

local function isText(item)
	return item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox")
end
-- texte clair : le contour sombre l'aide a ressortir ; un texte sombre n'en a pas besoin
local function isLight(color)
	return color.R * 0.3 + color.G * 0.59 + color.B * 0.11 > 0.35
end

local function restyle(item)
	if done[item] or not isText(item) then return end
	done[item] = true
	item.Font = FONT
	item:GetPropertyChangedSignal("Font"):Connect(function()
		if item.Font ~= FONT then item.Font = FONT end
	end)
	if isLight(item.TextColor3) and not item:FindFirstChildOfClass("UIStroke") then
		local stroke = Instance.new("UIStroke")
		stroke.Color = INK
		stroke.Thickness = item.TextSize >= 20 and 2 or 1.5
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		stroke.Parent = item
		item.TextStrokeTransparency = 1
	end
	if not item.TextScaled then
		local original = item.TextSize
		item.TextSize = math.floor(original * GROW + 0.5)
		-- la taille du texte est calculee a l'image suivante : on revient en arriere s'il deborde
		task.spawn(function()
			RunService.Heartbeat:Wait()
			if item.Parent and not item.TextFits and item.TextSize > original then item.TextSize = original end
		end)
	end
end

local function cover(root)
	for _, item in ipairs(root:GetDescendants()) do restyle(item) end
	root.DescendantAdded:Connect(restyle)
end

local function onGui(gui)
	if gui:IsA("ScreenGui") and GUIS[gui.Name] then cover(gui) end
end
for _, gui in ipairs(playerGui:GetChildren()) do onGui(gui) end
playerGui.ChildAdded:Connect(onGui)

-- noms dans le monde : boss, oeufs, portails, pets
local generated = workspace:WaitForChild("MWS_Generated", 20)
if generated then cover(generated) end
