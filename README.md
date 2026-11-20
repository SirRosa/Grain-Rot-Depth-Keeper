# Grain Rot Depth Keeper

Mod UE4SS dla Grain Rot: zachowuje głębokość po nieudanej wyprawie, aby następny zjazd windą nie zaczynał się od piętra pierwszego.

**Status: v0.3.0, optymalizacja wydajności (weryfikacja FPS w grze oczekuje na test).** Użytkownik potwierdził działanie przywracania głębokości w v0.2.0: po śmierci winda nadal wyświetlała poziom 3.

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
- Diagnostyka `DungeonLevel`, `CurrentSeed.Level` i stanu wyprawy po powrocie do bazy.
- Brak teleportacji, przywracania ekwipunku czy ingerencji w mapę.
- Logi: `UE4SS.log`, prefiks `[GrainRotDepthKeeper]`.

**Ustalono z logu 2026-11-20:** v0.1 przywracał `DungeonLevel` z 0 do 2 po porażce. Winda nadal pokazywała piętro 1, a po ponownym uruchomieniu gry pokazywała piętro 3. Wskazuje to na nieodświeżony stan runtime/UI.

**Wciąż niezweryfikowane:** czy `HeldenDungeonLevelDisplay` jest właściwym wyświetlaczem windy oraz czy nowy run startuje na poziomie wskazywanym przez ekran. Bez kolejnego logu z v0.2 nie można obiecać pełnej naprawy. Testy CI symulują API, nie uruchamiają Grain Rot.

## Optymalizacja v0.3.0
- Hook animacji jest nadal wymagany w obecnym buildzie gry, ale siedem na osiem wywołań od razu kończy się bez odczytu czasu i obiektów UE.
- Odpytywanie stanu gry: co 0,5 s (wcześniej co 0,2 s).
- Pamięć podręczna `GameModeBase`, `HeldenGameInstance`, `HeldenGameState` i wyświetlacza; czyszczenie przy `ClientRestart`, przy przejściu do kolejnej wyprawy i po unieważnieniu UObject.
- Usunięto niepotrzebne odczyty obiektów maszyny windy przy każdym sprawdzeniu ekranu.
- `enabled.txt` i ścieżka instalacji pozostają bez zmian.

**Ważne:** źródłem obciążenia może być samo wywołanie callbacku UE4SS na każdym cyklu animacji. Ograniczenie pracy callbacku nie eliminuje tego kosztu. GitHub Actions mierzy liczbę operacji w symulacji i sprawdza regresje, **nie FPS gry**.

## Sugerowany test porównawczy FPS
1. Na tym samym zapisie i w identycznym miejscu zmierz FPS przez 60 sekund z v0.2.0.
2. Zastąp tylko folder `GrainRotDepthKeeper` wersją v0.3.0, uruchom grę ponownie i powtórz pomiar w tym samym miejscu.
3. Zmierz średnie i 1% low (np. przez CapFrameX albo RTSS), porównuj przy tych samych ustawieniach.
4. Sprawdź odtworzenie piętra po śmierci bez restartowania gry; jeśli pojawi się regresja, prześlij nowy `UE4SS.log`.

## Historia
- v0.1.0: pierwsza próba zachowania głębokości.
- v0.2.0: przywracanie już na ekranie porażki + odświeżenie wyświetlacza (potwierdzone działanie u użytkownika).
- v0.3.0: odciążenie hooka i cache odczytów UE4SS, bez zmian reguł przywracania postępu.

Zaleca się kopię zapisu przed instalacją nowej wersji.
