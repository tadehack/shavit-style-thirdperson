#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <shavit>
#include <clientprefs>

// cvars
ConVar g_hSpecialString;
ConVar g_hMpForceCamera;

char g_sSpecialString[stylestrings_t::sSpecialString];
bool g_bThirdPerson[MAXPLAYERS + 1];
int g_iFov[MAXPLAYERS + 1];

Cookie g_cFovCookie;

public Plugin myinfo = {
	name = "Shavit - Thirdperson Style",
	author = "devins, shinoum",
	description = "Simple Third-Person Camera style for CS:S Bhop Timer.",
	version = "1.0.1",
	url = "https://github.com/NSchrot/shavit-style-thirdperson"
};

public void OnPluginStart()
{
	g_hSpecialString = CreateConVar("ss_thirdperson_specialstring", "thirdperson", "Special string to use in shavit-styles.cfg to activate this style.");
	g_hSpecialString.AddChangeHook(ConVar_OnSpecialStringChanged);
	g_hSpecialString.GetString(g_sSpecialString, sizeof(g_sSpecialString));
	g_hMpForceCamera = FindConVar("mp_forcecamera");

	HookEvent("player_spawn", OnPlayerSpawn);

	// FOV commands
	RegConsoleCmd("sm_tpfov", Command_ApplyFOV, "Apply User Inserted FOV for thirdperson style");
	RegConsoleCmd("sm_fov", Command_ApplyFOV, "Apply User Inserted FOV for thirdperson style");

	g_cFovCookie = new Cookie("tp_fov", "thirdperson fov state", CookieAccess_Protected);

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

// fix for fov being reset after dropping or picking up a weapon
public void OnClientPostThinkPost(int client)
{
	if (!IsValidClient(client) || !g_bThirdPerson[client])
		return;
		
	if (GetEntProp(client, Prop_Send, "m_iFOV") != g_iFov[client])
		SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
}

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
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client))
		return;

	if (IsInTPStyle(client))
	{
		g_bThirdPerson[client] = true;
		CreateTimer(0.1, Timer_ReApplyThirdPerson, GetClientSerial(client));
	}
}

public void OnClientDisconnect(int client)
{
	if (g_bThirdPerson[client])
		RevertFirstPerson(client);

	g_bThirdPerson[client] = false;
}

public void Shavit_OnStyleChanged(int client, int oldstyle, int newstyle, int track, bool manual)
{
    if (!IsValidClient(client))
        return;

    char sStyleSpecial[sizeof(stylestrings_t::sSpecialString)];
	Shavit_GetStyleStrings(newstyle, sSpecialString, sStyleSpecial, sizeof(sStyleSpecial));
    bool bIsInTPStyle = (StrContains(sStyleSpecial, g_sSpecialString) != -1);

    if (bIsInTPStyle && !g_bThirdPerson[client])
    {
        g_bThirdPerson[client] = true;
        ApplyThirdPerson(client);
    }
    else if (!bIsInTPStyle && g_bThirdPerson[client])
    {
        RevertFirstPerson(client);
        g_bThirdPerson[client] = false;
    }
}

public Action Command_ApplyFOV(int client, int args)
{
	if (client == 0)
		return Plugin_Handled;

	if (!IsInTPStyle(client))
		return Plugin_Handled;

	// If no FOV value is given
	if (args < 1)
	{
		Shavit_PrintToChat(client, "\x078efeffThird-Person: \x07ffffffCurrent FOV: \x07A082FF%i \x07ffffff(Default: 90)", g_iFov[client]);
		Shavit_PrintToChat(client, "\x078efeffThird-Person: \x07ffffffUsage: /tpfov \x07A082FF<value>");
		Shavit_PrintToChat(client, "\x078efeffThird-Person: \x07A082FFChanging the FOV affects mouse sensitivity!");
		
		return Plugin_Handled;
	}

	int iMinFov = 80;
	int imaxFov = 120;
	int iFov = GetCmdArgInt(1);
	
	if (iFov < iMinFov)
		iFov = iMinFov;
	else if (iFov > imaxFov)
		iFov = imaxFov;

	g_iFov[client] = iFov;

	// Save setting to cookie
	char buffer[8];
	Format(buffer, sizeof(buffer), "%d", g_iFov[client]);
	g_cFovCookie.Set(client, buffer);

	Shavit_PrintToChat(client, "\x078efeffThird-Person: \x07ffffffFOV set to: \x07A082FF%i \x07ffffff(Default: 90)", g_iFov[client]);
	Shavit_PrintToChat(client, "\x078efeffThird-Person: \x07A082FFChanging the FOV affects mouse sensitivity!");

	return Plugin_Handled;
}

public void ApplyThirdPerson(int client)
{
	if (!IsValidClient(client) || IsFakeClient(client))
		return;

	if (g_hMpForceCamera != null)
	{
		SendConVarValue(client, g_hMpForceCamera, "0");
	}

	SDKHook(client, SDKHook_PostThinkPost, OnClientPostThinkPost);
	CreateTimer(0.1, Timer_ActivateThirdPerson, GetClientSerial(client));

	Shavit_PrintToChat(client, "\x078efeffThird-Person: \x07ffffffType \x07A082FF/fov \x07ffffffto adjust your Field of View");
}

public void RevertFirstPerson(int client)
{
	if (!IsValidClient(client))
		return;

	SDKUnhook(client, SDKHook_PostThinkPost, OnClientPostThinkPost);
	SetObserverMode(client, 0);
	SetEntProp(client, Prop_Send, "m_iFOV", 90);

	if (g_hMpForceCamera != null)
	{
		SendConVarValue(client, g_hMpForceCamera, "1");
	}
	
	float resetAngles[3] = {0.0, 0.0, 0.0};
	TeleportEntity(client, NULL_VECTOR, resetAngles, NULL_VECTOR);
}

// This timer is being used to re-apply the third person camera once the player re-joins the server
public Action Timer_ReApplyThirdPerson(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);

	if (IsValidClient(client) && g_bThirdPerson[client])
	{
		CreateTimer(0.1, Timer_ActivateThirdPerson, GetClientSerial(client));
	}

	return Plugin_Stop;
}

public Action Timer_ActivateThirdPerson(Handle timer, int serial)
{
	int client = GetClientFromSerial(serial);
	if (!IsValidClient(client) || !g_bThirdPerson[client])
		return Plugin_Stop;
	
	SetObserverMode(client, 1);
	SetEntProp(client, Prop_Send, "m_iFOV", g_iFov[client]);
	
	return Plugin_Stop;
}

public void SetObserverMode(int client, int obsMode)
{
	if (!IsValidClient(client))
		return;
		
	SetEntProp(client, Prop_Send, "m_iObserverMode", obsMode);
	
	if (obsMode != 0)
	{
		SetEntProp(client, Prop_Send, "m_hObserverTarget", client);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_hObserverTarget", -1);
	}
}

bool IsInTPStyle(int client)
{
	int style = Shavit_GetBhopStyle(client);
    char sStyleSpecial[sizeof(stylestrings_t::sSpecialString)];
	Shavit_GetStyleStrings(style, sSpecialString, sStyleSpecial, sizeof(sStyleSpecial));
    bool isInTPStyle = (StrContains(sStyleSpecial, g_sSpecialString) != -1);

	return isInTPStyle;
}

public void ConVar_OnSpecialStringChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	convar.GetString(g_sSpecialString, sizeof(g_sSpecialString));
}
