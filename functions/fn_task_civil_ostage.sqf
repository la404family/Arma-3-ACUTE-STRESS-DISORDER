/*
    fn_task_civil_ostage.sqf
    
    Description:
    Mission de sauvetage d'otage civil en boucle.
    - 3 à 5 OPFOR déguisés en civils (sac + AKM) patrouillent autour d'une position
    - Un otage civil attend d'être libéré
    - Après libération, l'otage suit le joueur le plus proche
    - Un hélicoptère Huron extrait l'otage vers l'héliport le plus proche
    
    Après extraction réussie, une nouvelle mission démarre après 200-1500 secondes.
    
    Utilise les templates des civils civil_00 à civil_41 (comme fn_civilian_logique).
    Logique de suivi et d'embarquement inspirée de fn_task_4_launch.
    
    Optimisé pour le multijoueur.
*/

// Exécution uniquement sur le serveur
if (!isServer) exitWith {};

// ============================================================
// CONFIGURATION
// ============================================================

HOSTAGE_Debug = false;

HOSTAGE_fnc_log = {
    params ["_msg"];
    diag_log format ["[HOSTAGE] %1", _msg];
    if (HOSTAGE_Debug) then { systemChat format ["[HOSTAGE] %1", _msg]; };
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
    ["AVERTISSEMENT: Aucun template civil trouvé, utilisation du fallback"] call HOSTAGE_fnc_log;
    _civilTemplates pushBack ["C_man_polo_1_F", [], "WhiteHead_01"];
};

[format ["Templates civils collectés: %1", count _civilTemplates]] call HOSTAGE_fnc_log;

// ============================================================
// RÉCUPÉRATION DES TEMPLATES CIVILS (GLOBAL)
// ============================================================
private _civilTemplates = MISSION_CivilianTemplates;

if (isNil "_civilTemplates" || {count _civilTemplates == 0}) then {
    ["ERREUR: Templates manquants. Fallback."] call HOSTAGE_fnc_log;
    _civilTemplates = [["C_man_polo_1_F", [], "WhiteHead_01"]];
};

[format ["Templates civils collectés: %1", count _civilTemplates]] call HOSTAGE_fnc_log;

// ============================================================
// FONCTION: CRÉER UN OPFOR DÉGUISÉ EN CIVIL
// ============================================================

HOSTAGE_fnc_createDisguisedOPFOR = {
    params ["_pos", "_patrolRadius", "_templates"];
    
    private _template = selectRandom _templates;
    _template params ["_type", "_loadout", "_face"];
    
    // Créer le groupe OPFOR
    private _grp = createGroup [east, true];
    private _unit = _grp createUnit ["O_G_Soldier_F", [0,0,0], [], 0, "NONE"];
    _unit setPosASL _pos; // Utiliser la position ASL passée en paramètre
    
    // Appliquer l'apparence civile
    _unit setFace _face;
    
    // NETTOYAGE D'ABORD
    removeAllWeapons _unit;
    removeAllItems _unit;
    removeUniform _unit;
    removeVest _unit;
    removeBackpack _unit;
    removeHeadgear _unit;
    removeGoggles _unit;
    
    // CHARGEMENT TENUE
    if (count _loadout > 0) then {
        _unit setUnitLoadout _loadout;
    };
    
    // Retirer tout l'équipement d'armes et ajouter le sac + AKM
    removeAllWeapons _unit;
    removeBackpack _unit; // Au cas où le loadout en avait un
    
    _unit addBackpack "B_Messenger_Coyote_F";
    _unit addWeapon "arifle_AKM_F";
    _unit addPrimaryWeaponItem "30Rnd_762x39_Mag_F";
    
    for "_i" from 1 to 4 do {
        _unit addItemToBackpack "30Rnd_762x39_Mag_F";
    };
    
    _unit linkItem "ItemMap";
    _unit linkItem "ItemRadio";
    
    // Comportement
    _unit setCombatMode "YELLOW";
    _unit setBehaviour "SAFE";
    _unit setSkill 0.5;
    
    // Patrouille autour de la position
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
// BOUCLE PRINCIPALE - RESPAWN DE MISSIONS
// ============================================================

while {true} do {
    
    // ============================================================
    // ATTENDRE AVANT LA PROCHAINE MISSION
    // ============================================================
    
    private _waitTime = 150 + floor(random 600); // 150 à 600 secondes aléatoire
    [format ["Prochaine mission otage dans %1 secondes (%2 minutes)", _waitTime, round(_waitTime / 60)]] call HOSTAGE_fnc_log;
    
    sleep _waitTime;
    
    _missionCounter = _missionCounter + 1;
    
    // ============================================================
    // SÉLECTION ALÉATOIRE DE LA POSITION
    // ============================================================
    
    private _positionIndex = floor (random 177);
    private _positionName = format ["task_bomb_position_%1", _positionIndex];
    private _positionObject = missionNamespace getVariable [_positionName, objNull];
    
    if (isNull _positionObject) then {
        [format ["Position %1 introuvable, réessai...", _positionName]] call HOSTAGE_fnc_log;
        continue;
    };
    
    private _missionPos = getPos _positionObject;
    [format ["Mission #%1 à %2", _missionCounter, _positionName]] call HOSTAGE_fnc_log;
    
    // ============================================================
    // CRÉATION DE L'OTAGE EN PREMIER (invincible!)
    // ============================================================
    
    private _template = selectRandom _civilTemplates;
    _template params ["_civType", "_civLoadout", "_civFace"];
    
    private _grpCiv = createGroup [civilian, true];
    
    // Calculer la position au-dessus du terrain
    private _terrainZ = getTerrainHeightASL _missionPos;
    private _safeHostagePos = [_missionPos select 0, _missionPos select 1, _terrainZ + 0.7];
    
    private _hostage = _grpCiv createUnit [_civType, [0,0,0], [], 0, "NONE"];
    _hostage setPosASL _safeHostagePos;
    
    _hostage setFace _civFace;
    if (count _civLoadout > 0) then { _hostage setUnitLoadout _civLoadout; };
    
    // PROTECTION TEMPORAIRE AU SPAWN (10 secondes) puis vulnérable
    _hostage allowDamage false;
    
    [_hostage] spawn {
        params ["_h"];
        sleep 10;
        if (alive _h) then {
            _h allowDamage true;
            diag_log "[HOSTAGE] Otage maintenant vulnérable (10s écoulées)";
        };
    };
    
    // Configuration OTAGE (comme fn_task_4_launch)
    _hostage setCaptive true;
    removeAllWeapons _hostage;
    removeBackpack _hostage;
    
    _hostage disableAI "ANIM";
    _hostage disableAI "MOVE";
    _hostage disableAI "AUTOTARGET";
    _hostage disableAI "TARGET";
    
    _hostage switchMove "Acts_ExecutionVictim_Loop";
    
    _hostage setSkill ["aimingAccuracy", 0.90];
    _hostage setSkill ["courage", 1.0];
    _hostage allowFleeing 0;
    
    _hostage setVariable ["HOSTAGE_isCaptive", true, true];
    _hostage setVariable ["HOSTAGE_inHeli", false, true];
    
    // VÉRIFICATION DE SÉCURITÉ
    if (isNull _hostage) then {
        ["ERREUR: Otage non créé, réessai..."] call HOSTAGE_fnc_log;
        continue;
    };
    
    // Attendre 1 seconde pour laisser l'otage se stabiliser
    sleep 1;
    
    ["Otage créé (invincible pendant captivité)"] call HOSTAGE_fnc_log;
    
    // ============================================================
    // CRÉATION DES OPFOR APRÈS L'OTAGE (3 à 5)
    // ============================================================
    
    private _opforCount = 3 + floor (random 3);
    private _opforUnits = [];
    private _patrolRadius = 5 + random 10;
    
    for "_i" from 1 to _opforCount do {
        // Spawn OPFOR à au moins 5m de l'otage
        private _spawnPos = _missionPos getPos [5 + random 10, random 360];
        private _terrainZ = getTerrainHeightASL _spawnPos;
        _spawnPos = [_spawnPos select 0, _spawnPos select 1, _terrainZ + 0.7];
        private _unit = [_spawnPos, _patrolRadius, _civilTemplates] call HOSTAGE_fnc_createDisguisedOPFOR;
        
        // Empêcher l'OPFOR de cibler l'otage
        _unit addEventHandler ["FiredNear", {
            params ["_unit"];
            private _hostage = missionNamespace getVariable ["HOSTAGE_currentHostage", objNull];
            if (!isNull _hostage && _unit knowsAbout _hostage > 0) then {
                _unit forgetTarget _hostage;
            };
        }];
        
        _opforUnits pushBack _unit;
        sleep 0.3;
    };
    
    [format ["%1 OPFOR créés (ne ciblent pas l'otage)", _opforCount]] call HOSTAGE_fnc_log;
    
    // Variables globales pour cette mission
    private _taskId = format ["task_hostage_%1", _missionCounter];
    missionNamespace setVariable ["HOSTAGE_currentHostage", _hostage, true];
    missionNamespace setVariable ["HOSTAGE_currentTaskId", _taskId, true];
    
    ["Mission otage prête - En attente des joueurs"] call HOSTAGE_fnc_log;
    
    // ============================================================
    // HOLD ACTION DE LIBÉRATION (comme fn_task_4_launch)
    // ============================================================
    
    [_hostage, _taskId] remoteExec ["HOSTAGE_fnc_addHoldAction", 0, true];
    
    // Définir la fonction si pas déjà définie
    if (isNil "HOSTAGE_fnc_addHoldAction") then {
        HOSTAGE_fnc_addHoldAction = {
            params ["_captive", "_taskId"];
            
            if (!hasInterface) exitWith {};
            if (isNull _captive) exitWith {};
            
            [_captive, 
                localize "STR_HOSTAGE_ACTION_FREE",
                "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa",
                "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_unbind_ca.paa",
                "alive _target && _target distance _this < 2 && _target getVariable ['HOSTAGE_isCaptive', true]",
                "true",
                { hint (localize "STR_HOSTAGE_FREEING"); },
                {},
                {
                    params ["_target", "_caller", "_actionId", "_arguments"];
                    
                    // Lancer la logique de suivi (comme fn_task_4_launch L125-170)
                    [_target] spawn {
                        params ["_captive"];
                        
                        _captive setVariable ["HOSTAGE_isCaptive", false, true];
                        removeAllActions _captive;
                        
                        // Animation de libération
                        [_captive, "Acts_ExecutionVictim_Unbow"] remoteExec ["switchMove", 0];
                        sleep 8.5;
                        
                        // Notification
                        [localize "STR_HOSTAGE_FREED"] remoteExec ["hint", 0];
                        
                        // L'otage n'est plus captif
                        _captive setCaptive false;
                        { [_captive, _x] remoteExec ["enableAI", 0]; } forEach ["ANIM", "MOVE", "AUTOTARGET", "TARGET"];
                        
                        // --- Logique Suivre le joueur le plus proche (AMÉLIORÉE) ---
                        // Désactiver TOUTES les réactions IA qui pourraient le bloquer
                        _captive disableAI "FSM";
                        _captive disableAI "SUPPRESSION";
                        _captive disableAI "COVER";
                        _captive disableAI "AUTOCOMBAT";
                        _captive disableAI "MINEDETECTION";
                        
                        _captive setBehaviour "CARELESS";
                        _captive setUnitPos "UP";
                        _captive allowFleeing 0;
                        _captive setSkill ["courage", 1];
                        _captive setSkill ["commanding", 1];
                        _captive forceSpeed -1; // Vitesse maximale autorisée
                        
                        // Boucle de suivi - INJECTION CHAQUE SECONDE
                        while { alive _captive && !(_captive getVariable ["HOSTAGE_inHeli", false]) } do {
                            
                            // FORCER le comportement à chaque itération (anti-blocage)
                            _captive setUnitPos "UP";
                            _captive setBehaviour "CARELESS";
                            _captive setCombatMode "BLUE"; // Ne jamais engager
                            _captive allowFleeing 0;
                            _captive setSkill ["courage", 1];
                            _captive forceSpeed -1;
                            
                            // Annuler toute animation de peur/couverture
                            if (animationState _captive find "down" >= 0 || animationState _captive find "prone" >= 0) then {
                                _captive switchMove "";
                            };
                            
                            // Trouver le joueur le plus proche
                            private _nearestPlayer = objNull;
                            private _minDist = 99999;
                            
                            {
                                if (alive _x && !(_x isKindOf "HeadlessClient_F")) then {
                                    private _d = _captive distance _x;
                                    if (_d < _minDist) then {
                                        _minDist = _d;
                                        _nearestPlayer = _x;
                                    };
                                };
                            } forEach allPlayers;
                            
                            if (!isNull _nearestPlayer) then {
                                private _blockedTime = _captive getVariable ["HOSTAGE_blockedSince", 0];
                                private _isStuck = (_minDist > 5 && speed _captive < 0.5);
                                
                                if (_isStuck) then {
                                    // Début du blocage
                                    if (_blockedTime == 0) then {
                                        _captive setVariable ["HOSTAGE_blockedSince", time];
                                        _blockedTime = time;
                                    };
                                    
                                    private _stuckDuration = time - _blockedTime;
                                    
                                    if (_stuckDuration >= 20) then {
                                        // Bloqué 20+ secondes - TÉLÉPORTATION en dernier recours
                                        private _tpPos = (getPos _nearestPlayer) getPos [3, random 360];
                                        _captive setPos _tpPos;
                                        _captive setVariable ["HOSTAGE_blockedSince", 0];
                                        diag_log "[HOSTAGE] Otage bloqué 20s - téléportation de secours";
                                    } else {
                                        if (_stuckDuration >= 5) then {
                                            // Bloqué 5-20 secondes - CONTOURNEMENT
                                            // Changer de direction (gauche ou droite aléatoire)
                                            private _detourDir = (getDir _captive) + (selectRandom [-90, 90]);
                                            private _detourPos = _captive getPos [8, _detourDir];
                                            _captive doMove _detourPos;
                                            diag_log format ["[HOSTAGE] Otage bloqué %1s - contournement", round _stuckDuration];
                                        } else {
                                            // Bloqué moins de 5 secondes - continuer à essayer
                                            _captive doMove (getPos _nearestPlayer);
                                        };
                                    };
                                } else {
                                    // Pas bloqué - reset et mouvement normal
                                    _captive setVariable ["HOSTAGE_blockedSince", 0];
                                    _captive doMove (getPos _nearestPlayer);
                                    _captive setSpeedMode "FULL";
                                };
                            };
                            
                            sleep 1; // Vérification chaque seconde
                        };
                    };
                },
                {},
                [], 8, 0, false, false
            ] call BIS_fnc_holdActionAdd;
        };
    };
    
    // Appeler aussi localement pour le serveur
    [_hostage, _taskId] call HOSTAGE_fnc_addHoldAction;
    
    // ============================================================
    // CRÉATION DU MARQUEUR
    // ============================================================
    
    private _markerName = format ["marker_hostage_%1", _missionCounter];
    createMarker [_markerName, _missionPos];
    _markerName setMarkerType "hd_unknown";
    _markerName setMarkerColor "ColorOrange";
    _markerName setMarkerText localize "STR_HOSTAGE_MARKER";
    
    // ============================================================
    // CRÉATION DE LA TÂCHE
    // ============================================================
    
    [
        true,
        [_taskId],
        [
            localize "STR_HOSTAGE_TASK_DESC",
            localize "STR_HOSTAGE_TASK_TITLE",
            _markerName
        ],
        _missionPos,
        "CREATED",
        1,
        true,
        "search",
        true
    ] call BIS_fnc_taskCreate;
    
    // ============================================================
    // SURVEILLANCE: ATTENTE LIBÉRATION OTAGE
    // ============================================================
    
    waitUntil {
        sleep 2;
        !alive _hostage || !(_hostage getVariable ["HOSTAGE_isCaptive", true])
    };
    
    if (!alive _hostage) then {
        // Otage mort pendant captivité
        ["Otage mort - Échec mission"] call HOSTAGE_fnc_log;
        [_taskId, "FAILED"] call BIS_fnc_taskSetState;
        deleteMarker _markerName;
        [localize "STR_HOSTAGE_FAILED"] remoteExec ["hint", 0];
        
        // NE PAS SUPPRIMER l'otage ou les OPFOR (géré par fn_nettoyage plus tard)
        // Mais on nettoie l'hélico s'il a eu le temps de spawn
        
        if (!isNull _heli) then {
            // Faire repartir l'hélico pour qu'il ne reste pas planté là
            _heli setFuel 1;
            _heli engineOn true;
            _heli land "NONE";
            _heli flyInHeight 150;
            _heli doMove [0,0,1000];
            
            // Suppression différée de l'hélico
             [_heli, _heliCrew] spawn {
                params ["_h", "_c"];
                sleep 140; 
                { if (!isNull _x) then { deleteVehicle _x }; } forEach _c;
                if (!isNull _h) then { deleteVehicle _h };
            };
        };
        
        continue;
    };
    
    // ============================================================
    // OTAGE LIBÉRÉ - PHASE EXTRACTION
    // ============================================================
    
    ["Otage libéré - Phase extraction"] call HOSTAGE_fnc_log;
    [_taskId, "ASSIGNED"] call BIS_fnc_taskSetState;
    
    sleep 5;
    
    // ============================================================
    // TROUVER L'HÉLIPORT LE PLUS PROCHE
    // ============================================================
    
    private _closestHeliport = objNull;
    private _minDist = 99999;
    
    for "_i" from 0 to 66 do {
        private _heliportName = format ["task_heliport_%1", _i];
        private _heliport = missionNamespace getVariable [_heliportName, objNull];
        
        if (!isNull _heliport) then {
            private _d = _hostage distance (getPos _heliport);
            if (_d < _minDist) then {
                _minDist = _d;
                _closestHeliport = _heliport;
            };
        };
    };
    
    if (isNull _closestHeliport) then {
        ["ERREUR: Aucun héliport trouvé!"] call HOSTAGE_fnc_log;
        [_taskId, "FAILED"] call BIS_fnc_taskSetState;
        deleteMarker _markerName;
        continue;
    };
    
    private _lzPos = getPos _closestHeliport;
    [format ["LZ sélectionnée à %1m", round _minDist]] call HOSTAGE_fnc_log;
    
    // ============================================================
    // SPAWN HÉLICOPTÈRE HURON
    // ============================================================
    
    [localize "STR_HOSTAGE_HELI_INCOMING"] remoteExec ["hint", 0];
    
    private _spawnPos = _lzPos vectorAdd [-2000, -2000, 300];
    private _grpHeli = createGroup [west, true];
    
    private _heli = createVehicle ["B_Heli_Transport_03_unarmed_F", _spawnPos, [], 0, "FLY"];
    _heli lock 2;
    _heli allowDamage false; // Hélico invincible
    
    private _heliCrew = [];
    for "_i" from 1 to 4 do {
        private _crewUnit = _grpHeli createUnit ["B_Helipilot_F", _spawnPos, [], 0, "NONE"];
        _crewUnit moveInAny _heli;
        _crewUnit allowDamage false; // Équipage invincible
        _heliCrew pushBack _crewUnit;
    };
    
    // Marqueur LZ
    private _lzMarker = format ["marker_lz_%1", _missionCounter];
    createMarker [_lzMarker, _lzPos];
    _lzMarker setMarkerType "hd_pickup";
    _lzMarker setMarkerColor "ColorGreen";
    _lzMarker setMarkerText localize "STR_HOSTAGE_EXTRACTION_MARKER";
    
    // Créer un hélipad invisible
    private _helipad = createVehicle ["Land_HelipadEmpty_F", _lzPos, [], 0, "CAN_COLLIDE"];
    
    // Faire voler vers LZ
    _grpHeli setBehaviour "CARELESS";
    _grpHeli setCombatMode "BLUE";
    _grpHeli move _lzPos;
    _heli doMove _lzPos;
    _heli flyInHeight 30;
    
    // Attendre arrivée proche de la LZ
    waitUntil {
        sleep 1;
        !alive _hostage || !alive _heli || _heli distance2D _lzPos < 100
    };
    
    if (!alive _hostage || !alive _heli) then {
        ["Échec: Otage ou hélico détruit"] call HOSTAGE_fnc_log;
        [_taskId, "FAILED"] call BIS_fnc_taskSetState;
        deleteMarker _markerName;
        deleteMarker _lzMarker;
        deleteVehicle _helipad;
        if (!isNull _heli) then {
             // Faire repartir l'hélico
            _heli setFuel 1;
            _heli engineOn true;
            _heli land "NONE";
            _heli flyInHeight 150;
            _heli doMove [0,0,1000];
            
             [_heli, _heliCrew] spawn {
                params ["_h", "_c"];
                sleep 140; 
                { if (!isNull _x) then { deleteVehicle _x }; } forEach _c;
                if (!isNull _h) then { deleteVehicle _h };
            };
        };
        
        continue;
    };
    
    // ============================================================
    // ATTERRISSAGE FORCÉ PAR CARBURANT (méthode infaillible)
    // ============================================================
    
    ["Hélico proche - Atterrissage forcé par coupure carburant"] call HOSTAGE_fnc_log;
    
    // Couper le carburant pour forcer l'atterrissage
    _heli setFuel 0;
    _heli flyInHeight 0;
    _heli land "LAND";
    
    // Attendre que l'hélico touche le sol (max 45 secondes)
    private _landTimeout = time + 45;
    waitUntil {
        sleep 0.5;
        !alive _hostage || !alive _heli || isTouchingGround _heli || (time > _landTimeout)
    };
    
    // Si timeout, forcer la position au sol
    if (!isTouchingGround _heli && alive _heli) then {
        ["Atterrissage forcé par setPos"] call HOSTAGE_fnc_log;
        _heli setVelocity [0, 0, 0];
        _heli setPos [_lzPos select 0, _lzPos select 1, 0];
    };
    
    sleep 2; // Laisser l'hélico se stabiliser
    
    if (!alive _hostage || !alive _heli) then {
        ["Échec: Otage ou hélico détruit pendant atterrissage"] call HOSTAGE_fnc_log;
        [_taskId, "FAILED"] call BIS_fnc_taskSetState;
        deleteMarker _markerName;
        deleteMarker _lzMarker;
        deleteVehicle _helipad;
        if (!isNull _heli) then {
             // Faire repartir l'hélico
            _heli setFuel 1;
            _heli engineOn true;
            _heli land "NONE";
            _heli flyInHeight 150;
            _heli doMove [0,0,1000];
            
             [_heli, _heliCrew] spawn {
                params ["_h", "_c"];
                sleep 140; 
                { if (!isNull _x) then { deleteVehicle _x }; } forEach _c;
                if (!isNull _h) then { deleteVehicle _h };
            };
        };
        continue;
    };
    
    // ============================================================
    // LOGIQUE EMBARQUEMENT ROBUSTE
    // ============================================================
    
    ["Hélico au sol - Prêt pour embarquement"] call HOSTAGE_fnc_log;
    
    _heli lock 0; // Déverrouiller pour embarquement
    _heli engineOn true;
    
    private _takeOff = false;
    private _lastGetInActionTime = 0;
    
    waitUntil {
        sleep 2;
        
        if (!alive _heli || !alive _hostage) exitWith { true };
        
        private _hostageInVehicle = (vehicle _hostage == _heli);
        private _playersInVehicle = ({isPlayer _x} count (crew _heli)) > 0;
        
        if (_hostageInVehicle) then {
            if (_playersInVehicle) then {
                // Joueur à bord - attendre qu'il sorte
                _heli engineOn true;
                if (locked _heli == 2) then { _heli lock 0; };
                ["Joueur à bord - Attente sortie"] call HOSTAGE_fnc_log;
            } else {
                // Otage IN, Joueurs OUT -> DÉCOLLAGE OK
                _heli setFuel 1; // Remettre le carburant pour le décollage!
                _takeOff = true;
                _heli lock 2;
                ["Otage à bord - Décollage autorisé, carburant remis"] call HOSTAGE_fnc_log;
            };
        } else {
            // Otage pas encore à bord
            private _dist = _hostage distance _heli;
            
            if (_dist < 50) then {
                _hostage setVariable ["HOSTAGE_inHeli", true, true]; // Coupe le script de suivi
                _hostage setUnitPos "UP";
                _hostage setBehaviour "CARELESS";
                
                // JOIN le groupe de l'hélico (comme fn_task_4_launch L366-372)
                if (group _hostage != _grpHeli) then {
                    [_hostage] joinSilent _grpHeli;
                    _hostage setCaptive false;
                };
                
                // Assigner l'hélico
                if (assignedVehicle _hostage != _heli) then {
                    _hostage assignAsCargo _heli;
                };
                
                // Ordonner de monter
                [_hostage] orderGetIn true;
                
                if (_dist < 8) then {
                    if (time - _lastGetInActionTime > 4) then {
                        if (unitReady _hostage) then {
                            _hostage action ["GetInCargo", _heli];
                            _lastGetInActionTime = time;
                        };
                    };
                };
            };
        };
        
        _takeOff
    };
    
    // ============================================================
    // DÉCOLLAGE ET EXTRACTION
    // ============================================================
    
    if (!alive _heli || !alive _hostage) then {
        ["Échec: Otage ou hélico détruit"] call HOSTAGE_fnc_log;
        [_taskId, "FAILED"] call BIS_fnc_taskSetState;
        [localize "STR_HOSTAGE_FAILED"] remoteExec ["hint", 0];
        deleteMarker _markerName;
        deleteMarker _lzMarker;
        deleteVehicle _helipad;
        if (!isNull _heli) then {
             // Faire repartir l'hélico
            _heli setFuel 1;
            _heli engineOn true;
            _heli land "NONE";
            _heli flyInHeight 150;
            _heli doMove [0,0,1000];
            
             [_heli, _heliCrew] spawn {
                params ["_h", "_c"];
                sleep 140; 
                { if (!isNull _x) then { deleteVehicle _x }; } forEach _c;
                if (!isNull _h) then { deleteVehicle _h };
            };
        };
        
        continue;
    };
    
    ["Décollage extraction"] call HOSTAGE_fnc_log;
    
    _heli setFuel 1;
    _heli engineOn true;
    
    sleep 1;
    
    deleteMarker _lzMarker;
    deleteVehicle _helipad;
    
    _heli land "NONE";
    _grpHeli setBehaviour "CARELESS";
    _grpHeli setCombatMode "BLUE";
    
    private _pilot = driver _heli;
    
    _heli doMove [0, 0, 1000];
    if (!isNull _pilot) then { _pilot doMove [0, 0, 1000]; };
    
    _heli flyInHeight 150;
    
    [localize "STR_HOSTAGE_HELI_INCOMING"] remoteExec ["hint", 0];
    
    sleep 65;
    
    // ============================================================
    // FIN DE MISSION - SUCCÈS!
    // ============================================================
    
    if (alive _hostage) then {
        ["Mission réussie - Otage extrait"] call HOSTAGE_fnc_log;
        [_taskId, "SUCCEEDED"] call BIS_fnc_taskSetState;
        [localize "STR_HOSTAGE_EXTRACTED"] remoteExec ["hint", 0];
    } else {
        ["Mission échouée - Otage mort"] call HOSTAGE_fnc_log;
        [_taskId, "FAILED"] call BIS_fnc_taskSetState;
        [localize "STR_HOSTAGE_FAILED"] remoteExec ["hint", 0];
    };
    
    // Nettoyage
    deleteMarker _markerName;
    
    // Nettoyage: NE PAS SUPPRIMER Otage / OPFOR
    // { if (alive _x) then { deleteVehicle _x }; } forEach _opforUnits;
    // if (!isNull _hostage) then { deleteVehicle _hostage; };
    
    // Supprimer hélico et équipage APRÈS DÉLAI
    [_heli, _heliCrew] spawn {
        params ["_h", "_c"];
        sleep 140; // Délai étendu pour laisser l'hélico partir au loin
        { if (!isNull _x) then { deleteVehicle _x }; } forEach _c;
        if (!isNull _h) then { deleteVehicle _h };
    };
    
    [format ["Mission #%1 terminée. Prochaine dans 200-1500s...", _missionCounter]] call HOSTAGE_fnc_log;
    
    // La boucle continue automatiquement pour la prochaine mission
};
