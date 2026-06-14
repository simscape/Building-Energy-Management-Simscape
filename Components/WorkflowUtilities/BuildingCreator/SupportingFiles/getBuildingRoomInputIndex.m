function indexTable = getBuildingRoomInputIndex(NameValueArgs)
% Building model input array indexing definition

% Copyright 2026 The MathWorks, Inc.

    arguments
        NameValueArgs.BuildingModel struct {mustBeNonempty}
        NameValueArgs.OutputType string {mustBeMember(NameValueArgs.OutputType,["Table","Array"])}
    end

    fullListOfRooms = getListOfAllRoomsBuilding(BuildingData=NameValueArgs.BuildingModel);
    lenData = size(fullListOfRooms,1);
    buildingData = zeros(lenData,4);
    buildingData(:,2:4) = fullListOfRooms;
    for id = 1:lenData
        buildingData(id,1) = NameValueArgs.BuildingModel.("apartment"+buildingData(id,2)).("room"+buildingData(id,3)).geometry.dim.floorLevel;
    end
    if NameValueArgs.OutputType == "Table"
        indexTable = array2table(buildingData,"VariableNames",["Floor","Apartment","Room","SerialNum"]);
    else
        indexTable = buildingData;
    end
end