/*
    FONCTION: fn_task_civil_protection
    DESCRIPTION: Tâche de protection civile
    
    - Démarre 50 secondes après le début de la mission
    - Crée une tâche "Protection Civile" sans lieu précis
    - Surveille les morts civils causés par les joueurs
    - Compteur de 5 civils maximum - échec si 5 civils meurent
*/

if (!isServer) exitWith {};

// --- CONFIGURATION ---
CIVIL_PROTECTION_MaxDeaths    = 5;      // Nombre max de morts civils avant échec
CIVIL_PROTECTION_StartDelay   = 120;      // Délai avant activation (secondes)
CIVIL_PROTECTION_Debug        = false;  // Mode debug

// Variable globale pour le compteur (synchronisée)
CIVIL_PROTECTION_DeathCount = 0;
publicVariable "CIVIL_PROTECTION_DeathCount";

// Variable pour l'état de la tâche
CIVIL_PROTECTION_TaskFailed = false;
publicVariable "CIVIL_PROTECTION_TaskFailed";

// --- FONCTION: LOG DEBUG ---
CIVIL_PROTECTION_fnc_log = {
    params ["_msg"];
    if (CIVIL_PROTECTION_Debug) then { 
        systemChat format ["[CIVIL_PROTECTION] %1", _msg]; 
        diag_log format ["[CIVIL_PROTECTION] %1", _msg];
    };
};

// --- FONCTION: ÉCHEC DE LA TÂCHE ---
CIVIL_PROTECTION_fnc_failTask = {
    if (CIVIL_PROTECTION_TaskFailed) exitWith {};
    
    CIVIL_PROTECTION_TaskFailed = true;
    publicVariable "CIVIL_PROTECTION_TaskFailed";
    
    // Marquer la tâche comme échouée
    ["task_civil_protection", "FAILED"] call BIS_fnc_taskSetState;
    
    ["TÂCHE ÉCHOUÉE - Trop de civils tués!"] call CIVIL_PROTECTION_fnc_log;
};

// --- FONCTION: TRAITEMENT MORT D'UN CIVIL ---
CIVIL_PROTECTION_fnc_onCivilianKilled = {
    params ["_victim", "_killer"];
    
    // Vérifier si la tâche est déjà échouée
    if (CIVIL_PROTECTION_TaskFailed) exitWith {};
    
    // Vérifier si le tueur est un joueur
    if (!isPlayer _killer) exitWith {};
    
    // Incrémenter le compteur
    CIVIL_PROTECTION_DeathCount = CIVIL_PROTECTION_DeathCount + 1;
    publicVariable "CIVIL_PROTECTION_DeathCount";
    
    [format ["Civil tué par %1. Compteur: %2/%3", name _killer, CIVIL_PROTECTION_DeathCount, CIVIL_PROTECTION_MaxDeaths]] call CIVIL_PROTECTION_fnc_log;
    
    // Vérifier si échec
    if (CIVIL_PROTECTION_DeathCount >= CIVIL_PROTECTION_MaxDeaths) then {
        [] call CIVIL_PROTECTION_fnc_failTask;
    };
};

// --- BOUCLE PRINCIPALE ---
[] spawn {
    // Attendre le délai de démarrage
    sleep CIVIL_PROTECTION_StartDelay;
    
    ["Système de protection civile activé"] call CIVIL_PROTECTION_fnc_log;
    
    // Créer la tâche pour tous les joueurs
    [
        true,                                    // Global
        ["task_civil_protection"],               // ID de la tâche
        [
            localize "STR_CIVIL_PROTECTION_DESC",    // Description
            localize "STR_CIVIL_PROTECTION_TITLE",   // Titre
            ""                                       // Marqueur (aucun)
        ],
        objNull,                                 // Pas de destination
        "CREATED",                               // État initial
        -1,                                      // Priorité
        true,                                    // Afficher notification
        "defend"                                 // Type d'icône
    ] call BIS_fnc_taskCreate;
    
    // Activer la tâche
    ["task_civil_protection", "ASSIGNED"] call BIS_fnc_taskSetState;
    
    // Ajouter un Event Handler global pour tous les civils morts
    addMissionEventHandler ["EntityKilled", {
        params ["_victim", "_killer", "_instigator"];
        
        // Utiliser l'instigateur si disponible (pour les véhicules, etc.)
        if (!isNull _instigator) then { _killer = _instigator; };
        
        // Vérifier si c'est un civil
        if (side group _victim == civilian) then {
            [_victim, _killer] call CIVIL_PROTECTION_fnc_onCivilianKilled;
        };
    }];
    
    ["Event Handler EntityKilled ajouté"] call CIVIL_PROTECTION_fnc_log;
};
