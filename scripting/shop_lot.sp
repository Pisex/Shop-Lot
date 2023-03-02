#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <csgo_colors>
#include <shop>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "[SHOP] Lot",
	author = "Pisex",
	version = "1.0"
};

#define DMG_FALL (1 << 5)
Handle g_LotteryPanel,
	g_LotteryHistory,
	kv;
int ScrollTimes[MAXPLAYERS + 1],
	WinNumber[MAXPLAYERS + 1],
	g_iMKB;
bool NextStep[MAXPLAYERS + 1] = false,
	Podkrutka[MAXPLAYERS + 1] = false;
	
char Numb[256];

StringMap g_hMKBInfo;

int g_iCredits[5];

public void OnPluginStart()
{
	g_LotteryHistory = CreateTrie();
	
	RegConsoleCmd("sm_lot", lottery);
	
	g_hMKBInfo = new StringMap();
	if (Shop_IsStarted()) Shop_Started();
	KFG_Load();
}

public void Shop_Started()
{
	Shop_AddToFunctionsMenu(FunctionDisplay, FunctionSelect);
}

public void FunctionDisplay(int client, char[] buffer, int maxlength)
{
	strcopy(buffer, maxlength, "Лотерея");
}
public bool FunctionSelect(int iClient)
{
	lottery(iClient,0);
	return true;
}

public Action lottery(int client,int args)
{
	g_LotteryPanel = CreatePanel();
	DrawPanelItem(g_LotteryPanel, "Да, купить билет, вдруг повезет");
	DrawPanelItem(g_LotteryPanel, "Не-не-не, я отказываюсь участвовать");
	DrawPanelItem(g_LotteryPanel, "Посмотреть шансы на выпадение\n \n");
	//DrawPanelItem(g_LotteryPanel, "Панель Администратора\n \n",(GetAdminFlag(GetUserAdmin(client), Admin_Root))?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	DrawPanelItem(g_LotteryPanel, "Назад");
	DrawPanelItem(g_LotteryPanel, "Выход");
	SetPanelCurrentKey(g_LotteryPanel, 10);
	if (client > 0 && args < 1) {
		char steamid[28];
		int lasttime;
		if (GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)) && GetTrieValue(g_LotteryHistory, steamid, lasttime)) {
			int sec = GetTime() - lasttime;
			if(g_iCredits[0] < 61)
				if (sec < g_iCredits[0]) {
					CGOPrintToChat(client, "{RED}[Lot]{GRAY} Лотерея доступна 1 раз в %i сек. [%i сек.]",g_iCredits[0] , g_iCredits[0] - sec);
					return Plugin_Handled;
				} else
					RemoveFromTrie(g_LotteryHistory, steamid);
			else
			{
				if (sec < g_iCredits[0]) {
					CGOPrintToChat(client, "{RED}[Lot]{GRAY} Лотерея доступна 1 раз в %i мин. и %i сек. [Осталось: %i мин. и %i сек.]", g_iCredits[0]/60,g_iCredits[0]%60, (g_iCredits[0]-sec)/60,g_iCredits[0]-sec);
					return Plugin_Handled;
				} else
					RemoveFromTrie(g_LotteryHistory, steamid);
			}
		}
		wS_ShowLotPanel2(client);
	}
	
	return Plugin_Handled;
}

public int LotMenu(Handle panel, MenuAction action, int client,int item)
{
	if (action == MenuAction_Select) {
		if (item == 1) {
			if (Shop_GetClientCredits(client) > g_iCredits[1] - 1)
			{
				Shop_TakeClientCredits(client, g_iCredits[1]);
				iEx_Start(client);
				char steamid[28];
				if (GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
					SetTrieValue(g_LotteryHistory, steamid, GetTime());
			} else
				PrintToChat(client," \x04[Lot]\x02 У вас не хватает %d кредитов на билет!", g_iCredits[1] - Shop_GetClientCredits(client));
		} else if (item == 3)
			{
				char STIG[16], sBuffer[128], sBufs[4][64];
				for(int i = 0,iCreditsCFG,iDistanceMinCFG,iDistanceMaxCFG,iCreditsTakeCFG;i <= g_iMKB; ++i)
				{
					IntToString(i, STIG, 16);
					g_hMKBInfo.GetString(STIG, sBuffer, 128);
					ExplodeString(sBuffer, ";", sBufs, 4, 64);
					iCreditsCFG = StringToInt(sBufs[0]);
					iCreditsTakeCFG = StringToInt(sBufs[1]);
					iDistanceMinCFG = StringToInt(sBufs[2]);
					iDistanceMaxCFG = StringToInt(sBufs[3]);
					if(iCreditsCFG == 0) PrintToChat(client, " \x04[Lot]\x02 %i-%i -> Шанс Проиграть %i кр.", iDistanceMinCFG, iDistanceMaxCFG, iCreditsTakeCFG);
					else if(iCreditsTakeCFG == 0) PrintToChat(client, " \x04[Lot]\x02 %i-%i -> Шанс Выйграть %i кр.",iDistanceMinCFG, iDistanceMaxCFG, iCreditsCFG);
				}
			}
		// else if(item == 4)
		// {
		// 	Select_PL_MENU(client);
		// }
		else if(item == 4)
		{
			Shop_ShowFunctionsMenu(client);
		}
	}
}

public Action iEx_Start(int client)
{
	
	int RandomNumber = GetRandomInt(0,999);
	if(Podkrutka[client])
	{
		RandomNumber = StringToInt(Numb);
		Podkrutka[client] = false;
	}
	Handle panel = CreatePanel(); 
	SetPanelTitle(panel, "Лотерея:\n \n");
	char Message[128], Message2[128], Message3[128];
	
	Format(Message, 128, "█░░░░░░░░░█");
	Format(Message2, 128, "░░░░░░░░░░░");
	
	DrawPanelText(panel, Message);
	DrawPanelText(panel, Message2);
	
	if(RandomNumber < 10)
		Format(Message3, 128, "░░░░00%d░░░░",RandomNumber);
	else
		if(RandomNumber > 9 && RandomNumber < 100)
			Format(Message3, 128, "░░░░0%d░░░░",RandomNumber);
		else
			Format(Message3, 128, "░░░░%d░░░░",RandomNumber);

	DrawPanelText(panel, Message3);
	DrawPanelText(panel, Message2);
	DrawPanelText(panel, Message);
	SendPanelToClient(panel, client, Select_None, 10); 
	CloseHandle(panel);
	
	if(ScrollTimes[client] == 0)
		ClientCommand(client, "playgamesound ui/csgo_ui_crate_open.wav");

	if(ScrollTimes[client] < 20) {
		CreateTimer(0.15, Timer_Next,client);
		ScrollTimes[client] += 1;
		ClientCommand(client, "playgamesound ui/csgo_ui_crate_item_scroll.wav");
	} else
		if(ScrollTimes[client] < 30) {
			float AddSomeTime = 0.14;
			AddSomeTime += 0.01*ScrollTimes[client]/3;
			CreateTimer(AddSomeTime, Timer_Next,client);
			ScrollTimes[client] += 1;
			ClientCommand(client, "playgamesound ui/csgo_ui_crate_item_scroll.wav");
		} else
			if(ScrollTimes[client] == 30) {
				if(GetRandomInt(0,1)) {
					ClientCommand(client, "playgamesound ui/csgo_ui_crate_item_scroll.wav");
					ScrollTimes[client] += 1;
					CreateTimer(2.0, Timer_Next, client);
					if(NextStep[client]) Podkrutka[client] = true;
				} else {
					ClientCommand(client, "playgamesound ui/csgo_ui_crate_item_scroll.wav");
					CreateTimer(2.0, Timer_Finish, client);
					WinNumber[client] = RandomNumber;
					ScrollTimes[client] = 0;
				}
			} else {
				ClientCommand(client, "playgamesound ui/csgo_ui_crate_item_scroll.wav");
				CreateTimer(2.0, Timer_Finish, client);
				WinNumber[client] = RandomNumber;
				ScrollTimes[client] = 0;
			}
}

public Action Timer_Finish(Handle timer, any client)
{
	if (IsClientInGame(client))
		iEx_Win(client, WinNumber[client]);
}

public Action iEx_Win(int client,int Number)
{
	if(IsClientInGame(client))
	{
		bool lv;
		char STIG[16], sBuffer[128], sBufs[4][64];
		int iCreditsCFG,iCreditsTakeCFG;
		bool IsLose = true;
		for(int i = 0,iDistanceMinCFG,iDistanceMaxCFG;i <= g_iMKB; ++i)
		{
			IntToString(i, STIG, 16);
			g_hMKBInfo.GetString(STIG, sBuffer, 128);
			ExplodeString(sBuffer, ";", sBufs, 4, 64);
			iCreditsCFG = StringToInt(sBufs[0]);
			iCreditsTakeCFG = StringToInt(sBufs[1]);
			iDistanceMinCFG = StringToInt(sBufs[2]);
			iDistanceMaxCFG = StringToInt(sBufs[3]);
			if((Number >= iDistanceMinCFG) && (Number <= iDistanceMaxCFG))
			{
				if(iCreditsTakeCFG < 1)
				{
					lv = true;
					IsLose = false;
					break;
				}
				else if(iCreditsTakeCFG > 0)
				{
					lv = false;
					IsLose = false;
					break;
				}
			}
			else
				IsLose = true;
		}
				
		if(IsLose == false)
		{
			if(lv == true)
			{
				PrintToChatAll(" \x04 [Lot]\x02 Игрок \x04\"%N\"\x02 Вытянул лот под номером:\x0B %d",client,Number);
				PrintToChatAll(" \x04 [Lot]\x02 Выиграл: \x0B%i Кредитов, не плохой навар!!!",iCreditsCFG);
				ClientCommand(client, "playgamesound ui/panorama/case_reveal_legendary_01.wav");
				Shop_GiveClientCredits(client, iCreditsCFG,IGNORE_FORWARD_HOOK);
			}
			else if(lv == false)
			{
				PrintToChatAll(" \x04 [Lot]\x02 Игрок \x04\"%N\"\x02 Вытянул лот под номером:\x0B %d", client, Number);
				PrintToChatAll(" \x04 [Lot]\x02 Ему сильно не повезло, Проиграл: \x0B%i Кредитов!", iCreditsTakeCFG);
				ClientCommand(client, "playgamesound music/skog_01/lostround.mp3");
				Shop_TakeClientCredits(client, iCreditsTakeCFG ,IGNORE_FORWARD_HOOK);
			}
		}
		else if(IsLose == true)
		{
			if(g_iCredits[2] == 1)
			{
				int b = Shop_GetClientCredits(client);
				PrintToChatAll(" \x04 [Lot]\x02 Игрок \x04\"%N\"\x02 Вытянул лот под номером:\x0B %d", client, Number);
				PrintToChatAll(" \x04 [Lot]\x02 И проиграл все свои кредиты, Проиграл: \x0B%i Кредитов!", b);
				ClientCommand(client, "playgamesound music/skog_01/lostround.mp3");
				Shop_TakeClientCredits(client, b ,IGNORE_FORWARD_HOOK);
			}
			else if(g_iCredits[2] == 0)
			{
				int a = GetRandomInt(g_iCredits[3], g_iCredits[4]);
				PrintToChatAll(" \x04 [Lot]\x02 Игрок \x04\"%N\"\x02 Вытянул лот под номером:\x0B %d", client, Number);
				PrintToChatAll(" \x04 [Lot]\x02 Ему сильно не повезло, Проиграл: \x0B%d Кредитов!", a);
				ClientCommand(client, "playgamesound music/skog_01/lostround.mp3");
				Shop_TakeClientCredits(client, a ,IGNORE_FORWARD_HOOK);
			}
		}
	}
}

public Action Timer_Next(Handle timer, any client)
{
	if (IsClientInGame(client))
		iEx_Start(client);
}

public int Select_None(Handle panel, MenuAction action, int client,int option) 
{
}

public Action wS_ShowLotPanel2(int client)
{
	SetPanelTitle(g_LotteryPanel, "[Lot] Лотерея\n \n");
	SendPanelToClient(g_LotteryPanel, client, LotMenu, 0);
}

void KFG_Load()
{	
	if(kv) delete kv;
	char buffer[PLATFORM_MAX_PATH], g[64], STIG[16], sBuffer[128];
	int iCredits,iCreditsTake, iDistanceMin,iDistanceMax;
	kv = CreateKeyValues("lotshop");
	BuildPath(Path_SM, buffer, sizeof buffer, "configs/shop/lot.ini");
	FileToKeyValues(kv, buffer);
	KvRewind(kv);
	g_iCredits[0] = KvGetNum(kv,"time");
	g_iCredits[1] = KvGetNum(kv,"ticket");
	g_iCredits[2] = KvGetNum(kv,"takeall_credits");
	g_iCredits[3] = KvGetNum(kv,"take_credits_min");
	g_iCredits[4] = KvGetNum(kv,"take_credits_max");
	KvJumpToKey(kv,"lot", false);
	KvGotoFirstSubKey(kv, true);
	g_iMKB = -1;
	do 
	{
		if (KvGetSectionName(kv, g, 64))
		{
			
			++g_iMKB;
			IntToString(g_iMKB, STIG, 16);
			iCredits = KvGetNum(kv, "give_credits");
			iCreditsTake = KvGetNum(kv, "take_credits");
			iDistanceMin = KvGetNum(kv, "distance_min");
			iDistanceMax = KvGetNum(kv, "distance_max");
			Format(sBuffer, 128, "%i;%i;%i;%i",iCredits,iCreditsTake, iDistanceMin,iDistanceMax);
			g_hMKBInfo.SetString(STIG, sBuffer);
		}
	} while (KvGotoNextKey(kv, true));
}