# Grain Rot Depth Keeper

Mod UE4SS dla Grain Rot: zachowuje głębokość po nieudanej wyprawie, aby następny zjazd windą nie zaczynał się od piętra pierwszego.

**Status: v0.1.0, wersja testowa.** Kod oparty na polach z dostarczonego `.usmap` (Helden, UE 5.7.4), bez testu wewnątrz gry.

## Instalacja
1. Zainstaluj działającą wersję UE4SS dla Grain Rot.
2. Pobierz ZIP z **GitHub Actions → Artifacts**, następnie wypakuj do `Grain Rot\Helden\Binaries\Win64\`.
3. Sprawdź, czy istnieje `ue4ss\Mods\GrainRotDepthKeeper\Scripts\main.lua` i `enabled.txt`.
4. Gra co-op: mod instaluje tylko host.

## Technicznie
- Odczyt: `HeldenGameInstance.CurrentSaveGame.DungeonLevel` oraz `HeldenGameState.CurrentDungeonRun`.
- Przywrócenie po fladze zakończonej porażką, po powrocie do bazy.
- Lokalna kopia per slot: `%LOCALAPPDATA%\Helden\Saved\GrainRotDepthKeeper_slotN.txt`.
- Brak teleportacji, przywracania ekwipunku czy ingerencji w mapę.
- Logi: `UE4SS.log`, prefiks `[GrainRotDepthKeeper]`.

**Niezweryfikowane:** kolejność autosave'u gry po porażce oraz dokładne przeliczenie pola zapisu na piętro w aktualnym buildzie. Gdyby winda zjechała na zły poziom, potrzebne będą logi UE4SS z rozgrywki. Testy CI symulują zachowanie API, nie uruchamiają Grain Rot.

Kod źródłowy zawiera komentarze dotyczące znanych ograniczeń.
