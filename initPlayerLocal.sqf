/*
    initPlayerLocal.sqf
    
    Description:
    Exécuté automatiquement par chaque joueur (et en solo) au démarrage.
    Gère l'ajout du menu de support et sa persistance après respawn/TeamSwitch.
*/

// Fonction pour ajouter le menu de livraison au joueur actuel
MN_fnc_AddSupportMenu = {
    params ["_unit"];
    
    // Vérifier que c'est bien le joueur local
    if (_unit != player) exitWith {};

    // Sécurité: S'assurer que l'unité est valide
    if (isNull _unit) exitWith {};

    // ANTI-DOUBLON: Vérifie si le menu a déjà été ajouté à cette unité
    if (_unit getVariable ["MISSION_SupportMenuAdded", false]) exitWith {};
    _unit setVariable ["MISSION_SupportMenuAdded", true];

    // Ajouter le menu de communication pour la livraison véhicule
    [_unit, "DemandeVehicule"] call BIS_fnc_addCommMenuItem;
    diag_log format ["[SUPPORT] Menu livraison ajouté pour %1", name _unit];
};

// 1. Ajouter le menu au démarrage
[player] call MN_fnc_AddSupportMenu;

// Initialiser l'action de soin de groupe
[player] call Mission_fnc_task_x_revival;

// NOTE : La gestion du RESPAWN et du TEAM SWITCH est désormais faite directement
// dans onPlayerRespawn.sqf et via l'event handler TeamSwitch ici.

// 2. Gérer le TEAM SWITCH (Solo / MP Switch)
addMissionEventHandler ["TeamSwitch", {
    params ["_previousUnit", "_newUnit"];
    [_newUnit] call MN_fnc_AddSupportMenu;
    diag_log "[SUPPORT] Menu livraison réajouté après TeamSwitch";
}];
