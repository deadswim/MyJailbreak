/*
 * MyJailbreak - Warden - Icon Module.
 * by: shanapu
 * https://github.com/shanapu/MyJailbreak/
 *
 * This file is part of the MyJailbreak SourceMod Plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */


/******************************************************************************
                   STARTUP
******************************************************************************/


//Includes
#include <myjailbreak> //... all other includes in myjailbreak.inc


//Compiler Options
#pragma semicolon 1
#pragma newdecls required


//Console Variables
ConVar gc_bIcon;
ConVar gc_sIconPath;


//Integers
int g_iIcon[MAXPLAYERS + 1] = {-1, ...};


//Strings
char g_sIconPath[256];


//Start
public void Icon_OnPluginStart()
{
	//AutoExecConfig
	gc_bIcon = AutoExecConfig_CreateConVar("sm_warden_icon_enable", "1", "0 - disabled, 1 - enable the icon above the wardens head", _, true,  0.0, true, 1.0);
	gc_sIconPath = AutoExecConfig_CreateConVar("sm_warden_icon", "decals/MyJailbreak/warden" , "Path to the warden icon DONT TYPE .vmt or .vft");
	
	
	//Hooks
	HookEvent("round_poststart", Icon_Event_PostRoundStart);
	HookConVarChange(gc_sIconPath, Icon_OnSettingChanged);
	
	
	//FindConVar
	gc_sIconPath.GetString(g_sIconPath , sizeof(g_sIconPath));
}


public int Icon_OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == gc_sIconPath)
	{
		strcopy(g_sIconPath, sizeof(g_sIconPath), newValue);
		if(gc_bIcon.BoolValue) PrecacheModelAnyDownload(g_sIconPath);
	}
}


/******************************************************************************
                   EVENTS
******************************************************************************/


public void Icon_Event_PostRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(g_iWarden != -1) SpawnIcon(g_iWarden);
}


/******************************************************************************
                   FORWARDS LISTEN
******************************************************************************/


public void Icon_OnMapStart()
{
	if(gc_bIcon.BoolValue) PrecacheModelAnyDownload(g_sIconPath);
}


public void Icon_OnWardenCreation(int client)
{
	SpawnIcon(client);
}


public void Icon_OnWardenRemoved(int client)
{
	RemoveIcon(client);
}


/******************************************************************************
                   FUNCTIONS
******************************************************************************/


public Action Should_Transmit(int entity, int client)
{
	char m_ModelName[PLATFORM_MAX_PATH];
	char iconbuffer[256];
	Format(iconbuffer, sizeof(iconbuffer), "materials/%s.vmt", g_sIconPath);
	GetEntPropString(entity, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
	if (StrEqual( iconbuffer, m_ModelName))
		return Plugin_Continue;
	return Plugin_Handled;
}


/******************************************************************************
                   STOCKS
******************************************************************************/


stock int SpawnIcon(int client) 
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || !gc_bIcon.BoolValue) return -1;
	
	char iTarget[16];
	Format(iTarget, 16, "client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);

	g_iIcon[client] = CreateEntityByName("env_sprite");

	if(!g_iIcon[client]) return -1;
	char iconbuffer[256];
	Format(iconbuffer, sizeof(iconbuffer), "materials/%s.vmt", g_sIconPath);
	
	DispatchKeyValue(g_iIcon[client], "model", iconbuffer);
	DispatchKeyValue(g_iIcon[client], "classname", "env_sprite");
	DispatchKeyValue(g_iIcon[client], "spawnflags", "1");
	DispatchKeyValue(g_iIcon[client], "scale", "0.3");
	DispatchKeyValue(g_iIcon[client], "rendermode", "1");
	DispatchKeyValue(g_iIcon[client], "rendercolor", "255 255 255");
	DispatchSpawn(g_iIcon[client]);
	
	float origin[3];
	GetClientAbsOrigin(client, origin);
	origin[2] = origin[2] + 90.0;
	
	TeleportEntity(g_iIcon[client], origin, NULL_VECTOR, NULL_VECTOR);
	SetVariantString(iTarget);
	AcceptEntityInput(g_iIcon[client], "SetParent", g_iIcon[client], g_iIcon[client], 0);
	SDKHook(g_iIcon[client], SDKHook_SetTransmit, Should_Transmit);
	return g_iIcon[client];
}


stock void RemoveIcon(int client) 
{
	if(g_iIcon[client] > 0 && IsValidEdict(g_iIcon[client]))
	{
		AcceptEntityInput(g_iIcon[client], "Kill");
		g_iIcon[client] = -1;
	}
}