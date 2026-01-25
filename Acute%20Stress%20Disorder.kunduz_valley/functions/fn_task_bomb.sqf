/*
    fn_task_bomb.sqf
    
    Description:
    Mission de désamorçage de bombe en boucle. Une bombe est placée aléatoirement sur l'un des 
    177 emplacements (task_bomb_position_0 à task_bomb_position_176).
    Les joueurs ont entre 10 et 25 minutes pour la désamorcer avant explosion.
    
    Après désamorçage, une nouvelle bombe apparaît après 200-1500 secondes.
    La bombe émet un bip toutes les 5 secondes.
    Un marqueur indique la position exacte de la bombe.
    
    Optimisé pour le multijoueur.
*/

// Exécution uniquement sur le serveur
if (!isServer) exitWith {};

// ============================================================
// DÉFINIR LA FONCTION D'AJOUT D'ACTION (une seule fois)
// ============================================================

if (isNil "Mission_fnc_task_bomb_addAction") then {
    Mission_fnc_task_bomb_addAction = {
        params ["_bombObj"];
        
        if (!hasInterface) exitWith {};
        if (isNull _bombObj) exitWith {};
        
        _bombObj addAction [
            localize "STR_BOMB_DEFUSE_ACTION",
            {
                params ["_target", "_caller", "_actionId", "_arguments"];
                
                // Désactiver l'action pendant le désamorçage
                _caller setVariable ["isDefusing", true, true];
                
                // Animation de désamorçage
                _caller playMove "Acts_carFixingWheel";
                
                // Hint de progression
                hint (localize "STR_BOMB_DEFUSING");
                
                // Utiliser spawn pour attendre 10 secondes
                [_target, _caller] spawn {
                    params ["_bomb", "_player"];
                    
                    sleep 10;
                    
                    // Vérifier que le joueur est toujours en vie
                    if (!alive _player) exitWith {
                        hint (localize "STR_BOMB_DEFUSE_FAILED");
                        _player setVariable ["isDefusing", false, true];
                    };
                    
                    // Vérifier que le joueur est toujours proche
                    if (_player distance _bomb > 5) exitWith {
                        hint (localize "STR_BOMB_DEFUSE_FAILED");
                        _player setVariable ["isDefusing", false, true];
                    };
                    
                    // Désamorçage réussi!
                    missionNamespace setVariable ["MISSION_bomb_defused", true, true];
                    
                    // Retirer l'action de la bombe
                    removeAllActions _bomb;
                    
                    _player setVariable ["isDefusing", false, true];
                    _player switchMove "";
                    
                    // Attendre 45 secondes puis supprimer la bombe
                    sleep 45;
                    
                    if (!isNull _bomb) then {
                        deleteVehicle _bomb;
                        missionNamespace setVariable ["MISSION_bomb_active", objNull, true];
                    };
                };
            },
            [],
            6,
            true,
            true,
            "",
            "alive _this && {!(_this getVariable ['isDefusing', false])} && {_this distance _target < 3}",
            3
        ];
    };
};

// ============================================================
// COMPTEUR DE BOMBES POUR ID UNIQUE
// ============================================================

private _bombCounter = 0;

// ============================================================
// BOUCLE PRINCIPALE - RESPAWN DE BOMBES
// ============================================================

while {true} do {
    // ============================================================
    // ATTENDRE ENTRE 150 ET 600 SECONDES AVANT LA PROCHAINE BOMBE
    // ============================================================
    
    private _waitTime = 150 + floor(random 600); // 150 à 600 secondes aléatoire
    diag_log format ["[TASK_BOMB] Prochaine bombe dans %1 secondes (%2 minutes)", _waitTime, round(_waitTime / 60)];
    
    sleep _waitTime;
    
    // Incrémenter le compteur pour ID unique
    _bombCounter = _bombCounter + 1;
    
    // ============================================================
    // SÉLECTION ALÉATOIRE DE LA POSITION
    // ============================================================
    
    private _positionIndex = floor (random 177); // 0 à 176
    private _positionName = format ["task_bomb_position_%1", _positionIndex];
    private _positionObject = missionNamespace getVariable [_positionName, objNull];
    
    // Vérifier que la position existe
    if (isNull _positionObject) then {
        diag_log format ["[TASK_BOMB] ERREUR: Position %1 introuvable! Réessai...", _positionName];
        continue;
    };
    
    private _bombPosition = getPos _positionObject;
    
    diag_log format ["[TASK_BOMB] Bombe #%1 placée sur %2 à la position %3", _bombCounter, _positionName, _bombPosition];
    
    // ============================================================
    // CRÉATION DE L'EXPLOSIF (IED)
    // ============================================================
    
    // Créer l'explosif
    private _bomb = createVehicle ["Box_IED_Exp_F", [0,0,0], [], 0, "CAN_COLLIDE"];
    
    // Positionner l'explosif correctement au-dessus du terrain
    private _terrainZ = getTerrainHeightASL [_bombPosition select 0, _bombPosition select 1];
    _bomb setPosASL [_bombPosition select 0, _bombPosition select 1, _terrainZ + 0.5];
    
    
    // Rendre la bombe INDESTRUCTIBLE (ne peut pas être détruite par des armes)
    _bomb allowDamage false;
    _bomb enableSimulation true;
    
    // Rendre la bombe accessible globalement
    missionNamespace setVariable ["MISSION_bomb_active", _bomb, true];
    missionNamespace setVariable ["MISSION_bomb_defused", false, true];
    
    // ============================================================
    // AJOUT DE L'ACTION DE DÉSAMORÇAGE SUR LA BOMBE
    // ============================================================
    
    // L'action est ajoutée sur tous les clients
    [_bomb] remoteExec ["Mission_fnc_task_bomb_addAction", 0, true]; // JIP compatible
    
    // Exécuter localement aussi (pour le serveur si joueur hébergeur)
    [_bomb] call Mission_fnc_task_bomb_addAction;
    
    // ============================================================
    // CRÉATION DU MARQUEUR SUR LA CARTE
    // ============================================================
    
    private _markerName = format ["marker_bomb_location_%1", _bombCounter];
    createMarker [_markerName, _bombPosition];
    _markerName setMarkerType "hd_warning";
    _markerName setMarkerColor "ColorRed";
    _markerName setMarkerText localize "STR_BOMB_MARKER";
    
    // ============================================================
    // CRÉATION DE LA TÂCHE
    // ============================================================
    
    private _taskId = format ["task_bomb_defusal_%1", _bombCounter];
    
    // Créer la tâche pour tous les joueurs
    [
        true, // Global
        [_taskId], // ID de la tâche
        [
            localize "STR_BOMB_TASK_DESC", // Description
            localize "STR_BOMB_TASK_TITLE", // Titre
            _markerName // Marqueur
        ],
        _bombPosition, // Position
        "CREATED", // État
        1, // Priorité
        true, // Afficher notification
        "danger", // Type
        true // Afficher sur la carte
    ] call BIS_fnc_taskCreate;
    
    // ============================================================
    // TEMPS AVANT EXPLOSION (5 à 10 minutes)
    // ============================================================
    
    private _explosionTime = 300 + (random 600); // 300s (5min) + 0-600s (0-10min) = 5-10min
    private _startTime = time;
    private _endTime = _startTime + _explosionTime;
    
    diag_log format ["[TASK_BOMB] Bombe #%1 - Temps avant explosion: %2 secondes (%3 minutes)", _bombCounter, _explosionTime, _explosionTime / 60];
    
    // ============================================================
    // BOUCLE DE SURVEILLANCE - BIP BIP ET VÉRIFICATION
    // ============================================================
    
    private _lastBeepTime = 0;
    private _beepInterval = 5; // Bip toutes les 5 secondes
    private _bombResult = ""; // "defused" ou "exploded"
    
    while {_bombResult == ""} do {
        sleep 0.5;
        
        // Vérifier si la bombe est toujours active
        private _bombObj = missionNamespace getVariable ["MISSION_bomb_active", objNull];
        private _isDefused = missionNamespace getVariable ["MISSION_bomb_defused", false];
        
        // ============================================================
        // CAS 1: BOMBE DÉSAMORCÉE
        // ============================================================
        if (isNull _bombObj || _isDefused) then {
            _bombResult = "defused";
            diag_log format ["[TASK_BOMB] Bombe #%1 désamorcée avec succès!", _bombCounter];
            
            // Marquer la tâche comme réussie
            [_taskId, "SUCCEEDED", true] call BIS_fnc_taskSetState;
            
            // Supprimer le marqueur
            deleteMarker _markerName;
            
            // Notification de succès
            [localize "STR_BOMB_DEFUSED"] remoteExec ["hint", 0];
        };
        
        // ============================================================
        // CAS 2: TEMPS ÉCOULÉ - EXPLOSION
        // ============================================================
        if (_bombResult == "" && time >= _endTime) then {
            _bombResult = "exploded";
            diag_log format ["[TASK_BOMB] Bombe #%1 - Temps écoulé - EXPLOSION!", _bombCounter];
            
            // Créer une explosion massive
            private _bombPos = getPos _bombObj;
            "Bo_GBU12_LGB" createVehicle _bombPos;
            
            // Supprimer la bombe
            deleteVehicle _bombObj;
            missionNamespace setVariable ["MISSION_bomb_active", objNull, true];
            
            // Marquer la tâche comme échouée
            [_taskId, "FAILED", true] call BIS_fnc_taskSetState;
            
            // Supprimer le marqueur
            deleteMarker _markerName;
            
            // Notification d'échec
            [localize "STR_BOMB_EXPLODED"] remoteExec ["hint", 0];
        };
        
        // ============================================================
        // BIP BIP TOUTES LES 5 SECONDES (si bombe toujours active)
        // ============================================================
        if (_bombResult == "" && time - _lastBeepTime >= _beepInterval) then {
            _lastBeepTime = time;
            
            private _currentBomb = missionNamespace getVariable ["MISSION_bomb_active", objNull];
            if (!isNull _currentBomb) then {
                // Jouer le son de bip sur tous les clients proches
                [_currentBomb, ["beep", 50]] remoteExec ["say3D", 0];
                
                // Lumière clignotante rouge
                private _light = "#lightpoint" createVehicleLocal (getPos _currentBomb);
                _light setLightBrightness 1;
                _light setLightColor [1, 0, 0]; // Rouge
                _light setLightAmbient [1, 0, 0];
                
                // Éteindre la lumière après 0.2s
                [_light] spawn {
                    params ["_l"];
                    sleep 0.2;
                    deleteVehicle _l;
                };
            };
        };
    };
    
    diag_log format ["[TASK_BOMB] Bombe #%1 terminée (%2). Nouvelle bombe dans 200-1500 secondes...", _bombCounter, _bombResult];
    
    // La boucle continue automatiquement pour la prochaine bombe
};
