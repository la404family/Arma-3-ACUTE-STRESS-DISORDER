/*
    fn_task_cache_armes.sqf
    
    Description:
    Mission de destruction de cache d'armes en boucle.
    - 1 à 3 OPFOR déguisés en civils protègent la zone
    - Une cache d'armes à détruire via addAction
    - 40 secondes pour évacuer après activation
    - Petite explosion à la fin
    
    Après destruction réussie, une nouvelle mission démarre après 200-1500 secondes.
    
    Utilise les templates des civils civil_00 à civil_41 (comme fn_civilian_logique).
    
    Optimisé pour le multijoueur.
*/

// Exécution uniquement sur le serveur
if (!isServer) exitWith {};

// ============================================================
// CONFIGURATION
// ============================================================

CACHE_Debug = false; // Mettre à true pour debug

CACHE_fnc_log = {
    params ["_msg"];
    diag_log format ["[CACHE] %1", _msg];
    if (CACHE_Debug) then { systemChat format ["[CACHE] %1", _msg]; };
};

// ============================================================
// COLLECTER LES TEMPLATES DES CIVILS (civil_00 à civil_41)
// ============================================================

private _civilTemplates = [];

for "_i" from 0 to 41 do {
    private _varName = format ["civil_%1", if (_i < 10) then { "0" + str _i } else { str _i }];
    private _unit = missionNamespace getVariable [_varName, objNull];
    
    if (!isNull _unit) then {
        _civilTemplates pushBack [typeOf _unit, getUnitLoadout _unit, face _unit];
    };
};

// Fallback si aucun template trouvé
if (count _civilTemplates == 0) then {
    ["AVERTISSEMENT: Aucun template civil trouvé, utilisation du fallback"] call CACHE_fnc_log;
    _civilTemplates pushBack ["C_man_polo_1_F", [], "WhiteHead_01"];
};

[format ["Templates civils collectés: %1", count _civilTemplates]] call CACHE_fnc_log;

// ============================================================
// FONCTION: CRÉER UN OPFOR DÉGUISÉ EN CIVIL
// ============================================================

CACHE_fnc_createDisguisedOPFOR = {
    params ["_pos", "_patrolRadius", "_templates"];
    
    private _template = selectRandom _templates;
    _template params ["_type", "_loadout", "_face"];
    
    private _grp = createGroup [east, true];
    private _unit = _grp createUnit ["O_G_Soldier_F", [0,0,0], [], 0, "NONE"];
    _unit setPosASL _pos;
    
    _unit setFace _face;
    if (count _loadout > 0) then {
        _unit setUnitLoadout _loadout;
    };
    
    removeAllWeapons _unit;
    removeBackpack _unit;
    
    _unit addBackpack "B_Messenger_Coyote_F";
    _unit addWeapon "arifle_AKM_F";
    _unit addPrimaryWeaponItem "30Rnd_762x39_Mag_F";
    
    for "_i" from 1 to 4 do {
        _unit addItemToBackpack "30Rnd_762x39_Mag_F";
    };
    
    _unit linkItem "ItemMap";
    _unit linkItem "ItemRadio";
    
    _unit setCombatMode "YELLOW";
    _unit setBehaviour "SAFE";
    _unit setSkill 0.5;
    
    [_unit, _pos, _patrolRadius] spawn {
        params ["_u", "_center", "_radius"];
        
        _u setSpeedMode "LIMITED";
        
        while {alive _u} do {
            private _movePos = _center getPos [random _radius, random 360];
            _u doMove _movePos;
            sleep (20 + random 20);
        };
    };
    
    _unit
};

// ============================================================
// COMPTEUR DE MISSIONS POUR ID UNIQUE
// ============================================================

private _missionCounter = 0;

// ============================================================
// DÉFINITION DES FONCTIONS GLOBALES (avant la boucle!)
// ============================================================

CACHE_fnc_addDestroyAction = {
    params ["_cacheObj", "_taskId"];
    
    if (!hasInterface) exitWith {};
    if (isNull _cacheObj) exitWith {};
    
    private _actionId = _cacheObj addAction [
        format ["<t color='#FF6600'>%1</t>", localize "STR_CACHE_ACTION_DESTROY"],
        {
            params ["_target", "_caller", "_actionId", "_arguments"];
            
            // Retirer l'action immédiatement
            _target removeAction _actionId;
            
            // Marquer comme en cours de destruction
            _target setVariable ["CACHE_isDestroying", true, true];
            
            // Animation du joueur (pose d'explosif)
            _caller playMove "Acts_carFixingWheel";
            
            // Attendre la fin de l'animation (environ 5 secondes)
            [_caller, _target] spawn {
                params ["_player", "_cache"];
                
                sleep 5;
                
                // Remettre le joueur debout
                _player switchMove "";
                
                // Notification à tous les joueurs
                [localize "STR_CACHE_EVACUATE"] remoteExec ["hint", 0];
                
                // Lancer le compte à rebours sur le serveur
                [_cache] remoteExec ["CACHE_fnc_startCountdown", 2];
            };
        },
        [],
        6,
        true,
        true,
        "",
        "_this distance player < 4",
        3
    ];
};

CACHE_fnc_startCountdown = {
    params ["_cacheObj"];
    
    if (!isServer) exitWith {};
    
    ["Compte à rebours 40 secondes démarré"] call CACHE_fnc_log;
    
    // Compte à rebours de 40 secondes
    sleep 40;
    
    if (!isNull _cacheObj && _cacheObj getVariable ["CACHE_isDestroying", false]) then {
        // Récupérer la position avant destruction
        private _pos = getPosATL _cacheObj;
        
        // Marquer comme inactif
        _cacheObj setVariable ["CACHE_isActive", false, true];
        
        // Créer une explosion visible (mais pas trop puissante)
        createVehicle ["SmallSecondary", _pos, [], 0, "CAN_COLLIDE"];
        
        // Ajouter un effet de feu
        private _fire = createVehicle ["test_EmptyObjectForFireBig", _pos, [], 0, "CAN_COLLIDE"];
        
        // Supprimer le feu après 30 secondes
        [_fire] spawn {
            params ["_f"];
            sleep 30;
            if (!isNull _f) then { deleteVehicle _f; };
        };
        
        // Supprimer la cache
        deleteVehicle _cacheObj;
        missionNamespace setVariable ["CACHE_currentCache", objNull, true];
        
        ["Cache détruite avec explosion!"] call CACHE_fnc_log;
    };
};

// ============================================================
// BOUCLE PRINCIPALE - RESPAWN DE MISSIONS
// ============================================================

while {true} do {
    
    // ============================================================
    // ATTENDRE AVANT LA PROCHAINE MISSION
    // ============================================================
    
    private _waitTime = 150 + floor(random 600); // 150 à 600 secondes aléatoire
    [format ["Prochaine mission cache d'armes dans %1 secondes (%2 min)", _waitTime, round(_waitTime/60)]] call CACHE_fnc_log;
    
    sleep _waitTime;
    
    _missionCounter = _missionCounter + 1;
    
    // ============================================================
    // SÉLECTION ALÉATOIRE DE LA POSITION
    // ============================================================
    
    private _positionIndex = floor (random 177);
    private _positionName = format ["task_bomb_position_%1", _positionIndex];
    private _positionObject = missionNamespace getVariable [_positionName, objNull];
    
    if (isNull _positionObject) then {
        [format ["Position %1 introuvable, réessai...", _positionName]] call CACHE_fnc_log;
        continue;
    };
    
    private _missionPos = getPos _positionObject;
    [format ["Mission #%1 à %2", _missionCounter, _positionName]] call CACHE_fnc_log;
    
    // ============================================================
    // CRÉATION DES OPFOR (1 à 3)
    // ============================================================
    
    private _opforCount = 1 + floor (random 3); // 1, 2 ou 3
    private _opforUnits = [];
    private _patrolRadius = 5 + random 10;
    
    for "_i" from 1 to _opforCount do {
        private _spawnPos = _missionPos getPos [random 10, random 360];
        private _terrainZ = getTerrainHeightASL _spawnPos;
        _spawnPos = [_spawnPos select 0, _spawnPos select 1, _terrainZ + 0.7];
        private _unit = [_spawnPos, _patrolRadius, _civilTemplates] call CACHE_fnc_createDisguisedOPFOR;
        _opforUnits pushBack _unit;
        sleep 0.2;
    };
    
    [format ["%1 OPFOR créés", _opforCount]] call CACHE_fnc_log;
    
    // ============================================================
    // CRÉATION DE LA CACHE D'ARMES
    // ============================================================
    
    // Utiliser une caisse d'armes comme cache
    private _cache = createVehicle ["Box_East_Wps_F", [0,0,0], [], 0, "CAN_COLLIDE"];
    
    // Positionner correctement au-dessus du terrain
    private _terrainZ = getTerrainHeightASL _missionPos;
    _cache setPosASL [_missionPos select 0, _missionPos select 1, _terrainZ + 0.7];
    
    _cache allowDamage false; // Indestructible par les armes
    
    _cache setVariable ["CACHE_isActive", true, true];
    _cache setVariable ["CACHE_isDestroying", false, true];
    
    missionNamespace setVariable ["CACHE_currentCache", _cache, true];
    
    ["Cache d'armes créée"] call CACHE_fnc_log;
    
    // ============================================================
    // ACTION DE DESTRUCTION SUR LA CACHE
    // ============================================================
    
    private _taskId = format ["task_cache_%1", _missionCounter];
    
    [_cache, _taskId] remoteExec ["CACHE_fnc_addDestroyAction", 0, true];
    
    // Appeler localement aussi (pour le serveur/hôte)
    [_cache, _taskId] call CACHE_fnc_addDestroyAction;
    
    // ============================================================
    // CRÉATION DU MARQUEUR
    // ============================================================
    
    private _markerName = format ["marker_cache_%1", _missionCounter];
    createMarker [_markerName, _missionPos];
    _markerName setMarkerType "hd_objective";
    _markerName setMarkerColor "ColorRed";
    _markerName setMarkerText localize "STR_CACHE_MARKER";
    
    // ============================================================
    // CRÉATION DE LA TÂCHE
    // ============================================================
    
    [
        true,
        [_taskId],
        [
            localize "STR_CACHE_TASK_DESC",
            localize "STR_CACHE_TASK_TITLE",
            _markerName
        ],
        _missionPos,
        "CREATED",
        1,
        true,
        "destroy",
        true
    ] call BIS_fnc_taskCreate;
    
    // ============================================================
    // SURVEILLANCE: ATTENTE DESTRUCTION CACHE
    // ============================================================
    
    waitUntil {
        sleep 2;
        isNull _cache || !(_cache getVariable ["CACHE_isActive", true])
    };
    
    // ============================================================
    // FIN DE MISSION
    // ============================================================
    
    if (_cache getVariable ["CACHE_isDestroying", false] || isNull _cache) then {
        ["Mission réussie - Cache détruite"] call CACHE_fnc_log;
        [_taskId, "SUCCEEDED"] call BIS_fnc_taskSetState;
        [localize "STR_CACHE_DESTROYED"] remoteExec ["hint", 0];
    } else {
        ["Mission échouée"] call CACHE_fnc_log;
        [_taskId, "FAILED"] call BIS_fnc_taskSetState;
        [localize "STR_CACHE_FAILED"] remoteExec ["hint", 0];
    };
    
    // Nettoyage
    deleteMarker _markerName;
    
    { if (alive _x) then { deleteVehicle _x }; } forEach _opforUnits;
    
    if (!isNull _cache) then { deleteVehicle _cache; };
    
    [format ["Mission #%1 terminée. Prochaine dans 200-1500s...", _missionCounter]] call CACHE_fnc_log;
};
