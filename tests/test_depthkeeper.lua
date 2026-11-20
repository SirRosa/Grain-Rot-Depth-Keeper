-- In-memory UE4SS host/SaveGame mock; no game or original save required.
local main = "ue4ss/Mods/GrainRotDepthKeeper/Scripts/main.lua"
local function actor(fields)
    local a = fields or {}
    function a:IsValid() return self._valid ~= false end
    return a
end

local function sandbox()
    local now, logs, files, hooks = 0, {}, {}, {}
    local gm = actor()
    local save = actor({
        MetaData = {GameSlot = 0}, DungeonLevel = 0, TimePlayed = 1,
        DungeonWins = 0, DungeonFails = 0, _key = "SaveSlot0_1",
    })
    function save:GetFullName() return self._key end
    local gi = actor({CurrentSaveGame = save})
    local dungeon = actor({CurrentSeed = {Level = 0, Seed = 1122}})
    local gs = actor({CurrentDungeonRun = {State = 0, Flags = 0, DungeonActor = dungeon}})
    local display = actor({DisplayLevel = 1})
    local machine = actor({TargetDungeonName = "Dungeon"})
    local elevator = actor({CurrentStationIdx = 0})
    local objects = {
        GameModeBase = gm,
        HeldenGameInstance = gi,
        HeldenGameState = gs,
        HeldenDungeonLevelDisplay = display,
        HeldenElevatorMachine = machine,
        HeldenDungeonElevator = elevator,
    }
    local io_mock = {open = function(path, mode)
        if mode == "r" then
            if not files[path] then return nil end
            return {read = function() return (files[path]:match("([^\r\n]*)")) end, close = function() end}
        end
        if mode == "w" then
            local buf = ""
            return {
                write = function(_, text) buf = buf .. text end,
                close = function() files[path] = buf end,
            }
        end
        error("unexpected mode: " .. tostring(mode))
    end}
    local env = setmetatable({
        os = {clock = function() return now end,
              getenv = function() return "C:\\Users\\Tester\\AppData\\Local" end},
        io = io_mock,
        print = function(msg) logs[#logs+1] = msg end,
        FindFirstOf = function(name) return objects[name] end,
        RegisterHook = function(name, callback) hooks[name] = callback end,
    }, {__index = _G})
    assert(loadfile(main, "t", env))()
    local anim = "/Game/Animation/ABP_HeldenPlayer.ABP_HeldenPlayer_C:BlueprintUpdateAnimation"
    assert(hooks[anim], "heartbeat hook missing")
    return {
        save = save, game = gs, instance = gi, dungeon = dungeon,
        display = display, machine = machine, elevator = elevator,
        objects = objects, logs = logs, files = files,
        tick = function(dt) now = now + (dt or 0.4); hooks[anim]() end,
        createSave = function(slot, level, time, win, fail, key)
            local s = actor({MetaData = {GameSlot = slot}, DungeonLevel = level,
                TimePlayed = time, DungeonWins = win, DungeonFails = fail,
                _key = key or ("SaveSlot" .. slot .. "_2")})
            function s:GetFullName() return self._key end
            gi.CurrentSaveGame = s
            return s
        end,
        setHost = function(flag) objects.GameModeBase = flag and gm or nil end,
    }
end
local count = 0
local function test(name, callback)
    callback()
    count = count + 1
    print("PASS " .. name)
end

test("defeat on displayed floor 15 restores exact raw save depth 15", function()
    local t = sandbox()
    t.tick()
    t.game.CurrentDungeonRun.State = 2
    t.save.DungeonLevel = 1
    t.dungeon.CurrentSeed.Level = 0
    t.tick()
    t.save.DungeonLevel = 15
    t.dungeon.CurrentSeed.Level = 14
    t.tick()
    t.game.CurrentDungeonRun.State = 3
    t.game.CurrentDungeonRun.Flags = 1
    t.save.DungeonLevel = 0
    t.save.DungeonFails = 1
    t.tick()
    assert(t.save.DungeonLevel == 15, "early restore should happen during end screen")
    t.game.CurrentDungeonRun.State = 0
    t.tick()
    assert(t.save.DungeonLevel == 15, "should restore saved depth on return")
    t.tick()
    assert(t.save.DungeonLevel == 15)
end)

test("false deaths, successful exits and normal resets are ignored", function()
    local t = sandbox()
    t.tick()
    t.game.CurrentDungeonRun.State = 2
    t.save.DungeonLevel = 6
    t.dungeon.CurrentSeed.Level = 5
    t.tick()
    -- The current vessel can die but the team can revive it.
    t.game.CurrentDungeonRun.State = 3
    t.game.CurrentDungeonRun.Flags = 0
    t.save.DungeonLevel = 0
    t.tick()
    t.game.CurrentDungeonRun.State = 0
    t.tick()
    assert(t.save.DungeonLevel == 0, "no restore when run did not fail")
    assert(t.display.DisplayLevel == 1, "successful run must leave display untouched")
end)

test("raw save depth zero uses highest observed seed as fallback", function()
    local t = sandbox()
    t.tick()
    t.game.CurrentDungeonRun.State = 2
    t.dungeon.CurrentSeed.Level = 9
    t.tick()
    t.game.CurrentDungeonRun.Flags = "Failed"
    t.game.CurrentDungeonRun.State = 3
    t.tick()
    t.game.CurrentDungeonRun.State = 0
    t.tick()
    assert(t.save.DungeonLevel == 9, "seed offset fallback should preserve depth")
end)

test("no authority on client: does not write save or backup", function()
    local t = sandbox()
    t.setHost(false)
    t.game.CurrentDungeonRun.State = 2
    t.dungeon.CurrentSeed.Level = 10
    t.save.DungeonLevel = 11
    t.tick()
    t.save.DungeonLevel = 0
    t.game.CurrentDungeonRun.State = 0
    t.game.CurrentDungeonRun.Flags = 1
    t.tick()
    assert(t.save.DungeonLevel == 0, "clients must never change authoritative level")
    assert(next(t.files) == nil, "no writes from client")
end)

test("file backup restores after process restart with same slot", function()
    local old = sandbox()
    old.game.CurrentDungeonRun.State = 2
    old.save.TimePlayed = 120
    old.save.DungeonLevel = 15
    old.dungeon.CurrentSeed.Level = 14
    old.tick()
    local data
    for _, value in pairs(old.files) do data = value end
    assert(data and data:find("GRDK1"), "depth backup not stored")
    local new = sandbox()
    -- Transfer one simulated file from the previous Lua process.
    for path, value in pairs(old.files) do new.files[path] = value end
    local s = new.createSave(0, 0, 121, 0, 1, "SaveSlot0_reloaded")
    new.tick()
    assert(s.DungeonLevel == 15, "should restore persisted depth")
end)

test("slot change never copies depth from another game", function()
    local t = sandbox()
    t.game.CurrentDungeonRun.State = 2
    t.save.DungeonLevel = 13
    t.dungeon.CurrentSeed.Level = 12
    t.tick()
    local other = t.createSave(1, 0, 1, 0, 0, "SaveSlot1")
    t.game.CurrentDungeonRun.State = 0
    t.game.CurrentDungeonRun.Flags = 0
    t.tick()
    assert(other.DungeonLevel == 0)
end)

test("new game reusing a slot rejects older backup if playtime rewinds", function()
    local t = sandbox()
    t.save.TimePlayed = 1200
    t.save.DungeonLevel = 15
    t.tick()
    local other = t.createSave(0, 0, 1, 0, 0, "NewGameSameSlot")
    t.tick()
    assert(other.DungeonLevel == 0, "old game depth must not pollute new game")
end)


test("failed run refreshes stale cached outpost display without relaunch", function()
    local t = sandbox()
    t.save.DungeonLevel = 2
    t.display.DisplayLevel = 3
    t.tick()
    t.game.CurrentDungeonRun.State = 2
    t.dungeon.CurrentSeed.Level = 2
    t.tick()
    t.game.CurrentDungeonRun.State = 3
    t.game.CurrentDungeonRun.Flags = 1
    t.save.DungeonLevel = 0
    t.tick()
    assert(t.save.DungeonLevel == 2)
    t.game.CurrentDungeonRun.State = 0
    t.display.DisplayLevel = 1
    t.tick(3.5)
    assert(t.display.DisplayLevel == 3, "UI field should refresh to prior floor")
end)

test("game can reset depth again after end screen and keeper re-restores it", function()
    local t = sandbox()
    t.save.DungeonLevel = 4
    t.tick()
    t.game.CurrentDungeonRun.State = 2
    t.dungeon.CurrentSeed.Level = 3
    t.tick()
    t.game.CurrentDungeonRun.State = 3
    t.game.CurrentDungeonRun.Flags = 1
    t.save.DungeonLevel = 0
    t.tick()
    assert(t.save.DungeonLevel == 4)
    t.game.CurrentDungeonRun.State = 0
    t.save.DungeonLevel = 0
    t.tick()
    assert(t.save.DungeonLevel == 4)
end)

print(string.format("ALL TESTS PASSED (%d)", count))
