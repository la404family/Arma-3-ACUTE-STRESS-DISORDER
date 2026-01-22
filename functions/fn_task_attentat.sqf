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
        _unit setBehaviour "SAFE";
        _unit setSpeedMode "LIMITED";
        
        _terrorists pushBack _unit;
    };
    
    // Patrouille aléatoire (5-15m)
    [_grp, _missionPos] spawn {
        params ["_group", "_center"];
        while { ({alive _x} count units _group) > 0 } do {
            {
                if (unitReady _x && alive _x) then {
                    _x doMove (_center getPos [5 + random 10, random 360]);
                };
            } forEach units _group;
            sleep 10;
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
    private _targets = []; // Liste des leurres invisibles
    
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
        
        // B. Attaque des civils (toutes les 35 secondes)
        if (time - _lastAttackTime > 35) then {
            _lastAttackTime = time;
            
            // Trouver un civil proche des terroristes
            private _potentialVictims = _missionPos nearEntities ["Civilian", 100];
            // Filtrer: Vivant, pas un otage, pas un des terroristes (si side fail)
            _potentialVictims = _potentialVictims select { 
                alive _x && 
                !(_x in _terrorists) && 
                isNil {_x getVariable "ATTENTAT_Target"} 
            };
            
            if (count _potentialVictims > 0) then {
                private _victim = selectRandom _potentialVictims;
                
                // Créer cible BLUFOR invisible attachée au civil
                private _target = createVehicle ["B_Soldier_F", [0,0,0], [], 0, "NONE"]; // Soldier basique
                _target hideObjectGlobal true;
                _target allowDamage false; // Invincible pour durer un peu, mais capte l'aggro
                _target attachTo [_victim, [0,0,1]]; // Attaché au torse/tête
                
                _victim setVariable ["ATTENTAT_Target", _target];
                _targets pushBack _target; // Stocker pour suppression
                
                // Forcer les terroristes à engager cette cible
                _grp reveal [_target, 4];
                {
                    if (alive _x) then {
                        _x doTarget _target;
                        _x doFire _target;
                        _x setBehaviour "COMBAT";
                    };
                } forEach _terrorists;
                
                [format ["Attaque lancée sur civil %1", name _victim]] call _fnc_log;
                
                // Gestion de la vie de la cible invisible
                [_target, _victim, _terrorists] spawn {
                    params ["_t", "_v", "_terrorGroup"];
                    
                    // Attendre que : le civil soit mort OU plus aucun terroriste en vie
                    waitUntil {
                        sleep 1;
                        !alive _v || { {alive _x} count _terrorGroup == 0 }
                    };
                    
                    // Supprimer la cible
                    deleteVehicle _t;
                    if (!isNull _v) then { _v setVariable ["ATTENTAT_Target", nil]; };
                };
            };
        };
    };
    
    // 6. NETTOYAGE FIN DE MISSION
    sleep 10;
    deleteMarker _markerName;
    { if (!isNull _x) then { deleteVehicle _x }; } forEach _targets; // Supprimer leurres restants
    
    // Si échec (joueurs loin), supprimer les terroristes pour économiser ressources
    if ("FAILED" == ([_taskId] call BIS_fnc_taskState)) then {
        { deleteVehicle _x } forEach _terrorists;
    };
    
    // La boucle continue pour la prochaine mission
};
