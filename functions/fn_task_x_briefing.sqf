/*
    fn_task_x_briefing.sqf
    
    Description:
    Crée le briefing général de la mission dans le journal du joueur (Diary).
    Contient toutes les informations importantes sur la mission Acute Stress Disorder.
    
    Exécution: Client uniquement (hasInterface)
*/

if (!hasInterface) exitWith {};

waitUntil { !isNull player };

// ============================================================
// BRIEFING GÉNÉRAL - ACUTE STRESS DISORDER
// ============================================================
// Note: Les entrées sont ajoutées dans l'ordre inverse car le diary
// affiche les dernières entrées en premier

// --- SYSTÈMES JOUEUR ---
player createDiarySubject ["SYSTEMS", localize "STR_DIARY_SYSTEMS", "\a3\ui_f\data\Map\Markers\Military\unknown_ca.paa"];

player createDiaryRecord ["SYSTEMS", [
    localize "STR_DIARY_SYSTEMS_BROTHERS_TITLE",
    localize "STR_DIARY_SYSTEMS_BROTHERS_TEXT"
]];

player createDiaryRecord ["SYSTEMS", [
    localize "STR_DIARY_SYSTEMS_WEATHER_TITLE",
    localize "STR_DIARY_SYSTEMS_WEATHER_TEXT"
]];

player createDiaryRecord ["SYSTEMS", [
    localize "STR_DIARY_SYSTEMS_VEHICLES_TITLE",
    localize "STR_DIARY_SYSTEMS_VEHICLES_TEXT"
]];

player createDiaryRecord ["SYSTEMS", [
    localize "STR_DIARY_SYSTEMS_ARSENAL_TITLE",
    localize "STR_DIARY_SYSTEMS_ARSENAL_TEXT"
]];

// --- MISSIONS DYNAMIQUES ---
player createDiarySubject ["MISSIONS", localize "STR_DIARY_MISSIONS", "\a3\ui_f\data\Map\Markers\Military\objective_ca.paa"];

player createDiaryRecord ["MISSIONS", [
    localize "STR_DIARY_MISSION_MILITIA_TITLE",
    localize "STR_DIARY_MISSION_MILITIA_TEXT"
]];

player createDiaryRecord ["MISSIONS", [
    localize "STR_DIARY_MISSION_CACHE_TITLE",
    localize "STR_DIARY_MISSION_CACHE_TEXT"
]];

player createDiaryRecord ["MISSIONS", [
    localize "STR_DIARY_MISSION_HOSTAGE_TITLE",
    localize "STR_DIARY_MISSION_HOSTAGE_TEXT"
]];

player createDiaryRecord ["MISSIONS", [
    localize "STR_DIARY_MISSION_BOMB_TITLE",
    localize "STR_DIARY_MISSION_BOMB_TEXT"
]];

player createDiaryRecord ["MISSIONS", [
    localize "STR_DIARY_MISSION_PROTECTION_TITLE",
    localize "STR_DIARY_MISSION_PROTECTION_TEXT"
]];

// --- MENACES ---
player createDiarySubject ["THREATS", localize "STR_DIARY_THREATS", "\a3\ui_f\data\Map\Markers\Military\warning_ca.paa"];

player createDiaryRecord ["THREATS", [
    localize "STR_DIARY_THREAT_MINES_TITLE",
    localize "STR_DIARY_THREAT_MINES_TEXT"
]];

player createDiaryRecord ["THREATS", [
    localize "STR_DIARY_THREAT_INSURGENTS_TITLE",
    localize "STR_DIARY_THREAT_INSURGENTS_TEXT"
]];

// --- BRIEFING PRINCIPAL ---
player createDiarySubject ["BRIEFING", localize "STR_DIARY_BRIEFING", "\a3\ui_f\data\Map\Markers\Military\flag_ca.paa"];

player createDiaryRecord ["BRIEFING", [
    localize "STR_DIARY_SITUATION_TITLE",
    localize "STR_DIARY_SITUATION_TEXT"
]];

diag_log "[MISSION] Briefing créé avec succès";
