% Function to add wall temperature data to the building data-struct.

% Copyright 2024 The MathWorks, Inc.

function buildingDataWithTemp = getBuildingExtWallTemperatureData(buildingDataStruct,wallTempData)
    arguments
        buildingDataStruct struct {mustBeNonempty}
        wallTempData {mustBeNonempty}
    end
    
    params = getParamsForSimscapeComponent(buildingDataStruct); % Just required for nApts, nRooms data
    numHours = (0:length(buildingDataStruct.apartment1.room1.geometry.roof.sunlightFrac))'*3600;
    dataLen = length(wallTempData.Room(1,1).T.series.values);
    simlogTimeVal = wallTempData.Room(1,1).T.series.time;
    
    % Wall temperature data
    bldgExtWalls  = buildingDataStruct.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.wall;
    bldgExtWallsT = zeros(size(bldgExtWalls,1),length(numHours));
    for num = 1:size(bldgExtWalls,1)
        simlogTval = wallTempData.extWallToEnv(1,num).wallTemperature.series.values;
        bldgExtWallsT(num,:) = interp1(simlogTimeVal,simlogTval,numHours,'next','extrap');
    end
    buildingDataStruct.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.wallTemp = bldgExtWallsT;
    % disp(bldgExtWallsT)
    
    % Roof temperature data
    bldgRoofSurf  = buildingDataStruct.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.roof;
    bldgRoofSurfT = zeros(size(bldgRoofSurf,1),length(numHours));
    for num = 1:size(bldgRoofSurf,1)
        simlogTval = wallTempData.roofToEnv(1,num).wallTemperature.series.values;
        bldgRoofSurfT(num,:) = interp1(simlogTimeVal,simlogTval,numHours,'next','extrap');
    end
    buildingDataStruct.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.roofTemp = bldgRoofSurfT;
    % disp(bldgRoofSurfT)

    buildingDataWithTemp = buildingDataStruct;
end