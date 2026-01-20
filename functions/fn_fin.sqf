/*
    fn_fin.sqf
    
    Description:
    Système de fin de mission avec extraction par hélicoptère.
    - Après X minutes de jeu, message radio pour retour à la base
    - Un hélicoptère Ghost Hawk se pose près de marker_4 (la base)
    - Quand tous les joueurs montent, l'hélico décolle vers [0,0]
    - Après 120 secondes de vol, la mission se termine
*/

if (!isServer) exitWith {};

diag_log "[FIN_MISSION] === Démarrage du système de fin de mission ===";

// --- CONFIGURATION ---
private _delayBeforeMessage = 300; // 5 minutes (300 secondes) - MODIFIER POUR LES TESTS
private _heliClass = "B_Heli_Transport_01_F"; // UH-80 Ghost Hawk
private _flyTime = 120; // 120 secondes de vol avant fin de mission

// Position d'atterrissage - objet invisible heli_fin
private _heliFinObj = missionNamespace getVariable ["heli_fin", objNull];
private _landingPos = [0, 0, 0];

if (!isNull _heliFinObj) then {
    _landingPos = getPos _heliFinObj;
    diag_log "[FIN_MISSION] Objet heli_fin trouvé !";
} else {
    diag_log "[FIN_MISSION] ERREUR: Objet heli_fin non trouvé! Recherche de marker_4...";
    if (getMarkerColor "marker_4" != "") then {
        _landingPos = getMarkerPos "marker_4";
    } else {
        diag_log "[FIN_MISSION] ERREUR: marker_4 non trouvé! Utilisation de respawn_west";
        _landingPos = getMarkerPos "respawn_west";
    };
};

if (_landingPos isEqualTo [0,0,0]) then {
    diag_log "[FIN_MISSION] ERREUR CRITIQUE: Aucun point d'atterrissage trouvé! Abandon.";
    _landingPos = getPos (allPlayers select 0);
};

diag_log format ["[FIN_MISSION] Position atterrissage: %1", _landingPos];

// Position de spawn hélico (2km de la base)
private _spawnDir = random 360;
private _heliSpawnPos = _landingPos getPos [2000, _spawnDir];
_heliSpawnPos set [2, 150];

diag_log format ["[FIN_MISSION] Hélico spawn prévu en: %1", _heliSpawnPos];
diag_log format ["[FIN_MISSION] Extraction dans %1 secondes (%2 minutes)", _delayBeforeMessage, _delayBeforeMessage / 60];

// --- BOUCLE PRINCIPALE ---
[_delayBeforeMessage, _heliClass, _flyTime, _landingPos, _heliSpawnPos] spawn {
    params ["_delayBeforeMessage", "_heliClass", "_flyTime", "_landingPos", "_heliSpawnPos"];
    
    // Attendre le délai configuré
    diag_log format ["[FIN_MISSION] Attente de %1 secondes...", _delayBeforeMessage];
    sleep _delayBeforeMessage;
    
    diag_log "[FIN_MISSION] === Délai écoulé - Lancement extraction ===";
    
    // ============================================================
    // MESSAGE RADIO POUR TOUS LES JOUEURS
    // ============================================================
    (localize "STR_FIN_MESSAGE_EXTRACTION") remoteExec ["systemChat", 0];
    (localize "STR_FIN_MESSAGE_EXTRACTION") remoteExec ["hint", 0];
    
    sleep 3;
    
    // ============================================================
    // SPAWN DE L'HÉLICOPTÈRE D'EXTRACTION
    // ============================================================
    
    diag_log format ["[FIN_MISSION] Création hélicoptère: %1 en %2", _heliClass, _heliSpawnPos];
    
    // Créer l'hélico en vol
    private _heli = createVehicle [_heliClass, _heliSpawnPos, [], 0, "FLY"];
    
    if (isNull _heli) then {
        diag_log "[FIN_MISSION] ERREUR: Échec création hélicoptère!";
    } else {
        diag_log format ["[FIN_MISSION] Hélicoptère créé avec succès: %1", _heli];
    };
    
    _heli setPos _heliSpawnPos;
    _heli setDir (_heliSpawnPos getDir _landingPos);
    _heli flyInHeight 100;
    _heli setFuel 1;
    
    // Créer l'équipage
    private _group = createGroup [WEST, true];
    private _crew = [];
    
    private _pilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
    _pilot moveInDriver _heli;
    _crew pushBack _pilot;
    
    private _copilot = _group createUnit ["B_Helipilot_F", [0,0,0], [], 0, "NONE"];
    _copilot moveInTurret [_heli, [0]];
    _crew pushBack _copilot;
    
    diag_log format ["[FIN_MISSION] Équipage créé: %1 membres", count _crew];
    
    // Configuration IA - Indestructible
    _group setBehaviour "CARELESS";
    _group setCombatMode "BLUE";
    
    {
        _x disableAI "AUTOCOMBAT";
        _x disableAI "AUTOTARGET";
        _x setCaptive true;
        _x allowDamage false;
    } forEach _crew;
    
    _heli allowDamage false;
    
    // Message: hélico en approche
    (localize "STR_FIN_HELI_INBOUND") remoteExec ["systemChat", 0];
    
    // ============================================================
    // VOL VERS LA BASE ET ATTERRISSAGE
    // ============================================================
    
    diag_log format ["[FIN_MISSION] Hélico en route vers %1", _landingPos];
    
    _heli doMove _landingPos;
    
    // Attendre l'approche
    waitUntil { sleep 1; (_heli distance2D _landingPos) < 200 || !alive _heli };
    
    if (!alive _heli) exitWith {
        diag_log "[FIN_MISSION] ERREUR: Hélicoptère détruit!";
    };
    
    diag_log "[FIN_MISSION] Hélico proche - Début atterrissage";
    
    // Forcer l'atterrissage
    _heli flyInHeight 0;
    _heli land "GET IN";
    
    waitUntil { sleep 1; (_heli distance2D _landingPos) < 80 || !alive _heli };
    
    _heli setFuel 0; // Couper le carburant pour forcer l'atterrissage
    
    // Attendre que l'hélico soit au sol
    private _landTimeout = 0;
    waitUntil { 
        sleep 1; 
        _landTimeout = _landTimeout + 1;
        ((getPos _heli select 2) < 3) || _landTimeout > 60 
    };
    
    doStop _heli;
    
    diag_log "[FIN_MISSION] Hélicoptère posé - En attente des joueurs";
    
    // Message: hélico en attente
    (localize "STR_FIN_HELI_WAITING") remoteExec ["systemChat", 0];
    
    // Créer un marqueur sur l'hélico
    private _marker = createMarker ["extraction_heli", getPos _heli];
    _marker setMarkerType "mil_pickup";
    _marker setMarkerColor "ColorBLUFOR";
    _marker setMarkerText (localize "STR_FIN_MARKER_EXTRACTION");
    
    // ============================================================
    // ATTENDRE QUE TOUS LES JOUEURS MONTENT
    // ============================================================
    
    diag_log "[FIN_MISSION] En attente que tous les joueurs montent...";
    
    private _allPlayersInHeli = false;
    
    while {!_allPlayersInHeli} do {
        sleep 2;
        
        // Récupérer tous les joueurs vivants
        private _allPlayers = allPlayers select { alive _x && isPlayer _x };
        
        if (count _allPlayers == 0) then { continue };
        
        // Vérifier si tous sont dans l'hélico
        private _playersInHeli = { (vehicle _x) == _heli } count _allPlayers;
        
        diag_log format ["[FIN_MISSION] Joueurs dans hélico: %1/%2", _playersInHeli, count _allPlayers];
        
        if (_playersInHeli == count _allPlayers && count _allPlayers > 0) then {
            _allPlayersInHeli = true;
            diag_log format ["[FIN_MISSION] Tous les joueurs à bord (%1)", count _allPlayers];
        };
    };
    
    // ============================================================
    // DÉCOLLAGE VERS [0,0] ET FIN DE MISSION
    // ============================================================
    
    diag_log "[FIN_MISSION] Décollage vers extraction";
    
    // Restaurer le carburant
    _heli setFuel 1;
    
    // Message: décollage
    (localize "STR_FIN_TAKEOFF") remoteExec ["systemChat", 0];
    
    sleep 3;
    
    // Supprimer le marqueur
    deleteMarker "extraction_heli";
    
    // Destination: point 0,0 de la carte
    private _exitPos = [0, 0, 0];
    
    _heli flyInHeight 200;
    _heli doMove _exitPos;
    
    // Attendre le temps de vol
    diag_log format ["[FIN_MISSION] Vol vers extraction - %1 secondes restantes", _flyTime];
    
    sleep _flyTime;
    
    // ============================================================
    // FIN DE MISSION
    // ============================================================
    
    diag_log "[FIN_MISSION] === MISSION TERMINÉE - SUCCÈS ===";
    
    // Terminer la mission avec succès
    ["END1", true] remoteExec ["BIS_fnc_endMission", 0];
};

diag_log "[FIN_MISSION] Système initialisé avec succès";
