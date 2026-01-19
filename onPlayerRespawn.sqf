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

// Log pour debug (peut être supprimé en production)
diag_log format ["[MISSION] Joueur respawné: %1", name _newUnit];

// ============================================================
// RÉINITIALISATION DES ACTIONS DU JOUEUR
// ============================================================

// Arsenal - Ajoute l'action pour ouvrir l'arsenal virtuel
[] spawn Mission_fnc_spawn_arsenal;

// Frères d'armes - Ajoute l'action pour recruter des IA
["INIT"] spawn Mission_fnc_spawn_brothers_in_arms;

// Météo et temps - Ajoute l'action pour modifier le temps/climat
[] spawn Mission_fnc_spawn_weather_and_time;

// Véhicules - Ajoute l'action pour le garage de véhicules
["INIT"] spawn Mission_fnc_spawn_vehicles;

// Revival - Réinitialise l'action de soins du groupe (si applicable)
[] spawn Mission_fnc_task_x_revival;

// Chef d'équipe - Réajuste le statut de chef après respawn
[] spawn Mission_fnc_ajust_change_team_leader;

// ============================================================
// FIN DE LA RÉINITIALISATION
// ============================================================

diag_log "[MISSION] Actions réinitialisées après respawn";
