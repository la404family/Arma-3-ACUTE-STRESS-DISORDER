/*
    fn_task_x_briefing.sqf
    
    Description:
    Crée le briefing général de la mission dans le journal du joueur (Diary).
    Contient toutes les informations importantes sur la mission Acute Stress Disorder.
    Crée le briefing pour TOUTES les unités jouables pour supporter le switch.
    
    Exécution: Serveur et Client
*/

// Attendre que la mission soit prête
waitUntil { time > 0 };
waitUntil { !isNull player };

// Fonction locale pour créer le briefing sur une unité spécifique
private _fnc_createBriefingForUnit = {
    params ["_unit"];
    
    // Vérifier que l'unité est valide et n'a pas déjà le briefing
    if (isNull _unit) exitWith {};
    if (_unit getVariable ["MISSION_briefing_created", false]) exitWith {};
    
    // Marquer comme déjà créé
    _unit setVariable ["MISSION_briefing_created", true, true];

    // ============================================================
    // BRIEFING GÉNÉRAL - ACUTE STRESS DISORDER
    // ============================================================
    // Note: Les entrées sont ajoutées dans l'ordre inverse car le diary
    // affiche les dernières entrées en premier
    
    // --- SYSTÈMES JOUEUR ---
    _unit createDiarySubject ["SYSTEMS", localize "STR_DIARY_SYSTEMS", "\a3\ui_f\data\Map\Markers\Military\unknown_ca.paa"];
    
    _unit createDiaryRecord ["SYSTEMS", [
        localize "STR_DIARY_SYSTEMS_BROTHERS_TITLE",
        localize "STR_DIARY_SYSTEMS_BROTHERS_TEXT"
    ]];
    
    _unit createDiaryRecord ["SYSTEMS", [
        localize "STR_DIARY_SYSTEMS_WEATHER_TITLE",
        localize "STR_DIARY_SYSTEMS_WEATHER_TEXT"
    ]];
    
    _unit createDiaryRecord ["SYSTEMS", [
        localize "STR_DIARY_SYSTEMS_VEHICLES_TITLE",
        localize "STR_DIARY_SYSTEMS_VEHICLES_TEXT"
    ]];
    
    _unit createDiaryRecord ["SYSTEMS", [
        localize "STR_DIARY_SYSTEMS_ARSENAL_TITLE",
        localize "STR_DIARY_SYSTEMS_ARSENAL_TEXT"
    ]];
    
    // --- MISSIONS DYNAMIQUES ---
    _unit createDiarySubject ["MISSIONS", localize "STR_DIARY_MISSIONS", "\a3\ui_f\data\Map\Markers\Military\objective_ca.paa"];
    
    _unit createDiaryRecord ["MISSIONS", [
        localize "STR_DIARY_MISSION_MILITIA_TITLE",
        localize "STR_DIARY_MISSION_MILITIA_TEXT"
    ]];
    
    _unit createDiaryRecord ["MISSIONS", [
        localize "STR_DIARY_MISSION_CACHE_TITLE",
        localize "STR_DIARY_MISSION_CACHE_TEXT"
    ]];
    
    _unit createDiaryRecord ["MISSIONS", [
        localize "STR_DIARY_MISSION_HOSTAGE_TITLE",
        localize "STR_DIARY_MISSION_HOSTAGE_TEXT"
    ]];
    
    _unit createDiaryRecord ["MISSIONS", [
        localize "STR_DIARY_MISSION_BOMB_TITLE",
        localize "STR_DIARY_MISSION_BOMB_TEXT"
    ]];
    
    _unit createDiaryRecord ["MISSIONS", [
        localize "STR_DIARY_MISSION_PROTECTION_TITLE",
        localize "STR_DIARY_MISSION_PROTECTION_TEXT"
    ]];
    
    // --- MENACES ---
    _unit createDiarySubject ["THREATS", localize "STR_DIARY_THREATS", "\a3\ui_f\data\Map\Markers\Military\warning_ca.paa"];
    
    _unit createDiaryRecord ["THREATS", [
        localize "STR_DIARY_THREAT_MINES_TITLE",
        localize "STR_DIARY_THREAT_MINES_TEXT"
    ]];
    
    _unit createDiaryRecord ["THREATS", [
        localize "STR_DIARY_THREAT_INSURGENTS_TITLE",
        localize "STR_DIARY_THREAT_INSURGENTS_TEXT"
    ]];
    
    // --- BRIEFING PRINCIPAL ---
    _unit createDiarySubject ["BRIEFING", localize "STR_DIARY_BRIEFING", "\a3\ui_f\data\Map\Markers\Military\flag_ca.paa"];
    
    _unit createDiaryRecord ["BRIEFING", [
        localize "STR_DIARY_SITUATION_TITLE",
        localize "STR_DIARY_SITUATION_TEXT"
    ]];
    
    diag_log format ["[MISSION] Briefing créé pour: %1", name _unit];
};

// ============================================================
// CRÉER LE BRIEFING POUR TOUTES LES UNITÉS JOUABLES
// ============================================================

// Créer le briefing pour toutes les unités jouables (nécessaire pour le switch)
{
    [_x] call _fnc_createBriefingForUnit;
} forEach playableUnits + switchableUnits;

// Si aucune unité jouable (solo), créer pour le player actuel
if (hasInterface && {!isNull player}) then {
    [player] call _fnc_createBriefingForUnit;
};

diag_log "[MISSION] Briefing créé pour toutes les unités jouables";
