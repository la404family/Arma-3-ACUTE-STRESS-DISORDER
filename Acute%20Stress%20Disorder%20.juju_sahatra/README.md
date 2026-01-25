# ⚠️ ACUTE STRESS DISORDER
### Mission de Simulation de Combat Asymétrique — Arma 3

---

## 📋 CLASSIFICATION : DOCUMENT OPÉRATIONNEL

**Nom de code :** *Acute Stress Disorder*  
**Zone d'opération :** Sefrou-Ramal  
**Type :** Combat asymétrique en zone urbaine  
**Difficulté :** Extrême — AUCUNE CERTITUDE  
**Mode :** Solo / Coopératif multiplayer  
**Respawn :** ✅ Activé (Solo & Multijoueur)

---

## 🎯 CONTEXTE OPÉRATIONNEL

Vous êtes déployé dans une zone de conflit où **la ligne entre civil et combattant n'existe plus**.

Dans ce théâtre d'opérations, l'ennemi ne porte pas d'uniforme. Il se fond dans la population. Il marche parmi les civils. Il *est* civil — jusqu'au moment où il décide de ne plus l'être.

Cette mission reproduit **l'un des aspects les plus traumatisants de la guerre moderne** : l'impossibilité de distinguer clairement ami et ennemi, la pression psychologique constante, et les conséquences irréversibles de chaque décision de tir.

---

## ⚡ MENACE INSURGÉE : LE STRESS DU COMBATTANT

### 🔴 SYSTÈME DE CONVERSION CIVILE

> **ALERTE RENSEIGNEMENT**  
> *Des civils peuvent se révéler être des combattants ennemis à tout moment.*

**Mécanisme :**
- Toutes les **100 à 400 secondes** (intervalle aléatoire), le système sélectionne **3 civils** situés à plus de 50 mètres du joueur
- Ces civils sont **instantanément convertis** en combattants OPFOR
- Ils conservent leur **apparence civile** (mêmes vêtements, même visage)
- Ils reçoivent un sac coyote + **AKM + 180 munitions** et passent en mode combat
- Ils **attaquent immédiatement** le joueur le plus proche

**Impact psychologique réaliste :**
- Impossible de distinguer un civil pacifique d'un insurgé qui attend le bon moment
- Tension permanente lors de chaque contact avec la population
- Dilemme moral : tirer préventivement = crime de guerre / attendre = embuscade

---

### 💀 CHAMP DE MINES INVISIBLE

> **DANGER — ZONE NON SÉCURISÉE**

- **140 mines antipersonnel** (APERSMine) sont déployées aléatoirement sur la carte (principalement dans les routes)
- Réparties sur **14 zones** (mine_00 à mine_13), 10 mines par zone
- Position **aléatoire à chaque partie**
- Aucun marqueur, aucun avertissement

**Conséquence :** Chaque pas en terrain non reconnu peut être le dernier. Comme dans la vraie guerre.

---

## 📜 MISSIONS DYNAMIQUES

Toutes les missions se déclenchent **automatiquement et aléatoirement** pendant la partie. Le joueur ne choisit pas quand elles arrivent — **elles arrivent**.

---

### 🟠 MISSION : PROTECTION CIVILE
**Déclenchement :** 120 secondes après le début

> *"Votre mission principaleest de protéger la population civile. Tout dommage collatéral sera considéré comme un échec de commandement."*

- **Objectif :** Ne pas tuer plus de 5 civils
- **Comptabilisation :** Automatique — chaque mort civile causée par un joueur est comptée
- **Conséquence :** 5 morts civils = **ÉCHEC DE MISSION**

**Dilemme tactique :**
- Les insurgés sont déguisés en civils
- Tirer trop vite = risque de tuer un innocent
- Tirer trop tard = risque de mourir
- Chaque tir doit être justifié. Chaque hésitation peut être fatale.

---

### 🔴 MISSION : DÉSAMORÇAGE DE BOMBE
**Déclenchement :** Aléatoire (150 à 1500 secondes après le début)

> *"Un engin explosif improvisé a été signalé par la population. Temps estimé avant détonation : inconnu."*

- **Position :** Aléatoire parmi **177 emplacements** possibles
- **Temps avant explosion :** 5 à 10 minutes (le joueur ne connaît PAS le temps exact)
- **Signal sonore :** La bombe émet un bip toutes les 5 secondes
- **Désamorçage :** Action de 10 secondes à proximité de l'IED
- **Échec :** Explosion massive (équivalent bombe guidée)

**Stress opérationnel :**
- Pas de compte à rebours visible
- Le bip accélère-t-il ? Non. Mais vous ne le savez pas.
- Chaque seconde de trajet vers l'objectif est une seconde de moins pour le désamorçage

---

### 🟡 MISSION : SAUVETAGE D'OTAGE
**Déclenchement :** Aléatoire (150 à 1500 secondes après le début)

> *"Un civil est retenu par des éléments hostiles. L'extraction par hélicoptère est autorisée."*

- **Position :** Aléatoire parmi **177 emplacements**
- **Gardes :** 3 à 5 OPFOR déguisés en civils (sac coyote + AKM)
- **Otage :** En position d'exécution, immobile et vulnérable
- **Protection :** L'otage est invincible pendant 10 secondes après spawn (stabilisation)
- **Libération :** Action maintenue pour libérer l'otage
- **Extraction :** Un hélicoptère CH-67 Huron est envoyé vers l'héliport le plus proche
- **Embarquement :** L'otage doit monter dans l'hélicoptère SANS joueur à bord

**Points critiques :**
- Les gardes ressemblent à des civils — identification impossible jusqu'au premier tir
- L'otage peut mourir pendant l'échange de tirs
- L'hélicoptère atterrit en coupant son carburant (méthode de forçage)

---

### 🔵 MISSION : DESTRUCTION DE CACHE D'ARMES
**Déclenchement :** Aléatoire (5 à 1500 secondes après le début)

> *"Une cache d'armes ennemie a été localisée. Détruisez-la et évacuez la zone."*

- **Position :** Aléatoire parmi **177 emplacements**
- **Gardes :** 1 à 3 OPFOR déguisés en civils
- **Cache :** Caisse d'armes (Box_East_Wps_F), indestructible par les armes
- **Destruction :** Action de pose d'explosif (animation de 5 secondes)
- **Compte à rebours :** 40 secondes pour évacuer la zone
- **Détonation :** Explosion + incendie persistant (30 secondes)

---

### 🟣 MISSION : RENDEZ-VOUS AVEC LA MILICE
**Déclenchement :** Aléatoire (5 à 1500 secondes après le début)

> *"Un chef de milice locale demande à vous rencontrer. Il prétend avoir des informations sur les emplacements de mines. Procédez avec extrême prudence — loyautés incertaines."*

- **Position :** Aléatoire parmi **7 emplacements** (milice_0 à milice_6)
- **Chef de milice :** 1 unité immobile, tenue civile, armé d'un pistolet
- **Gardes :** 2 à 4 miliciens, tenue civile, armés d'AKM, flânent dans la zone
- **Action :** "Parler avec le chef de milices" (visible à moins de 5m)
- **Limite de temps :** 5 à 15 minutes (invisible), échec si dépassé et joueur à +1200m

**⚠️ TROIS SCÉNARIOS POSSIBLES (ALÉATOIRE) :**

| Scénario | Description | Condition de succès |
|----------|-------------|---------------------|
| **Succès** | Le chef coopère et révèle 5 positions de mines sur la carte | Mission terminée |
| **Trahison directe** | Le chef et ses hommes deviennent OPFOR et attaquent | Éliminer toutes les milices |
| **Trahison interne** | Le chef est trahi par ses hommes ; il devient BLUFOR | Protéger le chef + éliminer les hostiles |

**Particularités :**
- Les milices sont du side **INDEPENDENT** (non nettoyées par le système automatique)
- Spawn à 0.7m au-dessus du sol (anti-bug terrain)
- Nettoyage uniquement quand tous les joueurs sont à +1200m

---

### 🔴 MISSION : ATTENTAT TERRORISTE
**Déclenchement :** Aléatoire (5 à 1500 secondes après le début)

> *"Des terroristes armés attaquent la population civile. Intervenez immédiatement."*

- **Position :** Aléatoire parmi **177 emplacements**
- **Menace :** 3 à 6 OPFOR déguisés en civils (sac coyote + arme)
- **Activité :** Ils exécutent sommairement les civils à proximité
- **Objectif :** Éliminer tous les terroristes
- **Échec :** Si la zone n'est pas sécurisée à temps

**Urgence absolue :**
- Ils ne s'arrêtent pas de tuer tant qu'ils ne sont pas neutralisés
- Impossible de les distinguer des civils tant qu'ils n'ont pas ouvert le feu (ou via leur sac et armes)

---

## 🚁 SUPPORT LOGISTIQUE : LIVRAISON VÉHICULE

> *"INDICATIF AIGLE — Livraison en cours. Sécurisez la LZ."*

**Accès :** Menu communication **0** → **8** → Sélectionner "INDICATIF AIGLE - Pont Aérien Véhicule"

| Paramètre | Valeur |
|-----------|--------|
| **Véhicule livré** | Prowler (désarmé) |
| **Hélicoptère** | CH-67 Huron (sling load) |
| **Position de largage** | 10-50m du joueur |
| **Équipage hélico** | Indestructible (permanent) |
| **Véhicule** | Indestructible pendant transport, destructible après largage |

**Mécanisme :**
1. Demande envoyée → hélicoptère spawn à 2km
2. Approche vers le joueur (vol à 150m d'altitude)
3. Coupure carburant → descente forcée
4. Largage du véhicule → restauration carburant
5. Retour et nettoyage automatique (2km de distance)

---

## 🌦️ CONDITIONS ENVIRONNEMENTALES

### Météo et Heure Dynamiques
Le joueur peut modifier l'environnement via une zone d'interaction :

| Paramètre | Valeurs disponibles |
|-----------|---------------------|
| **Heure** | 03:00, 05:00, 07:00, 10:00, 11:00, 13:00, 17:00, 18:00, 19:00, 22:00 |
| **Nuages** | 5% à 95% de couverture |
| **Brouillard** | 0% à 2.5% de densité |

**Application tactique :**
- Opérations nocturnes = couverture mais visibilité réduite
- Brouillard = infiltration possible mais danger de contact rapproché
- Météo variable = incertitude supplémentaire

---

### 🕌 Appel à la Prière (Ezan)
- **Premier déclenchement :** Aléatoire entre 5 secondes et 15 minutes
- **Répétition :** Toutes les 60 minutes
- **Sources sonores :** 5 points de diffusion simultanés
- **Effet :** Immersion totale dans l'environnement opérationnel

---

## 👥 SYSTÈME DE FRÈRES D'ARMES

Recrutez jusqu'à **14 unités IA** pour renforcer votre groupe.

| Fonctionnalité | Description |
|----------------|-------------|
| **Recrutement** | Zone dédiée + interface de sélection |
| **Types** | Toutes les unités de votre faction, triées par faction |
| **Option spéciale** | "Un soldat comme moi !" — clone votre équipement |
| **Spawn** | Effet de fumée blanche, apparition séquentielle (2 secondes) |
| **Contrôle** | Unités switchables, insigne du chef de groupe |
| **Reset** | Suppression de toutes les IA du groupe |

---

## 📊 POPULATION CIVILE DYNAMIQUE

### Gestion Intelligente
- **Pool de templates :** 42 apparences civiles uniques (civil_00 à civil_41)
- **Population active :** Jusqu'à 45 civils simultanément + mod civil ajouté
- **Zone de spawn :** Rayon de 400m autour du joueur
- **Zone de despawn :** Au-delà de 800m
- **Spawn par vague :** Jusqu'à 5 civils par seconde

### Comportement IA
| État | Condition | Action |
|------|-----------|--------|
| **IDLE** | Aucune menace | Reste sur place 5-10 secondes |
| **WANDERING** | 70% de chance | Se déplace vers un point proche |
| **FLEEING** | Véhicule rapide ou tir | Fuite à vitesse maximale pendant 10 secondes |

**Réactions réalistes :**
- Fuite si un véhicule approche à plus de 45 km/h à moins de 35m
- Fuite si un tir est entendu à moins de 50m
- Évitement de collision entre civils

---

## ⚙️ ARCHITECTURE TECHNIQUE

### Optimisation Multijoueur
Cette mission est **entièrement optimisée pour le multijoueur** avec une séparation stricte Client/Serveur.

| Composant | Exécution | Fonction |
|-----------|-----------|----------|
| Logique IA & Missions | 🖥️ Serveur | Évite les conflits de synchronisation |
| Interface & Actions | 👤 Client | Performance optimale |
| Synchronisation | 🔄 remoteExec | Compatible JIP (Join In Progress) |

```
📁 Acute Stress Disorder.SefrouRamal/
├── 📄 init.sqf                           # Point d'entrée principal
├── 📄 initServer.sqf                     # Initialisation serveur (fonctions remoteExec)
├── 📄 initPlayerLocal.sqf                # Initialisation client (menus support)
├── 📄 onPlayerRespawn.sqf                # Réinitialisation après respawn
├── 📄 client_request_vehicule.sqf        # Demande livraison véhicule (client)
├── 📄 description.ext                    # Configuration mission + CfgFunctions
├── 📄 stringtable.xml                    # Localisation (13 langues)
├── 📄 mission.sqm                        # Données de l'éditeur Eden
│
├── 📁 functions/                         # 22 fonctions SQF
│   │
│   │── 🎬 CINÉMATIQUE
│   ├── fn_task_intro.sqf                 # Introduction cinématique (5 plans caméra)
│   │
│   │── 👥 GESTION CIVILS
│   ├── fn_civilian_logique.sqf           # Spawn dynamique (45 civils max, agents)
│   ├── fn_civil_change.sqf               # Conversion civils → insurgés OPFOR
│   │
│   │── 🎯 MISSIONS DYNAMIQUES
│   ├── fn_task_civil_protection.sqf      # Protection civile (5 morts max)
│   ├── fn_task_bomb.sqf                  # Désamorçage de bombe (177 positions)
│   ├── fn_task_civil_ostage.sqf          # Sauvetage d'otage + extraction hélico
│   ├── fn_task_cache_armes.sqf           # Destruction cache d'armes
│   ├── fn_task_appointment.sqf           # RDV milices (3 scénarios aléatoires)
│   │
│   │── ⚙️ SYSTÈMES JOUEUR
│   ├── fn_spawn_arsenal.sqf              # Arsenal virtuel + sync voix
│   ├── fn_spawn_brothers_in_arms.sqf     # Recrutement IA (14 max)
│   ├── fn_spawn_vehicles.sqf             # Garage de véhicules
│   ├── fn_spawn_weather_and_time.sqf     # Contrôle météo/heure
│   ├── fn_task_x_revival.sqf             # Auto-soins groupe IA
│   ├── fn_task_x_badge.sqf               # Synchronisation insignes équipe
│   │
│   │── 🚁 SUPPORT LOGISTIQUE
│   ├── fn_livraison_vehicule.sqf         # Livraison véhicule par hélico (sling load)
│   │
│   │── 🤖 GESTION IA
│   ├── fn_ajust_AI_skills.sqf            # Compétences IA (OPFOR/BLUFOR)
│   ├── fn_ajust_change_team_leader.sqf   # Transfert leadership auto
│   │
│   │── 🌍 ENVIRONNEMENT
│   ├── fn_mine.sqf                       # 140 mines sur 14 zones
│   ├── fn_ezan.sqf                       # Appel à la prière (5 minarets)
│   ├── fn_lang_marker_name.sqf           # Localisation marqueurs carte
│   └── fn_nettoyage.sqf                  # Cleanup OPFOR distants (1200m)
│
├── 📁 dialogs/                           # Interfaces utilisateur (HPP)
│   ├── defines.hpp
│   ├── recruit_menu.hpp                  # Menu frères d'armes
│   ├── vehicle_menu.hpp                  # Menu garage
│   ├── weather_time_menu.hpp             # Menu météo/temps
│   ├── missions_menu.hpp
│   └── enemies_menu.hpp
│
└── 📁 music/
    ├── ezan.ogg                          # Appel à la prière
    └── intro.ogg                         # Musique d'introduction
```

---

## ⚠️ AVERTISSEMENT FINAL

> *Cette mission simule le stress psychologique des opérations en zone de conflit asymétrique. Elle ne prétend pas reproduire parfaitement la réalité, mais elle s'efforce de capturer l'essence de ce que vivent les soldats modernes : l'incertitude, le doute, et le poids de chaque décision.*

> *Acute Stress Disorder (Trouble de Stress Aigu) n'est pas anodin. C'est un terme médical désignant les réactions psychologiques immédiates après un traumatisme.*

---

**BONNE CHANCE, SOLDAT.**

*Vous en aurez besoin.*

---
