#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <lvl_ranks>

#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHOR "RoadSide Romeo"

int		g_iDistributorValue,
		g_iDistributorTime;
Handle	g_hTimerGiver[MAXPLAYERS + 1];

public Plugin myinfo = {name = "[LR] Module - Distributor", author = PLUGIN_AUTHOR, version = PLUGIN_VERSION}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch(GetEngineVersion())
	{
		case Engine_CSGO, Engine_CSS, Engine_TF2: LogMessage("[%s Distributor] Запущен успешно", PLUGIN_NAME);
		default: SetFailState("[%s Distributor] Плагин работает только на CS:GO, CS:S или TF2", PLUGIN_NAME);
	}
}

public void OnPluginStart()
{
	LoadTranslations("levels_ranks_distributor.phrases");
}

public void OnMapStart() 
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/distributor.ini");
	KeyValues hLR_Distributor = new KeyValues("LR_Distributor");

	if(!hLR_Distributor.ImportFromFile(sPath) || !hLR_Distributor.GotoFirstSubKey())
	{
		SetFailState("[%s Distributor] : фатальная ошибка - файл не найден (%s)", PLUGIN_NAME, sPath);
	}

	hLR_Distributor.Rewind();

	if(hLR_Distributor.JumpToKey("Settings"))
	{
		g_iDistributorValue = hLR_Distributor.GetNum("value", 1);
		g_iDistributorTime = hLR_Distributor.GetNum("time", 50);
	}
	else SetFailState("[%s Distributor] : фатальная ошибка - секция Settings не найдена", PLUGIN_NAME);
	delete hLR_Distributor;
}

public void OnClientPostAdminCheck(int iClient)
{
	if((LR_TypeStatistics() < 2) && IsValidClient(iClient))
	{
		g_hTimerGiver[iClient] = CreateTimer(float(g_iDistributorTime), TimerGiver, GetClientUserId(iClient), TIMER_REPEAT);
	}
}

public Action TimerGiver(Handle hTimer, int iUserid)
{
	int iClient = GetClientOfUserId(iUserid);
	if(LR_CoreIsReady() && IsValidClient(iClient) && !IsFakeClient(iClient) && GetClientTeam(iClient) > 1)
	{
		LR_ChangeClientValue(iClient, g_iDistributorValue);
		int iValue = LR_GetClientValue(iClient);

		switch(LR_TypeStatistics())
		{
			case 0: LR_PrintToChat(iClient, "%t", "DistributorExp", iValue, g_iDistributorValue);
			case 1: LR_PrintToChat(iClient, "%t", "DistributorTime", iValue / 3600, iValue / 60 % 60, iValue % 60, g_iDistributorValue);
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	if(g_hTimerGiver[iClient] != null)
	{
		KillTimer(g_hTimerGiver[iClient]);
		g_hTimerGiver[iClient] = null;
	}
}

public void OnPluginEnd()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if(IsClientInGame(iClient))
		{
			OnClientDisconnect(iClient);
		}
	}
}