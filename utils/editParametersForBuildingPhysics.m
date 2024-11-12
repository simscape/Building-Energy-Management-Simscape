function updatedTbl = editParametersForBuildingPhysics(NameValueArgs)
% Generic function to edit building physics tabular data.

% Copyright 2024 The MathWorks, Inc.

    arguments
        NameValueArgs.PhysicsTable (:,9) table {mustBeNonempty}
        NameValueArgs.ListOfLevels (:,1) double {mustBeNonempty}
        NameValueArgs.ListOfRooms (:,1) string {mustBeNonempty}
        NameValueArgs.ListOfTimeValues (:,1) datetime {mustBeNonempty}
        NameValueArgs.PhysicsParameter string {mustBeMember(NameValueArgs.PhysicsParameter,["HVAC On","Heat Source (W)","Electrical Load (W)","Room Occupancy Level"])}
        NameValueArgs.NewValue {mustBeNonempty}
    end

    updatedTbl = NameValueArgs.PhysicsTable;
    
    tableUpdateSuccess = false;

    err = false;
    for i = 1:length(NameValueArgs.ListOfRooms)
        if sum(contains(NameValueArgs.PhysicsTable.("Room Name"),NameValueArgs.ListOfRooms(i,1))) == 0
            err = true;
            disp(strcat("ERROR: Room name - ",NameValueArgs.ListOfRooms(i,1),"- was NOT found. Please check room names and re-try. Update failed."));
        end
    end
    
    if ~err
        if strcmp(NameValueArgs.PhysicsParameter,"HVAC On")
            if ~isa(NameValueArgs.NewValue,"logical")
                disp('You must define HVAC On as logical - true or false.');
            else
                disp(strcat("For all the given Room List & DateTimeVector, ",NameValueArgs.PhysicsParameter," = ",num2str(NameValueArgs.NewValue)));
                tableUpdateSuccess = true;
            end
        elseif strcmp(NameValueArgs.PhysicsParameter,"Heat Source (W)")
            if ~isa(NameValueArgs.NewValue,"double")
                disp('You must define Heat Source (W) as double.');
            else
                disp(strcat("For all the given Room List & DateTimeVector, ",NameValueArgs.PhysicsParameter," = ",num2str(NameValueArgs.NewValue)));
                tableUpdateSuccess = true;
            end
        elseif strcmp(NameValueArgs.PhysicsParameter,"Electrical Load (W)")
            if ~isa(NameValueArgs.NewValue,"double")
                disp('You must define Electrical Load (W) as double.');
            else
                disp(strcat("For all the given Room List & DateTimeVector, ",NameValueArgs.PhysicsParameter," = ",num2str(NameValueArgs.NewValue)));
                tableUpdateSuccess = true;
            end
        else % if strcmp(NameValueArgs.PhysicsParameter,"Room Occupancy Level")
            if ~isa(NameValueArgs.NewValue,"double")
                disp('You must define Room Occupancy Level as an integer.');
            else
                disp(strcat("For all the given Room List & DateTimeVector, ",NameValueArgs.PhysicsParameter," = ",num2str(NameValueArgs.NewValue)));
                tableUpdateSuccess = true;
            end
        end
    end
    if tableUpdateSuccess
        rows = and(and(contains(NameValueArgs.PhysicsTable.("Room Name"),NameValueArgs.ListOfRooms), ...
                       ismember(NameValueArgs.PhysicsTable.("Date and Time"),NameValueArgs.ListOfTimeValues)), ...
                   ismember(NameValueArgs.PhysicsTable.Level,NameValueArgs.ListOfLevels)...
                  );
        updatedTbl(rows,:).(NameValueArgs.PhysicsParameter) = repmat(NameValueArgs.NewValue,length(NameValueArgs.PhysicsTable(rows,:).(NameValueArgs.PhysicsParameter)),1);
        disp(" ");
        disp("Updated Physics Table:");
        disp(" ");
        disp(updatedTbl)
        disp(" ");
    else
        disp(" ");
        disp("*** Update Skipped...");
        disp(" ");
    end
end