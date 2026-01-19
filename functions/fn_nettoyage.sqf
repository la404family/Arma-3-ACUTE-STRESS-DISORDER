/*
    fn_nettoyage.sqf
    
    Description:
    Nettoie la carte en supprimant les unités OPFOR trop éloignées des joueurs.
    - Supprime les OPFOR à plus de 1200m de TOUS les joueurs
    - Vérifie toutes les 600 secondes (10 minutes)
    - Optimise la mémoire et les performances en multijoueur
    
    Exécution: Serveur uniquement
*/

// Exécution uniquement sur le serveur
if (!isServer) exitWith {};

// ============================================================
// CONFIGURATION
// ============================================================

private _cleanupDistance = 1200; // Distance minimale en mètres
private _checkInterval = 600;      // Intervalle de vérification en secondes
private _debug = false;           // Mettre à true pour debug

// Fonction de log
NETTOYAGE_fnc_log = {
    params ["_msg"];
    diag_log format ["[NETTOYAGE] %1", _msg];
};

["Système de nettoyage OPFOR initialisé (distance: %1m, intervalle: %2s)", _cleanupDistance, _checkInterval] call NETTOYAGE_fnc_log;

// ============================================================
// BOUCLE PRINCIPALE DE NETTOYAGE
// ============================================================

while {true} do {
    
    // Attendre avant la prochaine vérification
    sleep _checkInterval;
    
    // Récupérer tous les joueurs vivants
    private _allPlayers = allPlayers select {alive _x};
    
    if (count _allPlayers == 0) then {
        continue; // Pas de joueurs, rien à faire
    };
    
    // Récupérer tous les OPFOR
    private _allOPFOR = allUnits select {side _x == east && alive _x};
    
    private _deletedCount = 0;
    
    {
        private _opfor = _x;
        private _tooFar = true;
        
        // Vérifier la distance par rapport à TOUS les joueurs
        {
            if (_opfor distance _x < _cleanupDistance) exitWith {
                _tooFar = false; // Au moins un joueur est proche
            };
        } forEach _allPlayers;
        
        // Si trop loin de TOUS les joueurs, supprimer
        if (_tooFar) then {
            private _grp = group _opfor;
            
            deleteVehicle _opfor;
            _deletedCount = _deletedCount + 1;
            
            // Supprimer le groupe s'il est vide
            if (count units _grp == 0) then {
                deleteGroup _grp;
            };
        };
        
    } forEach _allOPFOR;
    
    // Log si des unités ont été supprimées
    if (_deletedCount > 0) then {
        [format ["%1 OPFOR supprimés (trop loin > %2m)", _deletedCount, _cleanupDistance]] call NETTOYAGE_fnc_log;
    };
    
    // Debug: afficher les stats
    if (_debug) then {
        private _remainingOPFOR = count (allUnits select {side _x == east && alive _x});
        [format ["OPFOR restants: %1", _remainingOPFOR]] call NETTOYAGE_fnc_log;
    };
};
