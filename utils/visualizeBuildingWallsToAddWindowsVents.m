function visualizeBuildingWallsToAddWindowsVents(NameValueArgs)
% Function to visualize building external walls and their indices so that 
% windows and vent could be specified.

% Copyright 2024 The MathWorks, Inc.

    arguments
        NameValueArgs.FloorPlan struct {mustBeNonempty}
    end

    mergeFloorPlanTogether(NameValueArgs.FloorPlan,true);

    disp("Use function addOpeningOnWallSection() to add windows or vent to the walls.");
end