TOOL.Category = "STRIDER"
TOOL.Name = "#Prop Resizer"
TOOL.Mode = "presizer"
TOOL.ClientConVar["scale"] = "2"

local max = CreateConVar("presizer_max", "13", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "max sizeeeeeee")

function TOOL.BuildCPanel(panel)
	local slider = panel:NumSlider("Scale", "presizer_scale", 0.05, max:GetFloat(), 5)
	slider:SetValue(2)
	local textEntry = slider:GetTextArea()
    if IsValid(textEntry) then
        textEntry:SetEditable(false)
    end
end

local function resize(ent,scale) -- :(
	
	ent:SetModelScale( scale, 0.000001 )
	if SERVER then
		ent:PhysicsInit(SOLID_VPHYSICS) -- Sketchy!
		local physmat = ent:GetPhysicsObject():GetMaterial()
		local phys = ent:GetPhysicsObject()
		local oldMass = phys:GetMass()
		local convexes = phys:GetMeshConvexes()
		local out = {}
		for i, convex in ipairs(convexes) do
		    out[i] = {}
		    for j, v in ipairs(convex) do
		        out[i][j] = v.pos * scale
		    end
		end
		ent:PhysicsInitMultiConvex(out)
		ent:EnableCustomCollisions(true)
		phys = ent:GetPhysicsObject()
		phys:SetMaterial(physmat)
		phys:SetMass( math.Clamp( oldMass * scale ^ 3, 0.1, 50000 ) )
		phys:Wake()
	end
	if CLIENT then
		local out = {}
		ent:PhysicsInit(SOLID_VPHYSICS) -- Sketchy!
		local convexes = ent:GetPhysicsObject():GetMeshConvexes()
		for i, convex in ipairs(convexes) do
		    out[i] = {}
		    for j, v in ipairs(convex) do
		        out[i][j] = v.pos * scale
		    end
		end
		ent:PhysicsInitMultiConvex(out)
		ent:EnableCustomCollisions(true)
		ent:GetPhysicsObject():EnableMotion(false)
		ent:SetMoveType(MOVETYPE_NONE)
		--ent:PhysicsDestroy()
	end
	--if CLIENT then ent:SetMoveType(MOVETYPE_NONE) end
end

if CLIENT then
	language.Add("tool.presizer.name", "Prop Resizer")
	language.Add("tool.presizer.desc", "...")
	language.Add("tool.presizer.0", "Resize the prop you're looking at.")

	hook.Add("OnEntityCreated", "mei_presizer_hook", function(ent)
		ent:SetNWVarProxy("mei_scale", function(ent, name, old, new)
	        if new and new > 0 then
	            resize(ent, new)
	        end
	    end)
	    
	end)

end

function TOOL:LeftClick(trace)
    if CLIENT then return end
    if not IsFirstTimePredicted() then return end
    local ent = trace.Entity
    if ent:IsValid() then
	    local s = self:GetClientNumber("scale")
	    if s <= max:GetFloat() and s > 0 then
		    ent:SetNWFloat("mei_scale", s)
		    resize(ent, s)
		    duplicator.StoreEntityModifier(ent, "meipropresizer", { scale = s })
	    end
    end
    return true
end

duplicator.RegisterEntityModifier("meipropresizer", function(ply, ent, data)
    ent:SetNWFloat("mei_scale", data.scale)
    resize(ent, data.scale)
end)
