# Images de la boutique

Une image par article de la boutique Robux : 512 × 512, fond transparent, objet entier et centré.
Aperçu de l'ensemble : `preview.png`.

| Fichier | Ligne de `Config.Images` | Article |
| --- | --- | --- |
| `Cash1.png` | `Cash1` | Pack de pièces S |
| `Cash2.png` | `Cash2` | Pack de pièces M |
| `Cash3.png` | `Cash3` | Pack de pièces L |
| `PotionLuck.png` | `PotionLuck` | Potions de chance (x1, x3, x10 et inventaire) |
| `PotionSpeed.png` | `PotionSpeed` | Potions de vitesse (x1, x3, x10 et inventaire) |
| `trail_flammes.png` | `trail_flammes` | Traînée de flammes |
| `trail_sakura.png` | `trail_sakura` | Traînée de cerisier |
| `trail_cosmos.png` | `trail_cosmos` | Traînée cosmique |
| `trail_magma.png` | `trail_magma` | Traînée de magma |
| `pass_x2.png` | `pass_x2` | Gains x2 |

Les `.svg` sont les sources vectorielles : glisse-les dans Figma pour les retoucher
(ils s'importent en calques modifiables). Les `.png` sont prêts à être envoyés sur Roblox.

## Les mettre dans le jeu

1. Envoie les images sur Roblox (depuis Figma avec Framewisp, ou avec l'Asset Manager
   de Roblox Studio) et note l'identifiant `rbxassetid://...` de chacune.
2. Colle chaque identifiant sur sa ligne dans `Config.Images`
   (`src/shared/MWS_ShopConfig.luau`).

Tant qu'une ligne reste `""`, l'article garde son objet 3D en briques.
