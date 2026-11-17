-- MWS_Lang : traduction anglaise des textes du jeu (le jeu est ecrit en francais).
-- Les joueurs francais gardent le francais ; tous les autres voient l'anglais.
-- Le reglage "Jeu en anglais" (attribut MWS_SetEnglish) passe outre la langue de Roblox.
-- MWS_Lang.client applique Lang.tr a tous les textes affiches (menus, notifications,
-- panneaux, combats...) : les scripts du jeu n'ont rien a changer.
--
-- Pour traduire un nouveau texte : ajoute une ligne { "francais", "anglais" } dans PHRASES.
-- Les morceaux de phrases marchent aussi : " degats !" devient " damage!" partout.
local Lang = {}

-- mots seuls, traduits seulement quand ils sont tout le texte (avec une icone devant au plus)
local EXACT = {
	["Violet"] = "Purple", ["Bleu"] = "Blue", ["Vert"] = "Green", ["Dore"] = "Gold",
	["Rouge"] = "Red", ["Rose"] = "Pink", ["Blanc"] = "White",
	["Retour"] = "Back", ["Retourner"] = "Go back",
	["Debloque"] = "Unlocked", ["Debloquer"] = "Unlock",
	["Erreur"] = "Error", ["Vaincu"] = "Defeated", ["A battre"] = "To beat",
	["Aucune"] = "None", ["Utiliser"] = "Use", ["Bientôt"] = "Soon", ["Bientot"] = "Soon",
	["Max"] = "Max", ["NIVEAU"] = "LEVEL", ["RETOUR"] = "BACK",
	["DEFAITE"] = "DEFEAT", ["Y aller"] = "Go", ["après"] = "after",
}

-- phrases et morceaux de phrases { francais, anglais } (cherches du plus long au plus court)
local PHRASES = {
	-- mondes, oeufs, monstres
	{ "Prairie enchantee", "Enchanted Meadow" }, { "Royaume volcanique", "Volcanic Kingdom" },
	{ "Dimension mythique", "Mythic Dimension" },
	{ "Oeuf de base", "Basic Egg" }, { "Oeuf dore", "Golden Egg" }, { "Oeuf mythique", "Mythic Egg" },
	{ "Oeuf de lave", "Lava Egg" }, { "Oeuf celeste", "Celestial Egg" }, { "Oeuf primordial", "Primordial Egg" },
	{ "Oeuf de fusion", "Fusion Egg" },
	{ "Gobelin Sauvage", "Wild Goblin" }, { "Orque Brutal", "Brutal Orc" }, { "Chevalier Creux", "Husk Knight" },
	{ "Grand Sylvain", "Great Sylvan" }, { "Golem de Lave", "Lava Golem" }, { "Spectre d'Ossuaire", "Ossuary Specter" },
	{ "Renard Celeste", "Celestial Fox" }, { "Oni Celeste", "Celestial Oni" }, { "Neant Couronne", "Crowned Void" },
	-- pets
	{ "Poulet", "Chicken" }, { "Chien", "Dog" }, { "Renard", "Fox" }, { "Ours", "Bear" }, { "Cerf", "Deer" },
	{ "Licorne", "Unicorn" }, { "Tortue", "Turtle" }, { "Hibou des neiges", "Snow Owl" }, { "Panda roux", "Red Panda" },
	{ "Pterodactyle", "Pterodactyl" }, { "Dragon de glace", "Ice Dragon" }, { "Tigre sabre", "Sabertooth Tiger" },
	{ "Tigre", "Tiger" }, { "Dragon de lave", "Lava Dragon" }, { "Gorille", "Gorilla" }, { "Mammouth", "Mammoth" },
	{ "Phenix", "Phoenix" }, { "Phénix", "Phoenix" }, { "Taureau de feu", "Fire Bull" }, { "Salamandre", "Salamander" },
	{ "Pegase", "Pegasus" }, { "Dragon des ombres", "Shadow Dragon" }, { "Roi serpent", "Serpent King" },
	{ "Dragon cosmique", "Cosmic Dragon" }, { "Dragon du vide", "Void Dragon" }, { "Tyrannosaure", "Tyrannosaurus" },
	{ "Cerbere", "Cerberus" }, { "Dragon lunaire", "Moon Dragon" }, { "Dragon primordial", "Primordial Dragon" },
	-- raretes, tailles, mutations, cristaux
	{ "Commun", "Common" }, { "Epique", "Epic" }, { "Legendaire", "Legendary" }, { "Mythique", "Mythic" },
	{ "Divin", "Divine" }, { "ÉPIQUE", "EPIC" }, { "LÉGENDAIRE", "LEGENDARY" }, { "MYTHIQUE", "MYTHIC" },
	{ "DIVIN", "DIVINE" },
	{ "Géant", "Giant" }, { "Geant", "Giant" }, { "Grand", "Big" }, { "Arc-en-ciel", "Rainbow" }, { "Ombre", "Shadow" },
	{ "Doré", "Golden" }, { "Cristal dore", "Golden Crystal" }, { "Cristal royal", "Royal Crystal" }, { "Cristal", "Crystal" },

	-- menus et boutons
	{ "Mes Pets", "My Pets" }, { "Meilleurs", "Best" }, { "Oeufs", "Eggs" }, { "Combats", "Battles" },
	{ "Combat", "Battle" }, { "Renaissance", "Rebirth" }, { "RENAISSANCE", "REBIRTH" },
	{ "Boutique", "Shop" }, { "Mondes", "Worlds" }, { "Machine de fusion", "Fusion Machine" },
	{ "Quêtes", "Quests" }, { "Quetes", "Quests" }, { "Classement du serveur", "Server Leaderboard" },
	{ "Couleur de l'aura", "Aura Color" }, { "Pour tes pets fusionnés", "For your fused pets" },
	{ "Paramètres", "Settings" }, { "Maîtrise", "Mastery" }, { "MAÎTRISE", "MASTERY" },
	{ "Retirer", "Unequip" }, { "Equiper", "Equip" }, { "Équiper", "Equip" }, { "Possédé", "Owned" },
	{ "Fusionner", "Fuse" }, { "Combattre", "Fight" }, { "Attaquer", "Attack" }, { "Lame de Feu", "Fire Blade" },
	{ "Tempete Glace", "Ice Storm" }, { "Frappe Divine", "Divine Strike" }, { "Changer", "Switch" }, { "Fuir", "Flee" },
	{ "Protéger", "Guard" }, { "PROTÈGE-TOI !", "GUARD NOW!" }, { "Coup charge", "Charged Hit" },
	{ "Assaut puissant", "Power Assault" }, { "Assaut", "Assault" }, { "Attaque ultime", "Ultimate Attack" },
	{ "Ultime", "Ultimate" }, { "Chargement...", "Loading..." }, { "Clique ici !", "Click here!" },
	{ "Oui, je te défie !", "Yes, I challenge you!" }, { "Non, pas maintenant", "No, not now" },
	{ "— AUTRES PETS —", "— OTHER PETS —" }, { "— MONDE ", "— WORLD " },

	-- parametres
	{ "Musique de fond !", "Background music!" }, { "Musique", "Music" },
	{ "Volume des effets sonores !", "Sound effects volume!" }, { "Effets sonores", "Sound effects" },
	{ "Voir les autres animaux de compagnie", "Show other players' pets" },
	{ "Voir mes animaux de compagnie", "Show my pets" }, { "Voir mes œufs", "Show my eggs" },
	{ "Noms sur la carte", "Names on the map" }, { "Secousses de l'écran", "Screen shake" },
	{ "Jeu en anglais (English)", "Game in English" },
	{ "DÉSACTIVÉ", "OFF" }, { "ACTIVÉ", "ON" },

	-- argent, oeufs, pets
	{ "% de chance  ·  gains x", "% chance  ·  income x" }, { "  ·  taille x", "  ·  size x" },
	{ "Possede x", "Owned x" }, { "Pas encore", "Not yet" },
	{ "Pas assez de coins ! (", "Not enough coins! (" }, { " requis)", " needed)" },
	{ "Inventaire plein !", "Inventory full!" }, { "Inventaire plein : ", "Inventory full: " },
	{ "Tu dois etre dans le monde debloque correspondant pour acheter cet oeuf.", "You must be in the matching unlocked world to buy this egg." },
	{ "Acheter (", "Buy (" }, { " monstres - ", " monsters - " }, { "Combattre le monstre", "Fight the monster" },
	{ " est arrive dans ton inventaire !", " arrived in your inventory!" },
	{ "Pokedex : ", "Pokedex: " }, { " decouvert ! (", " discovered! (" },
	{ "Maximum ", "Maximum " }, { " pets equipes.", " pets equipped." },
	{ " Prochain emplacement a ", " Next slot at " },

	-- combat
	{ "Tour de l'adversaire...", "Opponent's turn..." }, { "VICTOIRE ! Tu gagnes ", "VICTORY! You win " },
	{ "VICTOIRE !", "VICTORY!" }, { "VICTOIRE", "VICTORY" }, { "CHARGE MAX !", "MAX CHARGE!" },
	{ "BLOQUÉ !", "BLOCKED!" }, { "AÏE ! COUP CRITIQUE", "OUCH! CRITICAL HIT" }, { "RATÉ !", "MISS!" },
	{ "COUP CRITIQUE !", "CRITICAL HIT!" }, { "Coup critique !", "Critical hit!" }, { "CRITIQUE !", "CRITICAL!" },
	{ "NIVEAU GAGNÉ !", "LEVEL UP!" },
	{ "Defaite... Combat interrompu.", "Defeat... Battle interrupted." },
	{ "Defaite... Reessaie quand tu seras plus fort !", "Defeat... Try again when you're stronger!" },
	{ "Defaite... Ancien combat termine.", "Defeat... Previous battle ended." },
	{ "Defaite... Tu as fui le combat.", "Defeat... You fled the battle." },
	{ "Defaite... Combat expire (inactivite).", "Defeat... Battle expired (inactivity)." },
	{ "Defaite", "Defeat" },
	{ "Ancien combat termine, relance le combat !", "Previous battle ended, start the battle again!" },
	{ "Tu dois equiper au moins un pet !", "You must equip at least one pet!" },
	{ "Aucun pet valide equipe !", "No valid pet equipped!" },
	{ "Toutes les arenes sont occupees, reessaie !", "All arenas are busy, try again!" },
	{ "Le combat commence ! ", "The battle begins! " }, { " t'attend !", " is waiting for you!" },
	{ " éclate de rire !", " bursts out laughing!" }, { "À toi de jouer !", "Your turn!" },
	{ " se met en garde !", " is guarding!" }, { "Tu changes pour ", "You switch to " },
	{ " n'est plus en feu.", " is no longer on fire." },
	{ " est sonné et perd son tour !", " is stunned and loses its turn!" },
	{ " est sonné : il ne pourra pas attaquer !", " is stunned: it can't attack!" },
	{ " entre en ÉRUPTION ! ", " ERUPTS! " }, { " lance sa SUPER ATTAQUE ! ", " unleashes its SUPER ATTACK! " },
	{ " prépare sa SUPER ATTAQUE : protège ton pet !", " is preparing its SUPER ATTACK: guard your pet!" },
	{ " inflige ", " deals " }, { " degats !", " damage!" }, { " Il lève son bouclier !", " It raises its shield!" },
	{ " Ton pet se protège !", " Your pet guards!" }, { " La brûlure inflige ", " The burn deals " },
	{ " est K.O. !", " is K.O.!" }, { " Tu envoies ", " You send out " },
	{ " entre lui-même dans le combat !", " joins the battle himself!" }, { " envoie ", " sends out " },
	{ "CHARGE ! Il s'écrase contre ta garde et sera sonné !", "CHARGE! It crashes into your guard and will be stunned!" },
	{ "Tu n'as pas attaqué : l'Oni perd patience et sera sonné !", "You didn't attack: the Oni loses patience and will be stunned!" },
	{ "FLAMME MAUDITE ! Ta garde la bloque !", "CURSED FLAME! Your guard blocks it!" },
	{ "FLAMME MAUDITE ! Protège-toi", "CURSED FLAME! Guard!" }, { "FLAMME MAUDITE ! ", "CURSED FLAME! " },
	{ " prend feu !", " catches fire!" }, { "LE NÉANT S'ÉVEILLE !", "THE VOID AWAKENS!" },
	{ "ÉCLIPSE ! Ta garde tient bon !", "ECLIPSE! Your guard holds!" },
	{ "ÉCLIPSE ! Ton pet perd toute sa charge !", "ECLIPSE! Your pet loses all its charge!" },
	{ "ÉCLIPSE ! Protège-toi", "ECLIPSE! Guard!" },
	{ " L'Orque prend son élan !", " The Orc is winding up!" },
	{ " L'Oni se met en posture de contre !", " The Oni takes a counter stance!" },
	{ " Ignareth prépare une flamme maudite !", " Ignareth is preparing a cursed flame!" },
	{ " Le Néant prépare une ÉCLIPSE !", " The Void is preparing an ECLIPSE!" },
	{ " Le renard se divise en trois !", " The fox splits into three!" },
	{ " Le spectre devient intangible !", " The specter becomes intangible!" },
	{ " Le spectre redevient visible !", " The specter is visible again!" },
	{ " Ses racines le soignent (+", " Its roots heal it (+" }, { " PV) !", " HP)!" },
	{ "Bouclier levé : seule une attaque chargée peut le briser !", "Shield up: only a charged attack can break it!" },
	{ "Le Golem refroidit : il subit +50 % de dégâts !", "The Golem is cooling down: it takes +50% damage!" },
	{ "ÉRUPTION imminente : protège ton pet !", "ERUPTION incoming: guard your pet!" },
	{ "Surchauffe : ", "Overheat: " },
	{ " L'attaque spéciale touche le spectre !", " The special attack hits the specter!" },
	{ " Ton attaque traverse le spectre !", " Your attack goes through the specter!" },
	{ " Ton attaque dissipe les illusions !", " Your attack clears the illusions!" },
	{ " Tu as touché le vrai renard !", " You hit the real fox!" }, { " C'était une illusion !", " It was an illusion!" },
	{ " L'Oni pare ton coup et prépare une riposte !", " The Oni parries and prepares a riposte!" },
	{ " RACINES TRANCHÉES !", " ROOTS CUT!" }, { " BOUCLIER BRISÉ !", " SHIELD BROKEN!" },
	{ " Le bouclier encaisse le coup !", " The shield absorbs the hit!" }, { " Point faible !", " Weak spot!" },
	-- jauges des boss
	{ "REFROIDI : +50 % DÉGÂTS", "COOLED: +50% DAMAGE" }, { "ÉRUPTION ! Protège-toi", "ERUPTION! Guard!" },
	{ "CHALEUR ", "HEAT " }, { "BOUCLIER : attaque spéciale !", "SHIELD: special attack!" },
	{ "Bouclier dans ", "Shield in " }, { " coup(s)", " hit(s)" }, { "CHARGE ! Protège-toi", "CHARGE! Guard!" },
	{ "Charge dans ", "Charge in " }, { "Racines coupées : ", "Roots cut: " }, { " tour(s)", " turn(s)" },
	{ "Racines : il se soigne (attaque spéciale)", "Roots: it heals (special attack)" },
	{ "INTANGIBLE : attaque spéciale", "INTANGIBLE: special attack" }, { "Visible : frappe-le !", "Visible: hit it!" },
	{ "Ton pet brûle : change de pet", "Your pet is burning: switch pets" }, { "Flamme dans ", "Flame in " },
	{ " renards : attaque spéciale", " foxes: special attack" }, { "Illusions dans ", "Illusions in " },
	{ "POSTURE DE CONTRE : protège-toi !", "COUNTER STANCE: guard!" }, { "RIPOSTE en approche !", "RIPOSTE incoming!" },
	{ "Posture dans ", "Stance in " }, { "S'éveille à 50 % de PV", "Awakens at 50% HP" },
	{ "ÉVEILLÉ : éclipse dans ", "AWAKENED: eclipse in " },
	-- dialogues des boss
	{ "Hé hé ! Tu es sûr de vouloir m'affronter, petit ?", "Heh heh! Are you sure you want to face me, little one?" },
	{ "Tes pets vont finir dans ma marmite !", "Your pets will end up in my cooking pot!" },
	{ "Tu oses marcher sur mes terres ? Tu veux vraiment te battre ?", "You dare walk on my lands? Do you really want to fight?" },
	{ "Alors prépare-toi à être écrasé !", "Then get ready to be crushed!" },
	{ "Cette armure est vide... mais elle n'a jamais perdu. Es-tu prêt ?", "This armor is empty... but it has never lost. Are you ready?" },
	{ "En garde, voyageur !", "En garde, traveler!" },
	{ "La forêt t'observe depuis ton arrivée. Oseras-tu me défier ?", "The forest has watched you since you arrived. Will you dare challenge me?" },
	{ "Mes racines vont t'engloutir !", "My roots will swallow you!" },
	{ "Mon corps brûle depuis la naissance du volcan. Tu veux vraiment t'y frotter ?", "My body has burned since the volcano was born. Do you really want to mess with me?" },
	{ "Je vais te fondre comme de la cire !", "I'll melt you like wax!" },
	{ "Tous ceux qui m'ont défié reposent ici. Tu veux les rejoindre ?", "Everyone who challenged me rests here. Do you want to join them?" },
	{ "Ta place est déjà creusée.", "Your grave is already dug." },
	{ "Un mortel devant le Prince des Cendres ? Tu es sûr de ton choix ?", "A mortal before the Prince of Ashes? Are you sure about this?" },
	{ "Brûle, et que tes cendres me servent de trône !", "Burn, and let your ashes be my throne!" },
	{ "Mes queues ont balayé des armées entières. Es-tu sûr de toi ?", "My tails have swept away whole armies. Are you sure?" },
	{ "Attrape-moi, si tu le peux !", "Catch me if you can!" },
	{ "Ma lame n'est jamais sortie sans goûter la victoire. Tu insistes ?", "My blade has never been drawn without tasting victory. Still want to fight?" },
	{ "Alors danse avec les pétales !", "Then dance with the petals!" },
	{ "Je suis la fin de toute chose. Tu veux vraiment défier le Néant ?", "I am the end of all things. Do you really want to challenge the Void?" },
	{ "Même les étoiles se sont inclinées. À ton tour !", "Even the stars have bowed. Your turn!" },

	-- renaissance
	{ "RENAISSANCE DU PHÉNIX", "PHOENIX REBIRTH" },
	{ "Le Phénix rend tes pets plus forts à chaque renaissance (bien sûr, tu repars de zéro).", "The Phoenix makes your pets stronger with every rebirth (of course, you start over from zero)." },
	{ "Chaque renaissance donne...", "Each rebirth gives..." }, { "Tu as...", "You have..." },
	{ "Pour renaître, il faut...", "To be reborn, you need..." }, { "RENAIS DE TES CENDRES !", "RISE FROM YOUR ASHES!" },
	{ "+50 % de coins", "+50% coins" }, { "et +1 pet équipé toutes les 2 renaissances", "and +1 equipped pet every 2 rebirths" },
	{ "tes gains actuels : x", "your current income: x" }, { " et battre tes dresseurs (", " and beat your trainers (" },
	{ "PAS ENCORE PRÊT", "NOT READY YET" }, { "RENAISSANCE !", "REBIRTH!" }, { "  ·  gains x", "  ·  income x" },
	{ "renaissances", "rebirths" }, { "renaissance(s)", "rebirth(s)" }, { "renaissance", "rebirth" },
	{ "Tu dois battre les dresseurs de tes mondes ! (", "You must beat the trainers of your worlds! (" },
	{ " coins pour renaitre !", " coins to be reborn!" },

	-- boutique
	{ "PIÈCES", "COINS" }, { "TRAÎNÉES", "TRAILS" },
	{ "Pack de pieces", "Coin Pack" }, { "Potion de chance", "Luck Potion" }, { "Potion de vitesse", "Speed Potion" },
	{ "potions de chance a garder", "luck potions to keep" }, { "potion de chance a garder", "luck potion to keep" },
	{ "potions de vitesse a garder", "speed potions to keep" }, { "potion de vitesse a garder", "speed potion to keep" },
	{ "potion de chance", "luck potion" }, { "potion de vitesse", "speed potion" },
	{ "Chance x2 pendant 15 min", "Luck x2 for 15 min" }, { "Vitesse x2 pendant 10 min", "Speed x2 for 10 min" },
	{ "Tu en as ", "You have " }, { "Chance", "Luck" }, { "Vitesse", "Speed" },
	{ "Trainee de flammes", "Flame Trail" }, { "Trainee de cerisier", "Cherry Blossom Trail" },
	{ "Trainee cosmique", "Cosmic Trail" }, { "Trainee de magma", "Magma Trail" },
	{ "Cosmetique : une trainee de feu derriere toi.", "Cosmetic: a trail of fire behind you." },
	{ "Cosmetique : une trainee rose derriere toi.", "Cosmetic: a pink trail behind you." },
	{ "Cosmetique : une trainee d'etoiles derriere toi.", "Cosmetic: a trail of stars behind you." },
	{ "Recompense : bats le Golem de Lave (monde 2).", "Reward: beat the Lava Golem (world 2)." },
	{ "Gains x2", "Income x2" }, { "Double les revenus de tes pets et les cristaux, a vie", "Doubles your pet income and crystals, forever" },
	{ "Bonus actifs : ", "Active boosts: " }, { "Aucun bonus actif", "No active boosts" },
	{ "Nouvelle récompense : la traînée de magma ! Tu la retrouves dans la boutique.", "New reward: the magma trail! You'll find it in the shop." },
	{ "traînée", "trail" },
	{ "Achat recu, mais pas encore livre : il sera retente a ta prochaine connexion.", "Purchase received but not delivered yet: it will be retried next time you join." },
	{ " arrivera des qu'une place se libere.", " will arrive as soon as a slot frees up." },
	{ "Merci ! ", "Thank you! " }, { " ajoute !", " added!" }, { " active !", " activated!" },
	{ "Cet article sera bientot disponible !", "This item will be available soon!" },
	{ "Cet article n'est disponible que dans le monde ", "This item is only available in world " },
	{ "Limite atteinte : un seul exemplaire par joueur !", "Limit reached: only one per player!" },
	{ "Ton inventaire est plein : libere une place avant d'acheter ce pet.", "Your inventory is full: free a slot before buying this pet." },
	{ "Tu possedes deja cet article !", "You already own this item!" },
	{ "Ton boost de vitesse est deja actif !", "Your speed boost is already active!" },
	{ " coins pour acheter le boost !", " coins to buy the boost!" }, { "Boost de vitesse x", "Speed boost x" },
	{ " active pendant ", " active for " }, { " secondes !", " seconds!" },

	-- fusion
	{ "3 pets pareils = 1 pet x4  (3 fusions max)", "3 identical pets = 1 pet x4  (3 fusions max)" },
	{ "Niveau maximum (+", "Max level (+" }, { "Aucun pet : achète des oeufs !", "No pets: buy some eggs!" },
	{ "FUSION PRETE", "FUSION READY" }, { "APPUIE >>", "PRESS >>" }, { "ACCES OK", "ACCESS OK" },
	{ "Appuyer : fusionner des pets", "Press: fuse pets" },
	{ "Approche-toi d'une machine de fusion !", "Get closer to a fusion machine!" },
	{ "Il te faut 3 pets identiques (meme niveau) !", "You need 3 identical pets (same level)!" },

	-- mondes et portails
	{ "Prix : ", "Price: " }, { " coins (une fois)", " coins (one time)" }, { " (tu en as ", " (you have " },
	{ "Termine ton combat avant de voyager !", "Finish your battle before traveling!" },
	{ "Debloque d'abord le monde precedent !", "Unlock the previous world first!" },
	{ " pour entrer ici !", " to enter here!" }, { " coins pour debloquer ", " coins to unlock " },
	{ "Nouveau monde debloque : ", "New world unlocked: " }, { "Bienvenue : ", "Welcome to " },
	{ "Entrer / Debloquer", "Enter / Unlock" }, { "Monde non debloque !", "World not unlocked!" },
	{ "Il te faut ", "You need " }, { "Monde", "World" }, { "monde", "world" },

	-- quetes, cadeau du jour, classement
	{ "CADEAU DU JOUR", "DAILY GIFT" }, { "Récupérer +", "Claim +" }, { "Récupérer !", "Claim!" },
	{ "QUÊTES DU JOUR", "DAILY QUESTS" }, { "QUÊTES DE LA SEMAINE", "WEEKLY QUESTS" },
	{ "Toutes les quêtes du jour sont terminées !", "All daily quests are done!" },
	{ "Toutes les quêtes de la semaine sont terminées !", "All weekly quests are done!" },
	{ "Classé par revenu/s", "Ranked by income/s" },
	{ "Recompense du jour deja reclamee, reviens demain !", "Daily reward already claimed, come back tomorrow!" },
	{ "Quete terminee : +", "Quest complete: +" }, { "Quête de la semaine : +", "Weekly quest: +" },
	{ "Quetes du jour finies : +1 potion ! Regarde dans la boutique.", "Daily quests done: +1 potion! Check the shop." },
	{ "Jour ", "Day " }, { " complete ! +", " complete! +" },
	{ "Bon retour ! Tes pets ont gagne ", "Welcome back! Your pets earned " },
	{ " coins pendant ton absence (", " coins while you were away (" },

	-- tutoriel
	{ "Tutoriel termine ! Tout est debloque : +", "Tutorial complete! Everything is unlocked: +" },
	{ " coins et chance x2 (5 min)", " coins and luck x2 (5 min)" },
	{ "Termine d'abord le tutoriel : ", "Finish the tutorial first: " },
	{ "Termine d'abord le tutoriel !", "Finish the tutorial first!" },
	{ "Objectif termine : +", "Goal complete: +" }, { "Tutoriel", "Tutorial" }, { "ICI  -  ", "HERE  -  " },
	{ "Suis la fleche jusqu'a l'Oeuf de base et appuie sur E", "Follow the arrow to the Basic Egg and press E" },
	{ "Ouvre le menu Pets et equipe ton nouvel animal", "Open the Pets menu and equip your new pet" },
	{ "Approche-toi des cristaux : tes pets les ramassent", "Walk near the crystals: your pets collect them" },
	{ "Entraine tes pets au sac de frappe (appuie sur E)", "Train your pets at the punching bag (press E)" },
	{ "Bats ton premier dresseur : ouvre le menu Combat", "Beat your first trainer: open the Battle menu" },

	-- entrainement
	{ "Sac d'entrainement", "Training Bag" }, { "Niveau max des pets : ", "Pet max level: " },
	{ "Entrainer tes pets", "Train your pets" }, { "Sac de frappe - ", "Punching Bag - " },
	{ "Debloque d'abord ce monde pour t'entrainer ici !", "Unlock this world first to train here!" },
	{ "Equipe au moins un pet pour l'entrainer !", "Equip at least one pet to train it!" },
	{ "Tes pets ont atteint le niveau max de ce monde (Niv ", "Your pets reached this world's max level (Lv " },
	{ "). Va dans un monde plus avance !", "). Go to a more advanced world!" },
	{ "Arreter l'entrainement", "Stop training" }, { "Entrainement termine", "Training finished" },
	{ "Entrainement en cours ! Appuie de nouveau sur E pres du sac pour arreter.", "Training in progress! Press E again near the bag to stop." },
	{ "Tu t'es eloigne : entrainement arrete", "You walked away: training stopped" },
	{ "Plus aucun pet equipe : entrainement arrete", "No pet equipped anymore: training stopped" },
	{ "Monde non debloque : entrainement arrete", "World not unlocked: training stopped" },
	{ "Entrainement arrete", "Training stopped" },
	{ "Entrainement... prochain gain dans ", "Training... next gain in " },
	{ " : Niv ", ": Lv " }, { "NIVEAU SUPERIEUR ! ", "LEVEL UP! " }, { " XP par pet au total)", " XP per pet in total)" },

	-- maitrises
	{ "Mastery : ", "Mastery: " }, { "Maîtrise : ", "Mastery: " }, { "Niveau MAX", "MAX Level" },
	{ "Maîtrise complète !", "Mastery complete!" }, { "Avantages de maîtrise", "Mastery perks" },
	{ " : niveau ", ": level " }, { "Nouvel avantage : ", "New perk: " },
	{ "Entraînement intense", "Intense Training" }, { "Pets féroces", "Fierce Pets" }, { "Main chanceuse", "Lucky Hand" },
	{ "Cristaux précieux", "Precious Crystals" }, { "Fusion dorée", "Golden Fusion" },
	{ "Entraînement", "Training" }, { "Éclosion", "Hatching" }, { "Cristaux", "Crystals" }, { "Richesse", "Wealth" },
	{ "Entraîne tes pets au sac de frappe.", "Train your pets at the punching bag." },
	{ "Gagne des combats contre les dresseurs et les boss.", "Win battles against trainers and bosses." },
	{ "Fais éclore des œufs.", "Hatch eggs." }, { "Ramasse des cristaux.", "Collect crystals." },
	{ "Fusionne des pets à la machine de fusion.", "Fuse pets at the fusion machine." },
	{ "Joue : tu gagnes de l'XP toutes les 10 secondes.", "Play: you earn XP every 10 seconds." },
	{ " % d'XP pour tes pets au sac de frappe", "% XP for your pets at the punching bag" },
	{ " % de vie et d'attaque en combat", "% health and attack in battle" },
	{ " % de chance d'avoir un pet rare", "% chance to get a rare pet" },
	{ " % de coins des cristaux", "% coins from crystals" },
	{ " % de revenu des pets fusionnés", "% income from fused pets" },
	{ " % de coins par seconde", "% coins per second" },
	{ "Niveau ", "Level " }, { "niveau ", "level " },
}

-- phrases avec des nombres au milieu (motifs Lua) : traduites avant les PHRASES
local PATTERNS = {
	{ "^J(%d+)$", "D%1" },
	{ "^Nv(%d+)", "Lv%1" },
	{ "^(%d+)j (%d+)h (%d+)m$", "%1d %2h %3m" },
	{ "^Acheter (%d+) oeufs$", "Buy %1 eggs" }, { "^Acheter (%d+) œufs$", "Buy %1 eggs" },
	{ "^Ramasser (%d+) cristaux$", "Collect %1 crystals" },
	{ "^Gagner 1 combat$", "Win 1 battle" }, { "^Gagner (%d+) combats$", "Win %1 battles" },
	{ "^Fusionner des pets %(1 fois%)$", "Fuse pets (1 time)" },
	{ "^Fusionner des pets %((%d+) fois%)$", "Fuse pets (%1 times)" },
	{ "^Equiper des pets %((%d+) fois%)$", "Equip pets (%1 times)" },
	{ "^Entra[iî]+ner tes pets %((%d+) fois%)$", "Train your pets (%1 times)" },
}

table.sort(PHRASES, function(a, b) return #a[1] > #b[1] end)

-- lettre ou chiffre juste avant / apres un morceau (pour ne pas couper un mot en deux)
local function isWordAt(s, i, before)
	local b = string.byte(s, i)
	if not b then return false end
	if (b >= 65 and b <= 90) or (b >= 97 and b <= 122) or b == 95 then return true end
	-- un chiffre colle derriere ne compte pas ("gains x" + "3"), mais devant si ("Renard" dans "2Renard")
	if b >= 48 and b <= 57 then return before end
	if before then
		-- fin d'une lettre accentuee (C3 xx ou C5 xx)
		local lead = string.byte(s, i - 1)
		return b >= 128 and b <= 191 and (lead == 0xC3 or lead == 0xC5)
	end
	return b == 0xC3 or b == 0xC5
end
local function startsWithWord(text) return isWordAt(text, 1, false) end
local function endsWithWord(text) return isWordAt(text, #text, true) end
for _, p in ipairs(PHRASES) do
	p[3] = startsWithWord(p[1])
	p[4] = endsWithWord(p[1])
end

local OPEN, CLOSE = "\1", "\2"
local function marker(i)
	return OPEN .. string.char(16 + (i // 256) % 16, 16 + (i // 16) % 16, 16 + i % 16) .. CLOSE
end

local cache, cacheSize = {}, 0

-- texte francais -> texte anglais (le texte reste tel quel s'il n'y a rien a traduire)
function Lang.tr(text)
	if type(text) ~= "string" or text == "" or not text:find("%a") then return text end
	local hit = cache[text]
	if hit then return hit end
	local out = EXACT[text]
	if not out then
		local icon, rest = text:match("^([\128-\255]+%s*)(.+)$")
		if icon and EXACT[rest] then out = icon .. EXACT[rest] end
	end
	if not out then
		local s = text
		local done = {}
		for _, p in ipairs(PATTERNS) do
			s = s:gsub(p[1], function(...)
				local caps = { ... }
				local english = p[2]:gsub("%%(%d)", function(n) return caps[tonumber(n)] or "" end)
				table.insert(done, english)
				return marker(#PHRASES + #done)
			end)
		end
		for i, p in ipairs(PHRASES) do
			local fr = p[1]
			local from = 1
			while true do
				local a, b = s:find(fr, from, true)
				if not a then break end
				if (p[3] and a > 1 and isWordAt(s, a - 1, true)) or (p[4] and isWordAt(s, b + 1, false)) then
					from = b + 1
				else
					local m = marker(i)
					s = s:sub(1, a - 1) .. m .. s:sub(b + 1)
					from = a + #m
				end
			end
		end
		if s ~= text then
			s = s:gsub(OPEN .. "(...)" .. CLOSE, function(code)
				local x, y, z = string.byte(code, 1, 3)
				local i = (x - 16) * 256 + (y - 16) * 16 + (z - 16)
				return PHRASES[i] and PHRASES[i][2] or done[i - #PHRASES] or ""
			end)
		end
		-- ponctuation et nombres a l'anglaise : "Bravo !" -> "Bravo!", "1 000" -> "1,000", "50 %" -> "50%"
		s = s:gsub(" ([!?])", "%1"):gsub(" : ", ": "):gsub("(%d) %%", "%1%%")
		local before
		repeat
			before = s
			s = s:gsub("(%d) (%d%d%d)%f[%D]", "%1,%2")
		until s == before
		out = s
	end
	if cacheSize > 3000 then cache, cacheSize = {}, 0 end
	cache[text] = out
	cacheSize += 1
	return out
end

-- vrai si ce joueur doit voir le jeu en anglais
function Lang.wantsEnglish(player)
	local forced = player and player:GetAttribute("MWS_SetEnglish")
	if type(forced) == "boolean" then return forced end
	local id = ""
	pcall(function() id = game:GetService("LocalizationService").RobloxLocaleId end)
	if id == "" and player then id = player.LocaleId end
	return not string.lower(id or ""):find("^fr")
end

return Lang
