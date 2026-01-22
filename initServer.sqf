/*
    initServer.sqf
    
    Description:
    Exécuté automatiquement côté serveur au démarrage de la mission.
    Compile et publie la fonction de livraison pour remoteExec.
*/

// ====================================================================================
// SYSTEME DE TEMPLATES CIVILS (GLOBAL)
// ====================================================================================
// On capture les données des civils placés dans l'éditeur (civil_00 à civil_41)
// AVANT que quiconque ne puisse les supprimer ou que le garbage collector ne passe.
// Cela garantit que toutes les tâches (Attentat, RDV, etc.) ont accès aux bonnes tenues.

MISSION_CivilianTemplates = [];

for "_i" from 0 to 41 do {
    private _varName = format ["civil_%1", if (_i < 10) then { "0" + str _i } else { str _i }];
    private _unit = missionNamespace getVariable [_varName, objNull];
    
    if (!isNull _unit) then {
        MISSION_CivilianTemplates pushBack [typeOf _unit, getUnitLoadout _unit, face _unit];
        
        // Nettoyage immédiat des unités éditeur pour éviter les doublons/conflits
        _unit hideObjectGlobal true;
        _unit enableSimulationGlobal false;
        deleteVehicle _unit;
    };
};

if (count MISSION_CivilianTemplates == 0) then {
    diag_log "[SERVER] ATTENTION: Aucun template civil_XX trouvé! Utilisation du fallback.";
    MISSION_CivilianTemplates pushBack ["C_man_polo_1_F", [], "WhiteHead_01"];
};

diag_log format ["[SERVER] MISSION_CivilianTemplates initialisé avec %1 templates.", count MISSION_CivilianTemplates];
publicVariable "MISSION_CivilianTemplates"; // Au cas où des clients en auraient besoin (optionnel)

// ====================================================================================

// Compiler la fonction de livraison véhicule
MN_fnc_serverDrop = compile preprocessFileLineNumbers "functions\fn_livraison_vehicule.sqf";

// Publier la fonction pour qu'elle soit accessible via remoteExec
publicVariable "MN_fnc_serverDrop";

diag_log "[SERVER] Fonction MN_fnc_serverDrop compilée et publiée";
