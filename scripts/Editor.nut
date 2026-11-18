/*
-				Map Editor Script
-				Created By:
-				Doom_Killer
-
-				Version:
-				1.2.5
-
-				Credits:
-				SLC - For providing a better SQLite plugin.
-				Juppi - Free Camera Movement Script.
-
-				Enjoy your mapping, if you find any bugs, report them on VCMP forum on the script's topic.
-*/
/*-				Changelogs	
-*/
/*
-				Changelog - v1.1
-				► Changed data-type for rotations x, y, z to FLOAT.
-
-				Changelog - v1.2	
-				► Improved queries to reduce memory leakage.
-				► Added Page UP | DOWN key in keys list.
-				
-				Changelog - v1.2.1
-				► Fixed error on location returning.
-				
-				Changelog - v1.2.2
-				► Fixed error on newmap, unable to release sqlite data.
-				► Fixed error when not sending any text argument in addobject.
-
-				Changelog - v1.2.3
-				► Fixed errors.
-				► Fixed crash on loading map.
-				► Fixed some other things regarding errors and crashes.
-
-				Changelog - v1.2.4
-				► Now with free camera view! /cam to toggle!
-
-				Changelog - v1.2.5
-				► Added text for Currently Holding Object Name and Model.
-				► Added Auto Saving for maps, default auto save every minute.
-				► Added autosave command! /autosave to toggle.
-				
-				Changelog - v1.2.6
-				► Map menu is now available! use /addobject without any id to enter map menu and select map while previewing!
-				► Press CTRL to select & create the object.
-
-				Changelog - v1.2.7
-				► Exports are now exported in a text file without any [SCRIPT] Tags, easy to add objects in script now!
-
-				Changelog - v1.2.8
-				► Fixed locations as the database was bugged
-				► Added /settime [hour] [minute] and /setweather [id] to set weather & time.
-				► Added object control in object selection menu, use page up/down to move object higher/lower and arrow up/down to bring it near or far.
-				► Added commands to get a list of all maps & locations. /getmaps & /getlocs
-				► Changed the location of object selection menu
-				► Added /view command to switch immediately to any object ID supplied when in object selection menu
-				► Added commands /deletemap [name] and /deleteloc [name] to delete any map or location from database
-				
-   			Changelog - v1.2.9
-    			► Now supports XML outputs!
-    			► Fixed /desall, not removing all objects.
-   			
-   			Changelog - v1.3
-    			► Updated to latest server version
-    			► Fixed a few very minor bugs
-    			► Added client-sided gui labels
-   			
-   			Changelog - v1.3.2
-    			► Fixed /desall @ Thanks to Omar for pointint it out!
-    			► Fixed /closemap working as savemap; Note that if you map but didn't save and did closemap, changes will be lost!
-    			► Added /selectobject || /editobject to edito the object ID specified; Useful for objects which can't be shot/collided @ Idea by [Serious]Sam.
-				► Added /objects || /allobjects to get a list of every object created with its ID and model @ Idea by [Serious]Sam.
*/

// =========================================== CONSTANTS ==============================================

const Motion_Speed = 100; // You should not touch this unless you know what you're doing.
const cAutoSaveTime = 60000; // Auto save every minute, you can change the time here.

// =========================================== CLASES =================================================

class PlayerData
{
	MapDelete = false;
	PositionMode = false;
	Speed = "normal";
	Editing = false;
	Holding = false;
	Motion = null;
	LastKey = null;
	CTRL = false;
	car = null;
	txdObject = null;
	// Object selection.
	lastPos = null;
	viewObject = null;
	viewModel = 500;
	motionTimer = null;
}

// =========================================== LOCALS ==================================================

local txdCurrentMap;
local txdTotalObjects;
local autoSave = true;
local mapSave = { Saved = false, unsavedObjects = [] };

local C_PLOC = Vector( -1789.84, -62.7762, 35.4862 ); /*Vector( -1351.37, 1275.35, 91.1706 ); //Old */
local C_VIEWLOC = Vector( -1903.7, -17.8781, 34.7495 ); /*Vector( -1372.88, 1282.51, 83.8704 ); // Old */

// =========================================== SERVER EVENTS ===========================================

/*
function onServerStart()
{
}

function onServerStop()
{
}
*/

function onScriptLoad()
{
	// =========================================== ARRAYS ==============================================
	pData <- array( GetMaxPlayers(), null );
	Object <- array( GetMaxPlayers(), null );
	
	// =========================================== DATABASE ============================================
	Maps <- ConnectSQL( "scripts/Maps.sqlite" );
	db <- ConnectSQL( "scripts/locations.sqlite" );
	
	// =========================================== GLOBAL ==============================================
	CurrentMap <- "";
	objCreated <- 0;
	
	// =========================================== FILES ===============================================
	dofile( "scripts/FileHandler.addon", true );
	dofile( "scripts/Freeview.addon", true );
	onCamScriptLoad();
	
	// =========================================== BINDS ===============================================
	enter <- BindKey( true, 0x0D, 0, 0 );
	del <- BindKey( true, 0x2E, 0, 0 );
	backspace <- BindKey( true, 0x08, 0, 0 );
	R <- BindKey( true, 0x52, 0, 0 );
	one <- BindKey( true, 0x31, 0, 0 );
	two <- BindKey( true, 0x32, 0, 0 );
	ctrl <- BindKey( true, 0x11, 0, 0 );
	c <- BindKey(true, 0x43, 0, 0 );
	PageUp <- BindKey( true, 0x21, 0, 0 );
	PageDown <- BindKey( true, 0x22, 0, 0 );
	ArrowUp <- BindKey( true, 0x26, 0, 0 );
	ArrowDown <- BindKey( true, 0x28, 0, 0 );
	ArrowLeft <- BindKey( true, 0x25, 0, 0 );
	ArrowRight <- BindKey( true, 0x27, 0, 0 );
	
	// =========================================== TIMERS ==============================================
	NewTimer( "AutoSave", cAutoSaveTime, 0 );
	
	// =========================================== PRINTS ==============================================
	print( "Doom_Killer's Map Editor successfully started!" );
	print( "Editor successfully running! ");
}

function onScriptUnload()
{

}

// =========================================== PLAYER EVENTS ===========================================

function onPlayerJoin( player )
{
	onCamPlayerJoin( player )
	pData[ player.ID ] = PlayerData( player.Name );
	Object[ player.ID ] = null;
	MessagePlayer( "[#ffffff][Server]: [#00CC00]Welcome to Map Editor!", player );
}

function onPlayerPart( player, reason )
{
	onCamPlayerPart( player, reason )
	pData[ player.ID ].Editing = false;
	pData[ player.ID ] = null;
	Object[ player.ID ] = null;
}

function onPlayerSpawn( player )
{
	NewTimer( "ClientRender", 1000, 0, player.ID );
	
	player.Pos = Vector( -335.591, -524.865, 12.7615 );
	player.Immunity = 31;
	player.GiveWeapon( 32, 99999 );
	
	MessagePlayer( "[#00CC00][KEYS]: [#FFFFFF]These are the keys used to interact with the editor!", player );
	MessagePlayer( "[#00CC00][KEYS]: [#FFFFFF]Arrow LEFT | RIGHT | UP | DOWN - Movement & Rotations", player );
	MessagePlayer( "[#00CC00][KEYS]: [#FFFFFF]Page UP | DOWN - Z Movement/Rotation.", player );
	MessagePlayer( "[#00CC00][KEYS]: [#FFFFFF]CTRL + C - Clone Object | R - Reset Object rotations | Delete - Delete object", player );
	MessagePlayer( "[#00CC00][KEYS]: [#FFFFFF]1 - Switch between Rotation & Position Mode | 2 - Speed variation", player );
	MessagePlayer( "[#00CC00][KEYS]: [#FFFFFF]Backspace - Stop controlling an object", player );
	MessagePlayer( "[#00CC00][COMMAND]: [#FFFFFF]/cam - To enable/disable free-view.", player );
}

function onPlayerCommand( player, cmd, text )
{
	if( cmd != "cam" && pCamera[ player.ID ].IsEnabled() ) return MessagePlayer( "[#00CC00][ERROR]: [#FFFFFF]Other commands are disabled when in camera mode!", player );
	
	if ( cmd == "cam" )
	{
		if( pData[ player.ID ].lastPos != null )
		{
			return null;
		}
		else if ( !pCamera[ player.ID ].IsEnabled() )
		{
			pCamera[ player.ID ].Enable();
			pData[ player.ID ].Editing = false;
			Object[ player.ID ] = null;
			MessagePlayer( "[#00CC00][CAM]: [#ffffff]Free view camera [#00CC00]enabled[#ffffff]. Type '/cam' to disable.", player );
		}
		else
		{
			pCamera[ player.ID ].Disable();
			MessagePlayer( "[#00CC00][CAM]: [#ffffff]Free view camera [#00CC00]disabled[#ffffff].", player );
		}
	}
	
	else if( cmd == "s" )
	{
		if( !text ) { print( "Pos: " + player.Pos ); return MessagePlayer( "Position saved!", player ); }
		print( "Pos: " + player.Pos + " //" + text );
		MessagePlayer( "Position " + text + "saved!", player );
	}
	
	else if( cmd == "newmap" )
	{
		if( text && CurrentMap == "" )
		{
			if( text == "default" ) return MessagePlayer( "[#00CC00][ERROR]: [#FFFFFF]The name [#00CC00]default [#FFFFFF]cannot be used to create a map", player );
			local check_map;
			try { check_map = QuerySQL( Maps, "SELECT * FROM sqlite_master WHERE type='table' AND name='" + CurrentMap.tolower() + "'"); } catch( e ) return MessagePlayer( "[#00CC00][MAP]: [#ffffff]A map with that name already exists!", player );
			QuerySQL( Maps, "CREATE TABLE '" + text.tolower() + "'( model INT, x INT, y INT, z INT, rotx FLOAT, roty FLOAT, rotz FLOAT )" );
			CurrentMap = "" + text.tolower();
			Message( "[#ffffff][New-Map]: [#00CC00]A new map [#ffffff]" + CurrentMap + " [#00CC00]was started by [#ffffff]" + player.Name + "." );
			if( check_map != null ) FreeSQLQuery( check_map );
		}
		else if( text && CurrentMap != "" )
		{ 
			Message( "[#00CC00][NEWMAP]: [#ffffff]The map [#00CC00]" + CurrentMap + " [#ffffff]is still loaded, please close this map before proceeding. /savemap to save & close!" );
		}
	}
	
	else if( cmd == "addobject" )
	{
		if( CurrentMap == "" ) return MessagePlayer( "[#00CC00][MAP]: [#ffffff]You must open a map to add objects!", player );
		else if( !text )
		{
			pData[ player.ID ].Editing = false;
			Object[ player.ID ] = null;
			MessagePlayer( "[#00CC00][EDIT]: [#ffffff]You have finished editing the object.", player );
			player.IsFrozen = true;
			player.World = 100 + player.ID;
			pData[ player.ID ].viewObject = CreateObject( pData[ player.ID ].viewModel, player.World, C_VIEWLOC.x, C_VIEWLOC.y, C_VIEWLOC.z, 255 );
			pData[ player.ID ].motionTimer = NewTimer( "onObjectRender", 100, 0, player.ID );
			pData[ player.ID ].lastPos = player.Pos;
			player.Pos = C_PLOC; //Vector( -1351.37, 1275.35, 91.1706 );
			player.SetCameraPos( C_PLOC, C_VIEWLOC ); //( Vector( -1351.37, 1275.35, 91.1706 ), Vector( -1372.88, 1282.51, 83.8704 ) );
		}
		else if( text && text != "" && IsNum( text ) )
		{
			Object[ player.ID ] = CreateObject( text.tointeger(), 0, player.Pos.x, player.Pos.y, player.Pos.z, 255 );
			Object[ player.ID ].TrackingShots = true;
			objCreated++;
			player.Pos = Vector( player.Pos.x, player.Pos.y, player.Pos.z + 3 );
			pData[ player.ID ].Editing = true;
			mapSave.Saved = false;
			mapSave.unsavedObjects.append( Object[ player.ID ] );
			Message( "[#00CC00][MAP]: [#ffffff]Created object " + text );
		}
	}
	
	else if( cmd == "view" )
	{
		if( !text ) return MessagePlayer( "[#00CC00][ERROR]: [#FFFFFF]/view [Object ID]", player );
		else if( text && !IsNum( text ) ) return MessagePlayer( "[#00CC00][ERROR]: [#FFFFFF]/view [Object ID] [ Use Number! ]", player );
		else if( text && IsNum( text ) && pData[ player.ID ].viewObject != null ) {
			pData[ player.ID ].viewObject.Delete();
			pData[ player.ID ].viewObject = null;
			pData[ player.ID ].viewModel = text.tointeger();
			pData[ player.ID ].viewObject = CreateObject( pData[ player.ID ].viewModel, player.World, C_VIEWLOC.x, C_VIEWLOC.y, C_VIEWLOC.z, 255 );
		}
		else if( pData[ player.ID ].viewObject == null ) return MessagePlayer( "[#00CC00][ERROR]: [#FFFFFF]You must be in map selection menu to use this!", player );
	}
	
	else if( cmd == "map" )
	{
		if( CurrentMap != "" ) Message( "[#00CC00][MAP]: [#ffffff]" + CurrentMap );
		else Message( "[#00CC00][MAP]: [#ffffff]None" );
	}
	
	else if( cmd == "settime" )
	{
		if( !text ) return MessagePlayer( "[#00CC00][ERROR]: [#ffffff]/settime [Hour] [Minute]", player );
		local arrayData = split( text, " " );
		if( arrayData.len() < 2 ) return MessagePlayer( "[#00CC00][ERROR]: [#ffffff]/settime [Hour] [Minute]", player );
		else if( !IsNum( arrayData[0] ) ) return MessagePlayer( "[#00CC00][ERROR]: [#ffffff]/settime [Hour] [Minute]", player );
		else if( !IsNum( arrayData[1] ) ) return MessagePlayer( "[#00CC00][ERROR]: [#ffffff]/settime [Hour] [Minute]", player );
		else {
			SetTime( arrayData[0].tointeger(), arrayData[1].tointeger() );
			Message( "[#00CC00][TIME]: [#FFFFFF]Time has been set to " + arrayData[0] + ":" + arrayData[1] + " [#FFFFFF]by " + player.Name + "!" );
		}
	}
	
	else if( cmd == "setweather" )
	{
		if( !text ) return MessagePlayer( "[#00CC00][ERROR]: [#ffffff]/setweather [ID]", player );
		else if( !IsNum( text ) ) return MessagePlayer( "[#00CC00][ERROR]: [#ffffff]/setweather [ID]", player );
		else {
			SetWeather( text.tointeger() );
			Message( "[#00CC00][WEATHER]: [#FFFFFF]Weather has been set to " + text.tointeger() + " [#FFFFFF]by " + player.Name + "!" );
		}
	}
	
	else if( cmd == "savemap" )
	{
		if( CurrentMap != "" )
		{
			if( objCreated == 0 )
			{
				QuerySQL( Maps, "DROP TABLE " + CurrentMap.tolower() + "" );
				CurrentMap = "";
				return MessagePlayer( "[#ffffff][Map]: [#00CC00]The map has been [#ffffff]closed & deleted [#00CC00]as no objects were created.", player );
			}
			
			QuerySQL( Maps, "DELETE FROM '" + CurrentMap.tolower() + "'" );
			pData[ player.ID ].Editing = false;
			for( local i = 0; i < objCreated; i++ )
			{
				local obj = FindObject(i);
				if( obj )
				{
					QuerySQL( Maps, "INSERT INTO '" + CurrentMap.tolower() + "' VALUES ( '" + obj.Model + "', '" + obj.Pos.x + "', '" + obj.Pos.y + "', '" + obj.Pos.z + "', '" + obj.RotationEuler.x + "', '" + obj.RotationEuler.y + "', '" + obj.RotationEuler.z + "');" );
				}
			}
			mapSave.Saved = true;
			mapSave.unsavedObjects = [];
			Message( "[#00CC00][MAP]: [#ffffff]" + player.Name + " has saved the map" );
		}
	}
	
	else if( cmd == "closemap" )
	{
		if( CurrentMap != "" )
		{
			if( objCreated == 0 )
			{
				QuerySQL( Maps, "DROP TABLE " + CurrentMap.tolower() );
				CurrentMap = "";
				return MessagePlayer( "[#ffffff][Map]: [#00CC00]The map has been [#ffffff]closed & deleted [#00CC00]as no objects were created.", player );
			}
			
			pData[ player.ID ].Editing = false;
			Object[ player.ID ] = null;
				
			if( mapSave.Saved ) {
				for( local i = 0; i < objCreated; i++ )
				{
					local obj = FindObject(i);
					if( obj ) obj.Delete();
				}
			}
			else {
				//print( "Unsaved Objects -> " + mapSave.unsavedObjects.len() );
				//print( "Objects Created -> " + objCreated );
				
				if( mapSave.unsavedObjects.len() == objCreated ) { // If none of the objects were saved at all after map creations
					foreach( index, value in mapSave.unsavedObjects ) {
						if( !value ) continue;
						value.Delete();
						objCreated--;
					}
					QuerySQL( Maps, "DROP TABLE " + CurrentMap.tolower() );
					CurrentMap = "";
					objCreated = 0;
					return MessagePlayer( "[#ffffff][Map]: [#00CC00]The map has been [#ffffff]closed & deleted [#00CC00]as the created objects were not saved!", player );
				}
				else {
					for( local i = 0; i < objCreated; i++ )
					{
						local obj = FindObject(i);
						if( obj ) obj.Delete();
						objCreated--;
					}
				}
			}
			
			CurrentMap = "";
			objCreated = 0;
			Message( "[#00CC00][MAP]: [#ffffff]" + player.Name + " has closed the map" );
		}
	}
	
	else if( cmd == "exportmap" )
	{
		if( CurrentMap != "" )
		{
			if( objCreated == 0 )
			{
				QuerySQL( Maps, "DROP TABLE " + CurrentMap.tolower() + "" );
				CurrentMap = "";
				return MessagePlayer( "[#ffffff][Map]: [#00CC00]The map has been [#ffffff]closed & deleted [#00CC00]as no objects were created.", player );
			}
			
			QuerySQL( Maps, "DELETE FROM '" + CurrentMap.tolower() + "'" );
			pData[ player.ID ].Editing = false;
			local mapData = "";
			setXMLBase( CurrentMap );
			for( local i = 0; i < objCreated; i++ )
			{
				local obj = FindObject(i);
				if( obj )
				{
					QuerySQL( Maps, "INSERT INTO '" + CurrentMap.tolower() + "' VALUES ( '" + obj.Model + "', '" + obj.Pos.x + "', '" + obj.Pos.y + "', '" + obj.Pos.z + "', '" + obj.RotationEuler.x + "', '" + obj.RotationEuler.y + "', '" + obj.RotationEuler.z + "');" );
					print( "CreateObject( " + obj.Model + ", 1, Vector( " + obj.Pos.x + ", " + obj.Pos.y + ", " + obj.Pos.z + "), 255 ).RotateByEuler( Vector( " + obj.RotationEuler.x + ", " + obj.RotationEuler.y + ", " + obj.RotationEuler.z + "), 0);" );
					mapData = mapData + "CreateObject( " + obj.Model + ", 1, Vector( " + obj.Pos.x + ", " + obj.Pos.y + ", " + obj.Pos.z + "), 255 ).RotateByEuler( Vector( " + obj.RotationEuler.x + ", " + obj.RotationEuler.y + ", " + obj.RotationEuler.z + "), 0);\r\n"
					addXMLObjectItem( CurrentMap, obj.ID, obj.Model, obj.Pos.x, obj.Pos.y, obj.Pos.z, obj.Rotation.x, obj.Rotation.y, obj.Rotation.z, -obj.Rotation.w );
					//print( "-- DEBUG -- " + obj.RotationEuler );
					//print( "-- DEBUG -- " + obj.Rotation );
					obj.Delete();
				}
			}
			setXMLEnd( CurrentMap );
			exportMapToFile( CurrentMap, mapData );
			CurrentMap = "";
			objCreated = 0;
			Object[ player.ID ] = null;
			Message( "[#00CC00][MAP]: [#ffffff]" + player.Name + " has exported the map!" );
		}
	}
	
	else if( cmd == "allmaps" || cmd == "maps" || cmd == "getmaps" )
	{
		local listQuery = QuerySQL( Maps, "SELECT * FROM sqlite_master WHERE type='table'" );
		local count = 0;
		while ( GetSQLNextRow( listQuery ) ) {
			count++;
			MessagePlayer( "[#00CC00][MAP#" + count + "]: [#FFFFFF]" + GetSQLColumnData( listQuery, 1 ), player );
		}
		if( count == 0 ) return MessagePlayer( "[#00CC00][ERROR]: [#FFFFFF]No maps to list!", player );
	}
	
	else if( cmd == "alllocs" || cmd == "locs" || cmd == "getlocs" )
	{
		local listQuery = QuerySQL( db, "SELECT * FROM `Gotoloc`" );
		local count = 0;
		while ( GetSQLNextRow( listQuery ) ) {
			count++;
			MessagePlayer( "[#00CC00][LOC#" + count + "]: [#FFFFFF]" + GetSQLColumnData( listQuery, 0 ), player );
		}
		FreeSQLQuery( listQuery );
		if( count == 0 ) return MessagePlayer( "[#00CC00][ERROR]: [#FFFFFF]No locations to list!", player );
	}
	
	else if( cmd == "deletemap" )
	{
		if( CurrentMap != "" ) return MessagePlayer( "[#00CC00][ERROR]: [#ffffff]Please close any opened maps before proceeding!", player );
		else if( !text ) return MessagePlayer( "[#00CC00][ERROR]: [#ffffff]Enter map name to delete!", player );
		else {
			local map;
			try {
				map = QuerySQL( Maps, "SELECT * FROM '" + text.tolower() + "'" );
			}
			catch( error ) return MessagePlayer( "[#00CC00][ERROR]: [#ffffff]Map not found!", player );
			
			if( map != null ) FreeSQLQuery( map );
			QuerySQL( Maps, "DROP TABLE " + text.tolower() );
			
			Message( "[#00CC00][Map]: [#FFFFFF]'" + text.tolower() + "' has been [#00CC00]deleted [#FFFFFF]by " + player.Name + "!" );
		}
	}
	
	else if( cmd == "deleteloc" )
	{
		if( !text ) return MessagePlayer( "[#00CC00][ERROR]: [#ffffff]Enter location name to delete!", player );
		else if ( text && !FindLoc( text ) ) MessagePlayer( "[#00CC00][ERROR]: [#ffffff]Location not found!", player );
		else if ( text && FindLoc( text ) ) {
			QuerySQL( db, "DELETE FROM `Gotoloc` WHERE Name='" + text + "'" );
			Message( "[#00CC00][LOC]: [#FFFFFF]'" + text + "' has been [#00CC00]deleted [#FFFFFF]by " + player.Name + "!" );
		}
	}
	
	else if( cmd == "loadmap" )
	{
		if( CurrentMap != "" ) MessagePlayer( "[#00CC00][MAP]: [#ffffff]A map is already opened!", player );
		else
		{
			if( !text ) return MessagePlayer( "[#00CC00][MAP]: [#ffffff]Enter map name to load!", player );
			else
			{
				local map;
				try
				{
					map = QuerySQL( Maps, "SELECT * FROM '" + text.tolower() + "'" );
				}
				catch( e ) return MessagePlayer( "[#00CC00][ERROR]: [#ffffff]Map not found!", player );
				
				if( map == null ) {
					QuerySQL( Maps, "DROP TABLE " + text.tolower() );
					return MessagePlayer( "[#00CC00][ERROR]: [#ffffff]Map not found!", player );
					//return MessagePlayer( "[#00CC00][ERROR]: [#ffffff]Map '" + text.tolower() + "' was deleted since it was corrupted!", player );
				}
				
				do
				{
					local model = GetSQLColumnData( map, 0 );
					local x = GetSQLColumnData( map, 1 );
					local y = GetSQLColumnData( map, 2 );
					local z = GetSQLColumnData( map, 3 );
					local rotx = GetSQLColumnData( map, 4 );
					local roty = GetSQLColumnData( map, 5 );
					local rotz = GetSQLColumnData( map, 6 );
					local _obj = CreateObject( model, 1, x, y, z, 255 );
					_obj.RotationEuler.x = rotx.tofloat();
					_obj.RotationEuler.y = roty.tofloat();
					_obj.RotationEuler.z = rotz.tofloat();
					objCreated++;
					_obj.TrackingShots = true;
					Object[ player.ID ] = null;
					//Object[ player.ID ] = _obj;
					//Message( "[#00CC00][LOAD]: [#ffffff]Created Object at " + x + ", " + y + ", z with rotation " + rotx + ", " + roty + ", " + rotz );
				}
				while ( GetSQLNextRow( map ) );
				FreeSQLQuery( map );
			}
			CurrentMap = "" + text.tolower(); 
			Message( "[#00CC00][MAP]: [#ffffff]" + text + " [#00CC00]has been loaded by [#ffffff]" + player.Name + "." );
		}
	}	
	
	else if( cmd == "desall" )
	{
		if( CurrentMap != "" ) RemoveObjects( CurrentMap );
	}
	
	else if( cmd == "objects" || cmd == "allobjects" ) {
		if( objCreated == 0 ) return MessagePlayer( "[#00CC00][ERROR]: [#FFFFFF]There are no objects to list!", player );
		for( local i = 0; i < objCreated; ++i ) {
			local obj = FindObject( i );
			if( obj ) {
				MessagePlayer( "[#00CC00][OBJECT #" + obj.ID + "]: [#FFFFFF]Object ID: [#00CC00]" + obj.ID + "[#FFFFFF] | Object Model: [#00CC00]" + obj.Model, player );
			}
		}
	}
	
	else if( cmd == "selectobject" || cmd == "editobject" ) {
		if( !text ) return MessagePlayer( "[#00CC00][ERROR]: [#FFFFFF]/" + cmd + " [Object ID]", player );
		else if( text && !IsNum( text ) ) return MessagePlayer( "[#00CC00][ERROR]: [#FFFFFF]ID must be positive integer!", player );
		text = text.tointeger();
		local object = FindObject( text );
		if( !object ) return MessagePlayer( "[#00CC00][ERROR]: [#FFFFFF]Invalid object ID!", player );
		onObjectShot( object, player, WEP_M60 );
	}
	
	else if( cmd == "delobj" )
	{
		if( !pData[ player.ID ].MapDelete )
		{
			pData[ player.ID ].MapDelete = true;
			MessagePlayer( "[#00CC00][DELETE]: [#ffffff]Map delete mode is [#00ff00]ON[#ffffff]! Touch object to delete it!", player );
			EnableBumpTracks();
		}
		
		else if( pData[ player.ID ].MapDelete )
		{
			pData[ player.ID ].MapDelete = false;
			MessagePlayer( "[#00CC00][DELETE]: [#ffffff]Map delete mode is [#ff0000]OFF[#ffffff]!", player );
			DisableBumpTracks();
		}
	}
	
	else if( cmd == "car" )
	{
		if( text && IsNum( text ) )
		{
			local veh = text.tointeger();
			if( veh >= 130 && veh <= 236 )
			{
				local pPos = player.Pos;
				if( pData[ player.ID ].car != null ) pData[ player.ID ].car.Remove();
				pData[ player.ID ].car = CreateVehicle( veh, player.World, player.Pos, player.Angle, -1, -1 );
				player.Vehicle = pData[ player.ID ].car;
				ClientMessage( "[#00CC00][CAR]: [#ffffff]Your vehicle has been spawned", player, 255,255,255 );
			}
			else ClientMessage( "[#00CC00][ERROR]: [#ffffff]Invalid vehicle ID", player, 255,255,255 );
		}
				
		else if( text && !IsNum( text ) )
		{
			local veh = GetVehicleModelFromName( text );
			if( veh >= 130 && veh <= 236 )
			{
				local pPos = player.Pos;
				if( pData[ player.ID ].car != null ) pData[ player.ID ].car.Remove();
				pData[ player.ID ].car = CreateVehicle( veh, player.World, player.Pos, player.Angle, -1, -1 );
				player.Vehicle = pData[ player.ID ].car;
				ClientMessage( "[#00CC00][CAR]: [#ffffff]Your vehicle has been spawned", player, 255,255,255 );
			}
		}
	}
	
	else if( cmd == "exec" ) 
	{
		if( !text ) ClientMessage( "[#00CC00][ERROR]: [#ffffff]/exec [Code]", player, 255,255,255 );
		else
		{
			try
			{
				local script = compilestring( text );
				script();
				MessagePlayer( "Done", player );
			}
			catch(e) MessagePlayer( "Error: " + e, player);
		}
	}
	
	else if( cmd == "autosave" )
	{
		switch( autoSave )
		{
			case true:
			autoSave = false;
			Message( "[#00CC00][AUTO-SAVE]: [#FFFFFF]Auto-Save has been [#ff0000]disabled[#FFFFFF] by " + player.Name );
			break;
			
			case false:
			autoSave = true;
			Message( "[#00CC00][AUTO-SAVE]: [#FFFFFF]Auto-Save has been [#00ff00]enabled[#FFFFFF] by " + player.Name );
			break;
		}
	}
	
	else if ( cmd == "saveloc" )
	{
		if ( !text ) MessagePlayer( "[#00CC00][ERROR]: [#ffffff]/saveloc [Location]", player );
		else if ( !player.IsSpawned ) MessagePlayer( "[#00CC00][ERROR]: [#ffffff]You are not spawned!", player );
        else if ( FindLoc( text ) ) MessagePlayer( "[#00CC00][ERROR]: [#ffffff]Location name in use!", player );
        else
        {
			QuerySQL( db, "INSERT INTO Gotoloc (Name, x, y, z, Creator) values ( '" + text + "', '" + player.Pos.x + "', '" + player.Pos.y + "', '" + player.Pos.z + "', '" + player.Name + "' )" );
            MessagePlayer( "[#00CC00][LOC]: [#FFFFFF]Location: " + text + " Saved!", player );                                       
        }         
	}
	
	else if ( cmd == "gotoloc" )
    {          
		if ( !text ) MessagePlayer( "[#00CC00][ERROR]: [#ffffff]/gotoloc [Location]", player );
		else if ( !player.IsSpawned ) MessagePlayer( "[#00CC00][ERROR]: [#ffffff]You are not spawned!", player );
		else
        {
			local q = QuerySQL( db, "SELECT x, y, z, Creator FROM Gotoloc WHERE Name = '"+ text +"'" );
			if ( q )
			{
				local x = GetSQLColumnData( q, 0 ), y = GetSQLColumnData( q, 1 ), z =GetSQLColumnData( q, 2 ), Creator = GetSQLColumnData( q, 3 );
				player.Pos = Vector( x, y, z );
			}
			else MessagePlayer("[#00CC00][ERROR]: [#ffffff]Invalid location!", player);
			if( q != null ) FreeSQLQuery( q );
        }
    }
	return 1;
}

function AutoSave()
{
	if( autoSave && CurrentMap != "" && objCreated > 1 )
	{
		QuerySQL( Maps, "DELETE FROM '" + CurrentMap.tolower() + "'" );
		for( local i = 0; i < objCreated; i++ )
		{
			local obj = FindObject(i);
			if( obj )
			{
				QuerySQL( Maps, "INSERT INTO '" + CurrentMap.tolower() + "' VALUES ( '" + obj.Model + "', '" + obj.Pos.x + "', '" + obj.Pos.y + "', '" + obj.Pos.z + "', '" + obj.RotationEuler.x + "', '" + obj.RotationEuler.y + "', '" + obj.RotationEuler.z + "');" );
			}
		}
		Message( "[#00CC00][AUTO-SAVE]: [#ffffff]Map has been saved!" );
	}
	else return;
}

function ClientRender( idPlayer )
{
	local player = FindPlayer( idPlayer );
	if( player )
	{
		sendClientData( player, "Map" );
		sendClientData( player, "TotalObjects" );
		sendClientData( player, "ControlObject" );
	}	
}

function sendClientData( player, data ) {
	if( data == "Map" ) {
		local mapdata = Stream();
		mapdata.WriteString( "Current Map:" + ( CurrentMap == "" ? "None" : CurrentMap ) );
		mapdata.SendStream( player );
	}
	else if( data == "TotalObjects" ) {
		local mapdata = Stream();
		mapdata.WriteString( "Total Objects:" + objCreated );
		mapdata.SendStream( player );
	}
	else if( data == "ControlObject" ) {
		local object; 
		local mapdata = Stream();
		if( Object[ player.ID ] == null ) {
			mapdata.WriteString( "Object:None" );
		}
		else {
			if( typeof Object[ player.ID ] == "instance" ) object = Object[ player.ID ];
			else object = FindObject( Object[ player.ID ] );
				
			local objectModel = object.Model, objectID = object.ID;
			mapdata.WriteString( "Object:" + objectModel + ":" + objectID );
		}
		mapdata.SendStream( player );
	}
}

function FindLoc( text ) 
{
    local Location = QuerySQL( db, "SELECT Name FROM Gotoloc WHERE Name='" + text + "'" );
    if( Location ) { FreeSQLQuery( Location ); return true }
    else { return false }
}

function onObjectShot( object, player, weapon )
{
	local obj = FindObject( object.ID );
	local plr = FindPlayer( player.ID );
	Object[ plr.ID ] = obj;
	pData[ player.ID ].Editing = true;
	MessagePlayer( "[#00CC00][SELECT]: [#ffffff]Selected object " + object.ID, player );
	return 1;
}

function onObjectBump( object, player )
{
	local obj = FindObject( object.ID );
	local plr = FindPlayer( player.ID );
	obj.Delete();
	pData[ player.ID ].Editing = false;
	objCreated--;
	Object[ player.ID ] = null;
	MessagePlayer( "[#00CC00][SELECT]: [#ffffff]Object deleted!", player );
}

function EnableBumpTracks()
{
	for( local i = 0; i < objCreated; i++ )
	{
		local o = FindObject( i );
		if( o ) o.TrackingBumps = true;
	}
}

function DisableBumpTracks()
{
	for( local i = 0; i < objCreated; i++ )
	{
		local o = FindObject( i );
		if( o ) o.TrackingBumps = false;
	}
}

function RemoveObjects( CurrentMap )
{
	local i = 0;
	do
	{
		local obj = FindObject( i );
		if( obj ) { obj.Delete(); objCreated--; }
		i++;
	}
	while( objCreated > 0 );
	objCreated = 0;
	Message( "[#ffffff]All objects of the map " + CurrentMap + " were removed!" );
}

function onKeyUp( player, key )
{
	if( pData[ player.ID ].Motion != null )
	{
		pData[ player.ID ].Motion.Delete();
		pData[ player.ID ].Motion = null;
	}
	
	if( key == ctrl ) { pData[ player.ID ].CTRL = false; }
	onCamKeyUp( player, key );
}

function onKeyDown( plr, key )
{
	local player;
	if( typeof plr != "instance" ) player = FindPlayer( plr );
	else player = plr;
	
	if( !pData[ player.ID ].Editing && pData[ player.ID ].lastPos == null ) return onCamKeyDown( plr, key ); /*MessagePlayer( "[#00CC00][MAP]: [#ffffff]You are not controlling any object!", player );*/
	
	if( key == ArrowRight && pData[ player.ID ].lastPos != null )
	{
		pData[ player.ID ].viewObject.Delete();
		pData[ player.ID ].viewObject = null;
		pData[ player.ID ].viewModel++;
		pData[ player.ID ].viewObject = CreateObject( pData[ player.ID ].viewModel, player.World, C_VIEWLOC.x, C_VIEWLOC.y, C_VIEWLOC.z, 255 );
		//MessagePlayer( "[#00CC00][OBJECT]: [#FFFFFF]Viewing object: " + pData[ player.ID ].viewModel, player );
	}
	else if( key == ArrowLeft && pData[ player.ID ].lastPos != null )
	{
		pData[ player.ID ].viewObject.Delete();
		pData[ player.ID ].viewObject = null;
		pData[ player.ID ].viewModel--;
		pData[ player.ID ].viewObject = CreateObject( pData[ player.ID ].viewModel, player.World, C_VIEWLOC.x, C_VIEWLOC.y, C_VIEWLOC.z, 255 );
		//MessagePlayer( "[#00CC00][OBJECT]: [#FFFFFF]Viewing object: " + pData[ player.ID ].viewModel, player );
	}
	else if( key == ctrl && pData[ player.ID ].lastPos != null )
	{
		pData[ player.ID ].motionTimer.Delete();
		player.Pos = pData[ player.ID ].lastPos;
		pData[ player.ID ].lastPos = null;
		player.RestoreCamera();
		player.World = 0;
		pData[ player.ID ].viewObject.Delete();
		pData[ player.ID ].viewObject = null;
		player.IsFrozen = false;
		Object[ player.ID ] = CreateObject( pData[ player.ID ].viewModel, 0, player.Pos.x, player.Pos.y, player.Pos.z, 255 );
		Object[ player.ID ].TrackingShots = true;
		objCreated++;
		player.Pos = Vector( player.Pos.x, player.Pos.y, player.Pos.z + 3 );
		pData[ player.ID ].Editing = true;
		mapSave.Saved = false;
		mapSave.unsavedObjects.append( Object[ player.ID ] );
		Message( "[#00CC00][MAP]: [#ffffff]Created object " + pData[ player.ID ].viewModel );
	}
	else if( key == PageDown && pData[ player.ID ].lastPos != null )
	{
		local objPosition = pData[ player.ID ].viewObject.Pos;
		pData[ player.ID ].viewObject.Pos = Vector( objPosition.x, objPosition.y, objPosition.z - 5 );
	}
	else if( key == PageUp && pData[ player.ID ].lastPos != null )
	{
		local objPosition = pData[ player.ID ].viewObject.Pos;
		pData[ player.ID ].viewObject.Pos = Vector( objPosition.x, objPosition.y, objPosition.z + 5 );
	}
	else if( key == ArrowDown && pData[ player.ID ].lastPos != null )
	{
		local objPosition = pData[ player.ID ].viewObject.Pos;
		pData[ player.ID ].viewObject.Pos = Vector( objPosition.x + 13, objPosition.y - 5, objPosition.z );
	}
	else if( key == ArrowUp && pData[ player.ID ].lastPos != null )
	{
		local objPosition = pData[ player.ID ].viewObject.Pos;
		pData[ player.ID ].viewObject.Pos = Vector( objPosition.x - 13, objPosition.y + 5, objPosition.z );
	}
	
	if( pData[ player.ID ].Motion == null && key != one && key != R && key != two && key != backspace && key != del ) pData[ player.ID ].Motion = NewTimer( "onKeyDown", Motion_Speed, 0, player.ID, key );
	
	if( key == ArrowLeft && !pData[ player.ID ].PositionMode && Object[ player.ID ] != null )
	{
		switch( pData[ player.ID ].Speed )
		{
			case "normal":
			Object[ player.ID ].RotateByEuler( Vector( 0, 0, 0.05 ), 100 );
			break;
			
			case "fast":
			Object[ player.ID ].RotateByEuler( Vector( 0, 0, 0.30 ), 100 );
			break;
			
			case "very fast":
			Object[ player.ID ].RotateByEuler( Vector( 0, 0, 1.30 ), 100 );
			break;
			
			case "very slow":
			Object[ player.ID ].RotateByEuler( Vector( 0, 0, 0.01 ), 100 );
			break;
			
			case "slow":
			Object[ player.ID ].RotateByEuler( Vector( 0, 0, 0.03 ), 100 );
			break;
		}
		return;
	}
	
	else if( key == ArrowRight && !pData[ player.ID ].PositionMode && Object[ player.ID ] != null )
	{
		switch( pData[ player.ID ].Speed )
		{
			case "normal":
			Object[ player.ID ].RotateByEuler( Vector( 0, 0, -0.05 ), 100 );
			break;
			
			case "fast":
			Object[ player.ID ].RotateByEuler( Vector( 0, 0, -0.30 ), 100 );
			break;
			
			case "very fast":
			Object[ player.ID ].RotateByEuler( Vector( 0, 0, -1.30 ), 100 );
			break;
			
			case "very slow":
			Object[ player.ID ].RotateByEuler( Vector( 0, 0, -0.01 ), 100 );
			break;
			
			case "slow":
			Object[ player.ID ].RotateByEuler( Vector( 0, 0, -0.03 ), 100 );
			break;
		}
		return;
	}
	
	else if( key == PageUp && !pData[ player.ID ].PositionMode && Object[ player.ID ] != null )
	{
		switch( pData[ player.ID ].Speed )
		{
			case "normal":
			Object[ player.ID ].RotateByEuler( Vector( 0.05, 0, 0 ), 100 );
			break;
			
			case "fast":
			Object[ player.ID ].RotateByEuler( Vector( 0.30, 0, 0 ), 100 );
			break;
			
			case "very fast":
			Object[ player.ID ].RotateByEuler( Vector( 1.30, 0, 0 ), 100 );
			break;
			
			case "very slow":
			Object[ player.ID ].RotateByEuler( Vector( 0.01, 0, 0 ), 100 );
			break;
			
			case "slow":
			Object[ player.ID ].RotateByEuler( Vector( 0.03, 0, 0 ), 100 );
			break;
		}
		return;
	}
	
	else if( key == PageDown && !pData[ player.ID ].PositionMode && Object[ player.ID ] != null )
	{
		switch( pData[ player.ID ].Speed )
		{
			case "normal":
			Object[ player.ID ].RotateByEuler( Vector( -0.05, 0, 0 ), 100 );
			break;
			
			case "fast":
			Object[ player.ID ].RotateByEuler( Vector( -0.30, 0, 0 ), 100 );
			break;
			
			case "very fast":
			Object[ player.ID ].RotateByEuler( Vector( -1.30, 0, 0 ), 100 );
			break;
			
			case "very slow":
			Object[ player.ID ].RotateByEuler( Vector( -0.01, 0, 0 ), 100 );
			break;
			
			case "slow":
			Object[ player.ID ].RotateByEuler( Vector( -0.03, 0, 0 ), 100 );
			break;
		}
		return;
	}
	
	else if( key == ArrowUp && !pData[ player.ID ].PositionMode && Object[ player.ID ] != null )
	{
		switch( pData[ player.ID ].Speed )
		{
			case "normal":
			Object[ player.ID ].RotateByEuler( Vector( 0, 0.05, 0 ), 100 );
			break;
			
			case "fast":
			Object[ player.ID ].RotateByEuler( Vector( 0, 0.30, 0 ), 100 );
			break;
			
			case "very fast":
			Object[ player.ID ].RotateByEuler( Vector( 0, 1.30, 0 ), 100 );
			break;
			
			case "very slow":
			Object[ player.ID ].RotateByEuler( Vector( 0, 0.01, 0 ), 100 );
			break;
			
			case "slow":
			Object[ player.ID ].RotateByEuler( Vector( 0, 0.03, 0 ), 100 );
			break;
		}
		return;
	}
	
	else if( key == ArrowDown && !pData[ player.ID ].PositionMode && Object[ player.ID ] != null )
	{
		switch( pData[ player.ID ].Speed )
		{
			case "normal":
			Object[ player.ID ].RotateByEuler( Vector( 0, -0.05, 0 ), 100 );
			break;
			
			case "fast":
			Object[ player.ID ].RotateByEuler( Vector( 0, -0.30, 0 ), 100 );
			break;
			
			case "very fast":
			Object[ player.ID ].RotateByEuler( Vector( 0, -1.30, 0 ), 100 );
			break;
			
			case "very slow":
			Object[ player.ID ].RotateByEuler( Vector( 0, -0.01, 0 ), 100 );
			break;
			
			case "slow":
			Object[ player.ID ].RotateByEuler( Vector( 0, -0.03, 0 ), 100 );
			break;
		}
		return;
	}
	
	else if( key == PageUp && pData[ player.ID ].PositionMode && Object[ player.ID ] != null )
	{
		local x = Object[ player.ID ].Pos.x;
		local y = Object[ player.ID ].Pos.y;
		local z = Object[ player.ID ].Pos.z;
		switch( pData[ player.ID ].Speed )
		{
			case "normal":
			Object[ player.ID ].Pos = Vector( x, y, z + 0.05 );
			break;
			
			case "fast":
			Object[ player.ID ].Pos = Vector( x, y, z + 0.30 );
			break;
			
			case "very fast":
			Object[ player.ID ].Pos = Vector( x, y, z + 1.30 );
			break;
			
			case "very slow":
			Object[ player.ID ].Pos = Vector( x, y, z + 0.01 );
			break;
			
			case "slow":
			Object[ player.ID ].Pos = Vector( x, y, z + 0.03 );
			break;
		}
		return;
	}
	
	
	else if( key == PageDown && pData[ player.ID ].PositionMode && Object[ player.ID ] != null )
	{
		local x = Object[ player.ID ].Pos.x;
		local y = Object[ player.ID ].Pos.y;
		local z = Object[ player.ID ].Pos.z;
		switch( pData[ player.ID ].Speed )
		{
			case "normal":
			Object[ player.ID ].Pos = Vector( x, y, z - 0.05 );
			break;
			
			case "fast":
			Object[ player.ID ].Pos = Vector( x, y, z - 0.30 );
			break;
			
			case "very fast":
			Object[ player.ID ].Pos = Vector( x, y, z - 1.30 );
			break;
			
			case "very slow":
			Object[ player.ID ].Pos = Vector( x, y, z - 0.01 );
			break;
			
			case "slow":
			Object[ player.ID ].Pos = Vector( x, y, z - 0.03 );
			break;
		}
		return;
	}
	
	else if( key == ArrowLeft && pData[ player.ID ].PositionMode && Object[ player.ID ] != null )
	{
		local x = Object[ player.ID ].Pos.x;
		local y = Object[ player.ID ].Pos.y;
		local z = Object[ player.ID ].Pos.z;
		switch( pData[ player.ID ].Speed )
		{
			case "normal":
			Object[ player.ID ].Pos = Vector( x - 0.05, y, z );
			break;
			
			case "fast":
			Object[ player.ID ].Pos = Vector( x - 0.30, y, z );
			break;
			
			case "very fast":
			Object[ player.ID ].Pos = Vector( x - 1.30, y, z);
			break;
			
			case "very slow":
			Object[ player.ID ].Pos = Vector( x - 0.01, y, z );
			break;
			
			case "slow":
			Object[ player.ID ].Pos = Vector( x - 0.03, y, z );
			break;
		}
		return;
	}
	
	else if( key == ArrowRight && pData[ player.ID ].PositionMode && Object[ player.ID ] != null )
	{
		local x = Object[ player.ID ].Pos.x;
		local y = Object[ player.ID ].Pos.y;
		local z = Object[ player.ID ].Pos.z;
		switch( pData[ player.ID ].Speed )
		{
			case "normal":
			Object[ player.ID ].Pos = Vector( x + 0.05, y, z );
			break;
			
			case "fast":
			Object[ player.ID ].Pos = Vector( x + 0.30, y, z );
			break;
			
			case "very fast":
			Object[ player.ID ].Pos = Vector( x + 1.30, y, z);
			break;
			
			case "very slow":
			Object[ player.ID ].Pos = Vector( x + 0.01, y, z );
			break;
			
			case "slow":
			Object[ player.ID ].Pos = Vector( x + 0.03, y, z );
			break;
		}
		return;
	}
	
	else if( key == ArrowUp && pData[ player.ID ].PositionMode && Object[ player.ID ] != null )
	{
		local x = Object[ player.ID ].Pos.x;
		local y = Object[ player.ID ].Pos.y;
		local z = Object[ player.ID ].Pos.z;
		switch( pData[ player.ID ].Speed )
		{
			case "normal":
			Object[ player.ID ].Pos = Vector( x, y + 0.05, z );
			break;
			
			case "fast":
			Object[ player.ID ].Pos = Vector( x, y + 0.30, z );
			break;
			
			case "very fast":
			Object[ player.ID ].Pos = Vector( x, y + 1.30, z);
			break;
			
			case "very slow":
			Object[ player.ID ].Pos = Vector( x, y + 0.01, z );
			break;
			
			case "slow":
			Object[ player.ID ].Pos = Vector( x, y + 0.03, z );
			break;
		}
		return;
	}
	
	else if( key == ArrowDown && pData[ player.ID ].PositionMode && Object[ player.ID ] != null )
	{
		local x = Object[ player.ID ].Pos.x;
		local y = Object[ player.ID ].Pos.y;
		local z = Object[ player.ID ].Pos.z;
		switch( pData[ player.ID ].Speed )
		{
			case "normal":
			Object[ player.ID ].Pos = Vector( x, y - 0.05, z );
			break;
			
			case "fast":
			Object[ player.ID ].Pos = Vector( x, y - 0.30, z );
			break;
			
			case "very fast":
			Object[ player.ID ].Pos = Vector( x, y - 1.30, z);
			break;
			
			case "very slow":
			Object[ player.ID ].Pos = Vector( x, y - 0.01, z );
			break;
			
			case "slow":
			Object[ player.ID ].Pos = Vector( x, y - 0.03, z );
			break;
		}
		return;
	}
	
	else if( key == one && Object[ player.ID ] != null )
	{
		if( !pData[ player.ID ].PositionMode )
		{
			pData[ player.ID ].PositionMode = true;
			MessagePlayer( "[#ffffff]Map positioning mode is [#00ff00]ON[#ffffff]! Rotation mode [#ff0000]OFF[#ffffff]!", player );
		}
		
		else if( pData[ player.ID ].PositionMode )
		{
			pData[ player.ID ].PositionMode = false;
			MessagePlayer( "[#ffffff]Map positioning mode is [#ff0000]OFF[#ffffff]! Rotation mode [#00ff00]ON[#ffffff]!", player );
		}
	}
	
	else if( key == two && Object[ player.ID ] != null )
	{
		switch( pData[ player.ID ].Speed )
		{
			case "normal":
			pData[ player.ID ].Speed = "fast";
			MessagePlayer( "[#ffffff]Speed movement level is now [#00ff00]Fast[#ffffff]!", player );
			break;
			
			case "fast":
			pData[ player.ID ].Speed = "very fast";
			MessagePlayer( "[#ffffff]Speed movement level is now [#00ff00]Very Fast[#ffffff]!", player );
			break;
			
			case "very fast":
			pData[ player.ID ].Speed = "very slow";
			MessagePlayer( "[#ffffff]Speed movement level is now [#00ff00]Very Slow[#ffffff]!", player );
			break;
			
			case "very slow":
			pData[ player.ID ].Speed = "slow";
			MessagePlayer( "[#ffffff]Speed movement level is now [#00ff00]Slow[#ffffff]!", player );
			break;
			
			case "slow":
			pData[ player.ID ].Speed = "normal";
			MessagePlayer( "[#ffffff]Speed movement level is now [#00ff00]Normal[#ffffff]!", player );
			break;
		}
	}
	
	else if( key == ctrl ) { pData[ player.ID ].CTRL = true; }
	
	else if( key == c && pData[ player.ID ].CTRL && Object[ player.ID ] != null )
	{
		local old_obj = Object[ player.ID ].Pos;
		local old_objid = Object[ player.ID ].Model;
		local old_objrot = Object[ player.ID ].RotationEuler;
		
		Object[ player.ID ] = CreateObject( old_objid, 0, old_obj, 255 );
		Object[ player.ID ].RotateToEuler( old_objrot, 0 );
		Object[ player.ID ].TrackingShots = true;
		objCreated++;
		pData[ player.ID ].Editing = true;
		Message( "[#00CC00][CLONE]: [#ffffff]Cloned object " + old_objid + " at its position" );
	}
	
	else if( key == del && Object[ player.ID ] != null )
	{
		local object;
		if( typeof Object[ player.ID ] != "instance" ) object = FindObject( Object[ player.ID ] );
		else object = Object[ player.ID ];
		if( !object ) return MessagePlayer( "[#00CC00][ERROR]: [#FFFFFF]Could not delete object", player );
		object.Delete();
		Object[ player.ID ] = null;
		pData[ player.ID ].Editing = false;
		objCreated--;
		MessagePlayer( "[#00CC00][SELECT]: [#ffffff]Object deleted!", player );
	}
	
	else if( key == R && Object[ player.ID ] != null )
	{
		Object[ player.ID ].RotateToEuler( Vector( 0, 0, 0 ), 0 );
		MessagePlayer( "[#ffffff]Rotation angles have been Reset!", player );
		return;
	}
	
	else if( key == backspace && pData[ player.ID ].Editing )
	{
		pData[ player.ID ].Editing = false;
		Object[ player.ID ] = null;
		MessagePlayer( "[#00CC00][EDIT]: [#ffffff]You have finished editing the object.", player );
	}
}

function onPlayerHealthChange( player, lastHP, newHP )
{
	player.Health = 100;
}

function onObjectRender( idPlayer )
{
	local player = FindPlayer( idPlayer );
	if( player && pData[ player.ID ].viewObject != null )
	{
		local object = pData[ player.ID ].viewObject;
		if( object ) 
		{
			if( object.World != player.World )
			{
				MessagePlayer( "Not same world, fixing.", player );
				object.World = player.World;
			}
			object.RotateByEuler( Vector( 0, 0, -0.1 ), 100 );
		}
	}
	else return null;
}
// ================================== END ======================================