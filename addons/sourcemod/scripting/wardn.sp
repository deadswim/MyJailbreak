//Includes
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <wardn>
#include <emitsoundany>
#include <smartjaildoors>
#include <smlib>
#include <colors>
#include <autoexecconfig>

//Compiler Options
#pragma semicolon 1
#pragma newdecls required

//Defines
#define PLUGIN_VERSION "0.3"

//Bools
bool IsCountDown = false;

//ConVars
ConVar gc_bOpenTimer;
ConVar gc_bOpenTimerWarden;
ConVar gc_bPlugin;
ConVar gc_bVote;
ConVar gc_bStayWarden;
ConVar gc_bNoBlock;
ConVar gc_bColor;
ConVar gc_bOpen;
ConVar gc_bSounds;
ConVar gc_bFF;
ConVar gc_bRandom;
ConVar gc_bMarker;
ConVar gc_iMarkerKey;
ConVar gc_fMarkerTime;
ConVar gc_bCountDown;
ConVar gc_bOverlays;
ConVar gc_sOverlayStartPath;
ConVar gc_sOverlayStopPath;
ConVar gc_sWarden;
ConVar gc_sUnWarden;
ConVar gc_sStart;
ConVar gc_sStop;
//ConVar gc_sModelPath;
//ConVar gc_bModel;
ConVar gc_bTag;
ConVar gc_bBetterNotes;
ConVar g_bFF;

//Integers
int g_iVoteCount;
int Warden = -1;
int tempwarden[MAXPLAYERS+1] = -1;
int g_CollisionOffset;
int opentimer;
int g_iCountStartTime = 9;
int g_iCountStopTime = 9;
int g_MarkerColor[] = {255,1,1,255};
int g_iBeamSprite = -1;
int g_iHaloSprite = -1;
int g_iSetCountStartStopTime;

//Handles
Handle g_fward_onBecome;
Handle g_fward_onRemove;
Handle gF_OnWardenCreatedByUser = null;
Handle gF_OnWardenCreatedByAdmin = null;
Handle gF_OnWardenDisconnected = null;
Handle gF_OnWardenDeath = null;
Handle gF_OnWardenRemovedBySelf = null;
Handle gF_OnWardenRemovedByAdmin = null;
Handle g_hOpenTimer=null;
Handle g_iWardenColorRed;
Handle g_iWardenColorGreen;
Handle g_iWardenColorBlue;
Handle countertime = null;

//Strings
char g_sHasVoted[1500];
//char g_sModelPath[256]; // change model back on unwarden
//char g_sWardenModel[256];
char g_sUnWarden[256];
char g_sWarden[256];
char g_sStart[256];
char g_sStop[256];
char g_sOverlayStart[256];
char g_sOverlayStop[256];

//float
float g_fMakerPos[3];


public Plugin myinfo = {
	name = "MyJailbreak - Warden",
	author = "shanapu, ecca, ESKO & .#zipcore",
	description = "Jailbreak Warden script",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart() 
{
	//Translation
	LoadTranslations("MyJailbreakWarden.phrases");
	
	//Client commands
	RegConsoleCmd("sm_noblockon", noblockon); 
	RegConsoleCmd("sm_noblockoff", noblockoff); 
	RegConsoleCmd("sm_w", BecomeWarden);
	RegConsoleCmd("sm_warden", BecomeWarden);
	RegConsoleCmd("sm_uw", ExitWarden);
	RegConsoleCmd("sm_unwarden", ExitWarden);
	RegConsoleCmd("sm_hg", BecomeWarden);
	RegConsoleCmd("sm_headguard", BecomeWarden);
	RegConsoleCmd("sm_uhg", ExitWarden);
	RegConsoleCmd("sm_unheadguard", ExitWarden);
	RegConsoleCmd("sm_c", BecomeWarden);
	RegConsoleCmd("sm_commander", BecomeWarden);
	RegConsoleCmd("sm_uc", ExitWarden);
	RegConsoleCmd("sm_uncommander", ExitWarden);
	RegConsoleCmd("sm_open", OpenDoors);
	RegConsoleCmd("sm_close", CloseDoors);
	RegConsoleCmd("sm_vw", VoteWarden);
	RegConsoleCmd("sm_votewarden", VoteWarden);
	RegConsoleCmd("sm_setff", ToggleFF);
	RegConsoleCmd("sm_cdstart", SetStartCountDown);
	RegConsoleCmd("sm_cdmenu", CDMenu);
	RegConsoleCmd("sm_cdstartstop", StartStopCDMenu);
	RegConsoleCmd("sm_cdstop", SetStopCountDown);
	RegConsoleCmd("sm_killrandom", KillRandom);
	
	//Admin commands
	RegAdminCmd("sm_sw", SetWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_setwarden", SetWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_rw", RemoveWarden, ADMFLAG_GENERIC);
	RegAdminCmd("sm_removewarden", RemoveWarden, ADMFLAG_GENERIC);

	//Forwards
	gF_OnWardenCreatedByUser = CreateGlobalForward("Warden_OnWardenCreatedByUser", ET_Ignore, Param_Cell);
	gF_OnWardenCreatedByAdmin = CreateGlobalForward("Warden_OnWardenCreatedByAdmin", ET_Ignore, Param_Cell);
	g_fward_onBecome = CreateGlobalForward("warden_OnWardenCreated", ET_Ignore, Param_Cell);
	gF_OnWardenDisconnected = CreateGlobalForward("Warden_OnWardenDisconnected", ET_Ignore, Param_Cell);
	gF_OnWardenDeath = CreateGlobalForward("Warden_OnWardenDeath", ET_Ignore, Param_Cell);
	gF_OnWardenRemovedBySelf = CreateGlobalForward("Warden_OnWardenRemovedBySelf", ET_Ignore, Param_Cell);
	gF_OnWardenRemovedByAdmin = CreateGlobalForward("Warden_OnWardenRemovedByAdmin", ET_Ignore, Param_Cell);
	g_fward_onRemove = CreateGlobalForward("warden_OnWardenRemoved", ET_Ignore, Param_Cell);
	
	//AutoExecConfig
	AutoExecConfig_SetFile("MyJailbreak_warden");
	AutoExecConfig_SetCreateFile(true);
	
	AutoExecConfig_CreateConVar("sm_warden_version", PLUGIN_VERSION,	"The version of the SourceMod plugin MyJailBreak - Warden", FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gc_bPlugin = AutoExecConfig_CreateConVar("sm_warden_enable", "1", "0 - disabled, 1 - enable warden");	
	gc_bBetterNotes = AutoExecConfig_CreateConVar("sm_warden_better_notifications", "1", "0 - disabled, 1 - Will use hint and center text", _, true, 0.0, true, 1.0);
	gc_bVote = AutoExecConfig_CreateConVar("sm_warden_vote", "1", "0 - disabled, 1 - enable player vote against warden");	
	gc_bStayWarden = AutoExecConfig_CreateConVar("sm_warden_stay", "1", "0 - disabled, 1 - enable warden stay after round end");	
	gc_bNoBlock = AutoExecConfig_CreateConVar("sm_warden_noblock", "1", "0 - disabled, 1 - enable setable noblock for warden");	
	gc_bFF = AutoExecConfig_CreateConVar("sm_warden_ff", "1", "0 - disabled, 1 - enable switch ff for T ");
	gc_bRandom = AutoExecConfig_CreateConVar("sm_warden_random", "1", "0 - disabled, 1 - enable kill a random t for warden");
	gc_bMarker = AutoExecConfig_CreateConVar("sm_warden_marker", "1", "0 - disabled, 1 - enable Warden simple markers ");
	gc_iMarkerKey = AutoExecConfig_CreateConVar("sm_warden_markerkey", "3", "1 - Look weapon / 2 - Use and shoot / 3 - walk and shoot");
	gc_fMarkerTime = AutoExecConfig_CreateConVar("sm_warden_marker_time", "20.0", "Time in seconds marker will disappears");
	gc_bCountDown = AutoExecConfig_CreateConVar("sm_warden_countdown", "1", "0 - disabled, 1 - enable countdown for warden");
	gc_bOverlays = AutoExecConfig_CreateConVar("sm_warden_overlays", "1", "0 - disabled, 1 - enable overlays", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_sOverlayStartPath = AutoExecConfig_CreateConVar("sm_warden_overlaystart_path", "overlays/MyJailbreak/start" , "Path to the start Overlay DONT TYPE .vmt or .vft");
	gc_sOverlayStopPath = AutoExecConfig_CreateConVar("sm_warden_overlaystop_path", "overlays/MyJailbreak/stop" , "Path to the stop Overlay DONT TYPE .vmt or .vft");
	gc_bOpen = AutoExecConfig_CreateConVar("sm_wardenopen_enable", "1", "0 - disabled, 1 - warden can open/close cells");
	g_hOpenTimer = AutoExecConfig_CreateConVar("sm_wardenopen_time", "60", "Time in seconds for open doors on round start automaticly");
	gc_bOpenTimer = AutoExecConfig_CreateConVar("sm_wardenopen_time_enable", "1", "should doors open automatic 0- no 1 yes");	 // TODO: DONT WORK
	gc_bOpenTimerWarden = AutoExecConfig_CreateConVar("sm_wardenopen_time_warden", "1", "should doors open automatic after sm_wardenopen_time when there is a warden? needs sm_wardenopen_time_enable 1"); 
	gc_bColor = AutoExecConfig_CreateConVar("sm_wardencolor_enable", "1", "0 - disabled, 1 - enable warden colored");
	g_iWardenColorRed = AutoExecConfig_CreateConVar("sm_wardencolor_red", "0","What color to turn the warden into (set R, G and B values to 255 to disable) (Rgb): x - red value", 0, true, 0.0, true, 255.0);
	g_iWardenColorGreen = AutoExecConfig_CreateConVar("sm_wardencolor_green", "0","What color to turn the warden into (rGb): x - green value", 0, true, 0.0, true, 255.0);
	g_iWardenColorBlue = AutoExecConfig_CreateConVar("sm_wardencolor_blue", "255","What color to turn the warden into (rgB): x - blue value", 0, true, 0.0, true, 255.0);
	gc_bSounds = AutoExecConfig_CreateConVar("sm_warden_sounds_enable", "1", "0 - disabled, 1 - enable warden sounds");
	gc_sWarden = AutoExecConfig_CreateConVar("sm_warden_sounds_warden", "music/myjailbreak/warden.mp3", "Path to the sound which should be played for a int warden.");
	gc_sUnWarden = AutoExecConfig_CreateConVar("sm_warden_sounds_unwarden", "music/myjailbreak/unwarden.mp3", "Path to the sound which should be played when there is no warden anymore.");
	gc_sStart = AutoExecConfig_CreateConVar("sm_warden_sounds_start", "music/myjailbreak/start.mp3", "Path to the sound which should be played for a start countdown.");
	gc_sStop = AutoExecConfig_CreateConVar("sm_warden_sounds_stop", "music/myjailbreak/stop.mp3", "Path to the sound which should be played for stop countdown.");
//	gc_bModel = AutoExecConfig_CreateConVar("sm_warden_model", "1", "0 - disabled, 1 - enable warden model", 0, true, 0.0, true, 1.0);
//	gc_sModelPath = AutoExecConfig_CreateConVar("sm_warden_model_path", "models/player/custom_player/legacy/security.mdl", "Path to the model for zombies.");
	gc_bTag = AutoExecConfig_CreateConVar("sm_warden_tag", "1", "Allow \"MyJailbreak\" to be added to the server tags? So player will find servers with MyJB faster. it dont touch you sv_tags", 0, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	//Hooks
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", playerDeath);
	HookEvent("bullet_impact", Event_BulletImpact);
//	HookConVarChange(gc_sModelPath, OnSettingChanged);
	HookConVarChange(gc_sUnWarden, OnSettingChanged);
	HookConVarChange(gc_sWarden, OnSettingChanged);
	HookConVarChange(gc_sStart, OnSettingChanged);
	HookConVarChange(gc_sStop, OnSettingChanged);
	HookConVarChange(gc_sOverlayStartPath, OnSettingChanged);
	HookConVarChange(gc_sOverlayStopPath, OnSettingChanged);
	
	//FindConVar
	g_bFF = FindConVar("mp_teammates_are_enemies");
	gc_sWarden.GetString(g_sWarden, sizeof(g_sWarden));
	gc_sUnWarden.GetString(g_sUnWarden, sizeof(g_sUnWarden));
	gc_sStart.GetString(g_sStart, sizeof(g_sStart));
	gc_sStop.GetString(g_sStop, sizeof(g_sStop));
//	gc_sModelPath.GetString(g_sWardenModel, sizeof(g_sWardenModel));
	gc_sOverlayStartPath.GetString(g_sOverlayStart , sizeof(g_sOverlayStart));
	gc_sOverlayStopPath.GetString(g_sOverlayStop , sizeof(g_sOverlayStop));
	
//	AddCommandListener(HookPlayerChat, "say");
	AddCommandListener(Command_LAW, "+lookatweapon");
	
	g_CollisionOffset = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	g_iVoteCount = 0;
	
	CreateTimer(1.0, Timer_DrawMakers, _, TIMER_REPEAT);
}

public Action Command_LAW(int client, const char[] command, int argc)
{
	if(!gc_bMarker.BoolValue)
		return Plugin_Continue;
	
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
		
	if(!warden_iswarden(client))
		return Plugin_Continue;
	
	if(gc_iMarkerKey.IntValue == 1)
	{
		GetClientAimTargetPos(client, g_fMakerPos);
		g_fMakerPos[2] += 5.0;
	}
	
	return Plugin_Continue;
}

public Action Event_BulletImpact(Handle hEvent,const char [] sName, bool bDontBroadcast)
{
	if(gc_bMarker.BoolValue)	
	{
		int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		
		if (Client_IsIngame(client) && IsPlayerAlive(client) && warden_iswarden(client))
		{
			if (GetClientButtons(client) & IN_USE) 
			{
				if(gc_iMarkerKey.IntValue == 2)
				{
					GetClientAimTargetPos(client, g_fMakerPos);
					g_fMakerPos[2] += 5.0;
					CPrintToChat(client, "%t %t", "warden_tag" , "warden_marker");
				}
			}
			else if (GetClientButtons(client) & IN_SPEED) 
				{
					if(gc_iMarkerKey.IntValue == 3)
					{
						GetClientAimTargetPos(client, g_fMakerPos);
						g_fMakerPos[2] += 5.0;
						CPrintToChat(client, "%t %t", "warden_tag" , "warden_marker");
					}
				}
		}
	}
}

int GetClientAimTargetPos(int client, float pos[3]) 
{
	if (!client) 
		return -1;
	
	float vAngles[3]; float vOrigin[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilterAllEntities, client);
	
	TR_GetEndPosition(pos, trace);
	pos[2] += 5.0;
	
	int entity = TR_GetEntityIndex(trace);
	
	CloseHandle(trace);
	
	return entity;
}

void ResetMarker()
{
	for(int i = 0; i < 3; i++)
		g_fMakerPos[i] = 0.0;
}

public bool TraceFilterAllEntities(int entity, int contentsMask, any client)
{
	if (entity == client)
		return false;
	if (entity > MaxClients)
		return false;
	if(!IsClientInGame(entity))
		return false;
	if(!IsPlayerAlive(entity))
		return false;
	
	return true;
}

public Action Timer_DrawMakers(Handle timer, any data)
{
	Draw_Markers();
	return Plugin_Continue;
}

void Draw_Markers()
{
	if (!gc_bMarker.BoolValue)
		return;
	
	if (g_fMakerPos[0] == 0.0)
		return;
	
	if(!warden_exist())
		return;
		
	// Show the ring
	
	TE_SetupBeamRingPoint(g_fMakerPos, 155.0, 155.0+0.1, g_iBeamSprite, g_iHaloSprite, 0, 10, 1.0, 6.0, 0.0, g_MarkerColor, 2, 0);
	TE_SendToAll();
	
	// Show the arrow
	
	float fStart[3];
	AddVectors(fStart, g_fMakerPos, fStart);
	fStart[2] += 0.0;
	
	float fEnd[3];
	AddVectors(fEnd, fStart, fEnd);
	fEnd[2] += 200.0;
	
	TE_SetupBeamPoints(fStart, fEnd, g_iBeamSprite, g_iHaloSprite, 0, 10, 1.0, 4.0, 16.0, 1, 0.0, g_MarkerColor, 5);
	TE_SendToAll();
	
	CreateTimer(gc_fMarkerTime.FloatValue, DeleteMarker);
}

public Action DeleteMarker( Handle timer) 
{
	ResetMarker();
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (countertime != null)
		KillTimer(countertime);
		
	countertime = null;
	
	if(gc_bPlugin.BoolValue)	
	{
		opentimer = GetConVarInt(g_hOpenTimer);
		countertime = CreateTimer(1.0, ccounter, _, TIMER_REPEAT);
	}
	else if(!gc_bPlugin.BoolValue)
	{
			Warden = -1;
	}
	if(!gc_bStayWarden.BoolValue)
	{
			Warden = -1;
	}
	IsCountDown = false;

}

public void OnConfigsExecuted()
{
	
	if (gc_bTag.BoolValue)
	{
		ConVar hTags = FindConVar("sv_tags");
		char sTags[128];
		hTags.GetString(sTags, sizeof(sTags));
		if (StrContains(sTags, "MyJailbreak", false) == -1)
		{
			StrCat(sTags, sizeof(sTags), ", MyJailbreak");
			hTags.SetString(sTags);
		}
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("warden_exist", Native_ExistWarden);
	CreateNative("warden_iswarden", Native_IsWarden);
	CreateNative("warden_set", Native_SetWarden);
	CreateNative("warden_removed", Native_RemoveWarden);
	CreateNative("warden_get", Native_GetWarden);
	
	RegPluginLibrary("warden");
	return APLRes_Success;
}

public void OnMapStart()
{
	if(gc_bSounds.BoolValue)	
	{
		PrecacheSoundAnyDownload(g_sWarden);
		PrecacheSoundAnyDownload(g_sUnWarden);
		PrecacheSoundAnyDownload(g_sStop);
		PrecacheSoundAnyDownload(g_sStart);
	}	
	g_iVoteCount = 0;
//	PrecacheModel(g_sWardenModel);
//	PrecacheModel("models/player/ctm_gsg9.mdl");
	if(gc_bOverlays.BoolValue) PrecacheOverlayAnyDownload(g_sOverlayStart);
	if(gc_bOverlays.BoolValue) PrecacheOverlayAnyDownload(g_sOverlayStop);
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/glow01.vmt");

}

public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == gc_sWarden)
	{
		strcopy(g_sWarden, sizeof(g_sWarden), newValue);
		if(gc_bSounds.BoolValue) PrecacheSoundAnyDownload(g_sWarden);
	}
	else if(convar == gc_sUnWarden)
	{
		strcopy(g_sUnWarden, sizeof(g_sUnWarden), newValue);
		if(gc_bSounds.BoolValue) PrecacheSoundAnyDownload(g_sUnWarden);
	}
	else if(convar == gc_sStart)
	{
		strcopy(g_sStart, sizeof(g_sStart), newValue);
		if(gc_bSounds.BoolValue) PrecacheSoundAnyDownload(g_sStart);
	}
		else if(convar == gc_sStop)
	{
		strcopy(g_sStop, sizeof(g_sStop), newValue);
		if(gc_bSounds.BoolValue) PrecacheSoundAnyDownload(g_sStop);
	}
	//else if(convar == gc_sModelPath)
	//{
	//	strcopy(g_sWardenModel, sizeof(g_sWardenModel), newValue);
	//	PrecacheModel(g_sWardenModel);
	//}
	else if(convar == gc_sOverlayStartPath)
	{
		strcopy(g_sOverlayStart, sizeof(g_sOverlayStart), newValue);
		if(gc_bOverlays.BoolValue) PrecacheOverlayAnyDownload(g_sOverlayStart);
	}
	else if(convar == gc_sOverlayStopPath)
	{
		strcopy(g_sOverlayStop, sizeof(g_sOverlayStop), newValue);
		if(gc_bOverlays.BoolValue) PrecacheOverlayAnyDownload(g_sOverlayStop);
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
		LOOP_CLIENTS(i, CLIENTFILTER_TEAMONE)
				{
						EnableBlock(i);
				}
}

public Action BecomeWarden(int client, int args)
{
	if(gc_bPlugin.BoolValue)
	{
		if (Warden == -1)
		{
			if (GetClientTeam(client) == CS_TEAM_CT)
			{
				if (IsPlayerAlive(client))
				{
				SetTheWarden(client);
				Call_StartForward(gF_OnWardenCreatedByUser);
				Call_PushCell(client);
				Call_Finish();
				}
				else CPrintToChat(client, "%t %t", "warden_tag" , "warden_playerdead");
			}
			else CPrintToChat(client, "%t %t", "warden_tag" , "warden_ctsonly");
		}
		else CPrintToChat(client, "%t %t", "warden_tag" , "warden_exist", Warden);
	}
	else CPrintToChat(client, "%t %t", "warden_tag" , "warden_disabled");
}

public Action ExitWarden(int client, int args) 
{
	if(gc_bPlugin.BoolValue)
	{
		if(client == Warden)
		{
			CPrintToChatAll("%t %t", "warden_tag" , "warden_retire", client);
			
			if(gc_bBetterNotes.BoolValue)
			{
				PrintCenterTextAll("%t", "warden_retire_nc", client);
				PrintHintTextToAll("%t", "warden_retire_nc", client);
			}
			Warden = -1;
			Forward_OnWardenRemoved(client);
			SetEntityRenderColor(client, 255, 255, 255, 255);
//			SetEntityModel(client, "models/player/ctm_gsg9.mdl");
			if(gc_bSounds.BoolValue)	
			{
				EmitSoundToAllAny(g_sUnWarden);
			}
			ResetMarker();
			g_iVoteCount = 0;
			Format(g_sHasVoted, sizeof(g_sHasVoted), "");
			g_sHasVoted[0] = '\0';
		}
		else CPrintToChat(client, "%t %t", "warden_tag" , "warden_notwarden");
	}
	else CPrintToChat(client, "%t %t", "warden_tag" , "warden_disabled");
}

public Action VoteWarden(int client,int args)
{
	if(gc_bPlugin.BoolValue)
	{
		if(gc_bVote.BoolValue)
		{
			char steamid[64];
			GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
			if (warden_exist())
			{
				if (StrContains(g_sHasVoted, steamid, true) == -1)
				{
					int playercount = (GetClientCount(true) / 2);
					g_iVoteCount++;
					int Missing = playercount - g_iVoteCount + 1;
					Format(g_sHasVoted, sizeof(g_sHasVoted), "%s,%s", g_sHasVoted, steamid);
					
					if (g_iVoteCount > playercount)
					{
						RemoveTheWarden(client);
					}
					else CPrintToChatAll("%t %t", "warden_tag" , "warden_need", Missing, client);
				}
				else CPrintToChat(client, "%t %t", "warden_tag" , "warden_voted");
			}
			else CPrintToChat(client, "%t %t", "warden_tag" , "warden_noexist");
		}
		else CPrintToChat(client, "%t %t", "warden_tag" , "warden_voting");
	}
	else CPrintToChat(client, "%t %t", "warden_tag" , "warden_disabled");
}

public Action playerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid")); // Get the dead clients id
	
	if(client == Warden) // Aww damn , he is the warden
	{
		if(gc_bSounds.BoolValue)
		{
			EmitSoundToAllAny(g_sUnWarden);
		}
		CPrintToChatAll("%t %t", "warden_tag" , "warden_dead", client);
		
		if(gc_bBetterNotes.BoolValue)
		{
			PrintCenterTextAll("%t", "warden_dead_nc", client);
			PrintHintTextToAll("%t", "warden_dead_nc", client);
		}
		
		Warden = -1;
		Call_StartForward(gF_OnWardenDeath);
		Call_PushCell(client);
		Call_Finish();
	}
}

public Action SetWarden(int client,int args)
{
	if(gc_bPlugin.BoolValue)	
	{
		if(IsValidClient(client))
		{
			Menu menu = CreateMenu(m_SetWarden);
			menu.SetTitle("Select players");
			for(int i = 1;i <= MaxClients;i++) if(IsValidClient(i, true))
			{
				if(GetClientTeam(i) == CS_TEAM_CT && IsClientWarden(i) == false)
				{
					char userid[11];
					char username[MAX_NAME_LENGTH];
					IntToString(GetClientUserId(i), userid, sizeof(userid));
					Format(username, sizeof(username), "%N", i);
					menu.AddItem(userid,username);
				}
			}
			menu.ExitButton = true;
			menu.Display(client,MENU_TIME_FOREVER);
		}
	}
	return Plugin_Handled;
}

public int m_SetWarden(Menu menu, MenuAction action, int client, int Position)
{
	if(action == MenuAction_Select)
	{
		char Item[11];
		menu.GetItem(Position,Item,sizeof(Item));
		for(int i = 1;i <= MaxClients;i++) if(IsValidClient(i, true))
		{
			if(GetClientTeam(i) == CS_TEAM_CT && IsClientWarden(i) == false)
			{
				int userid = GetClientUserId(i);
				if(userid == StringToInt(Item))
				{
					if(IsWarden() == true)
					{
						tempwarden[client] = userid;
						Menu menu1 = CreateMenu(m_WardenOverwrite);
						char buffer[64];
						Format(buffer,sizeof(buffer), "Kick warden %N?", Warden);
						menu1.SetTitle(buffer);
						menu1.AddItem("1", "Yes");
						menu1.AddItem("0", "No");
						menu1.ExitButton = false;
						menu1.Display(client,MENU_TIME_FOREVER);
					}
					else
					{
						Warden = i;
						CPrintToChatAll("%t %t", "warden_tag" , "warden_new", Warden);
						CreateTimer(0.5, Timer_WardenFixColor, i, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
						Call_StartForward(gF_OnWardenCreatedByAdmin);
						Call_PushCell(i);
						Call_Finish();
					}
				}
			}
		}
	}
}

public int m_WardenOverwrite(Menu menu, MenuAction action, int client, int Position)
{
	if(action == MenuAction_Select && IsClientWarden(client))
	{
		char Item[11];
		menu.GetItem(Position,Item,sizeof(Item));
		int choice = StringToInt(Item);
		if(choice == 1)
		{
			int newwarden = GetClientOfUserId(tempwarden[client]);
			CPrintToChatAll("%t %t", "warden_tag" , "warden_removed", Warden);
			CPrintToChatAll("%t %t", "warden_tag" , "warden_new", newwarden);
			Warden = newwarden;
			CreateTimer(0.5, Timer_WardenFixColor, newwarden, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			Call_StartForward(gF_OnWardenCreatedByAdmin);
			Call_PushCell(newwarden);
			Call_Finish();
		}
	}
}

public Action Timer_WardenFixColor(Handle timer,any client)
{
	if(IsValidClient(client, true))
	{
		int g_iWardenColorRedw;
		int g_iWardenColorGreenw;
		int g_iWardenColorBluew;
		g_iWardenColorRedw = GetConVarInt(g_iWardenColorRed);
		g_iWardenColorGreenw = GetConVarInt(g_iWardenColorGreen);
		g_iWardenColorBluew = GetConVarInt(g_iWardenColorBlue);

		if(IsClientWarden(client))
		{
			if(gc_bPlugin.BoolValue)	
			{ 
				if(gc_bColor.BoolValue)	
				{
					SetEntityRenderColor(client, g_iWardenColorRedw, g_iWardenColorGreenw, g_iWardenColorBluew, 255);
				}
//				if(gc_bModel.BoolValue)
//				{
//					//GetClientModel(client, g_sModelPath, sizeof(g_sModelPath));
//					//GetEntPropString(client, Prop_Data, "m_ModelName",g_sModelPath, sizeof(g_sModelPath));
//					SetEntityModel(client, g_sWardenModel);
//				}
			}
		}
		else
		{
			SetEntityRenderColor(client);
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action playerTeam(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client == Warden)
		RemoveTheWarden(client);
}

public void OnClientDisconnect(int client)
{
	if(client == Warden)
	{
		CPrintToChatAll("%t %t", "warden_tag" , "warden_disconnected");
		
		if(gc_bBetterNotes.BoolValue)
		{
			PrintCenterTextAll("%t", "warden_disconnected_nc", client);
			PrintHintTextToAll("%t", "warden_disconnected_nc", client);
		}
		
		Warden = -1;
		Forward_OnWardenRemoved(client);
		Call_StartForward(gF_OnWardenDisconnected);
		Call_PushCell(client);
		Call_Finish();
		if(gc_bSounds.BoolValue)	
		{
			EmitSoundToAllAny(g_sUnWarden);
		}
		ResetMarker();
	}
}

public Action RemoveWarden(int client, int args)
{
	if(Warden != -1)
	{
		RemoveTheWarden(client);
		Call_StartForward(gF_OnWardenRemovedByAdmin);
		Call_PushCell(client);
		Call_Finish();
	}
//	else CPrintToChatAll("%t %t", "warden_tag" , "warden_noexist");
	return Plugin_Handled;
	}

/*
public Action HookPlayerChat(int client, const char[] command, int args)
{
	if(Warden == client && client)
	{
		char szText[256];
		GetCmdArg(1, szText, sizeof(szText));
		
		if(szText[0] == '/' || szText[0] == '@' || IsChatTrigger())
			return Plugin_Handled;
		if(szText[0] == '!')
			return Plugin_Continue;
		
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
		{
			CPrintToChatAll("%t {blue}%N{default}: %s", "warden_tag", client, szText);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}
*/

void SetTheWarden(int client)
{
	if(gc_bPlugin.BoolValue)	
	{
		CPrintToChatAll("%t %t", "warden_tag" , "warden_new", client);
		
		if(gc_bBetterNotes.BoolValue)
		{
			PrintCenterTextAll("%t", "warden_new_nc", client);
			PrintHintTextToAll("%t", "warden_new_nc", client);
		}
		Warden = client;
		CreateTimer(0.5, Timer_WardenFixColor, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		SetClientListeningFlags(client, VOICE_NORMAL);
		Forward_OnWardenCreation(client);
		if(gc_bSounds.BoolValue)	
		{
			EmitSoundToAllAny(g_sWarden);
		}
		ResetMarker();
	}
	else CPrintToChat(client, "%t %t", "warden_tag" , "warden_disabled");
}

void RemoveTheWarden(int client)
{
	CPrintToChatAll("%t %t", "warden_tag" , "warden_removed", client, Warden);
	
	if(gc_bBetterNotes.BoolValue)
	{
		PrintCenterTextAll("%t", "warden_removed_nc", client, Warden);
		PrintHintTextToAll("%t", "warden_removed_nc", client, Warden);
	}
	
	if(IsClientInGame(client) && IsPlayerAlive(client) && warden_iswarden(client))
	SetEntityRenderColor(Warden, 255, 255, 255, 255);
//	SetEntityModel(client, "models/player/ctm_gsg9.mdl");
	Warden = -1;
	Call_StartForward(gF_OnWardenRemovedBySelf);
	Call_PushCell(client);
	Call_Finish();
	Forward_OnWardenRemoved(client);
	if(gc_bSounds.BoolValue)	
	{
		EmitSoundToAllAny(g_sUnWarden);
	}
	ResetMarker();
	g_iVoteCount = 0;
	Format(g_sHasVoted, sizeof(g_sHasVoted), "");
	g_sHasVoted[0] = '\0';
}

public Action CDMenu(int client, int args)
{
	Menu menu = new Menu(CDHandler);
	menu.SetTitle("Choose A Countdown");
	menu.AddItem("start", "Start Countdown");
	menu.AddItem("stop", "Stop Countdown");
	menu.AddItem("startstop", "Start/Stop Countdown");
	menu.ExitButton = false;
	menu.Display(client, 20);
	return Plugin_Handled;
}

public int CDHandler(Menu menu, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(selection, info, sizeof(info));
		
		if ( strcmp(info,"start") == 0 ) 
		{
		FakeClientCommand(client, "sm_cdstart");
		}
		else if ( strcmp(info,"stop") == 0 ) 
		{
		FakeClientCommand(client, "sm_cdstop");
		}
		else if ( strcmp(info,"startstop") == 0 ) 
		{
		FakeClientCommand(client, "sm_cdstartstop");
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action StartStopCDMenu(int client, int args)
{
	Menu menu = new Menu(StartStopCDHandler);
	menu.SetTitle("Time between Start & Stop");
	menu.AddItem("10", "10 Sek.");
	menu.AddItem("30", "30 Sek.");
	menu.AddItem("60", "1 Min.");
	menu.AddItem("120", "2 Min.");
	menu.AddItem("180", "3 Min.");
	menu.ExitButton = false;
	menu.Display(client, 20);
	return Plugin_Handled;
}

public int StartStopCDHandler(Menu menu, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(selection, info, sizeof(info));
		
		if ( strcmp(info,"10") == 0 ) 
		{
			g_iSetCountStartStopTime = 20;
			SetStartStopCountDown(client, 0);
		}
		else if ( strcmp(info,"30") == 0 ) 
		{
			g_iSetCountStartStopTime = 40;
			SetStartStopCountDown(client, 0);
		}
		else if ( strcmp(info,"60") == 0 ) 
		{
			g_iSetCountStartStopTime = 70;
			SetStartStopCountDown(client, 0);
		}
		else if ( strcmp(info,"120") == 0 ) 
		{
			g_iSetCountStartStopTime = 130;
			SetStartStopCountDown(client, 0);
		}
		else if ( strcmp(info,"180") == 0 ) 
		{
			g_iSetCountStartStopTime = 190;
			SetStartStopCountDown(client, 0);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action SetStartCountDown(int client, int args)
{
	if(gc_bCountDown.BoolValue)
	{
		if (warden_iswarden(client))
		{
			if (!IsCountDown)
			{
				g_iCountStopTime = 9;
				CreateTimer( 1.0, StartCountdown, client, TIMER_REPEAT);
				PrintHintTextToAll("%t", "warden_startcountdownhint_nc");
				CPrintToChatAll("%t %t", "warden_tag" , "warden_startcountdownhint");
				IsCountDown = true;
			}
			else CPrintToChat(client, "%t %t", "warden_tag" , "warden_countdownrunning");
		}
		else CPrintToChat(client, "%t %t", "warden_tag" , "warden_notwarden");
	}
}

public Action SetStopCountDown(int client, int args)
{
	if(gc_bCountDown.BoolValue)
	{
		if (warden_iswarden(client))
		{
			if (!IsCountDown)
			{
				g_iCountStopTime = 20;
				CreateTimer( 1.0, StopCountdown, client, TIMER_REPEAT);
				PrintHintTextToAll("%t", "warden_stopcountdownhint_nc");
				CPrintToChatAll("%t %t", "warden_tag" , "warden_stopcountdownhint");
				IsCountDown = true;
			}
			else CPrintToChat(client, "%t %t", "warden_tag" , "warden_countdownrunning");
		}
		else CPrintToChat(client, "%t %t", "warden_tag" , "warden_notwarden");
	}
}

public Action SetStartStopCountDown(int client, int args)
{
	if(gc_bCountDown.BoolValue)
	{
		if (warden_iswarden(client))
		{
			if (!IsCountDown)
			{
				g_iCountStartTime = 9;
				CreateTimer( 1.0, StartCountdown, client, TIMER_REPEAT);
				CreateTimer( 1.0, StopStartStopCountdown, client, TIMER_REPEAT);
				PrintHintTextToAll("%t", "warden_startstopcountdownhint_nc");
				CPrintToChatAll("%t %t", "warden_tag" , "warden_startstopcountdownhint");
				IsCountDown = true;
			}
			else CPrintToChat(client, "%t %t", "warden_tag" , "warden_countdownrunning");
		}
		else CPrintToChat(client, "%t %t", "warden_tag" , "warden_notwarden");
	}
}

public Action StartCountdown( Handle timer, any client ) 
{
	if (g_iCountStartTime > 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			if (g_iCountStartTime < 6) 
			{
				PrintCenterText(client,"%t", "warden_startcountdown_nc", g_iCountStartTime);
				CPrintToChatAll("%t %t", "warden_tag" , "warden_startcountdown", g_iCountStartTime);
			}
		}
		g_iCountStartTime--;
		return Plugin_Continue;
	}
	if (g_iCountStartTime == 0)
	{
		if(IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
		{
			PrintCenterText(client, "%t", "warden_countdownstart_nc");
			CPrintToChatAll("%t %t", "warden_tag" , "warden_countdownstart");
			g_iCountStartTime = 9;
			if(gc_bOverlays.BoolValue)
			{
				CreateTimer( 0.0, ShowOverlayStart, client);
			}
			if(gc_bSounds.BoolValue)	
			{
				EmitSoundToAllAny(g_sStart);
			}
			IsCountDown = false;
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action StopCountdown( Handle timer, any client ) 
{
	if (g_iCountStopTime > 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			if (g_iCountStopTime < 16) 
			{
				PrintCenterText(client,"%t", "warden_stopcountdown_nc", g_iCountStopTime);
				CPrintToChatAll("%t %t", "warden_tag" , "warden_stopcountdown", g_iCountStopTime);
			}
		}
		g_iCountStopTime--;
		return Plugin_Continue;
	}
	if (g_iCountStopTime == 0)
	{
		if(IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
		{
			PrintCenterText(client, "%t", "warden_countdownstop_nc");
			CPrintToChatAll("%t %t", "warden_tag" , "warden_countdownstop");
			g_iCountStopTime = 20;
			g_iCountStartTime = 9;
			if(gc_bOverlays.BoolValue)
			{
				CreateTimer( 0.0, ShowOverlayStop, client);
			}
			if(gc_bSounds.BoolValue)	
			{
				EmitSoundToAllAny(g_sStop);
			}
			IsCountDown = false;
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action StopStartStopCountdown( Handle timer, any client ) 
{
	if ( g_iSetCountStartStopTime > 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			if ( g_iSetCountStartStopTime < 16) 
			{
				PrintCenterText(client,"%t", "warden_stopcountdown_nc", g_iSetCountStartStopTime);
				CPrintToChatAll("%t %t", "warden_tag" , "warden_stopcountdown", g_iSetCountStartStopTime);
			}
		}
		g_iSetCountStartStopTime--;
		return Plugin_Continue;
	}
	if ( g_iSetCountStartStopTime == 0)
	{
		if(IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
		{
			PrintCenterText(client, "%t", "warden_countdownstop_nc");
			CPrintToChatAll("%t %t", "warden_tag" , "warden_countdownstop");
			g_iCountStartTime = 9;
			if(gc_bOverlays.BoolValue)
			{
				CreateTimer( 0.0, ShowOverlayStop, client);
			}
			if(gc_bSounds.BoolValue)	
			{
				EmitSoundToAllAny(g_sStop);
			}
			IsCountDown = false;
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}



public Action ShowOverlayStop( Handle timer, any client ) 
{
	if(IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
	{
		int iFlag = GetCommandFlags( "r_screenoverlay" ) & ( ~FCVAR_CHEAT ); 
		SetCommandFlags( "r_screenoverlay", iFlag ); 
		ClientCommand( client, "r_screenoverlay \"%s.vtf\"", g_sOverlayStop);
		CreateTimer( 2.0, DeleteOverlay, client );
	}
	return Plugin_Continue;
}



public Action EnableNoBlock(int client)
{
	SetEntData(client, g_CollisionOffset, 2, 4, true);
}

public Action EnableBlock(int client)
{
	SetEntData(client, g_CollisionOffset, 5, 4, true);
}

public Action noblockon(int client, int args)
{
	if(gc_bNoBlock.BoolValue)	
	{
		if (warden_iswarden(client))
		{
	
		LOOP_CLIENTS(i, CLIENTFILTER_TEAMONE)
				{
						
						EnableNoBlock(i);	
				}

		CPrintToChatAll("%t %t", "warden_tag" , "warden_noblockon");
		}
		else
		{
		CPrintToChat(client, "%t %t", "warden_tag" , "warden_notwarden");
		}
	}
}

public Action noblockoff(int client, int args)
{ 
	if (warden_iswarden(client))
	{
	LOOP_CLIENTS(i, CLIENTFILTER_TEAMONE)
				{
					
						EnableBlock(i);	
				}
	CPrintToChatAll("%t %t", "warden_tag" , "warden_noblockoff");	
		}
	else
	{
		CPrintToChat(client, "%t %t", "warden_tag" , "warden_notwarden"); 
	}
}

public Action ToggleFF(int client, int args)
{
	if (gc_bFF.BoolValue) 
	{
		if (g_bFF.BoolValue) 
		{
			if (warden_iswarden(client))
			{
				g_bFF.BoolValue = false;
				CPrintToChatAll("%t %t", "warden_tag", "warden_ffisoff" );
			}else CPrintToChatAll("%t %t", "warden_tag", "warden_ffison" );
			
		}else
		{	
			if (warden_iswarden(client))
			{
				g_bFF.BoolValue = true;
				CPrintToChatAll("%t %t", "warden_tag", "warden_ffison" );
			}
			else CPrintToChatAll("%t %t", "warden_tag", "warden_ffisoff" );
		}
	}
}

public Action KillRandom(int client, int args)
{
	if (gc_bRandom.BoolValue) 
	{
		if (warden_iswarden(client))
		{
			int clientV = GetRandomPlayer(CS_TEAM_T);
			if(clientV > 0)
			{
				ForcePlayerSuicide(clientV);
				CPrintToChatAll("%t %t", "warden_tag", "warden_israndomdead", clientV); 
			}
		}
		else CPrintToChat(client, "%t %t", "warden_tag" , "warden_notwarden"); 
	}
}

stock int GetRandomPlayer(int team) 
{
	int[] clients = new int[MaxClients];
	int clientCount;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (Client_IsIngame(i) && (GetClientTeam(i) == team))
		{
			clients[clientCount++] = i;
		}
	}
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount-1)];
}

public Action ccounter(Handle timer, Handle pack)
{
	if(gc_bPlugin.BoolValue)
	{
		--opentimer;
		if(opentimer < 1)
		{
		if(warden_exist() != 1)	
		{
			if(gc_bOpenTimer.BoolValue)	
			{
			SJD_OpenDoors(); 
			CPrintToChatAll("%t %t", "warden_tag" , "warden_openauto");
			
			if (countertime != null)
				KillTimer(countertime);
			
			countertime = null;
			}
			
		}else 
		if(gc_bOpenTimer.BoolValue)
			{
			if(gc_bOpenTimerWarden.BoolValue)
			{
			SJD_OpenDoors(); 
			CPrintToChatAll("%t %t", "warden_tag" , "warden_openauto");
			
			if (countertime != null)
				KillTimer(countertime);
			
			countertime = null;
			}else
		CPrintToChatAll("%t %t", "warden_tag" , "warden_opentime"); 
			if (countertime != null)
			KillTimer(countertime);
			countertime = null;
			} 
		}
	}
}

public Action OpenDoors(int client, int args)
{
	if(gc_bPlugin.BoolValue)	
	{
	if(gc_bOpen.BoolValue)
	{
	if (warden_iswarden(client))
	{
	CPrintToChatAll("%t %t", "warden_tag" , "warden_dooropen"); 
	SJD_OpenDoors();
	}
	else
	CPrintToChat(client, "%t %t", "warden_tag" , "warden_notwarden"); 
	}
	}
}

public Action CloseDoors(int client, int args)
{
	if(gc_bPlugin.BoolValue)	
	{
	if(gc_bOpen.BoolValue)
	{
		if (warden_iswarden(client))
		{
			CPrintToChatAll("%t %t", "warden_tag" , "warden_doorclose"); 
			SJD_CloseDoors();
			if (countertime != null)
			KillTimer(countertime);
			countertime = null;
		}
		else CPrintToChat(client, "%t %t", "warden_tag" , "warden_notwarden"); 
	}
	}
}

public int Native_ExistWarden(Handle plugin, int numParams)
{
	if(Warden != -1)
		return true;
	
	return false;
}

public int Native_IsWarden(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if(!IsClientInGame(client) && !IsClientConnected(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if(client == Warden)
		return true;
	
	return false;
}

public int Native_SetWarden(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if(Warden == -1)
		SetTheWarden(client);
}

public int Native_RemoveWarden(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsClientInGame(client) && !IsClientConnected(client))
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
	
	if(client == Warden)
		RemoveTheWarden(client);
}

public int Native_GetWarden(Handle plugin, int argc)
{	
		return Warden;
}

void Forward_OnWardenCreation(int client)
{
	Call_StartForward(g_fward_onBecome);
	Call_PushCell(client);
	Call_Finish();
}

void Forward_OnWardenRemoved(int client)
{
	Call_StartForward(g_fward_onRemove);
	Call_PushCell(client);
	Call_Finish();
}

stock bool IsWarden()
{
	if(Warden != -1)
	{
	return true;
	}
	return false;
}

stock bool IsClientWarden(int client)
{
	if(client == Warden)
	{
	return true;
	}
	return false;
}

stock bool IsValidClient(int client, bool alive = false)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)))
	{
	return true;
	}
	return false;
}

public void warden_OnWardenCreated(int client)
{

}

stock void PrecacheOverlayAnyDownload(char [] sOverlay)
{
	char sBufferVmt[256];
	char sBufferVtf[256];
	Format(sBufferVmt, sizeof(sBufferVmt), "%s.vmt", sOverlay);
	Format(sBufferVtf, sizeof(sBufferVtf), "%s.vtf", sOverlay);
	PrecacheDecal(sBufferVmt, true);
	PrecacheDecal(sBufferVtf, true);
	Format(sBufferVmt, sizeof(sBufferVmt), "materials/%s.vmt", sOverlay);
	Format(sBufferVtf, sizeof(sBufferVtf), "materials/%s.vtf", sOverlay);
	AddFileToDownloadsTable(sBufferVmt);
	AddFileToDownloadsTable(sBufferVtf);
}

stock void PrecacheSoundAnyDownload(char [] sSound)
{
	PrecacheSoundAny(sSound);
	char sBuffer[256];
	Format(sBuffer, sizeof(sBuffer), "sound/%s", sSound);
	AddFileToDownloadsTable(sBuffer);
	
}

public Action ShowOverlayStart( Handle timer, any client ) 
{
	if(IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
	{
		int iFlag = GetCommandFlags( "r_screenoverlay" ) & ( ~FCVAR_CHEAT ); 
		SetCommandFlags( "r_screenoverlay", iFlag ); 
		ClientCommand( client, "r_screenoverlay \"%s.vtf\"", g_sOverlayStart);
		CreateTimer( 2.0, DeleteOverlay, client );
	}
	return Plugin_Continue;
}

public Action DeleteOverlay( Handle timer, any client ) 
{
	if(IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
	{
	int iFlag = GetCommandFlags( "r_screenoverlay" ) & ( ~FCVAR_CHEAT ); 
	SetCommandFlags( "r_screenoverlay", iFlag ); 
	ClientCommand( client, "r_screenoverlay \"\"" );
	}
	return Plugin_Continue;
}
