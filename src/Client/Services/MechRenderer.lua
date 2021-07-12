local MechRenderer = {Priority = 499}


local Network, AssetService, MetronomeService, PilotControls


local MechFolder
local RenderList, RenderLock


local RenderJobID


-- Updates all mechs in our render list
-- @param dt <float>
local function RenderJob(dt)
    RenderLock:Lock()

    for _, rMech in RenderList:Iterator() do
        rMech:Update(dt)
    end

    RenderLock:Release()
end


-- Adds a mech to our render list
-- @param mechAssetID <string>, AssetID of the asset this mech is using
-- @param mechUID <string>, unique ID of the mech
-- @param loadout <table>
-- @param pilot <Player>, who is controlling the mech (TODO: NPC MECHS)
function MechRenderer:RenderMech(mechAssetID, mechUID, loadout, pilot) self:Print("Render", mechUID)
    local realMech = MechFolder:WaitForChild(mechUID, 30)

    if (realMech == nil) then
        -- TODO: DebugService with info dump
        warn("Failed to stream mech", mechAssetID, mechUID, loadout, pilot)
        return
    end

    local mechAsset = AssetService:GetAsset(mechAssetID)
    local rMech = self.Classes.RMech.new(realMech, mechAsset, loadout, pilot)

    RenderLock:Lock()
    RenderList:Add(mechUID, rMech)
    RenderLock:Release()

    -- This is the one we control
    if (pilot == self.LocalPlayer) then
        --PilotControls:SetMech(mechUID)
    end
end


-- Removes a mech from our records
-- @param mechUID <string>
function MechRenderer:RemoveMech(mechUID)
    local rMech = RenderList:Get(mechUID)

    if (rMech ~= nil) then
        rMech:Destroy()
        RenderList:Remove(mechUID)
    end
end


-- Retrieves a mech
-- @param mechUID <string>
-- @returns <RMech>
function MechRenderer:GetMech(mechUID)
    return RenderList:Get(mechUID)
end


-- Enables or disables the renderer
-- @param state <boolean>
function MechRenderer:Enable(state)
    if (state) then
        RenderJobID = MetronomeService:BindToFrequency(60, RenderJob)
    else
        MetronomeService:Unbind(RenderJobID)
    end
end


function MechRenderer:EngineInit()
	Network = self.Services.Network
    AssetService = self.Services.AssetService
    MetronomeService = self.Services.MetronomeService
    PilotControls = self.Services.PilotControls

    MechFolder = workspace.RMechs

    -- Create the renderlist and a mutex to protect against data corruption
    RenderList = self.Classes.IndexedMap.new()
    RenderLock = self.Classes.Mutex.new()
end


function MechRenderer:EngineStart()
	Network:HandleRequestType(
        Network.NetRequestType.MechCreated,
        function(dt, ...) self:RenderMech(...) end
    )

    Network:HandleRequestType(
        Network.NetRequestType.MechRemoved,
        function(dt, ...) self:RemoveMech(...) end
    )

    self:Enable(true)
end


return MechRenderer