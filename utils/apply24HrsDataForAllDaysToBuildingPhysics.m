function physTable = apply24HrsDataForAllDaysToBuildingPhysics(NameValueArgs)
% Function to specify 24 hr parameters to all rooms and for entire time duration.

% Copyright 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.Building struct {mustBeNonempty}
        NameValueArgs.PhysicsParameter string {mustBeMember(NameValueArgs.PhysicsParameter,["HVAC On","Heat Source (W)","Electrical Load (W)","Room Occupancy Level"])}
        NameValueArgs.Data (1,24) {mustBeNonempty}
        NameValueArgs.PhysicsTable (:,9) table {mustBeNonempty}
        NameValueArgs.ListOfRoomNames (1,:) string {mustBeNonempty}
        NameValueArgs.ListOfFloorLevels (1,:) {mustBeNonempty}
        NameValueArgs.DateTimeVec datetime {mustBeNonempty}
    end
 
    physTable = NameValueArgs.PhysicsTable;
    for i = 1:24 % loop over 24 hrs of data applicable to each day
        newValue = NameValueArgs.Data(1,i);
        listOfDateTime = NameValueArgs.DateTimeVec(hour(NameValueArgs.DateTimeVec)==i);
        if ~isempty(listOfDateTime)
            physTable = editParametersForBuildingPhysics(PhysicsTable=physTable,...
                                                         ListOfLevels=unique(NameValueArgs.ListOfFloorLevels),...
                                                         ListOfRooms=unique(NameValueArgs.ListOfRoomNames),...
                                                         ListOfTimeValues=listOfDateTime',...
                                                         PhysicsParameter=NameValueArgs.PhysicsParameter,...
                                                         NewValue=newValue,DisplayMessages=false);
        end
    end
end