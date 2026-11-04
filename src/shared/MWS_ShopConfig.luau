-- ============================================================
-- MWS_ShopConfig : LA BOUTIQUE ROBUX (c'est ICI que tu mets tes ID)
-- ============================================================
-- Comment faire :
--  1) Va sur create.roblox.com > ton jeu > Monetisation.
--  2) Cree un "Produit de developpeur" (achat repetable) ou un "Passe" (achat unique).
--  3) Copie son numero (ID) et colle-le dans le champ  id = 0  de l'article ci-dessous.
--
-- Tant que id = 0, l'article s'affiche "Bientot" et ne peut pas etre achete.
-- "kind" : "product" = produit de developpeur (repetable) | "gamepass" = passe (une seule fois)
-- "price" : prix affiche tant que Roblox ne l'a pas renvoye (le vrai prix est lu automatiquement).
-- Options d'un article :
--   world = N  -> l'article n'apparait et ne s'achete QUE quand le joueur est dans le monde N
--   limit = N  -> nombre maximum d'achats par joueur (1 = un seul achat a vie)
-- Recompenses possibles (reward.type) :
--   coins     -> { type = "coins", amount = 10000 }
--   speed     -> { type = "speed", seconds = 600 }            (boost de vitesse x2)
--   luck      -> { type = "luck", mult = 2, seconds = 900 }   (plus de chances d'animaux rares)
--   pet       -> { type = "pet", pet = "Licorne" }            (nom EXACT de l'animal)
--   coinsmult -> { type = "coinsmult", mult = 2 }             (passe : gains de coins x2 a vie)
--   trail     -> { type = "trail", colors = { {r,g,b}, {r,g,b} } } (cosmetique : trainee du personnage)

local Config = {}

Config.Items = {
	{
		key = "coins_s", kind = "product", id = 3728204521, price = 49,
		icon = "\u{1F4B5}", name = "Pack de pieces S", desc = "+10 000 coins",
		reward = { type = "coins", amount = 10000 },
	},
	{
		key = "coins_m", kind = "product", id = 3728204674, price = 199,
		icon = "\u{1F4B0}", name = "Pack de pieces M", desc = "+100 000 coins",
		reward = { type = "coins", amount = 100000 },
	},
	{
		key = "coins_l", kind = "product", id = 3728204806, price = 999,
		icon = "\u{1F4B8}", name = "Pack de pieces L", desc = "+1 000 000 coins",
		reward = { type = "coins", amount = 1000000 },
	},
	{
		key = "speed10", kind = "product", id = 3728204836, price = 29,
		icon = "\u{26A1}", name = "Boost de vitesse", desc = "Vitesse x2 pendant 10 minutes",
		reward = { type = "speed", seconds = 600 },
	},
	{
		key = "luck15", kind = "product", id = 3728204985, price = 99,
		icon = "\u{1F340}", name = "Potion de chance", desc = "Chance x2 sur les animaux rares pendant 15 minutes",
		reward = { type = "luck", mult = 2, seconds = 900 },
	},
	{
		key = "trail_flammes", kind = "product", id = 3728205027, price = 99, limit = 1,
		icon = "\u{1F525}", name = "Trainee de flammes", desc = "Cosmetique : une trainee de feu derriere toi.",
		reward = { type = "trail", colors = { {255, 200, 60}, {230, 50, 20} } },
	},
	{
		key = "trail_sakura", kind = "product", id = 3728205071, price = 99, limit = 1,
		icon = "\u{1F338}", name = "Trainee de cerisier", desc = "Cosmetique : une trainee rose derriere toi.",
		reward = { type = "trail", colors = { {255, 210, 230}, {240, 90, 170} } },
	},
	{
		key = "trail_cosmos", kind = "product", id = 3728205113, price = 199, limit = 1,
		icon = "\u{2728}", name = "Trainee cosmique", desc = "Cosmetique : une trainee d'etoiles derriere toi.",
		reward = { type = "trail", colors = { {120, 220, 255}, {110, 50, 220} } },
	},
	{
		key = "pass_x2", kind = "gamepass", id = 2071248448, price = 499,
		icon = "\u{1F451}", name = "Gains x2", desc = "Double les revenus de tes pets et les cristaux, a vie",
		reward = { type = "coinsmult", mult = 2 },
	},
}

return Config
