#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shavit>
#include <clientprefs>

// Global Variables -------------------------------------------------------
ConVar g_hSpecialString;
ConVar g_hMpForceCamera;

char g_sSpecialString[stylestrings_t::sSpecialString];

bool g_bThirdPersonIsEnabled[MAXPLAYERS + 1];
bool g_bNightVisionIsEnabled[MAXPLAYERS + 1];

int g_iFov[MAXPLAYERS + 1];
int g_iMinFov = 80;
int g_iMaxFov = 125;

Cookie g_cFovCookie;
Cookie g_cNvgCookie;

// Plugin Info -----------------------------------------------------------

public Plugin myinfo = {
	name = "Shavit - Thirdperson Style",
	author = "devins, shinoum",
	description = "Simple Third-Person Camera style for CS:S Bhop Timer.",
	version = "1.1.0",
	url = "https://github.com/NSchrot/shavit-style-thirdperson"
};

// Plugin Starts ---------------------------------------------------------

public void OnPluginStart()
{
	g_hSpecialString = CreateConVar("ss_thirdperson_specialstring", "thirdperson", "Special string to use in shavit-styles.cfg to activate this style.");
	g_hSpecialString.AddChangeHook(ConVar_OnSpecialStringChanged);
	g_hSpecialString.GetString(g_sSpecialString, sizeof(g_sSpecialString));
	g_hMpForceCamera = FindConVar("mp_forcecamera");

	HookEvent("player_spawn", OnPlayerSpawn);

	// Commands -----
	
	RegConsoleCmd("sm_tpmenu", Command_MainMenu, "Open Thirdperson Main Menu");

	RegConsoleCmd("sm_tpnvg", Command_ToggleNightVision, "Toggle Night Vision");
	RegConsoleCmd("sm_tpnv", Command_ToggleNightVision, "Toggle Night Vision");
	RegConsoleCmd("sm_nvg", Command_ToggleNightVision, "Toggle Night Vision");
	RegConsoleCmd("sm_nv", Command_ToggleNightVision, "Toggle Night Vision");

	RegConsoleCmd("sm_tpfov", Command_ApplyFOV, "Apply User Inserted FOV for thirdperson style");
	RegConsoleCmd("sm_fov", Command_ApplyFOV, "Apply User Inserted FOV for thirdperson style");

	// Cookies -----

	g_cFovCookie = new Cookie("tp_fov", "thirdperson fov state", CookieAccess_Protected);
	g_cNvgCookie = new Cookie("tp_nvg", "thirdperson nvg state", CookieAccess_Protected);

	for (int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client))
		{
			OnClientPutInServer(client);
			
			if (AreClientCookiesCached(client))
			    OnClientCookiesCached(client);
		}
	}

	AutoExecConfig();
}

// On Clients / Players --------------------------------------------------------------------

public void OnClientPutInServer(int client)
{
    OnClientCookiesCached(client);
}

public void OnClientCookiesCached(int client)
{
	if (IsFakeClient(client))
		return;
	
	char buffer[8];
	
	// Load FOV Cookie
	g_cFovCookie.Get(client, buffer, sizeof(buffer));
	if (buffer[0] == '\0')
	{
		g_iFov[client] = 90;
		g_cFovCookie.Set(client, "90");
	}
	else
	{
		g_iFov[client] = StringToInt(buffer);
	}

	// Load Night Vision Goggles cookie
	g_cNvgCookie.Get(client, buffer, sizeof(buffer));
	if (buffer[0] == '\0')
	{
	    g_bNightVisionIsEnabled[client] = false;
	    g_cNvgCookie.Set(client, "0");
	}
	else
	{
	    g_bNightVisionIsEnabled[client] = (StringToInt(buffer) == 1);
	}
}

public void OnClientDisconnect(int client)
{
	if (g_bThirdPersonIsEnabled[client])
		RevertFirstPerson(client);

	g_bThirdPersonIsEnabled[client] = false;
}

// fix for fov being reset after dropping or picking up a weapon
public void OnClientPostThinkPost(int client)
{
	if (!IsValidClient(client) || !g_bThirdPersonIsEnabled[client])
		return;
		
	if (GetEntProp(client, Prop_Send, "m_iFOV") != g_iFov[client])
		SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client) || !IsInTPStyle(client))
		return;

	g_bThirdPersonIsEnabled[client] = true;
	CreateTimer(0.1, Timer_ReApplyThirdPerson, GetClientSerial(client));
}

// Style Changed ---------------------------------------------------------------------------

public void Shavit_OnStyleChanged(int client, int oldstyle, int newstyle, int track, bool manual)
{
    if (!IsValidClient(client))
        return;

    char sStyleSpecial[sizeof(stylestrings_t::sSpecialString)];
	Shavit_GetStyleStrings(newstyle, sSpecialString, sStyleSpecial, sizeof(sStyleSpecial));
    bool bIsInTPStyle = (StrContains(sStyleSpecial, g_sSpecialString) != -1);

    if (bIsInTPStyle && !g_bThirdPersonIsEnabled[client])
    {
        g_bThirdPersonIsEnabled[client] = true;
        ApplyThirdPerson(client);
    }
    else if (!bIsInTPStyle && g_bThirdPersonIsEnabled[client])
    {
        RevertFirstPerson(client);
        g_bThirdPersonIsEnabled[client] = false;
    }
}

public void ConVar_OnSpecialStringChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	convar.GetString(g_sSpecialString, sizeof(g_sSpecialString));
}

// Commands ---------------------------------------------------------------------------------

public Action Command_ToggleNightVision(int client, int args)
{
    if (!IsValidClient(client) || !IsInTPStyle(client))
        return Plugin_Handled;

	g_bNightVisionIsEnabled[client] = !g_bNightVisionIsEnabled[client];
	SetEntProp(client, Prop_Send, "m_bNightVisionOn", g_bNightVisionIsEnabled[client] ? 1 : 0);

	SaveSettingToCookie(g_cNvgCookie, client, g_bNightVisionIsEnabled[client]);

    return Plugin_Handled;
}

public Action Command_ApplyFOV(int client, int args)
{
	if (client == 0 || !IsInTPStyle(client))
		return Plugin_Handled;

	// If no FOV value is given
	if (args < 1)
	{
		Shavit_PrintToChat(client, "\x078efeffThird-Person: \x07ffffffCurrent FOV: \x07A082FF%i \x07ffffff(Default: 90)", g_iFov[client]);
		Shavit_PrintToChat(client, "\x078efeffThird-Person: \x07ffffffUsage: /tpfov \x07A082FF<value>");
		Shavit_PrintToChat(client, "\x078efeffThird-Person: \x07A082FFChanging the FOV affects mouse sensitivity!");

		ShowFovMenu(client);
		
		return Plugin_Handled;
	}

	int iFov = GetCmdArgInt(1);
	
	if (iFov < g_iMinFov)
		iFov = g_iMinFov;
	else if (iFov > g_iMaxFov)
		iFov = g_iMaxFov;

	g_iFov[client] = iFov;

	// Save setting to cookie
	char buffer[8];
	Format(buffer, sizeof(buffer), "%d", g_iFov[client]);
	g_cFovCookie.Set(client, buffer);

	Shavit_PrintToChat(client, "\x078efeffThird-Person: \x07ffffffFOV set to: \x07A082FF%i \x07ffffff(Default: 90)", g_iFov[client]);
	Shavit_PrintToChat(client, "\x078efeffThird-Person: \x07A082FFChanging the FOV affects mouse sensitivity!");

	return Plugin_Handled;
}

public Action Command_MainMenu(int client, int args)
{
	if (!IsValidClient(client) || !IsInTPStyle(client))
		return Plugin_Handled;

	ShowMainMenu(client);

	return Plugin_Handled;
}

// Timers ----------------------------------------------------------------------------------

// This timer is being used to re-apply the third person camera once the player re-joins the server
public Action Timer_ReApplyThirdPerson(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (IsValidClient(client) && g_bThirdPersonIsEnabled[client])
	{
		CreateTimer(0.1, Timer_ActivateThirdPerson, GetClientSerial(client));
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", g_bNightVisionIsEnabled[client] ? 1 : 0);
	}

	return Plugin_Stop;
}

public Action Timer_ActivateThirdPerson(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (IsValidClient(client) && g_bThirdPersonIsEnabled[client])
	{
		SetObserverMode(client, 1);
		SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
	}

	return Plugin_Stop;
}

// Functions -------------------------------------------------------------------------------

public void ApplyThirdPerson(int client)
{
	if (!IsValidClient(client) || IsFakeClient(client))
		return;

	if (g_hMpForceCamera != null)
		SendConVarValue(client, g_hMpForceCamera, "0");

	SDKHook(client, SDKHook_PostThinkPost, OnClientPostThinkPost);
	CreateTimer(0.1, Timer_ActivateThirdPerson, GetClientSerial(client));

	Shavit_PrintToChat(client, "\x078efeffThird-Person: \x07ffffffType \x07A082FF/tpmenu \x07ffffffto adjust settings");
}

public void RevertFirstPerson(int client)
{
	if (!IsValidClient(client))
		return;

	SDKUnhook(client, SDKHook_PostThinkPost, OnClientPostThinkPost);
	SetObserverMode(client, 0);
	SetEntProp(client, Prop_Send, "m_iFOV", 90);

	if (g_hMpForceCamera != null)
		SendConVarValue(client, g_hMpForceCamera, "1");
	
	float resetAngles[3] = {0.0, 0.0, 0.0};
	TeleportEntity(client, NULL_VECTOR, resetAngles, NULL_VECTOR);
}

public void SetObserverMode(int client, int obsMode)
{
	if (!IsValidClient(client))
		return;
		
	SetEntProp(client, Prop_Send, "m_iObserverMode", obsMode);
	
	if (obsMode != 0)
		SetEntProp(client, Prop_Send, "m_hObserverTarget", client);
	else
		SetEntProp(client, Prop_Send, "m_hObserverTarget", -1);
}

bool IsInTPStyle(int client)
{
	int style = Shavit_GetBhopStyle(client);
    char sStyleSpecial[sizeof(stylestrings_t::sSpecialString)];
	Shavit_GetStyleStrings(style, sSpecialString, sStyleSpecial, sizeof(sStyleSpecial));
    bool isInTPStyle = (StrContains(sStyleSpecial, g_sSpecialString) != -1);

	return isInTPStyle;
}

public void SaveSettingToCookie(Cookie cookie, int client, int value)
{
	char buffer[8];
	Format(buffer, sizeof(buffer), "%d", value);
	cookie.Set(client, buffer);
}

// Menus ------------------------------------------------------------------------

void ShowMainMenu(int client)
{
	Menu menu = new Menu(MainMenuHandler, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("Third Person\n \n");

	char nvgStatus[32];
	Format(nvgStatus, sizeof(nvgStatus), "Night Vision: %s", g_bNightVisionIsEnabled[client] ? "On" : "Off");
	menu.AddItem("nvg", nvgStatus);

	menu.AddItem("fov", "FOV");

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MainMenuHandler(Menu menu, MenuAction action, int client, int option)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(option, info, sizeof(info));

			if (StrEqual(info, "fov"))
			{
				ShowFovMenu(client);
			}
			else if (StrEqual(info, "nvg"))
			{
				Command_ToggleNightVision(client, 0);
				ShowMainMenu(client);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

void ShowFovMenu(int client)
{
	Menu menu = new Menu(FovMenuHandler, MENU_ACTIONS_DEFAULT);
	
	char title[64];
	Format(title, sizeof(title), "Third Person | FOV\n \nCurrent FOV: %d\n ", g_iFov[client]);
	menu.SetTitle(title);
	
	menu.AddItem("increase", "++");
	menu.AddItem("decrease", "--\n \n");

	menu.AddItem("default", "Set to Default\n \n");

	menu.AddItem("mainMenu", "Main Menu");
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int FovMenuHandler(Menu menu, MenuAction action, int client, int option)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(option, info, sizeof(info));
			
			if (g_bThirdPersonIsEnabled[client])
			{
				if (StrEqual(info, "increase"))
				{
					if (g_iFov[client] < g_iMaxFov)
					{
						g_iFov[client] += 5;
						SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
						SaveSettingToCookie(g_cFovCookie, client, g_iFov[client]);
					}
				}
				else if (StrEqual(info, "decrease"))
				{
					if (g_iFov[client] > g_iMinFov)
					{
						g_iFov[client] -= 5;
						SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
						SaveSettingToCookie(g_cFovCookie, client, g_iFov[client]);
					}
				}
				else if (StrEqual(info, "default"))
				{
					g_iFov[client] = 90;
					SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
					SaveSettingToCookie(g_cFovCookie, client, g_iFov[client]);
				}

				if (StrEqual(info, "mainMenu"))
					ShowMainMenu(client);
				else
					ShowFovMenu(client);	
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}
