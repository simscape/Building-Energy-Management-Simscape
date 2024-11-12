function updatedBldg = editHVACModelParameterRoom(NameValueArgs)
% Function to edit room physics HVAC model values.

% Copyright 2024 The MathWorks, Inc.

    arguments
        NameValueArgs.Building struct {mustBeNonempty}
        NameValueArgs.ListOfLevels (:,1) double {mustBeNonempty}
        NameValueArgs.ListOfRooms (:,1) string {mustBeNonempty}
        NameValueArgs.ModelParameter string {mustBeMember(NameValueArgs.ModelParameter,["Radiator Coverage Area Fraction","Underfloor Coverage Area Fraction"])}
        NameValueArgs.NewValue {mustBeNonempty}
    end

    updateSuccess = 0;
    updatedBldg = NameValueArgs.Building;
    [nApt, nRooms] = getNumAptAndRoomsFromFloorPlan(NameValueArgs.Building);
    for i = 1:nApt
        for j = 1:max(nRooms)
            level = NameValueArgs.Building.("apartment"+i).("room"+j).geometry.dim.floorLevel;
            roomN = NameValueArgs.Building.("apartment"+i).("room"+j).name;
            if any(contains(NameValueArgs.ListOfRooms,roomN)) && any(ismember(NameValueArgs.ListOfLevels,level))
                if strcmp(NameValueArgs.ModelParameter,"Radiator Coverage Area Fraction")
                    updatedBldg.("apartment"+i).("room"+j).physics.radiator = NameValueArgs.NewValue;
                    updateSuccess = 1;
                else
                    updatedBldg.("apartment"+i).("room"+j).physics.underfloor = NameValueArgs.NewValue;
                    updateSuccess = 1;
                end
            end
        end
    end

    if ~updateSuccess
        disp('*** ERROR : Data not updated. Check input values.')
    end
end