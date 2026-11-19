#include <windows.h>
#include <shellapi.h>
#include <stdio.h>
#include <string.h>

#pragma pack(push, 1)
struct CMenuEntry {
    unsigned short m_nAction;
    char m_EntryName[8];
    unsigned char m_nSaveSlot;
    char m_nTargetMenu;
    unsigned short m_nX;
    unsigned short m_nY;
    unsigned short m_nAlign;
};

struct CMenuScreen {
    char m_ScreenName[8];
    char m_nPreviousPage;
    char m_nParentEntry;
    struct CMenuEntry m_aEntries[12];
};
#pragma pack(pop)

#define SCREENS_ARRAY ((struct CMenuScreen*)0x6D8B70)
#define ADDR_CALL_SWITCH 0x499C46

typedef void (__thiscall *tSwitchScreen)(void *pThis, int screen);
static const tSwitchScreen pOrigSwitch = (tSwitchScreen)0x4983EF;

void ConnectToServer(const char *host, int port) {
    char szCurrentExe[MAX_PATH];
    GetModuleFileNameA(NULL, szCurrentExe, MAX_PATH);

    char szGameDir[MAX_PATH];
    strcpy(szGameDir, szCurrentExe);
    char *pSlash = strrchr(szGameDir, '\\');
    if (pSlash) *pSlash = '\0';

    char szDllPath[MAX_PATH];
    wsprintfA(szDllPath, "%s\\0.4.7.1\\vcmp-game.dll", szGameDir);

    char szIniPath[MAX_PATH];
    wsprintfA(szIniPath, "%s\\scripts\\MultiplayerMenu.ini", szGameDir);
    char szNick[64];
    GetPrivateProfileStringA("Settings", "PlayerName", "Player", szNick, sizeof(szNick), szIniPath);

    char szCmd[1024];
    wsprintfA(szCmd, "\"%s\" -c -h %s -c -p %d -n %s", szCurrentExe, host, port, szNick);

    STARTUPINFOA si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    BOOL bCreated = CreateProcessA(
        NULL,
        szCmd,
        NULL,
        NULL,
        FALSE,
        CREATE_SUSPENDED,
        NULL,
        szGameDir,
        &si,
        &pi
    );

    if (bCreated) {
        int nDllPathLen = (int)strlen(szDllPath) + 1;
        LPVOID pRemoteBuf = VirtualAllocEx(pi.hProcess, NULL, nDllPathLen, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
        if (pRemoteBuf) {
            WriteProcessMemory(pi.hProcess, pRemoteBuf, szDllPath, nDllPathLen, NULL);

            HMODULE hKernel32 = GetModuleHandleA("kernel32.dll");
            LPTHREAD_START_ROUTINE pLoadLibrary = (LPTHREAD_START_ROUTINE)GetProcAddress(hKernel32, "LoadLibraryA");

            HANDLE hThread = CreateRemoteThread(pi.hProcess, NULL, 0, pLoadLibrary, pRemoteBuf, 0, NULL);
            if (hThread) {
                WaitForSingleObject(hThread, 5000);
                CloseHandle(hThread);
            }
        }

        ResumeThread(pi.hThread);
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);

        ExitProcess(0);
    }
}

void ConnectCloudServer(void) {
    char szCurrentExe[MAX_PATH];
    GetModuleFileNameA(NULL, szCurrentExe, MAX_PATH);
    char szGameDir[MAX_PATH];
    strcpy(szGameDir, szCurrentExe);
    char *pSlash = strrchr(szGameDir, '\\');
    if (pSlash) *pSlash = '\0';

    char szIniPath[MAX_PATH];
    wsprintfA(szIniPath, "%s\\scripts\\MultiplayerMenu.ini", szGameDir);

    char szHost[256];
    GetPrivateProfileStringA("Settings", "CloudServerHost", "obscure-halibut-9676grp645rx2769w-8192.app.github.dev", szHost, sizeof(szHost), szIniPath);
    int port = GetPrivateProfileIntA("Settings", "CloudServerPort", 8192, szIniPath);

    ConnectToServer(szHost, port);
}

void ConnectLocalServer(void) {
    char szCurrentExe[MAX_PATH];
    GetModuleFileNameA(NULL, szCurrentExe, MAX_PATH);
    char szGameDir[MAX_PATH];
    strcpy(szGameDir, szCurrentExe);
    char *pSlash = strrchr(szGameDir, '\\');
    if (pSlash) *pSlash = '\0';

    char szIniPath[MAX_PATH];
    wsprintfA(szIniPath, "%s\\scripts\\MultiplayerMenu.ini", szGameDir);

    char szHost[256];
    GetPrivateProfileStringA("Settings", "LocalServerHost", "127.0.0.1", szHost, sizeof(szHost), szIniPath);
    int port = GetPrivateProfileIntA("Settings", "LocalServerPort", 8192, szIniPath);

    char szServerExe[MAX_PATH];
    wsprintfA(szServerExe, "%s\\VCMP_Server\\server64.exe", szGameDir);
    char szServerDir[MAX_PATH];
    wsprintfA(szServerDir, "%s\\VCMP_Server", szGameDir);
    ShellExecuteA(NULL, "open", szServerExe, NULL, szServerDir, SW_MINIMIZE);

    Sleep(500);
    ConnectToServer(szHost, port);
}

void __thiscall Hooked_SwitchScreen(void *pThis, int screen) {
    if (screen == 50) {
        ConnectCloudServer();
        return;
    }
    if (screen == 51) {
        ConnectLocalServer();
        return;
    }
    pOrigSwitch(pThis, screen);
}

void SetupInGameMenus(void) {
    DWORD oldProt;
    VirtualProtect((void*)SCREENS_ARRAY, 35 * sizeof(struct CMenuScreen), PAGE_EXECUTE_READWRITE, &oldProt);

    struct CMenuScreen *pScreens = SCREENS_ARRAY;

    // 1. Configure Main Menu (Page 29)
    // Entry 0: Start Game
    pScreens[29].m_aEntries[0].m_nAction = 4;
    strncpy(pScreens[29].m_aEntries[0].m_EntryName, "FEP_STG", 8);
    pScreens[29].m_aEntries[0].m_nSaveSlot = 0;
    pScreens[29].m_aEntries[0].m_nTargetMenu = 1;
    pScreens[29].m_aEntries[0].m_nX = 320;
    pScreens[29].m_aEntries[0].m_nY = 160;
    pScreens[29].m_aEntries[0].m_nAlign = 3;

    // Entry 1: MULTIPLAYER
    pScreens[29].m_aEntries[1].m_nAction = 4;
    strncpy(pScreens[29].m_aEntries[1].m_EntryName, "FEM_MUL", 8);
    pScreens[29].m_aEntries[1].m_nSaveSlot = 0;
    pScreens[29].m_aEntries[1].m_nTargetMenu = 33; // Opens Page 33 in-game
    pScreens[29].m_aEntries[1].m_nX = 320;
    pScreens[29].m_aEntries[1].m_nY = 195;
    pScreens[29].m_aEntries[1].m_nAlign = 3;

    // Entry 2: Options
    pScreens[29].m_aEntries[2].m_nAction = 4;
    strncpy(pScreens[29].m_aEntries[2].m_EntryName, "FEP_OPT", 8);
    pScreens[29].m_aEntries[2].m_nSaveSlot = 0;
    pScreens[29].m_aEntries[2].m_nTargetMenu = 27;
    pScreens[29].m_aEntries[2].m_nX = 320;
    pScreens[29].m_aEntries[2].m_nY = 230;
    pScreens[29].m_aEntries[2].m_nAlign = 3;

    // Entry 3: Quit Game
    pScreens[29].m_aEntries[3].m_nAction = 4;
    strncpy(pScreens[29].m_aEntries[3].m_EntryName, "FEP_QUI", 8);
    pScreens[29].m_aEntries[3].m_nSaveSlot = 0;
    pScreens[29].m_aEntries[3].m_nTargetMenu = 28;
    pScreens[29].m_aEntries[3].m_nX = 320;
    pScreens[29].m_aEntries[3].m_nY = 265;
    pScreens[29].m_aEntries[3].m_nAlign = 3;

    // Clear remaining entries on Page 29
    for (int i = 4; i < 12; i++) {
        memset(&pScreens[29].m_aEntries[i], 0, sizeof(struct CMenuEntry));
    }

    // 2. Configure In-Game Multiplayer Screen (Page 33)
    memset(&pScreens[33], 0, sizeof(struct CMenuScreen));
    strncpy(pScreens[33].m_ScreenName, "FEM_MUL", 8);
    pScreens[33].m_nPreviousPage = 29; // Returns cleanly to Main Menu on ESC / Back!
    pScreens[33].m_nParentEntry = 1;

    // Entry 0: Bangladesh 24/7 Cloud Server
    pScreens[33].m_aEntries[0].m_nAction = 4;
    strncpy(pScreens[33].m_aEntries[0].m_EntryName, "FEM_SR1", 8);
    pScreens[33].m_aEntries[0].m_nSaveSlot = 0;
    pScreens[33].m_aEntries[0].m_nTargetMenu = 50; // Custom target for Cloud Server
    pScreens[33].m_aEntries[0].m_nX = 320;
    pScreens[33].m_aEntries[0].m_nY = 160;
    pScreens[33].m_aEntries[0].m_nAlign = 3;

    // Entry 1: Local Server (127.0.0.1)
    pScreens[33].m_aEntries[1].m_nAction = 4;
    strncpy(pScreens[33].m_aEntries[1].m_EntryName, "FEM_SR2", 8);
    pScreens[33].m_aEntries[1].m_nSaveSlot = 0;
    pScreens[33].m_aEntries[1].m_nTargetMenu = 51; // Custom target for Local Server
    pScreens[33].m_aEntries[1].m_nX = 320;
    pScreens[33].m_aEntries[1].m_nY = 195;
    pScreens[33].m_aEntries[1].m_nAlign = 3;

    // Entry 2: BACK (Action 34 = MENUACTION_GOBACK)
    pScreens[33].m_aEntries[2].m_nAction = 34;
    strncpy(pScreens[33].m_aEntries[2].m_EntryName, "FEDS_TB", 8);
    pScreens[33].m_aEntries[2].m_nSaveSlot = 0;
    pScreens[33].m_aEntries[2].m_nTargetMenu = 0;
    pScreens[33].m_aEntries[2].m_nX = 320;
    pScreens[33].m_aEntries[2].m_nY = 240;
    pScreens[33].m_aEntries[2].m_nAlign = 3;

    VirtualProtect((void*)SCREENS_ARRAY, 35 * sizeof(struct CMenuScreen), oldProt, &oldProt);

    // 3. Patch the single CALL at 0x499C46 to redirect menu selection
    VirtualProtect((void*)ADDR_CALL_SWITCH, 5, PAGE_EXECUTE_READWRITE, &oldProt);
    unsigned char patchCall[5];
    patchCall[0] = 0xE8; // CALL rel32
    DWORD rel = (DWORD)Hooked_SwitchScreen - (ADDR_CALL_SWITCH + 5);
    memcpy(&patchCall[1], &rel, 4);
    memcpy((void*)ADDR_CALL_SWITCH, patchCall, 5);
    VirtualProtect((void*)ADDR_CALL_SWITCH, 5, oldProt, &oldProt);
}

BOOL WINAPI DllMain(HINSTANCE hInst, DWORD dwReason, LPVOID lpReserved) {
    if (dwReason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hInst);

        char *pCmd = GetCommandLineA();
        if (pCmd && strstr(pCmd, "-c") && strstr(pCmd, "-h")) {
            return TRUE;
        }

        SetupInGameMenus();
    }
    return TRUE;
}
