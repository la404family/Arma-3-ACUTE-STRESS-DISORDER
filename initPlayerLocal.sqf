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
    if (_unit == player) then {
        // Ajouter le menu de communication pour la livraison véhicule
        [_unit, "DemandeVehicule"] call BIS_fnc_addCommMenuItem;
        diag_log format ["[SUPPORT] Menu livraison ajouté pour %1", name _unit];
    };
};

// 1. Ajouter le menu au démarrage
[player] call MN_fnc_AddSupportMenu;

// 2. Gérer le RESPAWN (MP)
player addEventHandler ["Respawn", {
    params ["_unit", "_corpse"];
    [_unit] call MN_fnc_AddSupportMenu;
    diag_log "[SUPPORT] Menu livraison réajouté après respawn";
}];

// 3. Gérer le TEAM SWITCH (Solo / MP Switch)
addMissionEventHandler ["TeamSwitch", {
    params ["_previousUnit", "_newUnit"];
    [_newUnit] call MN_fnc_AddSupportMenu;
    diag_log "[SUPPORT] Menu livraison réajouté après TeamSwitch";
}];
