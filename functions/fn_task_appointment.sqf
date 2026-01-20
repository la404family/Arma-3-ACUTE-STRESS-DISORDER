/*
    fn_task_appointment.sqf
    
    Description:
    Mission de rendez-vous avec un chef de milices local.
    - Le chef vend des informations sur l'emplacement de 5 mines
    - Utilise des unités INDÉPENDANTES pour éviter le système de nettoyage (fn_nettoyage)
    - 3 scénarios possibles: Succès, Trahison directe, Trahison interne
    - Système de conversion de side pour les trahisons scénarisées
    
    Spawns: milice_0 à milice_6 (héliports invisibles)
    Délai: 5 secondes après le début de la mission
    Limite de temps: 5-15 minutes aléatoire
    
    Optimisé pour le multijoueur.
*/

// Exécution uniquement sur le serveur
if (!isServer) exitWith {};

// ============================================================
// CONFIGURATION
// ============================================================

APPOINTMENT_Debug = false;

APPOINTMENT_fnc_log = {
    params ["_msg"];
    diag_log format ["[APPOINTMENT] %1", _msg];
    if (APPOINTMENT_Debug) then { systemChat format ["[APPOINTMENT] %1", _msg]; };
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
    ["AVERTISSEMENT: Aucun template civil trouvé, utilisation du fallback"] call APPOINTMENT_fnc_log;
    _civilTemplates pushBack ["C_man_polo_1_F", [], "WhiteHead_01"];
};

[format ["Templates civils collectés: %1", count _civilTemplates]] call APPOINTMENT_fnc_log;

// ============================================================
// FONCTION: CRÉER UNE UNITÉ MILICE (INDÉPENDANTE, TENUE CIVILE, ARMÉE)
// ============================================================

APPOINTMENT_fnc_createMilitia = {
    params ["_pos", "_templates", ["_isChief", false]];
    
    // Sélectionner un template aléatoire
    private _template = selectRandom _templates;
    _template params ["_type", "_loadout", "_face"];
    
    // Créer le groupe INDÉPENDANT (pour éviter fn_nettoyage qui cible EAST)
    private _grp = createGroup [independent, true];
    private _unit = _grp createUnit ["I_G_Soldier_F", [0,0,0], [], 0, "NONE"];
    
    // Positionner au-dessus du terrain (0.7m) pour éviter les bugs
    private _terrainZ = getTerrainHeightASL _pos;
    private _safePos = [_pos select 0, _pos select 1, _terrainZ + 0.7];
    _unit setPosASL _safePos;
    
    // Appliquer l'apparence civile
    _unit setFace _face;
    if (count _loadout > 0) then {
        _unit setUnitLoadout _loadout;
    };
    
    // Retirer tout l'équipement militaire et ajouter arme civile
    removeAllWeapons _unit;
    removeBackpack _unit;
    removeHeadgear _unit;
    removeVest _unit;
    
    // Ajouter une arme (AKM ou pistolet selon chef ou non)
    if (_isChief) then {
        _unit addWeapon "hgun_Pistol_heavy_01_F";
        _unit addHandgunItem "11Rnd_45ACP_Mag";
        for "_i" from 1 to 2 do { _unit addItem "11Rnd_45ACP_Mag"; };
    } else {
        _unit addWeapon "arifle_AKM_F";
        _unit addPrimaryWeaponItem "30Rnd_762x39_Mag_F";
        for "_i" from 1 to 3 do { _unit addItem "30Rnd_762x39_Mag_F"; };
    };
    
    // Comportement initial
    _unit setCombatMode "WHITE";
    _unit setBehaviour "SAFE";
    _unit setSkill 0.5;
    
    // Variable pour identifier l'unité comme milice
    _unit setVariable ["APPOINTMENT_isMilitia", true, true];
    
    _unit
};

// ============================================================
// COMPTEUR DE MISSIONS POUR ID UNIQUE
// ============================================================

private _missionCounter = 0;

// ============================================================
// ATTENDRE 5 SECONDES AVANT DE LANCER LA PREMIÈRE MISSION
// ============================================================

private _initialDelay = 150 + floor(random 1350); // 150 à 1500 secondes aléatoire
[format ["Attente de %1 secondes (%2 min) avant le lancement de la mission RDV milices...", _initialDelay, round(_initialDelay / 60)]] call APPOINTMENT_fnc_log;
sleep _initialDelay;

// ============================================================
// BOUCLE PRINCIPALE - RESPAWN DE MISSIONS
// ============================================================

while {true} do {
    
    _missionCounter = _missionCounter + 1;
    ["Démarrage de la mission RDV milices #%1", _missionCounter] call APPOINTMENT_fnc_log;
    
    // ============================================================
    // SÉLECTION ALÉATOIRE DE LA POSITION (milice_0 à milice_6)
    // ============================================================
    
    private _positionIndex = floor (random 7);
    private _positionName = format ["milice_%1", _positionIndex];
    private _positionObject = missionNamespace getVariable [_positionName, objNull];
    
    if (isNull _positionObject) then {
        [format ["Position %1 introuvable, réessai...", _positionName]] call APPOINTMENT_fnc_log;
        sleep 60;
        continue;
    };
    
    private _missionPos = getPos _positionObject;
    [format ["Mission #%1 à %2 (pos: %3)", _missionCounter, _positionName, _missionPos]] call APPOINTMENT_fnc_log;
    
    // ============================================================
    // CRÉATION DU CHEF DE MILICES (IMMOBILE)
    // ============================================================
    
    private _chief = [_missionPos, _civilTemplates, true] call APPOINTMENT_fnc_createMilitia;
    
    // Chef immobile - flâne sur place
    _chief disableAI "MOVE";
    _chief setUnitPos "UP";
    _chief switchMove "Acts_CivilTalking_1";
    
    _chief setVariable ["APPOINTMENT_isChief", true, true];
    
    ["Chef de milices créé"] call APPOINTMENT_fnc_log;
    
    // ============================================================
    // CRÉATION DES HOMMES DE MILICES (2 à 4)
    // ============================================================
    
    private _militiaCount = 2 + floor (random 3); // 2 à 4
    private _militiaUnits = [_chief]; // Inclure le chef dans la liste
    
    for "_i" from 1 to _militiaCount do {
        private _spawnPos = _missionPos getPos [5 + random 15, random 360];
        private _unit = [_spawnPos, _civilTemplates, false] call APPOINTMENT_fnc_createMilitia;
        
        // Comportement flânerie (waypoints aléatoires)
        [_unit, _missionPos] spawn {
            params ["_u", "_center"];
            
            _u setSpeedMode "LIMITED";
            
            while {alive _u && !(_u getVariable ["APPOINTMENT_combatMode", false])} do {
                private _movePos = _center getPos [5 + random 20, random 360];
                _u doMove _movePos;
                sleep (15 + random 25);
            };
        };
        
        _militiaUnits pushBack _unit;
        sleep 0.3;
    };
    
    [format ["%1 miliciens créés (+ 1 chef)", _militiaCount]] call APPOINTMENT_fnc_log;
    
    // ============================================================
    // VARIABLES DE MISSION
    // ============================================================
    
    private _taskId = format ["task_appointment_%1", _missionCounter];
    private _markerName = format ["marker_appointment_%1", _missionCounter];
    private _timeLimit = 300 + floor(random 600); // 5 à 15 minutes en secondes
    private _missionStartTime = time;
    private _missionCompleted = false;
    private _missionFailed = false;
    private _scenarioTriggered = false;
    private _chiefAlive = true;
    private _actionId = -1;
    
    // Variable globale pour accès depuis addAction
    missionNamespace setVariable ["APPOINTMENT_currentChief", _chief, true];
    missionNamespace setVariable ["APPOINTMENT_currentMilitia", _militiaUnits, true];
    missionNamespace setVariable ["APPOINTMENT_missionPos", _missionPos, true];
    missionNamespace setVariable ["APPOINTMENT_taskId", _taskId, true];
    missionNamespace setVariable ["APPOINTMENT_scenarioTriggered", false, true];
    missionNamespace setVariable ["APPOINTMENT_missionCompleted", false, true];
    missionNamespace setVariable ["APPOINTMENT_missionFailed", false, true];
    missionNamespace setVariable ["APPOINTMENT_chiefMustSurvive", false, true];
    missionNamespace setVariable ["APPOINTMENT_allMilitiaKilled", false, true];
    
    // ============================================================
    // CRÉATION DU MARQUEUR
    // ============================================================
    
    createMarker [_markerName, _missionPos];
    _markerName setMarkerType "hd_unknown";
    _markerName setMarkerColor "ColorYellow";
    _markerName setMarkerText localize "STR_APPOINTMENT_MARKER";
    
    // ============================================================
    // CRÉATION DE LA TÂCHE
    // ============================================================
    
    [
        true,
        [_taskId],
        [
            localize "STR_APPOINTMENT_TASK_DESC",
            localize "STR_APPOINTMENT_TASK_TITLE",
            _markerName
        ],
        _missionPos,
        "CREATED",
        1,
        true,
        "meet",
        true
    ] call BIS_fnc_taskCreate;
    
    // ============================================================
    // FONCTION: RÉVÉLER LES 5 MINES SUR LA CARTE
    // ============================================================
    
    APPOINTMENT_fnc_revealMines = {
        ["Révélation des 5 emplacements de mines..."] call APPOINTMENT_fnc_log;
        
        private _mineMarkers = [];
        private _minePositions = [];
        
        // Collecter toutes les positions de mines disponibles
        for "_i" from 0 to 13 do {
            private _mineName = format ["mine_%1", if (_i < 10) then { "0" + str _i } else { str _i }];
            private _minePos = getMarkerPos _mineName;
            if (_minePos select 0 != 0 || _minePos select 1 != 0) then {
                _minePositions pushBack _minePos;
            };
        };
        
        // Sélectionner 5 positions aléatoires (ou moins si pas assez)
        private _selectedMines = [];
        private _count = (count _minePositions) min 5;
        
        for "_i" from 0 to (_count - 1) do {
            if (count _minePositions > 0) then {
                private _randIndex = floor (random (count _minePositions));
                _selectedMines pushBack (_minePositions select _randIndex);
                _minePositions deleteAt _randIndex;
            };
        };
        
        // Créer les marqueurs "X" pour les mines révélées
        {
            private _mineMarkerName = format ["revealed_mine_%1_%2", time, _forEachIndex];
            createMarker [_mineMarkerName, _x];
            _mineMarkerName setMarkerType "hd_destroy";
            _mineMarkerName setMarkerColor "ColorRed";
            _mineMarkerName setMarkerText format [localize "STR_APPOINTMENT_MINE_MARKER", _forEachIndex + 1];
            _mineMarkers pushBack _mineMarkerName;
        } forEach _selectedMines;
        
        [format ["%1 emplacements de mines révélés", count _selectedMines]] call APPOINTMENT_fnc_log;
        
        _mineMarkers
    };
    
    // ============================================================
    // FONCTION: CONVERTIR SIDE (POUR TRAHISONS)
    // ============================================================
    
    APPOINTMENT_fnc_convertSide = {
        params ["_unit", "_newSide"];
        
        if (!alive _unit) exitWith {};
        
        private _pos = getPosASL _unit;
        private _dir = getDir _unit;
        private _loadout = getUnitLoadout _unit;
        private _face = face _unit;
        private _damage = damage _unit;
        private _isChief = _unit getVariable ["APPOINTMENT_isChief", false];
        
        // Créer nouveau groupe
        private _grp = createGroup [_newSide, true];
        
        // Déterminer le type d'unité selon la faction
        private _unitType = switch (_newSide) do {
            case east: { "O_G_Soldier_F" };
            case west: { "B_Soldier_F" };
            default { "I_G_Soldier_F" };
        };
        
        private _newUnit = _grp createUnit [_unitType, [0,0,0], [], 0, "NONE"];
        _newUnit setPosASL _pos;
        _newUnit setDir _dir;
        _newUnit setFace _face;
        _newUnit setUnitLoadout _loadout;
        _newUnit setDamage _damage;
        
        // Comportement combat
        _newUnit setCombatMode "RED";
        _newUnit setBehaviour "COMBAT";
        _newUnit setVariable ["APPOINTMENT_combatMode", true, true];
        _newUnit setVariable ["APPOINTMENT_isMilitia", true, true];
        
        if (_isChief) then {
            _newUnit setVariable ["APPOINTMENT_isChief", true, true];
            missionNamespace setVariable ["APPOINTMENT_currentChief", _newUnit, true];
        };
        
        // Supprimer ancienne unité
        deleteVehicle _unit;
        
        _newUnit
    };
    
    // ============================================================
    // ACTION: PARLER AVEC LE CHEF (addAction sur tous les clients)
    // ============================================================
    
    // Définir la fonction d'action si pas déjà définie
    if (isNil "APPOINTMENT_fnc_addTalkAction") then {
        APPOINTMENT_fnc_addTalkAction = {
            params ["_chief", "_taskId"];
            
            if (!hasInterface) exitWith {};
            if (isNull _chief) exitWith {};
            
            private _actionId = _chief addAction [
                localize "STR_APPOINTMENT_ACTION_TALK",
                {
                    params ["_target", "_caller", "_actionId", "_arguments"];
                    
                    // Retirer l'action immédiatement
                    _target removeAction _actionId;
                    
                    // Empêcher déclenchement multiple
                    if (missionNamespace getVariable ["APPOINTMENT_scenarioTriggered", false]) exitWith {};
                    missionNamespace setVariable ["APPOINTMENT_scenarioTriggered", true, true];
                    
                    // Sélectionner un scénario aléatoire (1 = Succès, 2 = Trahison directe, 3 = Trahison interne)
                    private _scenario = 1 + floor (random 3);
                    
                    [format ["Scénario sélectionné: %1", _scenario]] remoteExec ["APPOINTMENT_fnc_log", 2];
                    
                    // Exécuter le scénario côté serveur
                    [_scenario, _target, _caller] remoteExec ["APPOINTMENT_fnc_executeScenario", 2];
                },
                [],
                6,
                true,
                true,
                "",
                "alive _target && _this distance _target < 5 && !(missionNamespace getVariable ['APPOINTMENT_scenarioTriggered', false])"
            ];
            
            _actionId
        };
    };
    
    // Exécuter sur tous les clients
    [_chief, _taskId] remoteExec ["APPOINTMENT_fnc_addTalkAction", 0, true];
    
    // ============================================================
    // FONCTION: EXÉCUTER LE SCÉNARIO (côté serveur)
    // ============================================================
    
    if (isNil "APPOINTMENT_fnc_executeScenario") then {
        APPOINTMENT_fnc_executeScenario = {
            params ["_scenario", "_chief", "_player"];
            
            private _militia = missionNamespace getVariable ["APPOINTMENT_currentMilitia", []];
            private _taskId = missionNamespace getVariable ["APPOINTMENT_taskId", ""];
            
            switch (_scenario) do {
                
                // ============================================================
                // CAS A: SUCCÈS STANDARD
                // ============================================================
                case 1: {
                    ["CAS A: Succès - Le chef donne l'information"] call APPOINTMENT_fnc_log;
                    
                    // Notification
                    [localize "STR_APPOINTMENT_SUCCESS_INFO"] remoteExec ["hint", 0];
                    
                    // Révéler les mines
                    [] call APPOINTMENT_fnc_revealMines;
                    
                    // Tâche réussie
                    [_taskId, "SUCCEEDED"] call BIS_fnc_taskSetState;
                    missionNamespace setVariable ["APPOINTMENT_missionCompleted", true, true];
                    
                    [localize "STR_APPOINTMENT_TASK_SUCCESS"] remoteExec ["hint", 0];
                };
                
                // ============================================================
                // CAS B: TRAHISON DIRECTE
                // ============================================================
                case 2: {
                    ["CAS B: Trahison directe - Milices attaquent"] call APPOINTMENT_fnc_log;
                    
                    // Notification
                    [localize "STR_APPOINTMENT_BETRAYAL_DIRECT"] remoteExec ["hint", 0];
                    
                    // Convertir toutes les milices en OPFOR
                    private _newMilitia = [];
                    {
                        if (alive _x) then {
                            private _newUnit = [_x, east] call APPOINTMENT_fnc_convertSide;
                            _newMilitia pushBack _newUnit;
                            
                            // Cibler les joueurs
                            {
                                if (isPlayer _x && alive _x) then {
                                    _newUnit doTarget _x;
                                    _newUnit doFire _x;
                                };
                            } forEach allPlayers;
                        };
                    } forEach _militia;
                    
                    missionNamespace setVariable ["APPOINTMENT_currentMilitia", _newMilitia, true];
                    missionNamespace setVariable ["APPOINTMENT_chiefMustSurvive", false, true];
                    
                    // Surveiller si toutes les milices sont mortes
                    [] spawn {
                        waitUntil {
                            sleep 2;
                            private _militia = missionNamespace getVariable ["APPOINTMENT_currentMilitia", []];
                            private _allDead = true;
                            {
                                if (alive _x) exitWith { _allDead = false; };
                            } forEach _militia;
                            _allDead
                        };
                        
                        // Toutes les milices mortes = Succès
                        missionNamespace setVariable ["APPOINTMENT_allMilitiaKilled", true, true];
                        missionNamespace setVariable ["APPOINTMENT_missionCompleted", true, true];
                        
                        private _taskId = missionNamespace getVariable ["APPOINTMENT_taskId", ""];
                        [_taskId, "SUCCEEDED"] call BIS_fnc_taskSetState;
                        [localize "STR_APPOINTMENT_MILITIA_ELIMINATED"] remoteExec ["hint", 0];
                    };
                };
                
                // ============================================================
                // CAS C: TRAHISON INTERNE
                // ============================================================
                case 3: {
                    ["CAS C: Trahison interne - Le chef est trahi"] call APPOINTMENT_fnc_log;
                    
                    // Notification
                    [localize "STR_APPOINTMENT_BETRAYAL_INTERNAL"] remoteExec ["hint", 0];
                    
                    // Révéler les mines d'abord
                    [] call APPOINTMENT_fnc_revealMines;
                    
                    // Convertir le chef en BLUFOR
                    private _newChief = [_chief, west] call APPOINTMENT_fnc_convertSide;
                    missionNamespace setVariable ["APPOINTMENT_currentChief", _newChief, true];
                    
                    // Convertir les autres miliciens en OPFOR
                    private _newMilitia = [_newChief];
                    {
                        if (alive _x && !(_x getVariable ["APPOINTMENT_isChief", false])) then {
                            private _newUnit = [_x, east] call APPOINTMENT_fnc_convertSide;
                            _newMilitia pushBack _newUnit;
                            
                            // Cibler le chef et les joueurs
                            _newUnit doTarget _newChief;
                            _newUnit doFire _newChief;
                        };
                    } forEach (_militia select {!(_x getVariable ["APPOINTMENT_isChief", false])});
                    
                    missionNamespace setVariable ["APPOINTMENT_currentMilitia", _newMilitia, true];
                    missionNamespace setVariable ["APPOINTMENT_chiefMustSurvive", true, true];
                    
                    // Surveiller le chef et les miliciens hostiles
                    [] spawn {
                        waitUntil {
                            sleep 2;
                            private _chief = missionNamespace getVariable ["APPOINTMENT_currentChief", objNull];
                            private _militia = missionNamespace getVariable ["APPOINTMENT_currentMilitia", []];
                            
                            // Vérifier si le chef est mort
                            if (!alive _chief) exitWith {
                                // ÉCHEC - Chef mort
                                missionNamespace setVariable ["APPOINTMENT_missionFailed", true, true];
                                private _taskId = missionNamespace getVariable ["APPOINTMENT_taskId", ""];
                                [_taskId, "FAILED"] call BIS_fnc_taskSetState;
                                [localize "STR_APPOINTMENT_CHIEF_DEAD"] remoteExec ["hint", 0];
                                true
                            };
                            
                            // Vérifier si tous les miliciens hostiles sont morts
                            private _allHostileDead = true;
                            {
                                if (alive _x && side _x == east) exitWith { _allHostileDead = false; };
                            } forEach _militia;
                            
                            if (_allHostileDead && alive _chief) exitWith {
                                // SUCCÈS - Chef en vie, hostiles éliminés
                                missionNamespace setVariable ["APPOINTMENT_missionCompleted", true, true];
                                private _taskId = missionNamespace getVariable ["APPOINTMENT_taskId", ""];
                                [_taskId, "SUCCEEDED"] call BIS_fnc_taskSetState;
                                [localize "STR_APPOINTMENT_CHIEF_SAVED"] remoteExec ["hint", 0];
                                true
                            };
                            
                            false
                        };
                    };
                };
            };
        };
    };
    
    // ============================================================
    // SURVEILLANCE: TEMPS, DISTANCE, COMPLÉTION
    // ============================================================
    
    private _timeExpired = false;
    
    while {!_missionCompleted && !_missionFailed && alive _chief} do {
        sleep 3;
        
        // Récupérer les variables globales mises à jour
        _missionCompleted = missionNamespace getVariable ["APPOINTMENT_missionCompleted", false];
        _missionFailed = missionNamespace getVariable ["APPOINTMENT_missionFailed", false];
        _chief = missionNamespace getVariable ["APPOINTMENT_currentChief", _chief];
        
        if (_missionCompleted || _missionFailed) exitWith {};
        
        // Vérifier le temps
        private _elapsedTime = time - _missionStartTime;
        
        if (_elapsedTime > _timeLimit && !_timeExpired) then {
            _timeExpired = true;
            ["Temps expiré - Vérification de la distance..."] call APPOINTMENT_fnc_log;
        };
        
        if (_timeExpired && !(missionNamespace getVariable ["APPOINTMENT_scenarioTriggered", false])) then {
            // Vérifier la distance du joueur le plus proche
            private _closestDist = 99999;
            {
                private _d = _x distance _missionPos;
                if (_d < _closestDist) then { _closestDist = _d; };
            } forEach allPlayers;
            
            if (_closestDist > 1200) then {
                // Joueur trop loin - ÉCHEC
                _missionFailed = true;
                missionNamespace setVariable ["APPOINTMENT_missionFailed", true, true];
                [_taskId, "FAILED"] call BIS_fnc_taskSetState;
                [localize "STR_APPOINTMENT_TIMEOUT"] remoteExec ["hint", 0];
                ["Mission échouée - Temps expiré et joueur trop loin"] call APPOINTMENT_fnc_log;
            };
            // Sinon on attend que le joueur s'éloigne ou complète le RDV
        };
        
        // Vérifier si le chef doit survivre (Cas C) et est mort
        if (missionNamespace getVariable ["APPOINTMENT_chiefMustSurvive", false]) then {
            if (!alive _chief) then {
                _missionFailed = true;
                missionNamespace setVariable ["APPOINTMENT_missionFailed", true, true];
            };
        };
    };
    
    // ============================================================
    // NETTOYAGE POST-MISSION
    // ============================================================
    
    // Attendre éloignement des joueurs pour nettoyage (TOUJOURS, succès OU échec)
    ["Mission terminée - Attente éloignement joueurs (>1200m) pour nettoyage..."] call APPOINTMENT_fnc_log;
    
    waitUntil {
        sleep 10;
        private _closestDist = 99999;
        {
            private _d = _x distance _missionPos;
            if (_d < _closestDist) then { _closestDist = _d; };
        } forEach allPlayers;
        
        _closestDist > 1200
    };
    
    ["Joueurs éloignés (>1200m) - Nettoyage des unités..."] call APPOINTMENT_fnc_log;
    
    // Supprimer le marqueur
    deleteMarker _markerName;
    
    // Supprimer les milices
    private _finalMilitia = missionNamespace getVariable ["APPOINTMENT_currentMilitia", _militiaUnits];
    {
        if (!isNull _x) then {
            private _grp = group _x;
            deleteVehicle _x;
            if (!isNull _grp && count units _grp == 0) then { deleteGroup _grp; };
        };
    } forEach _finalMilitia;
    
    [format ["Mission #%1 nettoyée. Prochaine dans 200-1500s...", _missionCounter]] call APPOINTMENT_fnc_log;
    
    // Réinitialiser les variables
    missionNamespace setVariable ["APPOINTMENT_currentChief", objNull, true];
    missionNamespace setVariable ["APPOINTMENT_currentMilitia", [], true];
    missionNamespace setVariable ["APPOINTMENT_scenarioTriggered", false, true];
    missionNamespace setVariable ["APPOINTMENT_missionCompleted", false, true];
    missionNamespace setVariable ["APPOINTMENT_missionFailed", false, true];
    missionNamespace setVariable ["APPOINTMENT_chiefMustSurvive", false, true];
    missionNamespace setVariable ["APPOINTMENT_allMilitiaKilled", false, true];
    
    // Attendre avant la prochaine mission
    private _nextMissionDelay = 200 + floor(random 1300);
    [format ["Prochaine mission dans %1 secondes (%2 minutes)", _nextMissionDelay, round(_nextMissionDelay / 60)]] call APPOINTMENT_fnc_log;
    sleep _nextMissionDelay;
};
