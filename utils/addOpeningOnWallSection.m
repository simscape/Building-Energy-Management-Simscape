function updatedFloorPlan = addOpeningOnWallSection(NameValueArgs)
% Function to add a window or vent information to the building walls.

% Copyright 2024 The MathWorks, Inc.

    arguments
        NameValueArgs.FloorPlan struct {mustBeNonempty}
        NameValueArgs.Data (:,3) {mustBeNumeric,mustBeReal}
        NameValueArgs.Type (1,1) string {mustBeNonempty,mustBeMember(NameValueArgs.Type,["window","vent"])}
    end
    
    if strcmp(NameValueArgs.Type,"window")
        structName = "Window";
    else
        structName = "Vent";
    end
    
    if isfield(NameValueArgs.FloorPlan.("apartment"+num2str(1)).("room"+num2str(1)).geometry.dim,'allExtWallVertices')
        updatedFloorPlan = NameValueArgs.FloorPlan;
    else
        updatedFloorPlan = mergeFloorPlanTogether(NameValueArgs.FloorPlan,false);
    end
    numWindows = size(NameValueArgs.Data,1);
    nApts = numel(fieldnames(NameValueArgs.FloorPlan));
    for i = 1:nApts
        nRooms = numel(fieldnames(NameValueArgs.FloorPlan.("apartment"+num2str(i))));
        for j = 1:nRooms
            numExtVert = size(updatedFloorPlan.("apartment"+num2str(1)).("room"+num2str(1)).geometry.dim.allExtWallVertices,1);
            allExtWallWindowFracValue = zeros(numExtVert,1);
            for k = 1:numWindows
                maxID = max(NameValueArgs.Data(k,1:2));
                minID = min(NameValueArgs.Data(k,1:2));
                if maxID == numExtVert
                    storeID = maxID;
                else
                    storeID = minID;
                end
                % The values stored in NameValueArgs.Data(k,1:2) are the two
                % numbers represented on merged floorplan picture. They are
                % numbered from 1,2,3... and so on. Hence, these numbers
                % indicate the index in allExtWallWindowFracValue where the
                % wall data could be stored.
                allExtWallWindowFracValue(storeID,1) = NameValueArgs.Data(k,3);
            end
            updatedFloorPlan.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.("allExtWall"+structName+"Frac") = allExtWallWindowFracValue;
        end
    end
end