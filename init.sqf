// TOUT LE CODE DOIT ETRE OPTMISER POUR LE MULTIPLAYER

// civil_00 à civil_41 sont des civils dans l'éditeur.
// village_00 à village_08 sont des "marker" qui indiquent les lieux des présences des civils.
// civil_presence_00 à civil_presence_08 sont des "système de présence civil - ambiant" qui indiquent les lieux des présences des civils.
// presence_position_00 à presence_position_82 sont des "positions de présence civil - ambiant" qui indiquent les lieux des présences des civils.
// point_daparission_00 à point_daparission_62 sont des "points de départ des civils" qui indiquent les lieux des départ des civils.
// mine_00 à mine_08 sont des "marker" qui indiquent les lieux des mines.

// village_00 à village_09 sont des "marker" qui indiquent les lieux des mines.
// mine_00 à mine_13 sont des "marker" qui indiquent les lieux des civils.
// task_bomb_position_0 à task_bomb_position_176 sont des héliports invisibles qui indique les lieux des missions.
// task_heliport_0 à task_heliport_66 sont des héliports invisibles qui indique les lieux d'atterrissage des hélicoptères.
// milice_0 à milice_6 sont des héliports invisibles qui indique les lieux des milices.

// ============================================================
// CONFIGURATION INTRODUCTION CINÉMATIQUE
// ============================================================

// Hélicoptère d'introduction (UH-80 Ghost Hawk)
MISSION_var_helicopters = [
    ["task_x_helicoptere", "B_Heli_Transport_01_F"]
];
publicVariable "MISSION_var_helicopters";

// Loadout du modèle joueur (pour l'équipage hélico)
// Défini côté serveur avec un loadout par défaut, puis mis à jour par le client
if (isServer) then {
    MISSION_var_model_player = [
        ["model_player", "", "", "", "", []]
    ];
    publicVariable "MISSION_var_model_player";
};

// Mise à jour avec le vrai loadout du joueur (côté client)
if (hasInterface) then {
    [] spawn {
        waitUntil { !isNull player };
        sleep 0.5;
        MISSION_var_model_player = [
            ["model_player", "", "", "", "", getUnitLoadout player]
        ];
        publicVariable "MISSION_var_model_player";
    };
};

// Lancer l'introduction cinématique
[] spawn Mission_fnc_task_intro;

// Créer le briefing général de la mission (journal)
[] spawn Mission_fnc_task_x_briefing;

// ============================================================
// FONCTIONS DE LA MISSION
// ============================================================

// fonction qui lance l'appel à la prière.
[] spawn Mission_fnc_ezan;
// Fonction qui génère les mines
[] spawn Mission_fnc_mine;

// (Fonction civils déplacée après l'intro)

// Fonction qui ajuste les compétences des IA
[] spawn Mission_fnc_ajust_AI_skills;

// Fonction qui corriger le leader des IA lors de la mort ou du switch
[] spawn Mission_fnc_ajust_change_team_leader;

// Event handler pour TeamSwitch - restaure automatiquement le statut de leader et le briefing
if (hasInterface) then {
    addMissionEventHandler ["TeamSwitch", {
        params ["_previousUnit", "_newUnit"];
        diag_log format ["[SWITCH] TeamSwitch: %1 -> %2", name _previousUnit, name _newUnit];
        
        // Petit délai pour laisser le switch se terminer
        [_newUnit] spawn {
            params ["_newUnit"];
            
            sleep 0.5;
            
            // CRITIQUE: Réinitialiser les variables anti-doublon sur la nouvelle unité
            _newUnit setVariable ["MISSION_SupportMenuAdded", false];
            _newUnit setVariable ["MISSION_arsenalActionAdded", false];
            _newUnit setVariable ["MISSION_brothersActionAdded", false];
            _newUnit setVariable ["MISSION_vehiclesActionAdded", false];
            _newUnit setVariable ["MISSION_weatherActionAdded", false];
            _newUnit setVariable ["MISSION_briefing_created", false];
            
            // Restaurer le statut de chef d'équipe
            [] call Mission_fnc_ajust_change_team_leader;
            
            // Recréer le briefing pour la nouvelle unité
            [] call Mission_fnc_task_x_briefing;
            
            // Réinitialiser les actions (arsenal, véhicules, etc.)
            ["INIT", [_newUnit]] call Mission_fnc_spawn_arsenal;
            ["INIT", [_newUnit]] call Mission_fnc_spawn_brothers_in_arms;
            ["INIT", [_newUnit]] call Mission_fnc_spawn_weather_and_time;
            ["INIT", [_newUnit]] call Mission_fnc_spawn_vehicles;
            [_newUnit] call Mission_fnc_task_x_revival;
            
            // Réattacher la tâche de protection civile (l'état ASSIGNED/FAILED est préservé)
            if ("task_civil_protection" call BIS_fnc_taskExists) then {
                diag_log "[SWITCH] Tâche protection civile réattachée";
            };
            
            diag_log "[SWITCH] Briefing et actions réinitialisés";
        };
    }];
};

// Fonction qui change le nom des marqueurs en fonction de la langue
[] spawn Mission_fnc_lang_marker_name;   

// Fonction qui lance l'arsenal
["INIT"] spawn Mission_fnc_spawn_arsenal;

// Fonction qui permet de choisir ses freres d'armes (INIT mode)
["INIT"] spawn Mission_fnc_spawn_brothers_in_arms;

// Fonction qui permet de modifier le temps et le climat
["INIT"] spawn Mission_fnc_spawn_weather_and_time;

// Fonction qui lance le spawn de véhicule (garage)
["INIT"] spawn Mission_fnc_spawn_vehicles;

// --------------------------------------------------------------------------------------------------
// ATTENTE FIN INTRO : Le jeu "actif" ne commence qu'après l'intro
// --------------------------------------------------------------------------------------------------
waitUntil { sleep 1; missionNamespace getVariable ["MISSION_intro_finished", false] };

// Fonction qui génère les civils (Spawn une fois sur zone)
[] spawn Mission_fnc_civilian_logique;

// Fonction qui convertit périodiquement des civils en insurgés OPFOR
[] spawn Mission_fnc_civil_change;

// Tâche de protection civile (démarre après 50 secondes)
[] spawn Mission_fnc_task_civil_protection;

// Tâche de désamorçage de bombe (démarre après 200-1500 secondes)
[] spawn Mission_fnc_task_bomb;

// Tâche de sauvetage d'otage (démarre après 200-1500 secondes)
[] spawn Mission_fnc_task_civil_ostage;

// Tâche de destruction de cache d'armes (démarre après 200-1500 secondes)
[] spawn Mission_fnc_task_cache_armes;

// Nettoyage des OPFOR distants (optimisation mémoire)
[] spawn Mission_fnc_nettoyage;

// Tâche de rendez-vous avec milices locales (démarre après 150 secondes)
[] spawn Mission_fnc_task_appointment;

// Tâche d'attaque terroriste (démarre après 150 secondes)
[] spawn Mission_fnc_task_attentat;

// Système de fin de mission avec extraction (démarre après 5 minutes)
[] spawn Mission_fnc_fin;