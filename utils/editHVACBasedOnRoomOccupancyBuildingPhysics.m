function physTable = editHVACBasedOnRoomOccupancyBuildingPhysics(NameValueArgs)
% Function to specify HVAC parameters based on Room occupancy data.

% Copyright 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.PhysicsTable (:,9) table {mustBeNonempty}
        NameValueArgs.HVAC {mustBeMember(NameValueArgs.HVAC,["alwaysON","adaptive"])} = "adaptive"
    end

    physTable = NameValueArgs.PhysicsTable;
    if strcmp(NameValueArgs.HVAC,"adaptive")
        physTable.("HVAC On")(physTable.("Room Occupancy Level")==0) = 0;
        physTable.("HVAC On")(physTable.("Room Occupancy Level")>0) = 1;
    else
        physTable.("HVAC On") = ones(size(physTable.("HVAC On"),1),1);
    end
end