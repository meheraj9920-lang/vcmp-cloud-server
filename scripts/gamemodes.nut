// ==============================================================================
// BANGLADESH VICE CITY MULTIPLAYER (VC:MP) - ALL-IN-ONE GAMEMODES SYSTEM
// Modes Included: Team Deathmatch (TDM), Open-World City RPG, Stunt & Freeroam
// ==============================================================================

// --- GLOBAL STATE ---
local CURRENT_GAMEMODE = "City RPG & TDM (Open World)";

// Team Scores
local TDM_Scores = {
    Vercetti = 0,
    Cubans = 0,
    Haitians = 0,
    Police = 0
};

// Player tracking tables
local PlayerKillstreaks = {};
local PlayerJobs = {};
local PlayerTeams = {};
local PlayerGodmode = {};

// --- INITIALIZATION ---
function InitGamemodes() {
    print("[GAMEMODES] Loading Bangladesh VC:MP All-in-One Gamemodes System...");
    print("[GAMEMODES] TDM, City RPG, Jobs, Teleports & Vehicle Spawner Loaded!");
}

// --- ON PLAYER SPAWN ---
function HandleGamemodeSpawn(player) {
    local id = player.ID;
    PlayerKillstreaks[id] <- 0;
    
    if (!(id in PlayerJobs)) {
        PlayerJobs[id] <- "Civilian";
    }
    if (!(id in PlayerTeams)) {
        PlayerTeams[id] <- "Vercetti";
    }

    // Default starting weapons
    player.Health = 100.0;
    player.Armour = 100.0;
    player.SetWeapon(24, 250); // M4
    player.SetWeapon(17, 100); // Colt .45

    MessagePlayer("[#00FFCC]=== Welcome to Bangladesh Vice City Open World ===[#FFFFFF]", player);
    MessagePlayer("[#FFFF00]Mode: " + CURRENT_GAMEMODE + " | Type [#00FF00]/help [#FFFF00]or [#00FF00]/cmds[#FFFFFF]", player);
}

// --- ON PLAYER KILL ---
function HandleGamemodeKill(killer, victim, reason) {
    if (!killer || !victim) return;
    
    local kID = killer.ID;
    local vID = victim.ID;
    
    if (kID in PlayerKillstreaks) PlayerKillstreaks[kID]++;
    else PlayerKillstreaks[kID] <- 1;
    
    PlayerKillstreaks[vID] <- 0;
    
    local streak = PlayerKillstreaks[kID];
    local kTeam = (kID in PlayerTeams) ? PlayerTeams[kID] : "Vercetti";
    
    // Update team score
    if (kTeam in TDM_Scores) {
        TDM_Scores[kTeam]++;
    }
    
    // Kill Message
    Message("[#FF3333][KILL] [#00FFCC]" + killer.Name + " [#FFFFFF]eliminated [#FF9900]" + victim.Name + " [#00FF00](+1 Score for Team " + kTeam + ")!");
    
    // Killstreaks
    if (streak == 3) {
        Message("[#FFCC00][KILLSTREAK] " + killer.Name + " is on a TRIPLE KILL RAMPAGE! (3 Kills)!");
    } else if (streak == 5) {
        Message("[#FF0000][KILLSTREAK] " + killer.Name + " is UNSTOPPABLE! (5 Kills streak)!");
    } else if (streak == 10) {
        Message("[#FF00FF][KILLSTREAK] " + killer.Name + " is a GOD OF WAR! (10 Kills)!");
    }
}

// --- COMMAND HANDLER ---
function HandleGamemodeCommand(player, cmd, text) {
    cmd = cmd.tolower();
    local id = player.ID;

    // ----------------------------------------------------
    // HELP & INFO COMMANDS
    // ----------------------------------------------------
    if (cmd == "help" || cmd == "cmds") {
        MessagePlayer("[#00FFFF]================ SERVER COMMANDS ================[#FFFFFF]", player);
        MessagePlayer("[#FFFF00]TDM Modes: [#00FF00]/team, /tdm, /score, /kit, /weapons[#FFFFFF]", player);
        MessagePlayer("[#FFFF00]City RPG:  [#00FF00]/job, /tp, /heal, /armor, /god, /stats[#FFFFFF]", player);
        MessagePlayer("[#FFFF00]Vehicles:  [#00FF00]/v, /flip, /repair, /fix, /color, /boost[#FFFFFF]", player);
        MessagePlayer("[#00FFFF]Type [#FFFF00]/tp help [#00FFFF]or [#FFFF00]/v help [#00FFFF]for details![#FFFFFF]", player);
        return true;
    }

    if (cmd == "rules") {
        MessagePlayer("[#00FFFF]=== BANGLADESH VICE CITY RULES ===[#FFFFFF]", player);
        MessagePlayer("[#FFFF00]1. Play fair and respect other players.[#FFFFFF]", player);
        MessagePlayer("[#FFFF00]2. Use /team to switch gangs in TDM.[#FFFFFF]", player);
        MessagePlayer("[#FFFF00]3. Enjoy city exploration and deathmatch![#FFFFFF]", player);
        return true;
    }

    if (cmd == "modes") {
        MessagePlayer("[#00FFCC]Current Active Gamemode: [#FFFF00]" + CURRENT_GAMEMODE, player);
        MessagePlayer("[#00FFCC]All modes (TDM, City RPG, Freeroam) are active simultaneously!", player);
        return true;
    }

    // ----------------------------------------------------
    // TDM (TEAM DEATHMATCH) COMMANDS
    // ----------------------------------------------------
    if (cmd == "tdm" || cmd == "score" || cmd == "scores") {
        MessagePlayer("[#00FFFF]========== TDM SCOREBOARD ==========[#FFFFFF]", player);
        MessagePlayer("[#00FFCC]Team Vercetti (Cyan):    [#FFFFFF]" + TDM_Scores.Vercetti + " Kills", player);
        MessagePlayer("[#FFFF00]Team Cuban (Gold):       [#FFFFFF]" + TDM_Scores.Cubans + " Kills", player);
        MessagePlayer("[#FF3333]Team Haitian (Red):      [#FFFFFF]" + TDM_Scores.Haitians + " Kills", player);
        MessagePlayer("[#3399FF]Team Police & SWAT (Blue): [#FFFFFF]" + TDM_Scores.Police + " Kills", player);
        return true;
    }

    if (cmd == "team") {
        if (!text) {
            MessagePlayer("[#FFCC00]Syntax: /team <vercetti / cuban / haitian / cop>[#FFFFFF]", player);
            return true;
        }
        text = text.tolower();
        if (text == "vercetti" || text == "1") {
            PlayerTeams[id] <- "Vercetti";
            player.Colour = RGB(0, 255, 200);
            Message("[#00FFCC]" + player.Name + " joined Team Vercetti (Mafia)!");
        } else if (text == "cuban" || text == "2") {
            PlayerTeams[id] <- "Cubans";
            player.Colour = RGB(255, 215, 0);
            Message("[#FFFF00]" + player.Name + " joined Team Cuban Cartel!");
        } else if (text == "haitian" || text == "3") {
            PlayerTeams[id] <- "Haitians";
            player.Colour = RGB(255, 50, 50);
            Message("[#FF3333]" + player.Name + " joined Team Haitian Gang!");
        } else if (text == "cop" || text == "police" || text == "4") {
            PlayerTeams[id] <- "Police";
            player.Colour = RGB(50, 150, 255);
            Message("[#3399FF]" + player.Name + " joined Team Vice City Police & SWAT!");
        } else {
            MessagePlayer("[#FFCC00]Unknown team. Options: vercetti, cuban, haitian, cop[#FFFFFF]", player);
        }
        return true;
    }

    if (cmd == "kit" || cmd == "weapons") {
        player.Health = 100.0;
        player.Armour = 100.0;
        player.SetWeapon(8, 1);    // Katana
        player.SetWeapon(18, 150); // Python .357
        player.SetWeapon(20, 100); // Spas-12 Shotgun
        player.SetWeapon(24, 500); // M4 Assault Rifle
        player.SetWeapon(28, 50);  // Sniper Rifle
        MessagePlayer("[#00FF00]Full TDM Combat Loadout equipped![#FFFFFF]", player);
        return true;
    }

    // ----------------------------------------------------
    // CITY RPG & JOBS COMMANDS
    // ----------------------------------------------------
    if (cmd == "job") {
        if (!text) {
            MessagePlayer("[#FFCC00]Syntax: /job <cop / taxi / medic / mafia / pilot / civilian>[#FFFFFF]", player);
            return true;
        }
        text = text.tolower();
        if (text == "cop" || text == "police") {
            PlayerJobs[id] <- "Police Officer";
            player.Armour = 100.0;
            player.SetWeapon(3, 1);    // Nightstick
            player.SetWeapon(17, 100); // Pistol
            player.SetWeapon(25, 300); // MP5
            MessagePlayer("[#3399FF]You are now on duty as a Police Officer![#FFFFFF]", player);
        } else if (text == "taxi") {
            PlayerJobs[id] <- "Taxi Driver";
            player.SetWeapon(5, 1);    // Baseball Bat
            MessagePlayer("[#FFFF00]You are now a Kaufman Taxi Driver! Use /v taxi to spawn your cab.[#FFFFFF]", player);
        } else if (text == "medic") {
            PlayerJobs[id] <- "Paramedic";
            player.Health = 100.0;
            MessagePlayer("[#00FF88]You are now a Paramedic! Help and heal city civilians.[#FFFFFF]", player);
        } else if (text == "mafia") {
            PlayerJobs[id] <- "Vercetti Mafia";
            player.SetWeapon(8, 1);    // Katana
            player.SetWeapon(24, 400); // M4
            player.SetWeapon(18, 100); // Python
            MessagePlayer("[#00FFCC]You are now a Vercetti Mafia Enforcer![#FFFFFF]", player);
        } else if (text == "pilot") {
            PlayerJobs[id] <- "Pilot";
            MessagePlayer("[#00CCFF]You are now a Pilot! Use /v heli to spawn a helicopter.[#FFFFFF]", player);
        } else {
            PlayerJobs[id] <- "Civilian";
            MessagePlayer("[#FFFFFF]You are now a Civilian.", player);
        }
        return true;
    }

    // ----------------------------------------------------
    // HEAL, ARMOUR, STATS & GODMODE
    // ----------------------------------------------------
    if (cmd == "heal") {
        player.Health = 100.0;
        MessagePlayer("[#00FF00]Your health has been restored to 100%![#FFFFFF]", player);
        return true;
    }

    if (cmd == "armor" || cmd == "armour") {
        player.Armour = 100.0;
        MessagePlayer("[#00CCFF]Your body armour has been restored to 100%![#FFFFFF]", player);
        return true;
    }

    if (cmd == "god") {
        if (!(id in PlayerGodmode) || !PlayerGodmode[id]) {
            PlayerGodmode[id] <- true;
            player.Health = 1000.0;
            MessagePlayer("[#00FF00]Godmode ENABLED![#FFFFFF]", player);
        } else {
            PlayerGodmode[id] <- false;
            player.Health = 100.0;
            MessagePlayer("[#FF3333]Godmode DISABLED![#FFFFFF]", player);
        }
        return true;
    }

    if (cmd == "stats") {
        local streak = (id in PlayerKillstreaks) ? PlayerKillstreaks[id] : 0;
        local job = (id in PlayerJobs) ? PlayerJobs[id] : "Civilian";
        local team = (id in PlayerTeams) ? PlayerTeams[id] : "Vercetti";
        MessagePlayer("[#00FFFF]=== PLAYER STATS (" + player.Name + ") ===[#FFFFFF]", player);
        MessagePlayer("[#FFFF00]Team: [#00FFCC]" + team + " [#FFFF00]| Job: [#00FFCC]" + job + " [#FFFF00]| Killstreak: [#00FFCC]" + streak, player);
        return true;
    }

    // ----------------------------------------------------
    // CITY TELEPORT COMMANDS (/tp)
    // ----------------------------------------------------
    if (cmd == "tp") {
        if (!text) {
            MessagePlayer("[#00FFFF]Locations: mansion, mall, beach, airport, club, bank, military, rooftop, port", player);
            return true;
        }
        text = text.tolower();
        if (text == "mansion") {
            player.Pos = Vector(-378.1, -579.6, 25.3);
            MessagePlayer("[#00FF00]Teleported to Vercetti Estate (Starfish Island)!", player);
        } else if (text == "mall") {
            player.Pos = Vector(402.6, 102.5, 11.4);
            MessagePlayer("[#00FF00]Teleported to North Point Shopping Mall!", player);
        } else if (text == "beach") {
            player.Pos = Vector(237.7, -1280.5, 11.0);
            MessagePlayer("[#00FF00]Teleported to Ocean Beach (Ocean Drive)!", player);
        } else if (text == "airport") {
            player.Pos = Vector(-1685.0, -933.3, 14.8);
            MessagePlayer("[#00FF00]Teleported to Escobar International Airport!", player);
        } else if (text == "club") {
            player.Pos = Vector(476.9, -60.0, 11.0);
            MessagePlayer("[#00FF00]Teleported to Malibu Nightclub!", player);
        } else if (text == "bank") {
            player.Pos = Vector(-980.4, 118.7, 11.0);
            MessagePlayer("[#00FF00]Teleported to Vice City Downtown Bank!", player);
        } else if (text == "military") {
            player.Pos = Vector(-1721.7, -248.8, 14.8);
            MessagePlayer("[#00FF00]Teleported to Fort Baxter Military Base!", player);
        } else if (text == "rooftop") {
            player.Pos = Vector(-545.8, 694.6, 60.0);
            MessagePlayer("[#00FF00]Teleported to Downtown Skyscraper Rooftop!", player);
        } else if (text == "port") {
            player.Pos = Vector(-251.3, -1360.6, 8.1);
            MessagePlayer("[#00FF00]Teleported to Colonel Cortez Yacht Port!", player);
        } else {
            MessagePlayer("[#FFCC00]Unknown destination! Try: mansion, mall, beach, airport, club, bank, military, rooftop", player);
        }
        return true;
    }

    // ----------------------------------------------------
    // VEHICLE COMMANDS (/v, /flip, /repair, /boost)
    // ----------------------------------------------------
    if (cmd == "v" || cmd == "veh" || cmd == "car") {
        if (!text) {
            MessagePlayer("[#00FFFF]Vehicles: infernus, cheetah, banshee, stinger, phoenix, pcj, sanchez, heli, hunter, tank, taxi, cop", player);
            return true;
        }
        text = text.tolower();
        local modelId = 130; // default infernus

        if (text == "infernus" || text == "lambo") modelId = 130;
        else if (text == "cheetah") modelId = 141;
        else if (text == "banshee") modelId = 142;
        else if (text == "stinger") modelId = 135;
        else if (text == "phoenix") modelId = 162;
        else if (text == "pcj" || text == "bike") modelId = 191;
        else if (text == "sanchez") modelId = 194;
        else if (text == "faggio") modelId = 192;
        else if (text == "heli" || text == "maverick") modelId = 146;
        else if (text == "hunter") modelId = 147;
        else if (text == "sparrow") modelId = 164;
        else if (text == "tank" || text == "rhino") modelId = 162;
        else if (text == "taxi") modelId = 143;
        else if (text == "cop" || text == "police") modelId = 146;
        else {
            try { modelId = text.tointeger(); } catch(e) { modelId = 130; }
        }

        local v = CreateVehicle(modelId, player.Pos.x + 2.0, player.Pos.y + 2.0, player.Pos.z + 1.0, player.Angle);
        if (v) {
            MessagePlayer("[#00FF00]Vehicle spawned successfully![#FFFFFF]", player);
        }
        return true;
    }

    if (cmd == "flip") {
        if (player.Vehicle) {
            local angle = player.Vehicle.Angle;
            player.Vehicle.Pos.z += 2.0;
            player.Vehicle.Angle = angle;
            MessagePlayer("[#00FF00]Vehicle flipped upright![#FFFFFF]", player);
        } else {
            MessagePlayer("[#FF3333]You are not in a vehicle![#FFFFFF]", player);
        }
        return true;
    }

    if (cmd == "repair" || cmd == "fix") {
        if (player.Vehicle) {
            player.Vehicle.Health = 1000.0;
            MessagePlayer("[#00FF00]Vehicle repaired to 100%![#FFFFFF]", player);
        } else {
            MessagePlayer("[#FF3333]You are not in a vehicle![#FFFFFF]", player);
        }
        return true;
    }

    if (cmd == "boost" || cmd == "nos") {
        if (player.Vehicle) {
            player.Vehicle.Speed = player.Vehicle.Speed * 1.8;
            MessagePlayer("[#00FFCC]NITRO BOOST ACTIVATED![#FFFFFF]", player);
        } else {
            MessagePlayer("[#FF3333]You are not in a vehicle![#FFFFFF]", player);
        }
        return true;
    }

    // ----------------------------------------------------
    // WEAPONS COMMAND (/w)
    // ----------------------------------------------------
    if (cmd == "w" || cmd == "weapon") {
        if (!text) {
            MessagePlayer("[#00FFFF]Weapons: m4, sniper, minigun, rpg, katana, shotgun, python, flamethrower, all", player);
            return true;
        }
        text = text.tolower();
        if (text == "m4") { player.SetWeapon(24, 500); MessagePlayer("[#00FF00]Given M4 Assault Rifle!", player); }
        else if (text == "sniper") { player.SetWeapon(28, 100); MessagePlayer("[#00FF00]Given Sniper Rifle!", player); }
        else if (text == "minigun") { player.SetWeapon(33, 2000); MessagePlayer("[#00FF00]Given Gatling Minigun!", player); }
        else if (text == "rpg" || text == "rocket") { player.SetWeapon(30, 50); MessagePlayer("[#00FF00]Given Rocket Launcher!", player); }
        else if (text == "katana") { player.SetWeapon(8, 1); MessagePlayer("[#00FF00]Given Katana Sword!", player); }
        else if (text == "shotgun") { player.SetWeapon(20, 150); MessagePlayer("[#00FF00]Given Spas-12 Shotgun!", player); }
        else if (text == "python") { player.SetWeapon(18, 150); MessagePlayer("[#00FF00]Given Colt Python .357!", player); }
        else if (text == "all") {
            player.SetWeapon(8, 1);
            player.SetWeapon(18, 200);
            player.SetWeapon(20, 150);
            player.SetWeapon(24, 800);
            player.SetWeapon(28, 100);
            player.SetWeapon(30, 50);
            player.SetWeapon(33, 1000);
            MessagePlayer("[#00FF00]Ultimate Weapon Arsenal given!", player);
        }
        return true;
    }

    return false; // Not handled by gamemodes
}
