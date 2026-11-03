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

local Config = {}

Config.Items = {
	{
		key = "coins_s", kind = "product", id = 0, price = 49,
		icon = "\u{1F4B5}", name = "Pack de pieces S", desc = "+10 000 coins",
		reward = { type = "coins", amount = 10000 },
	},
	{
		key = "coins_m", kind = "product", id = 0, price = 199,
		icon = "\u{1F4B0}", name = "Pack de pieces M", desc = "+100 000 coins",
		reward = { type = "coins", amount = 100000 },
	},
	{
		key = "coins_l", kind = "product", id = 0, price = 999,
		icon = "\u{1F4B8}", name = "Pack de pieces L", desc = "+1 000 000 coins",
		reward = { type = "coins", amount = 1000000 },
	},
	{
		key = "speed10", kind = "product", id = 0, price = 29,
		icon = "\u{26A1}", name = "Boost de vitesse", desc = "Vitesse x2 pendant 10 minutes",
		reward = { type = "speed", seconds = 600 },
	},
	{
		key = "luck15", kind = "product", id = 0, price = 99,
		icon = "\u{1F340}", name = "Potion de chance", desc = "Chance x2 sur les animaux rares pendant 15 minutes",
		reward = { type = "luck", mult = 2, seconds = 900 },
	},
	{
		key = "pet_dragon", kind = "product", id = 0, price = 599, world = 1, limit = 1,
		icon = "\u{1F984}", name = "Licorne", desc = "Monde 1 : la Licorne (Legendaire). 1 seule par joueur.",
		reward = { type = "pet", pet = "Licorne" },
	},
	{
		key = "pet_w2", kind = "product", id = 0, price = 1299, world = 2, limit = 1,
		icon = "\u{1F525}", name = "Dragon des ombres", desc = "Monde 2 : le Dragon des ombres (Divin). 1 seul par joueur.",
		reward = { type = "pet", pet = "Dragon des ombres" },
	},
	{
		key = "pet_w3", kind = "product", id = 0, price = 2999, world = 3, limit = 1,
		icon = "\u{2728}", name = "Dragon primordial", desc = "Monde 3 : le Dragon primordial (Secret). 1 seul par joueur.",
		reward = { type = "pet", pet = "Dragon primordial" },
	},
	{
		key = "pass_x2", kind = "gamepass", id = 0, price = 499,
		icon = "\u{1F451}", name = "Gains x2", desc = "Tous tes gains de coins sont doubles, a vie",
		reward = { type = "coinsmult", mult = 2 },
	},
}

return Config
