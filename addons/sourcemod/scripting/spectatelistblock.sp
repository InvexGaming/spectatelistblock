#include <sourcemod>
#include <sdkhooks>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

/*********************************
 *  Plugin Information
 *********************************/
#define PLUGIN_VERSION "1.01"

public Plugin myinfo =
{
  name = "Spectate List Block",
  author = "Invex | Byte",
  description = "Block Spectate List Feature of many cheating tools.",
  version = PLUGIN_VERSION,
  url = "http://www.invexgaming.com.au"
};

/*********************************
 *  Globals
 *********************************/

//Convars
ConVar g_Cvar_BlockMode = null;
ConVar g_Cvar_BlockFlag = null;

//Lateload
bool g_LateLoaded = false;

/*********************************
 *  Forwards
 *********************************/
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
  g_LateLoaded = late;
  return APLRes_Success;
}

public void OnPluginStart()
{
  //Convars
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


/*********************************
 *  Hooks
 *********************************/
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
      if (ClientHasAdminFlag(entity, Admin_Generic))
        return Plugin_Handled;
    }
    
    case 2:
    {
      if (IsClientBlockTarget(client))
        return Plugin_Handled;
    }
  }
  
  return Plugin_Continue; // Anything else continue as normal.
}

/*********************************
 *  Stocks
 *********************************/
stock bool IsClientBlockTarget(int client)
{
  if (!IsClientConnected(client) || IsFakeClient(client))
    return false;
  
  char buffer[2];
  g_Cvar_BlockFlag.GetString(buffer, sizeof(buffer));

  //Empty flag means open access
  if(strlen(buffer) == 0)
    return true;

  return ClientHasCharFlag(client, buffer[0]);
}

stock bool ClientHasCharFlag(int client, char charFlag)
{
  AdminFlag flag;
  return (FindFlagByChar(charFlag, flag) && ClientHasAdminFlag(client, flag));
}

stock bool ClientHasAdminFlag(int client, AdminFlag flag)
{
  if (!IsClientConnected(client))
    return false;
  
  AdminId admin = GetUserAdmin(client);
  if (admin != INVALID_ADMIN_ID && GetAdminFlag(admin, flag, Access_Effective))
    return true;
  return false;
}