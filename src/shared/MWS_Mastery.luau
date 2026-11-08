-- MWS_Mastery : maitrises (progression a long terme), partagees par le serveur et le client.
-- Chaque action du jeu donne de l'XP a sa maitrise ; certains niveaux debloquent un avantage
-- (5 paliers, I a V). Le serveur garde l'XP totale de chaque maitrise dans s.mastery[cle].
local M = {}

M.MAX_LEVEL = 50
M.PERK_LEVELS = { 5, 10, 20, 35, 50 }
M.ROMAN = { "I", "II", "III", "IV", "V" }

-- values : bonus en % de chaque palier (le plus haut palier debloque compte, ils ne s'additionnent pas)
M.LIST = {
	{
		key = "entrainement", name = "Entraînement", icon = "\u{1F94A}", color = { 255, 120, 60 },
		how = "Entraîne tes pets au sac de frappe.",
		perk = "Entraînement intense", desc = "+%d %% d'XP pour tes pets au sac de frappe",
		values = { 10, 20, 35, 50, 100 },
	},
	{
		key = "combat", name = "Combat", icon = "\u{2694}\u{FE0F}", color = { 255, 80, 90 },
		how = "Gagne des combats contre les dresseurs et les boss.",
		perk = "Pets féroces", desc = "+%d %% de vie et d'attaque en combat",
		values = { 3, 6, 10, 15, 25 },
	},
	{
		key = "eclosion", name = "Éclosion", icon = "\u{1F95A}", color = { 190, 120, 255 },
		how = "Fais éclore des œufs.",
		perk = "Main chanceuse", desc = "+%d %% de chance d'avoir un pet rare",
		values = { 2, 4, 7, 10, 15 },
	},
	{
		key = "cristaux", name = "Cristaux", icon = "\u{1F48E}", color = { 90, 200, 255 },
		how = "Ramasse des cristaux.",
		perk = "Cristaux précieux", desc = "+%d %% de coins des cristaux",
		values = { 10, 20, 35, 50, 100 },
	},
	{
		key = "fusion", name = "Fusion", icon = "\u{1F9EA}", color = { 120, 255, 170 },
		how = "Fusionne des pets à la machine de fusion.",
		perk = "Fusion dorée", desc = "+%d %% de revenu des pets fusionnés",
		values = { 5, 10, 15, 20, 30 },
	},
	{
		key = "richesse", name = "Richesse", icon = "\u{1F4B0}", color = { 255, 210, 60 },
		how = "Joue : tu gagnes de l'XP toutes les 10 secondes.",
		perk = "Fortune", desc = "+%d %% de coins par seconde",
		values = { 2, 4, 6, 8, 10 },
	},
}
M.BY_KEY = {}
for i, m in ipairs(M.LIST) do
	m.index = i
	M.BY_KEY[m.key] = m
end

-- XP donnee par chaque action suivie par le jeu (_G.MWS_Track) ; "time" = toutes les 10 s de jeu
M.EVENTS = {
	train = { "entrainement", 3 },
	battle = { "combat", 10 },
	egg = { "eclosion", 2 },
	crystal = { "cristaux", 2 },
	fusion = { "fusion", 20 },
	time = { "richesse", 1 },
}

-- XP pour passer du niveau lvl au niveau lvl + 1
function M.need(lvl)
	return 5 + 3 * lvl
end

M.MAX_XP = 0
for lvl = 0, M.MAX_LEVEL - 1 do M.MAX_XP = M.MAX_XP + M.need(lvl) end

-- XP totale -> niveau, XP dans le niveau, XP necessaire pour le suivant (0 au niveau max)
function M.levelOf(total)
	local xp = math.clamp(math.floor(tonumber(total) or 0), 0, M.MAX_XP)
	local lvl = 0
	while lvl < M.MAX_LEVEL and xp >= M.need(lvl) do
		xp = xp - M.need(lvl)
		lvl = lvl + 1
	end
	if lvl >= M.MAX_LEVEL then return lvl, 0, 0 end
	return lvl, xp, M.need(lvl)
end

-- nombre de paliers debloques a ce niveau
function M.perksAt(lvl)
	local n = 0
	for _, need in ipairs(M.PERK_LEVELS) do
		if lvl >= need then n = n + 1 end
	end
	return n
end

-- bonus actuel d'une maitrise, en fraction (0.25 = +25 %)
function M.bonus(s, key)
	local m = M.BY_KEY[key]
	if not m or type(s) ~= "table" or type(s.mastery) ~= "table" then return 0 end
	local n = M.perksAt((M.levelOf(s.mastery[key])))
	return n > 0 and m.values[n] / 100 or 0
end

function M.perkName(m, i)
	return m.perk .. " " .. M.ROMAN[i]
end

function M.perkText(m, i)
	return string.format(m.desc, m.values[i])
end

-- sauvegarde verifiee au chargement : seulement des maitrises connues, XP entiere et bornee
function M.clean(s)
	local clean = {}
	if type(s.mastery) == "table" then
		for key in pairs(M.BY_KEY) do
			local v = tonumber(s.mastery[key])
			if v and v == v and v > 0 then clean[key] = math.min(math.floor(v), M.MAX_XP) end
		end
	end
	s.mastery = clean
end

return M
