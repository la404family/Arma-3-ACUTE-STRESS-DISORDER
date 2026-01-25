/*
    fn_task_attentat.sqf
    
    Description:
    Mission "Attaque Terroriste" / "Attentat".
    - Se lance toutes les 150-750 secondes.
    - Choisit une position aléatoire (task_bomb_position_X).
    - 3-6 OPFOR (apparence civile + armes) spawnent.
    - Ils attaquent les civils environnants (via leurres BLUFOR invisibles).
    - Échec si 10 minutes passées et joueurs loin (>1200m).
    - Succès si tous les terroristes sont éliminés.
*/

if (!isServer) exitWith {};

// --- CONFIGURATION ---
private _debug = false;
private _missionCounter = 0;

// Fonctions internes
private _fnc_log = {
    params ["_msg"];
    diag_log format ["[ATTENTAT] %1", _msg];
    if (_debug) then { systemChat format ["[ATTENTAT] %1", _msg]; };
};

// Attente pour initialisation des objets éditeur
sleep 5;

// ============================================================
// RÉCUPÉRATION DES TEMPLATES CIVILS (GLOBAL)
// ============================================================
private _civilTemplates = MISSION_CivilianTemplates;

if (isNil "_civilTemplates" || {count _civilTemplates == 0}) then {
    ["ERREUR: Templates manquants. Fallback."] call _fnc_log;
    _civilTemplates = [["C_man_polo_1_F", [], "WhiteHead_01"]];
};

// --- BOUCLE PRINCIPALE ---
while {true} do {
    
    // 1. DÉLAI ALÉATOIRE
    private _waitTime = 150 + floor(random 600);
    [format ["Prochaine attaque dans %1 secondes", _waitTime]] call _fnc_log;
    sleep _waitTime;
    
    _missionCounter = _missionCounter + 1;
    
    // 2. CHOIX DE LA POSITION
    private _posIndex = floor (random 177);
    private _posName = format ["task_bomb_position_%1", _posIndex];
    private _posObj = missionNamespace getVariable [_posName, objNull];
    
    if (isNull _posObj) then {
        [format ["Position %1 invalide", _posName]] call _fnc_log;
        continue;
    };
    
    private _missionPos = getPos _posObj;
    
    // 3. SPAWN DES TERRORISTES (OPFOR déguisés)
    private _terroristCount = 3 + floor(random 4); // 3 à 6
    private _terrorists = [];
    private _grp = createGroup [east, true];
    
    for "_i" from 1 to _terroristCount do {
        private _spawnPos = _missionPos getPos [5 + random 10, random 360];
        _spawnPos set [2, 0.7]; // Force height 0.7
        private _unit = _grp createUnit ["O_G_Soldier_F", _spawnPos, [], 0, "CAN_COLLIDE"];
        
        // NETTOYAGE COMPLET (Robustesse: on retire tout équipement militaire d'abord)
        removeAllWeapons _unit;
        removeAllItems _unit;
        removeUniform _unit;
        removeVest _unit;
        removeBackpack _unit;
        removeHeadgear _unit;
        removeGoggles _unit;
        
        // Apparence civile (Template)
        private _template = selectRandom _civilTemplates;
        _template params ["_tType", "_tLoadout", "_tFace"];
        
        _unit setFace _tFace;
        
        if (count _tLoadout > 0) then {
            _unit setUnitLoadout _tLoadout;
        } else {
            _unit forceAddUniform "U_C_Poloshirt_blue";
        };
        
        // Armement (AKM)
        removeAllWeapons _unit;
        _unit addWeapon "arifle_AKM_F";
        _unit addPrimaryWeaponItem "30Rnd_762x39_Mag_F";
        for "_k" from 1 to 4 do { _unit addItem "30Rnd_762x39_Mag_F"; };
        
        // Compétences & IA
        _unit setSkill 0.4;
        _unit setUnitPos "UP"; // Force debout
        _unit setBehaviour "SAFE";
        _unit setSpeedMode "LIMITED";
        
        _terrorists pushBack _unit;
    };
    
    // Patrouille aléatoire (5-15m, plus fluide)
    [_grp, _missionPos] spawn {
        params ["_group", "_center"];
        while { ({alive _x} count units _group) > 0 } do {
            {
                if (alive _x && {behaviour _x == "SAFE"} && {unitReady _x}) then {  // Seulement si SAFE et prêt
                    _x doMove (_center getPos [5 + random 15, random 360]);
                };
            } forEach units _group;
            sleep 15;  // Cycle plus long pour fluidité
        };
    };
    
    [format ["Attaque #%1 lancée en %2 avec %3 terroristes", _missionCounter, _posName, _terroristCount]] call _fnc_log;
    
    // 4. CRÉATION TÂCHE ET MARQUEUR
    private _taskId = format ["task_attentat_%1", _missionCounter];
    private _markerName = format ["marker_attentat_%1", _missionCounter];
    
    createMarker [_markerName, _missionPos];
    _markerName setMarkerType "hd_warning";
    _markerName setMarkerColor "ColorRed";
    _markerName setMarkerText (localize "STR_TASK_ATTENTAT_TITLE");
    
    // Obtenir nom ville la plus proche pour la description
    private _nearestLoc = nearestLocation [_missionPos, "NameCity"];
    private _locName = if (isNull _nearestLoc) then { "Sefrou-Ramal" } else { text _nearestLoc };
    
    [
        true,
        [_taskId],
        [
            format [localize "STR_TASK_ATTENTAT_DESC", _locName],
            localize "STR_TASK_ATTENTAT_TITLE",
            _markerName
        ],
        _missionPos,
        "CREATED",
        1,
        true,
        "attack",
        true
    ] call BIS_fnc_taskCreate;
    
    [_taskId, "ASSIGNED"] call BIS_fnc_taskSetState;
    
    // 5. BOUCLE DE MISSION (SURVEILLANCE & ATTAQUE CIVILS)
    private _startTime = time;
    private _maxDuration = 600; // 10 minutes
    private _lastAttackTime = time;
    private _targets = []; // Victimes attaquées (pour cleanup variable)
    
    private _missionEnded = false;
    
    while {!_missionEnded} do {
        sleep 2;
        
        // A. Vérification conditions de fin
        private _aliveTerrorists = { alive _x } count _terrorists;
        
        // SUCCÈS: Tous les terroristes morts
        if (_aliveTerrorists == 0) exitWith {
            [_taskId, "SUCCEEDED"] call BIS_fnc_taskSetState;
            [localize "STR_TASK_ATTENTAT_SUCCESS"] remoteExec ["hint", 0];
            _missionEnded = true;
        };
        
        // ÉCHEC: Temps écoulé ET joueurs loin
        if (time - _startTime > _maxDuration) then {
            private _playersClose = { _x distance2D _missionPos < 1200 } count allPlayers;
            if (_playersClose == 0) then {
                [_taskId, "FAILED"] call BIS_fnc_taskSetState;
                [localize "STR_TASK_ATTENTAT_FAILED"] remoteExec ["hint", 0];
                _missionEnded = true;
            };
        };
        
        if (_missionEnded) exitWith {};
        
        // B. Attaque des civils (toutes les 45 secondes, forçage sur TOUS les terroristes vivants)
        if (time - _lastAttackTime > 45) then {
            _lastAttackTime = time;
            
            // Trouver tous les civils à proximité (agents ou units, non-armés, non-véhiculés)
            private _potentialVictims = (_missionPos nearEntities ["CAManBase", 150]) select { 
                alive _x && 
                {side _x == civilian} && 
                {!(_x in _terrorists)} &&
                {isNil {_x getVariable "ATTENTAT_Victim"}} &&  // Pas déjà attaqué récemment
                {primaryWeapon _x == ""} &&  // Non-armé (vrai civil)
                {isNull objectParent _x}  // Pas en véhicule
            };
            
            [format ["[ATTENTAT] Potentielles victimes trouvées: %1", count _potentialVictims]] call _fnc_log;
            
            if (count _potentialVictims > 0) then {
                private _aliveTerrorists = _terrorists select {alive _x};
                
                // Pour CHAQUE terroriste vivant, assigner une victime proche (si disponible)
                {
                    private _shooter = _x;
                    if (count _potentialVictims > 0) then {
                        // Trier par distance au shooter et prendre le plus proche
                        _potentialVictims = [_potentialVictims, [], {_shooter distance2D _x}, "ASCEND"] call BIS_fnc_sortBy;
                        private _victim = _potentialVictims deleteAt 0;  // Prend et retire pour éviter doublons
                        
                        if (!isNull _victim) then {
                            _victim setVariable ["ATTENTAT_Victim", true];
                            _targets pushBack _victim;
                            
                            [format ["[ATTENTAT] %1 attaque %2", name _shooter, name _victim]] call _fnc_log;
                            
                            // Spawn thread d'attaque par terroriste
                            [_shooter, _victim, _grp, _missionPos] spawn {
                                params ["_attacker", "_target", "_group", "_center"];
                                
                                if (!alive _attacker || !alive _target) exitWith {};
                                
                                // 1. Mode combat agressif
                                _attacker setBehaviour "COMBAT";
                                _attacker setSpeedMode "FULL";
                                _attacker setCombatMode "RED";  // Engage tout
                                _attacker reveal [_target, 4];  // Détection max
                                _attacker doTarget _target;
                                
                                // 2. Déplacement forcé vers cible
                                _attacker doMove (getPosATL _target);
                                
                                // Attendre proximité (20m, timeout 30s pour plus d'action)
                                private _timeout = time + 30;
                                waitUntil {
                                    sleep 0.5;
                                    !alive _attacker || !alive _target || _attacker distance2D _target < 20 || time > _timeout
                                };
                                
                                if (!alive _attacker || !alive _target) exitWith {
                                    // Reset groupe si avorté
                                    { if (alive _x) then { _x setBehaviour "SAFE"; _x setSpeedMode "LIMITED"; }; } forEach units _group;
                                };
                                
                                // 3. Tirs forcés répétés (rafales + boucle pour insister)
                                for "_burst" from 1 to 3 do {  // 3 rafales pour tuer
                                    if (!alive _attacker || !alive _target) exitWith {};
                                    _attacker lookAt _target;
                                    _attacker doFire _target;
                                    private _weapon = primaryWeapon _attacker;
                                    private _modes = getArray (configFile >> "CfgWeapons" >> _weapon >> "modes");
                                    private _mode = if (count _modes > 0) then { _modes #0 } else { "Single" };
                                    for "_shot" from 1 to (3 + floor random 3) do {
                                        if (!alive _attacker || !alive _target) exitWith {};
                                        _attacker forceWeaponFire [_weapon, _mode];
                                        sleep 0.15;
                                    };
                                    sleep 1;  // Pause entre rafales
                                };
                                
                                // 4. Attendre mort ou timeout (insister si vivant)
                                private _deathTimeout = time + 10;
                                waitUntil { sleep 0.5; !alive _target || time > _deathTimeout };
                                if (alive _target && alive _attacker) then {
                                    _attacker doFire _target;  // Tir final
                                    sleep 2;
                                };
                                
                                // 5. Retour forcé à patrouille près du spawn
                                sleep 2;
                                if (alive _attacker) then {
                                    _attacker setBehaviour "SAFE";
                                    _attacker setSpeedMode "LIMITED";
                                    _attacker setCombatMode "GREEN";  // Hold fire
                                    _attacker doMove (_center getPos [5 + random 10, random 360]);  // Retour proche spawn
                                };
                                
                                // Reset variable victime
                                if (!isNull _target) then { _target setVariable ["ATTENTAT_Victim", nil]; };
                            };
                        };
                    };
                } forEach _aliveTerrorists;
            };
        };
    };
    
    // 6. NETTOYAGE FIN DE MISSION
    sleep 10;
    deleteMarker _markerName;
    
    // Cleanup decoys + reset (plus de decoys, juste reset variables)
    { 
        if (!isNull _x && alive _x) then { _x setVariable ["ATTENTAT_Victim", nil]; }; 
    } forEach _targets;
    
    if ("FAILED" == ([_taskId] call BIS_fnc_taskState)) then {
        { if (!isNull _x) then { deleteVehicle _x; }; } forEach _terrorists;
    };
    
    // La boucle continue pour la prochaine mission
};
