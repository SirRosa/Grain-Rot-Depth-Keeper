# Grain Rot Depth Keeper

Mod UE4SS dla Grain Rot: zachowuje głębokość po nieudanej wyprawie, aby następny zjazd windą nie zaczynał się od piętra pierwszego.

**Status: v0.2.0, wersja testowa (działanie w grze niepotwierdzone).** Kod oparty na polach z dostarczonego `.usmap` (Helden, UE 5.7.4), bez testu wewnątrz gry.

## Instalacja
1. Zainstaluj działającą wersję UE4SS dla Grain Rot.
2. Pobierz ZIP z **GitHub Actions → Artifacts**, następnie wypakuj do `Grain Rot\Helden\Binaries\Win64\`.
3. Sprawdź, czy istnieje `ue4ss\Mods\GrainRotDepthKeeper\Scripts\main.lua` i `enabled.txt`.
4. Gra co-op: mod instaluje tylko host.

## Technicznie
- Odczyt: `HeldenGameInstance.CurrentSaveGame.DungeonLevel` oraz `HeldenGameState.CurrentDungeonRun`.
- Przywrócenie po fladze zakończonej porażką już na ekranie końca wyprawy i ponownie po powrocie do bazy, jeśli gra wyzeruje postęp później.
- Lokalna kopia per slot: `%LOCALAPPDATA%\Helden\Saved\GrainRotDepthKeeper_slotN.txt`.
- Odświeżenie `HeldenDungeonLevelDisplay.DisplayLevel` po śmierci (jeśli instancja jest dostępna; nie ma jeszcze potwierdzenia, że jest to wyświetlacz maszyny windy).
- Diagnostyka `DungeonLevel`, `CurrentSeed.Level`, stanu wyprawy oraz obiektów windy po powrocie do bazy.
- Brak teleportacji, przywracania ekwipunku czy ingerencji w mapę.
- Logi: `UE4SS.log`, prefiks `[GrainRotDepthKeeper]`.

**Ustalono z logu 2026-11-20:** v0.1 przywracał `DungeonLevel` z 0 do 2 po porażce. Winda nadal pokazywała piętro 1, a po ponownym uruchomieniu gry pokazywała piętro 3. Wskazuje to na nieodświeżony stan runtime/UI.

**Wciąż niezweryfikowane:** czy `HeldenDungeonLevelDisplay` jest właściwym wyświetlaczem windy oraz czy nowy run startuje na poziomie wskazywanym przez ekran. Bez kolejnego logu z v0.2 nie można obiecać pełnej naprawy. Testy CI symulują API, nie uruchamiają Grain Rot.

## Test po instalacji v0.2
1. Uruchom grę z modem; sprawdź, na jakim piętrze jest winda.
2. Przejdź piętro, doprowadź do **porażki całej wyprawy** i wróć do windy **bez restartu gry**.
3. Sprawdź numer w windzie; jeśli nadal jest błędny, nie schodź na kolejne piętro. Zakończ grę i wyślij `ue4ss/UE4SS.log` z liniami `[GrainRotDepthKeeper]`.
4. Wpisy `outpost`, `display refresh`, `run state`, `WARNING` wskażą, czy blokuje nas wyświetlacz, czy generator.

Zaleca się kopię zapisu przed testem.

Kod źródłowy zawiera komentarze dotyczące znanych ograniczeń.
