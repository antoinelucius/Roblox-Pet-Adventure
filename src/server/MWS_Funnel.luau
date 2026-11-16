--!strict
-- ============================================================
-- MWS_Funnel : entonnoir d'accueil (onboarding funnel) de Mythic Worlds Simulator.
-- A placer dans ServerStorage (ModuleScript nomme "MWS_Funnel"). Facultatif : sans lui,
-- le serveur n'envoie rien et le jeu tourne exactement comme avant.
--
-- Il sert a voir, dans le tableau de bord Createur (Analytique > Entonnoirs), a quelle etape
-- les nouveaux joueurs quittent le jeu. Seul le numero et le nom de l'etape sont envoyes :
-- aucune donnee de sauvegarde, aucun texte du joueur.
--
-- Les etapes suivent le tutoriel du serveur (table TUT) : chaque etape n'est franchie
-- qu'une fois par joueur, donc l'evenement n'est envoye qu'une fois.
-- ============================================================

local AnalyticsService = game:GetService("AnalyticsService")

local Funnel = {}

-- L'ordre et les noms ne doivent plus changer une fois le jeu publie : Roblox range les
-- joueurs par numero d'etape. Pour ajouter une etape, l'ajouter a la fin.
local STEPS: { [string]: { index: number, name: string } } = {
	arrival = { index = 1, name = "Arrivee dans le jeu" },
	egg = { index = 2, name = "Premier oeuf achete" },
	equip = { index = 3, name = "Premier pet equipe" },
	crystal = { index = 4, name = "Premiers cristaux ramasses" },
	train = { index = 5, name = "Premier entrainement" },
	battle = { index = 6, name = "Premiere victoire en combat" },
	world2 = { index = 7, name = "Deuxieme monde debloque" },
}

-- cle = "arrival", un evenement du tutoriel ("egg", "equip", ...) ou "world2"
function Funnel.step(player: Player, key: string)
	local def = STEPS[key]
	if not def then
		return
	end
	local ok, err = pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, def.index, def.name)
	end)
	if not ok then
		warn("[MWS] Entonnoir non envoye (" .. def.name .. ") : " .. tostring(err))
	end
end

return Funnel
