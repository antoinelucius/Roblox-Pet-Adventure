-- MWS_Lang (client) : met le jeu en anglais pour les joueurs qui ne parlent pas francais.
-- Surveille tous les textes affiches (ecran du joueur et panneaux dans le monde) et les
-- traduit avec le module MWS_Lang. Le texte francais d'origine est garde : si le joueur
-- choisit le francais dans les Parametres, tout revient en francais tout de suite.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lang = require(ReplicatedStorage:WaitForChild("MWS_Lang"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- proprietes de texte a traduire, selon le type d'objet
local PROPS = {
	TextLabel = { "Text" },
	TextButton = { "Text" },
	TextBox = { "PlaceholderText" },   -- jamais ce que le joueur tape
	ProximityPrompt = { "ActionText", "ObjectText" },
}

local english = Lang.wantsEnglish(player)
local original = setmetatable({}, { __mode = "k" })   -- objet -> { propriete -> texte francais }
local written = setmetatable({}, { __mode = "k" })    -- objet -> { propriete -> texte ecrit par ce script }

local function show(item, prop)
	local french = original[item][prop]
	local text = english and Lang.tr(french) or french
	if item[prop] ~= text then
		written[item][prop] = text
		item[prop] = text
	end
end

local function onChanged(item, prop)
	local current = item[prop]
	if current == written[item][prop] then return end   -- c'est notre propre traduction
	original[item][prop] = current
	written[item][prop] = nil
	if english then show(item, prop) end
end

local function watch(item)
	local props = PROPS[item.ClassName]
	if not props or original[item] then return end
	original[item], written[item] = {}, {}
	for _, prop in ipairs(props) do
		original[item][prop] = item[prop]
		item:GetPropertyChangedSignal(prop):Connect(function() onChanged(item, prop) end)
		if english then show(item, prop) end
	end
end

-- choix de langue change dans les Parametres : tous les textes connus suivent
player:GetAttributeChangedSignal("MWS_SetEnglish"):Connect(function()
	local now = Lang.wantsEnglish(player)
	if now == english then return end
	english = now
	for item, props in pairs(original) do
		if item.Parent then
			for prop in pairs(props) do show(item, prop) end
		end
	end
end)

for _, root in ipairs({ playerGui, workspace }) do
	root.DescendantAdded:Connect(watch)
	for _, item in ipairs(root:GetDescendants()) do watch(item) end
end
