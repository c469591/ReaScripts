-- @description Name: Solo Track Without Move Edit Cursor (Perform Until Shortcut Released)
-- @version 1.0
-- @author zaibuyidao
-- @changelog Initial release
-- @links
--   webpage https://www.soundengine.cn/user/%E5%86%8D%E8%A3%9C%E4%B8%80%E5%88%80
--   repo https://github.com/zaibuyidao/ReaScripts
-- @donate http://www.paypal.me/zaibuyidao
-- @about Requires JS_ReaScriptAPI & SWS Extension

--[[
1.After running the script, it will work in the background. If you want to stop it, run the script again (or set the script as a toolbar button to toggle it on and off).
2.If the bound key triggers the system alarm, then please bind the key to Action:No-op (no action)
3.If you want to change the key, find reaper-extstate.ini in the REAPER installation folder, find and delete:
[SOLO_TRACK_WITHOUT_MOVE_EDIT_CURSOR]
Key=the key you set
--]]

function print(string) reaper.ShowConsoleMsg(tostring(string)..'\n') end

-- https://docs.microsoft.com/en-us/windows/desktop/inputdev/virtual-key-codes

key_map = { 
    ['0'] = 0x30,
    ['1'] = 0x31,
    ['2'] = 0x32,
    ['3'] = 0x33,
    ['4'] = 0x34,
    ['5'] = 0x35,
    ['6'] = 0x36,
    ['7'] = 0x37,
    ['8'] = 0x38,
    ['9'] = 0x39,
    ['A'] = 0x41,
    ['B'] = 0x42,
    ['C'] = 0x43,
    ['D'] = 0x44,
    ['E'] = 0x45,
    ['F'] = 0x46,
    ['G'] = 0x47,
    ['H'] = 0x48,
    ['I'] = 0x49,
    ['J'] = 0x4A,
    ['K'] = 0x4B,
    ['L'] = 0x4C,
    ['M'] = 0x4D,
    ['N'] = 0x4E,
    ['O'] = 0x4F,
    ['P'] = 0x50,
    ['Q'] = 0x51,
    ['R'] = 0x52,
    ['S'] = 0x53,
    ['T'] = 0x54,
    ['U'] = 0x55,
    ['V'] = 0x56,
    ['W'] = 0x57,
    ['X'] = 0x58,
    ['Y'] = 0x59,
    ['Z'] = 0x5A,
    ['a'] = 0x41,
    ['b'] = 0x42,
    ['c'] = 0x43,
    ['d'] = 0x44,
    ['e'] = 0x45,
    ['f'] = 0x46,
    ['g'] = 0x47,
    ['h'] = 0x48,
    ['i'] = 0x49,
    ['j'] = 0x4A,
    ['k'] = 0x4B,
    ['l'] = 0x4C,
    ['m'] = 0x4D,
    ['n'] = 0x4E,
    ['o'] = 0x4F,
    ['p'] = 0x50,
    ['q'] = 0x51,
    ['r'] = 0x52,
    ['s'] = 0x53,
    ['t'] = 0x54,
    ['u'] = 0x55,
    ['v'] = 0x56,
    ['w'] = 0x57,
    ['x'] = 0x58,
    ['y'] = 0x59,
    ['z'] = 0x5A,
    [','] = 0xBC,
    ['.'] = 0xBE,
    ['<'] = 0xBC,
    ['>'] = 0xBE
}

shift_key = 0x10

state = reaper.JS_VKeys_GetState(0) -- 获取按键的状态
key = reaper.GetExtState("SOLO_TRACK_WITHOUT_MOVE_EDIT_CURSOR", "VirtualKey")
--VirtualKeyCode = key_map[key]
if state:byte(shift_key) ~= 0 then -- 检查Shift键是否被按下
    if key == ',' then
        VirtualKeyCode = key_map['<']
    elseif key == '.' then
        VirtualKeyCode = key_map['>']
    end
else
    VirtualKeyCode = key_map[key]
end

function show_select_key_dialog()
    if (not key or not key_map[key]) then
        key = '9'
        local retval, retvals_csv = reaper.GetUserInputs("Set the Solo Key", 1, "Enter 0-9, A-Z, ',' or '.'", key)
        if not retval then
            stop_solo = true
            return stop_solo
        end
        if (not key_map[retvals_csv]) then
            reaper.MB("Cannot set this Key", "Error", 0)
            stop_solo = true
            return stop_solo
        end
        key = retvals_csv
        VirtualKeyCode = key_map[key]
        reaper.SetExtState("SOLO_TRACK_WITHOUT_MOVE_EDIT_CURSOR", "VirtualKey", key, true)
    end
end

show_select_key_dialog()
if stop_solo then return end

function Open_URL(url)
    if not OS then local OS = reaper.GetOS() end
    if OS=="OSX32" or OS=="OSX64" then
      os.execute("open ".. url)
     else
      os.execute("start ".. url)
    end
end

local function UnsoloAllTrack()
    for i = 0, reaper.CountTracks(0)-1 do
        local track = reaper.GetTrack(0, i)
        reaper.SetMediaTrackInfo_Value(track, 'I_SOLO', 0)
    end
end

local function UnselectAllTracks() -- 反選所有軌道
    local first_track = reaper.GetTrack(0, 0)
    if first_track ~= nil then
        reaper.SetOnlyTrackSelected(first_track)
        reaper.SetTrackSelected(first_track, false)
    end
end

local function SaveSelectedItems(t) -- 保存選中的item
    for i = 0, reaper.CountSelectedMediaItems(0)-1 do
        t[i+1] = reaper.GetSelectedMediaItem(0, i)
    end
end

local function RestoreSelectedItems(t) -- 恢復選中的item
    reaper.Main_OnCommand(40289, 0) -- Item: Unselect all items
    for _, item in ipairs(t) do
        reaper.SetMediaItemSelected(item, true)
    end
end

local function SaveSelectedTracks(t)
    for i = 0, reaper.CountSelectedTracks(0)-1 do
        t[i+1] = reaper.GetSelectedTrack(0, i)
    end
end

local function RestoreSelectedTracks(t)
    UnselectAllTracks()
    for _, track in ipairs(t) do
        reaper.SetTrackSelected(track, true)
    end
end

local function SaveSoloTracks(t) -- 保存Solo的軌道
    for i = 1, reaper.CountTracks(0) do 
      local tr= reaper.GetTrack(0, i-1)
      t[#t+1] = {tr_ptr = tr, GUID = reaper.GetTrackGUID(tr), solo = reaper.GetMediaTrackInfo_Value(tr, "I_SOLO") }
    end
end

local function RestoreSoloTracks(t) -- 恢復Solo的軌道状态
    for i = 1, #t do
        local src_tr = reaper.BR_GetMediaTrackByGUID(0, t[i].GUID)
        reaper.SetMediaTrackInfo_Value(src_tr, "I_SOLO", t[i].solo)
    end
end

flag = 0

function main()
    reaper.PreventUIRefresh(1)
    cur_pos = reaper.GetCursorPosition()

    count_sel_items = reaper.CountSelectedMediaItems(0)
    count_sel_track = reaper.CountSelectedTracks(0)
    state = reaper.JS_VKeys_GetState(0) -- 獲取按鍵的狀態

    if state:byte(VirtualKeyCode) ~= 0 and flag == 0 then

        local screen_x, screen_y = reaper.GetMousePosition()
        local track_ret, info_out = reaper.GetTrackFromPoint(screen_x, screen_y)

        init_sel_tracks = {}
        SaveSelectedTracks(init_sel_tracks)
        init_solo_tracks = {}
        SaveSoloTracks(init_solo_tracks) -- 保存選中的軌道

        if count_sel_track <= 1 then
            if track_ret then
                reaper.Main_OnCommand(40340,0) -- Track: Unsolo all tracks

                if count_sel_items == 0 then
                    --reaper.SetTrackSelected(track_ret, true)
                    reaper.SetMediaTrackInfo_Value(track_ret, 'I_SOLO', 2)
                else
                    local selected_track = {} -- 选中的轨道

                    for m = 0, count_sel_items - 1  do
                        local item = reaper.GetSelectedMediaItem(0, m)
                        local track = reaper.GetMediaItem_Track(item)
                        if (not selected_track[track]) then
                            selected_track[track] = true
                        end
                    end
        
                    for track, _ in pairs(selected_track) do
                        --reaper.SetTrackSelected(track, true) -- 將軌道設置為選中
                        reaper.SetMediaTrackInfo_Value(track, 'I_SOLO', 2)
                    end
                end
            end
        elseif count_sel_track > 1 then
            if track_ret then
                reaper.Main_OnCommand(40340,0) -- Track: Unsolo all tracks

                for i = 0, count_sel_track-1 do
                    local track = reaper.GetSelectedTrack(0, i)
                    --reaper.SetTrackSelected(track, true) -- 將軌道設置為選中
                    reaper.SetMediaTrackInfo_Value(track, 'I_SOLO', 2)
                end
            end
        end
        --reaper.SetEditCurPos(cur_pos, 0, 0)
        --reaper.Main_OnCommand(1007, 0) -- Transport: Play
        flag = 1
    elseif state:byte(VirtualKeyCode) == 0 and flag == 1 then
        --reaper.Main_OnCommand(1016, 0) -- Transport: Stop
        RestoreSelectedTracks(init_sel_tracks)
        RestoreSoloTracks(init_solo_tracks) -- 恢復Solo的軌道狀態
        flag = 0
    end

    reaper.SetEditCurPos(cur_pos, 0, 0)
    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.defer(main)
end

if not reaper.JS_VKeys_GetState then
    local retval = reaper.ShowMessageBox("js_ReaScriptAPI extension is required by this script.\nHowever, it doesn't seem to be present for this REAPER installation.\n\nDo you want to download it now ?", "Warning", 1)
    if retval == 1 then
        Open_URL("https://github.com/juliansader/ReaExtensions/tree/master/js_ReaScriptAPI/")
    end
    return
    --reaper.ShowConsoleMsg('Please Install js_ReaScriptAPI extension.\nhttps://forum.cockos.com/showthread.php?t=212174\n')
  else
    reaper.ClearConsole()
    local _, _, sectionId, cmdId = reaper.get_action_context()
    if sectionId ~= -1 then
        reaper.SetToggleCommandState(sectionId, cmdId, 1)
        reaper.RefreshToolbar2(sectionId, cmdId)
        main()
        reaper.atexit(function()
            reaper.SetToggleCommandState(sectionId, cmdId, 0)
            reaper.RefreshToolbar2(sectionId, cmdId)
        end)
    end
end

reaper.defer(function() end)