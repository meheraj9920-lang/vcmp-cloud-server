sX <- GUI.GetScreenSize().X;
sY <- GUI.GetScreenSize().Y;

::pGUI <- {
	Current_Map = null,
	Total_Objects = null,
	Control_Object = null
}

function Script::ScriptLoad()
{

}

function Script::ScriptProcess()
{

}

function Server::ServerData(stream) {
	local data = stream.ReadString();
	local mapdata = split( data, ":" );
	if( mapdata[0] == "Current Map" ) {
		if( ::pGUI.Current_Map ) return ::pGUI.Current_Map.Text = "Map: " + mapdata[1] 
		::pGUI.Current_Map = GUILabel( VectorScreen(0, sY-25), Colour( 255, 85, 85, 255 ), "Map: " + mapdata[1] );
		::pGUI.Current_Map.FontSize = 15;
		::pGUI.Current_Map.FontFlags = GUI_FFLAG_BOLD | GUI_FFLAG_OUTLINE;
	}
	else if( mapdata[0] == "Total Objects" ) {
		if( ::pGUI.Total_Objects ) return ::pGUI.Total_Objects.Text = "Total Objects: " + mapdata[1];
		::pGUI.Total_Objects = GUILabel( VectorScreen(0, sY-50), Colour( 255, 85, 85, 255 ), "Total Objects: " + mapdata[1] );
		::pGUI.Total_Objects.FontSize = 15;
		::pGUI.Total_Objects.FontFlags = GUI_FFLAG_BOLD | GUI_FFLAG_OUTLINE;
	}
	else if( mapdata[0] == "Object" ) {
		if( ::pGUI.Control_Object ) {
			if( mapdata[1] == "None" ) {
				::pGUI.Control_Object.Text = "Object: None";
			} else {
				::pGUI.Control_Object.Text = "Model: " + mapdata[1] + " | Object ID: " + mapdata[2];
			}
		}
		
		if( mapdata[1] == "None" ) {
			::pGUI.Control_Object = GUILabel( VectorScreen(0, sY-75), Colour( 255, 85, 85, 255 ), "Object: None" );
		} else {
			::pGUI.Control_Object.Text = "Model: " + mapdata[1] + " | Object ID: " + mapdata[2];
		}
		::pGUI.Control_Object.FontSize = 15;
		::pGUI.Control_Object.FontFlags = GUI_FFLAG_BOLD | GUI_FFLAG_OUTLINE;
	}
}