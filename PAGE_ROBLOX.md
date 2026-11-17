# Page Roblox du jeu : à faire avant la sortie

Ce fichier regroupe ce que les vidéos de Codex conseillent pour la page du jeu (nom, description,
miniatures, langue, trailer, pub). Le code du jeu est prêt ; ces étapes se font dans le
**Creator Hub** (create.roblox.com), c'est donc toi qui les fais.

---

## 1. Nom du jeu (à choisir)

Conseil de Codex (vidéo 27) : **une action + un univers**, compréhensible en 1 seconde, en anglais.
« Mythic Worlds Simulator » dit l'univers mais pas l'action. Idées :

| Nom | Action | Univers |
|---|---|---|
| **Hatch Mythic Pets** | éclore | pets mythiques |
| Hatch & Battle Mythic Pets | éclore + combattre | pets mythiques |
| Mythic Pet Battles | combattre | pets mythiques |
| Train Mythic Pets | entraîner | pets mythiques |
| Mythic Pet Tamer | dresser | pets mythiques |

Ma préférence : **Hatch Mythic Pets** (court, l'action principale du jeu en premier).
Une session Claude avait renommé le jeu « Magic Pets » sur sa branche : ce nom n'a **pas** été
repris. C'est à toi de décider.

---

## 2. Description (à copier dans la page du jeu)

Codex (vidéos 13 et 27) : phrases courtes, ce qu'on fait dans le jeu dès la 1re ligne, base en anglais.

**English**

> 🥚 Hatch mythic pets, train them and battle giant bosses!
>
> 🐉 31 pets to collect: dragons, phoenixes, secret pets…
> ⚔️ Turn-based battles: guard, charged attacks and ultimate moves
> 🥊 Train your pets on punching bags to level them up
> 🌍 3 worlds: Enchanted Meadow, Volcanic Kingdom, Mythic Dimension
> 🔁 Rebirth to earn more, master 6 skills, claim a gift every day
>
> 👍 Like the game and add it to your favorites to get updates!

**Français**

> 🥚 Fais éclore des pets mythiques, entraîne-les et bats des boss géants !
>
> 🐉 31 pets à collectionner : dragons, phénix, pets secrets…
> ⚔️ Combats au tour par tour : protection, attaques chargées et attaque ultime
> 🥊 Entraîne tes pets au sac de frappe pour les faire monter de niveau
> 🌍 3 mondes : Prairie enchantée, Royaume volcanique, Dimension mythique
> 🔁 Renaissance pour gagner plus, 6 maîtrises, un cadeau chaque jour
>
> 👍 Like le jeu et ajoute-le à tes favoris pour suivre les nouveautés !

---

## 3. Miniatures

Codex (vidéos 22 et 25) : en tester **une vingtaine**, garder les meilleures, puis en faire environ
5 variantes.

- `miniatures/` : 12 miniatures 1920×1080 faites avec de **vraies images du jeu**
  (5 scènes en anglais, les mêmes en français, et 2 sans texte). `miniatures/apercu.jpg` les
  montre toutes.
- La branche `claude/roblox-game-posters-174wtz` contient 7 affiches de plus (dessinées). Attention :
  elles portent le nom « Magic Pets ».

Comment les tester : envoie-les dans les miniatures du jeu sur le Creator Hub. Roblox peut
répartir les joueurs entre plusieurs miniatures et te montre laquelle donne le plus de clics.
Après une semaine ou deux, garde les 2 ou 3 meilleures et fais-en des variantes (autre couleur
de titre, autre scène, avec ou sans texte).

---

## 4. Anglais

Le jeu est en français. La solution la plus simple, sans toucher au code : dans le Creator Hub,
partie **Localisation** du jeu, mets la **langue source sur Français** et active la
**traduction automatique** vers l'anglais. Roblox traduit alors les textes pour les joueurs
anglophones. Teste ensuite avec un compte réglé en anglais pour vérifier les textes importants
(tutoriel, boutons).

Traduire tout le jeu à la main en anglais est un plus gros chantier, à faire séparément.

---

## 5. Suivre où les joueurs abandonnent (entonnoir)

Le jeu envoie maintenant 7 étapes à Roblox (`ServerStorage.MWS_Funnel`) : arrivée, 1er œuf,
1er pet équipé, cristaux, entraînement, 1re victoire, monde 2. Après la publication, regarde
dans le Creator Hub, partie **Analytique → Entonnoirs (onboarding)**, l'étape où beaucoup de
joueurs s'arrêtent : c'est elle qu'il faut rendre plus simple ou plus claire.
Rien n'est envoyé pendant les tests dans Studio.

---

## 6. Trailer (environ 30 secondes, vidéo 5 de Codex)

Montrer du **vrai gameplay**, rythmé, une idée par plan :

1. 0-3 s : un œuf qui éclot en pet Secret (animation la plus grosse) + titre du jeu.
2. 3-8 s : le joueur entouré de ses pets dans la Prairie.
3. 8-14 s : entraînement au sac de frappe, niveaux qui montent.
4. 14-22 s : combat de boss (Ignareth ou le Néant Couronné) : protection, coup critique,
   attaque ultime.
5. 22-27 s : passage dans les 3 mondes (prairie, volcan, dimension mythique).
6. 27-30 s : « Hatch Mythic Pets » + « Play now! ».

Les miniatures ont été prises aux mêmes endroits : ce sont de bons points de départ pour filmer.

---

## 7. Publicité (vidéos 4, 12, 21 et 26)

Quand le jeu est publié et que les miniatures sont testées : campagne **Plays**, tous les
joueurs, sur environ 10 jours, petit budget pour commencer. Les chiffres donnés dans les vidéos
sont des exemples, pas des promesses. C'est ta décision.

---

## 8. Fait le 17/11/2026

- Nom choisi : **Hatch Mythic Pets**. Le nom et la description (anglais + une ligne en français) sont
  mis sur la page depuis Studio. Icône : `miniatures/icone_hatch_mythic_pets.png`.
- Jeu publié, toujours **privé**.
- Ton ancienne description, gardée au cas où tu voudrais la remettre :

> Tu arrives dans la prairie avec 100 coins en poche. Le but : repartir avec un Dragon primordial. Bon courage.
>
> Ramasse des cristaux, achète des œufs et monte ton équipe de 6 pets. Ils te suivent partout et ramassent les cristaux tout seuls pendant que tu fais autre chose.
>
> Dans le jeu :
> - 31 pets à collectionner, du Commun au Divin
> - 6 œufs, du basique à l'Œuf primordial (il coûte cher, oui)
> - 3 mondes : Prairie enchantée, Royaume volcanique, Dimension mythique
> - 9 dresseurs à battre, du Gobelin Sauvage au Titan Primordial
> - 3 attaques spéciales à charger en combat
> - Des cristaux dorés et royaux qui rapportent beaucoup plus, ouvre l'œil
> - La renaissance pour débloquer les mondes suivants
>
> Le jeu est encore en développement et j'ajoute des trucs régulièrement. Si tu trouves un bug ou que t'as une idée, dis-le moi !
>
> Un like si tu t'amuses, ça aide vraiment.
