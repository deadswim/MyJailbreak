//includes
#include <cstrike>
#include <sourcemod>
#include <colors>
#include <warden>
#include <emitsoundany>
#include <autoexecconfig>
#include <myjailbreak>
#include <lastrequest>

//Compiler Options
#pragma semicolon 1
#pragma newdecls required

//ConVars
ConVar gc_fRefuseTime;
ConVar gc_bRefuse;
ConVar gc_bPlugin;
ConVar gc_iRefuseLimit;
ConVar gc_iRefuseColorRed;
ConVar gc_iRefuseColorGreen;
ConVar gc_iRefuseColorBlue;
ConVar gc_fCapitulationTime;
ConVar gc_fRebelTime;
ConVar gc_bCapitulation;
ConVar gc_iCapitulationColorRed;
ConVar gc_iCapitulationColorGreen;
ConVar gc_iCapitulationColorBlue;
ConVar gc_bSounds;
ConVar gc_sSoundRefusePath;
ConVar gc_sSoundCapitulationPath;
ConVar gc_bHeal;
ConVar gc_fHealTime;
ConVar gc_iHealLimit;
ConVar gc_iHealColorRed;
ConVar gc_iHealColorGreen;
ConVar gc_iHealColorBlue;


//Bools
bool g_bHealed[MAXPLAYERS+1];
bool g_bCapitulated[MAXPLAYERS+1];
bool g_bRefuse[MAXPLAYERS+1];

//Integers
int g_iRefuseCounter[MAXPLAYERS+1];
int g_iHealCounter[MAXPLAYERS+1];

//Handles
Handle RebelTimer[MAXPLAYERS+1];
Handle RefuseTimer[MAXPLAYERS+1];
Handle CapitulationTimer[MAXPLAYERS+1];
Handle HealTimer[MAXPLAYERS+1];
Handle RefusePanel;

//characters
char g_sSoundRefusePath[256];
char g_sSoundCapitulationPath[256];

public Plugin myinfo = 
{
	name = "MyJailbreak - Appeal",
	author = "shanapu, Jackmaster",
	description = "Appeals - refuse, capitulation/pardon, heal",
	version = PLUGIN_VERSION,
	url = URL_LINK
}

public void OnPluginStart()
{
	// Translation
	LoadTranslations("MyJailbreak.Warden.phrases");
	LoadTranslations("MyJailbreak.Appeal.phrases");
	
	//Client Commands
	RegConsoleCmd("sm_r", Command_refuse);
	RegConsoleCmd("sm_refuse", Command_refuse);
	RegConsoleCmd("sm_v", Command_refuse);
	RegConsoleCmd("sm_verweigern", Command_refuse);
	
	RegConsoleCmd("sm_c", Command_Capitulation);
	RegConsoleCmd("sm_capitulation", Command_Capitulation);
	RegConsoleCmd("sm_e", Command_Capitulation);
	RegConsoleCmd("sm_ergeben", Command_Capitulation);
	RegConsoleCmd("sm_p", Command_Capitulation);
	RegConsoleCmd("sm_pardon", Command_Capitulation);
	
	//AutoExecConfig
	AutoExecConfig_SetFile("Appeal", "MyJailbreak");
	AutoExecConfig_SetCreateFile(true);
	
	gc_bPlugin = AutoExecConfig_CreateConVar("sm_appeal_enable", "1", "Enable or Disable Appeal Plugin");
	gc_bRefuse = AutoExecConfig_CreateConVar("sm_refuse_enable", "1", "Enable or Disable Refuse");
	gc_iRefuseLimit = AutoExecConfig_CreateConVar("sm_refuse_limit", "1", "Сount how many times you can use the command");
	gc_fRefuseTime = AutoExecConfig_CreateConVar("sm_refuse_time", "15.0", "Time after the player gets his normal colors back");
	gc_iRefuseColorRed = AutoExecConfig_CreateConVar("sm_refuse_color_red", "0","What color to turn the refusing Terror into (set R, G and B values to 255 to disable) (Rgb): x - red value", _, true, 0.0, true, 255.0);
	gc_iRefuseColorGreen = AutoExecConfig_CreateConVar("sm_refuse_color_green", "250","What color to turn the refusing Terror into (rGb): x - green value", _, true, 0.0, true, 255.0);
	gc_iRefuseColorBlue = AutoExecConfig_CreateConVar("sm_refuse_color_blue", "250","What color to turn the refusing Terror into (rgB): x - blue value", _, true, 0.0, true, 255.0);
	gc_bCapitulation = AutoExecConfig_CreateConVar("sm_capitulation_enable", "1", "Enable or Disable Capitulation");
	gc_fCapitulationTime = AutoExecConfig_CreateConVar("sm_capitulation_timer", "10.0", "Time to decide to accept the capitulation");
	gc_fRebelTime = AutoExecConfig_CreateConVar("sm_capitulation_rebel_timer", "10.0", "Time to give a rebel on not accepted capitulation his knife back");
	gc_iCapitulationColorRed = AutoExecConfig_CreateConVar("sm_capitulation_color_red", "0","What color to turn the capitulation Terror into (set R, G and B values to 255 to disable) (Rgb): x - red value", _, true, 0.0, true, 255.0);
	gc_iCapitulationColorGreen = AutoExecConfig_CreateConVar("sm_capitulation_color_green", "250","What color to turn the capitulation Terror into (rGb): x - green value", _, true, 0.0, true, 255.0);
	gc_iCapitulationColorBlue = AutoExecConfig_CreateConVar("sm_capitulation_color_blue", "0","What color to turn the capitulation Terror into (rgB): x - blue value", _, true, 0.0, true, 255.0);
	gc_bHeal = AutoExecConfig_CreateConVar("sm_heal_enable", "1", "Enable or Disable heal");
	gc_iHealLimit = AutoExecConfig_CreateConVar("sm_heal_limit", "2", "Сount how many times you can use the command");
	gc_fHealTime = AutoExecConfig_CreateConVar("sm_heal_time", "10.0", "Time after the player gets his normal colors back");
	gc_iHealColorRed = AutoExecConfig_CreateConVar("sm_heal_color_red", "0","What color to turn the heal Terror into (set R, G and B values to 255 to disable) (Rgb): x - red value", _, true, 0.0, true, 255.0);
	gc_iHealColorGreen = AutoExecConfig_CreateConVar("sm_heal_color_green", "250","What color to turn the heal Terror into (rGb): x - green value", _, true, 0.0, true, 255.0);
	gc_iHealColorBlue = AutoExecConfig_CreateConVar("sm_heal_color_blue", "0","What color to turn the heal Terror into (rgB): x - blue value", _, true, 0.0, true, 255.0);
	gc_bSounds = AutoExecConfig_CreateConVar("sm_appeal_sounds_enable", "1", "0 - disabled, 1 - enable sounds ", _, true,  0.0, true, 1.0);
	gc_sSoundRefusePath = AutoExecConfig_CreateConVar("sm_refuse_sound", "music/MyJailbreak/refuse.mp3", "Path to the soundfile which should be played for a refusing.");
	gc_sSoundCapitulationPath = AutoExecConfig_CreateConVar("sm_capitulation_sound", "music/MyJailbreak/refuse.mp3", "Path to the soundfile which should be played for a capitulation.");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	//Hooks
	HookEvent("round_start", RoundStart);
	
	//FindConVar
	gc_sSoundRefusePath.GetString(g_sSoundRefusePath, sizeof(g_sSoundRefusePath));
	gc_sSoundCapitulationPath.GetString(g_sSoundCapitulationPath, sizeof(g_sSoundCapitulationPath));
	
}

public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == gc_sSoundRefusePath)
	{
		strcopy(g_sSoundRefusePath, sizeof(g_sSoundRefusePath), newValue);
		if(gc_bSounds.BoolValue) PrecacheSoundAnyDownload(g_sSoundRefusePath);
	}
	else if(convar == gc_sSoundCapitulationPath)
	{
		strcopy(g_sSoundCapitulationPath, sizeof(g_sSoundCapitulationPath), newValue);
		if(gc_bSounds.BoolValue) PrecacheSoundAnyDownload(g_sSoundCapitulationPath);
	}
}

public void OnMapStart()
{
	if(gc_bSounds.BoolValue)
	{
		PrecacheSoundAnyDownload(g_sSoundRefusePath);
		PrecacheSoundAnyDownload(g_sSoundCapitulationPath);
	}
}


public Action RoundStart(Handle event, char [] name, bool dontBroadcast)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if (IsClientConnected(client))
		{

			if (RefuseTimer[client] != null)
			{
				CloseHandle(RefuseTimer[client]);
				RefuseTimer[client] = null;
			}
			if (CapitulationTimer[client] != null)
			{
				CloseHandle(CapitulationTimer[client]);
				CapitulationTimer[client] = null;
			}
			if (RebelTimer[client] != null)
			{
				CloseHandle(RebelTimer[client]);
				RebelTimer[client] = null;
			}
			if (HealTimer[client] != null)
			{
				CloseHandle(HealTimer[client]);
				HealTimer[client] = null;
			}
			g_iRefuseCounter[client] = 0;
			g_bCapitulated[client] = false;
			g_iHealCounter[client] = 0;
			g_bHealed[client] = false;
		}
	}
	return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
	g_bCapitulated[client] = false;
	g_iRefuseCounter[client] = 0;
	g_iHealCounter[client] = 0;
	g_bHealed[client] = false;
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakedamage);
}


public void OnClientDisconnect(int client)
{
	if (RefuseTimer[client] != null)
	{
		CloseHandle(RefuseTimer[client]);
		RefuseTimer[client] = null;
	}
	if (CapitulationTimer[client] != null)
	{
		CloseHandle(CapitulationTimer[client]);
		CapitulationTimer[client] = null;
	}
	if (HealTimer[client] != null)
	{
		CloseHandle(HealTimer[client]);
		HealTimer[client] = null;
	}
	if (RebelTimer[client] != null)
	{
		CloseHandle(RebelTimer[client]);
		RebelTimer[client] = null;
	}
	if (HealTimer[client] != null)
	{
		CloseHandle(HealTimer[client]);
		HealTimer[client] = null;
	}
	g_bCapitulated[client] = false;
	g_iRefuseCounter[client] = 0;
	g_bHealed[client] = false;
	g_iHealCounter[client] = 0;
}

public Action Command_refuse(int client, int args)
{
	if (gc_bPlugin.BoolValue)
	{
		if (gc_bRefuse.BoolValue)
		{
			if (GetClientTeam(client) == CS_TEAM_CT && IsPlayerAlive(client))
			{
				if (RefuseTimer[client] == null)
				{
					if (g_iRefuseCounter[client] < gc_iRefuseLimit.IntValue)
					{
						g_iRefuseCounter[client]++;
						g_bRefuse[client] = true;
						SetEntityRenderColor(client, gc_iRefuseColorRed.IntValue, gc_iRefuseColorGreen.IntValue, gc_iRefuseColorBlue.IntValue, 255);
						CPrintToChatAll("%t %t", "appeal_tag", "appeal_refusing", client);
						RefuseTimer[client] = CreateTimer(gc_fRefuseTime.FloatValue, ResetColorRefuse, client);
						if (warden_exist()) for(int i=1; i <= MaxClients; i++) RefuseMenu(i);
					}
					else
					{
						CPrintToChat(client, "%t %t", "appeal_tag", "appeal_refusedtimes");
					}
				}
				else
				{
					CPrintToChat(client, "%t %t", "appeal_tag", "appeal_alreadyrefused");
				}
			}
			else
			{
				CPrintToChat(client, "%t %t", "appeal_tag", "appeal_notalivect");
			}
		}
	}
	return Plugin_Handled;
}

public Action RefuseMenu(int warden)
{
	if (IsValidClient(warden, false, false) && warden_iswarden(warden))
	{
		char info1[255];
		RefusePanel = CreatePanel();
		Format(info1, sizeof(info1), "%T", "appeal_refuser", LANG_SERVER);
		SetPanelTitle(RefusePanel, info1);
		DrawPanelText(RefusePanel, "-----------------------------------");
		for(int i = 1;i <= MaxClients;i++) if(IsValidClient(i, true))
		{
			if(g_bRefuse[i])
			{
				char userid[11];
				char username[MAX_NAME_LENGTH];
				IntToString(GetClientUserId(i), userid, sizeof(userid));
				Format(username, sizeof(username), "%N", i);
				DrawPanelText(RefusePanel,username);
			}
		}
		DrawPanelText(RefusePanel, "-----------------------------------");
		SendPanelToClient(RefusePanel, warden, NullHandler, 20);
	}
}

public Action Command_Capitulation(int client, int args)
{
	if (gc_bPlugin.BoolValue)
	{
		if (gc_bCapitulation.BoolValue)
		{
			if (GetClientTeam(client) == CS_TEAM_CT && (IsPlayerAlive(client)))
			{
				if (!(g_bCapitulated[client]))
				{
					if (warden_exist())
					{
						g_bCapitulated[client] = true;
						
						CPrintToChatAll("%t %t", "appeal_tag", "appeal_capitulation", client);
						SetEntityRenderColor(client, gc_iCapitulationColorRed.IntValue, gc_iCapitulationColorGreen.IntValue, gc_iCapitulationColorBlue.IntValue, 255);
						StripAllWeapons(client);
						for(int i=1; i <= MaxClients; i++) CapitulationMenu(i);
					}
					else CPrintToChat(client, "%t %t", "appeal_tag", "warden_noexist");
				}
				else
				{
					CPrintToChat(client, "%t %t", "appeal_tag", "appeal_alreadycapitulated");
				}
			}
			else
			{
				CPrintToChat(client, "%t %t", "appeal_tag", "appeal_notalivect");
			}
		}
	}
	return Plugin_Handled;
}

public Action CapitulationMenu(int warden)
{
	if (IsValidClient(warden, false, false) && warden_iswarden(warden))
	{
		char info5[255], info6[255], info7[255];
		Menu menu1 = CreateMenu(CapitulationMenuHandler);
		Format(info5, sizeof(info5), "%T", "appeal_acceptcapitulation", LANG_SERVER);
		menu1.SetTitle(info5);
		Format(info6, sizeof(info6), "%T", "warden_no", LANG_SERVER);
		Format(info7, sizeof(info7), "%T", "warden_yes", LANG_SERVER);
		menu1.AddItem("0", info6);
		menu1.AddItem("1", info7);
		menu1.Display(warden,gc_fCapitulationTime.IntValue);
	}
}

public int CapitulationMenuHandler(Menu menu, MenuAction action, int client, int Position)
{
	if(action == MenuAction_Select)
	{
		char Item[11];
		menu.GetItem(Position,Item,sizeof(Item));
		int choice = StringToInt(Item);
		if(choice == 1)
		{
			for(int i=1; i <= MaxClients; i++) if(g_bCapitulated[i])
			{
				CapitulationTimer[i] = CreateTimer(gc_fCapitulationTime.FloatValue, GiveKnifeCapitulated, i);
				CPrintToChatAll("%t %t", "warden_tag", "appeal_accepted", i);
			}
		}
		if(choice == 0)
		{
			for(int i=1; i <= MaxClients; i++) if(g_bCapitulated[i])
			{
				RebelTimer[i] = CreateTimer(gc_fRebelTime.FloatValue, GiveKnifeRebel, i);
				CPrintToChatAll("%t %t", "warden_tag", "appeal_noaccepted", i);
			}
		}
	}
}

//heal

public Action Command_Heal(int client, int args)
{
	if (gc_bPlugin.BoolValue)
	{
		if (gc_bHeal.BoolValue)
		{
			if (GetClientTeam(client) == CS_TEAM_CT && (IsPlayerAlive(client)))
			{
				if (HealTimer[client] == null)
				{
					if (g_iHealCounter[client] < gc_iHealLimit.IntValue)
					{
						if (warden_exist())
						{
							g_bHealed[client] = true;
							g_iHealCounter[client]++;
							
							CPrintToChatAll("%t %t", "appeal_tag", "appeal_heal", client);
							SetEntityRenderColor(client, gc_iHealColorRed.IntValue, gc_iHealColorGreen.IntValue, gc_iHealColorBlue.IntValue, 255);
							HealTimer[client] = CreateTimer(gc_fHealTime.FloatValue, ResetColorRefuse, client);
							for(int i=1; i <= MaxClients; i++) HealMenu(i);
						}
						else CPrintToChat(client, "%t %t", "appeal_tag", "warden_noexist");
					}
					else
					{
						CPrintToChat(client, "%t %t", "appeal_tag", "appeal_healwstimes");
					}
				}
				else
				{
					CPrintToChat(client, "%t %t", "appeal_tag", "appeal_alreadyhealed");
				}
			}
			else
			{
				CPrintToChat(client, "%t %t", "appeal_tag", "appeal_notalivect");
			}
		}
	}
	return Plugin_Handled;
}

public Action HealMenu(int warden)
{
	if (IsValidClient(warden, false, false) && warden_iswarden(warden))
	{
		char info5[255], info6[255], info7[255];
		Menu menu1 = CreateMenu(HealMenuHandler);
		Format(info5, sizeof(info5), "%T", "appeal_acceptheal", LANG_SERVER);
		menu1.SetTitle(info5);
		Format(info6, sizeof(info6), "%T", "warden_no", LANG_SERVER);
		Format(info7, sizeof(info7), "%T", "warden_yes", LANG_SERVER);
		menu1.AddItem("0", info6);
		menu1.AddItem("1", info7);
		menu1.Display(warden,gc_fHealTime.IntValue);
	}
}

public int HealMenuHandler(Menu menu, MenuAction action, int client, int Position)
{
	if(action == MenuAction_Select)
	{
		char Item[11];
		menu.GetItem(Position,Item,sizeof(Item));
		int choice = StringToInt(Item);
		if(choice == 1)
		{
			for(int i=1; i <= MaxClients; i++) if(g_bHealed[i])
			{
				GivePlayerItem(i, "weapon_healthshot");
				CPrintToChat(i, "%t %t", "appeal_tag", "appeal_health");
				CPrintToChatAll("%t %t", "warden_tag", "appeal_accepted", i);
				
			}
		}
		if(choice == 0)
		{
			for(int i=1; i <= MaxClients; i++) if(g_bHealed[i])
			{
				CPrintToChatAll("%t %t", "warden_tag", "appeal_noaccepted", i);
			}
		}
	}
}

public Action ResetColorRefuse(Handle timer, any client)
{
	if (IsClientConnected(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	RefuseTimer[client] = null;
	g_bRefuse[client] = false;
}

public Action ResetColorHeal(Handle timer, any client)
{
	if (IsClientConnected(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	HealTimer[client] = null;
	g_bHealed[client] = false;
}

public Action GiveKnifeCapitulated(Handle timer, any client)
{
	if (IsClientConnected(client))
	{
		GivePlayerItem(client,"weapon_knife");
		CPrintToChat(client, "%t %t", "appeal_tag", "appeal_knifeback");
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	CapitulationTimer[client] = null;
}

public Action GiveKnifeRebel(Handle timer, any client)
{
	if (IsClientConnected(client))
	{
		GivePlayerItem(client,"weapon_knife");
		CPrintToChat(client, "%t %t", "appeal_tag", "appeal_knifeback");
		SetEntityRenderColor(client, 255, 0, 0, 255);
		
	}
	g_bCapitulated[client] = false;
	CapitulationTimer[client] = null;
	RebelTimer[client] = null;
}

public Action OnWeaponCanUse(int client, int weapon)
{
	if(g_bCapitulated[client])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action OnTakedamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(g_bCapitulated[attacker])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public int OnAvailableLR(int Announced)
{
	for (int i = 1; i <= MaxClients; i++) g_bCapitulated[i] = false;
}