#include <sourcemod>
#include <sdkhooks>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

#define VERSION "1.00"

bool g_LateLoaded = false;

//Convars
ConVar g_Cvar_BlockMode = null;
ConVar g_Cvar_BlockFlag = null;

public Plugin myinfo =
{
  name = "Spectate List Block",
  author = "Invex | Byte",
  description = "Block Spectate List Feature of many cheating tools.",
  version = VERSION,
  url = "http://www.invexgaming.com.au"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
  g_LateLoaded = late;
  return APLRes_Success;
}

public void OnPluginStart()
{
  //Convars
  CreateConVar("sm_spectatelistblock_version", VERSION, "", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
  g_Cvar_BlockMode = CreateConVar("sm_spectatelistblock_blockmode", "0", "Which players spectator data should be blocked from reaching clients. 0 = block all players, 1 = block all admins, 2 = block people with flag");
  g_Cvar_BlockFlag = CreateConVar("sm_spectatelistblock_blockflag", "z", "Which flag to block if sm_spectatelistblock_blockmode is set to 2");
  
  AutoExecConfig(true, "spectatelistblock");
  
  //Late load our hook
  if (g_LateLoaded) {
    for (int i = 1; i <= MaxClients; ++i) {
      if (IsClientInGame(i))
        OnClientPutInServer(i);
    }
    
    g_LateLoaded = false;
  }
}

public void OnClientPutInServer(int client)
{
  if (!IsFakeClient(client))
    SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public Action Hook_SetTransmit(int entity, int client) 
{
  if (entity == client) { // Always transmit client to themselves otherwise they will crash
    return Plugin_Continue;
  }
  
  if (entity <= 0 || entity > MaxClients) { // Not a player
    return Plugin_Continue;
  }
  
  if (!IsClientInGame(entity)) { // Not in game.
    return Plugin_Continue;
  }
  
  if (!IsClientInGame(entity)) { // Not in game.
    return Plugin_Continue;
  }
  switch (g_Cvar_BlockMode.IntValue)
  {
    case 0:
    {
      int entityTeam = GetClientTeam(entity);
      if (entityTeam == CS_TEAM_NONE || entityTeam == CS_TEAM_SPECTATOR)
        return Plugin_Handled;
    }
    
    case 1:
    {
      if (ClientHasFlag(entity, Admin_Generic))
        return Plugin_Handled;
    }
    
    case 2:
    {
      AdminFlag flag;
      char buffer[2];
      g_Cvar_BlockFlag.GetString(buffer, sizeof(buffer));
      if (FindFlagByChar(buffer[0], flag) && ClientHasFlag(entity, flag))
        return Plugin_Handled;
    }
  }
  
  return Plugin_Continue; // Anything else continue as normal.
}

stock bool ClientHasFlag(int client, AdminFlag flag)
{
  AdminId admin = GetUserAdmin(client);
  if (admin != INVALID_ADMIN_ID && GetAdminFlag(admin, flag, Access_Effective))
    return true;
  return false;
}