/*
    onPlayerRespawn.sqf
    
    Description:
    Ce fichier est automatiquement exécuté par Arma 3 à chaque fois qu'un joueur respawn.
    Il réinitialise toutes les actions (arsenal, véhicules, frères d'armes, etc.) 
    pour que le joueur respawné puisse à nouveau y accéder.
    
    Paramètres automatiques:
    _newUnit      - La nouvelle unité du joueur après respawn
    _oldUnit      - L'ancienne unité (corps) du joueur
    _respawn      - Type de respawn (0=none, 1=bird, 2=instant, 3=base, 4=group, 5=side, 6=custom, etc.)
    _respawnDelay - Délai de respawn configuré
*/

params ["_newUnit", "_oldUnit", "_respawn", "_respawnDelay"];

// Sécurité : Si _newUnit est null (peut arriver lors de lags intenses), on tente de récupérer player
if (isNull _newUnit) then {
    _newUnit = player;
    diag_log "[RESPAWN] ATTENTION: _newUnit était null, fallback sur 'player'";
};

// Log pour debug (peut être supprimé en production)
diag_log format ["[MISSION] Joueur respawné: %1", name _newUnit];

// ============================================================
// RESTAURATION DE L'ÉQUIPEMENT (LOADOUT)
// ============================================================

// Récupère l'équipement de l'ancien corps et l'applique au nouveau joueur
if (!isNull _oldUnit) then {
    private _loadout = getUnitLoadout _oldUnit;
    if (count _loadout > 0) then {
        _newUnit setUnitLoadout _loadout;
        diag_log format ["[MISSION] Loadout restauré depuis l'ancien corps pour %1", name _newUnit];
    };
};

// ============================================================
// RÉINITIALISATION DES ACTIONS DU JOUEUR
// ============================================================

// Ajouter le menu de support (Livraison Véhicule)
// Note: MN_fnc_AddSupportMenu est défini dans initPlayerLocal.sqf
if (!isNil "MN_fnc_AddSupportMenu") then {
    [_newUnit] call MN_fnc_AddSupportMenu;
};

// Arsenal - Ajoute l'action pour ouvrir l'arsenal virtuel
["INIT", [_newUnit]] spawn Mission_fnc_spawn_arsenal;

// Frères d'armes - Ajoute l'action pour recruter des IA
["INIT", [_newUnit]] spawn Mission_fnc_spawn_brothers_in_arms;

// Météo et temps - Ajoute l'action pour modifier le temps/climat
["INIT", [_newUnit]] spawn Mission_fnc_spawn_weather_and_time;

// Véhicules - Ajoute l'action pour le garage de véhicules
["INIT", [_newUnit]] spawn Mission_fnc_spawn_vehicles;

// Revival - Réinitialise l'action de soins du groupe (si applicable)
[] spawn Mission_fnc_task_x_revival;

// Chef d'équipe - Réajuste le statut de chef après respawn
[] spawn Mission_fnc_ajust_change_team_leader;

// ============================================================
// RECRÉATION DU BRIEFING (JOURNAL)
// ============================================================

// Le briefing doit être recréé car il est attaché à l'ancienne unité
[] spawn Mission_fnc_task_x_briefing;

// ============================================================
// RÉATTACHEMENT DES TÂCHES PERMANENTES
// ============================================================

// Tâche de protection civile - réattacher au nouveau joueur
[] spawn {
    sleep 1; // Attendre que le joueur soit complètement initialisé
    
    // Vérifier si la tâche existe
    if ("task_civil_protection" call BIS_fnc_taskExists) then {
        // La tâche existe déjà, on la réattache simplement au joueur
        // L'état (ASSIGNED ou FAILED) est préservé automatiquement
        diag_log "[RESPAWN] Tâche protection civile réattachée";
    } else {
        // La tâche n'existe pas encore (ne devrait pas arriver)
        diag_log "[RESPAWN] Tâche protection civile non trouvée - attente création serveur";
    };
};

// ============================================================
// FIN DE LA RÉINITIALISATION
// ============================================================

diag_log "[MISSION] Actions et briefing réinitialisés après respawn";
