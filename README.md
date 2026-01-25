# ⚠️ ACUTE STRESS DISORDER
### Mission de Simulation de Combat Asymétrique — Arma 3

---

## 📋 CLASSIFICATION : DOCUMENT OPÉRATIONNEL

**Nom de code :** *Acute Stress Disorder*  
**Type :** Combat asymétrique en zone urbaine  
**Difficulté :** Extrême — AUCUNE CERTITUDE  
**Mode :** Solo / Coopératif multiplayer  
**Respawn :** ✅ Activé (en Multijoueur)

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
│   ├── fn_attentat.sqf                   # Attaque terroriste sur les civils
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
