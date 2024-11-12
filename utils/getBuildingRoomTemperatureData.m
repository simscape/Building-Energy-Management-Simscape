function buildingDataWithTemp = getBuildingRoomTemperatureData(NameValueArgs)
% Function to add building room temperature data to building data-struct.

% Copyright 2024 The MathWorks, Inc.

    arguments
        NameValueArgs.Building struct {mustBeNonempty}
        NameValueArgs.SimlogData {mustBeNonempty}
    end
    
    [nApt, nRooms] = getNumAptAndRoomsFromFloorPlan(NameValueArgs.Building);

    numHours = (0:length(NameValueArgs.Building.apartment1.room1.geometry.roof.sunlightFrac))'*3600;
    simlogTimeVal = NameValueArgs.SimlogData.simlog.Building.roomTemp.series.time;
    
    simlogTempData = zeros(nApt,max(nRooms),length(numHours));
    simlogTvalues = NameValueArgs.SimlogData.simlog.Building.roomTemp.series.values;
    for i = 1:nApt
        for j = 1:max(nRooms)
            k = (i-1)*max(nRooms)+j;
            simlogTempVal = simlogTvalues(:,k);
            simlogTempData(i,j,:) = interp1(simlogTimeVal,simlogTempVal,numHours,'linear','extrap');
        end
    end

    % Wall temperature data
    bldgExtWalls = NameValueArgs.Building.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.wall;
    bldgExtWallsRoomT = zeros(size(bldgExtWalls,1),length(numHours));
    for num = 1:size(bldgExtWalls,1)
        bldgExtWallsRoomT(num,:) = simlogTempData(bldgExtWalls(num,1),bldgExtWalls(num,2),:);
    end
    NameValueArgs.Building.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.wallTemp = bldgExtWallsRoomT;

    % Roof temperature data
    bldgRoofSurf = NameValueArgs.Building.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.roof;
    bldgRoofSurfRoomT = zeros(size(bldgRoofSurf,1),length(numHours));
    for num = 1:size(bldgRoofSurf,1)
        bldgRoofSurfRoomT(num,:) = simlogTempData(bldgRoofSurf(num,1),bldgRoofSurf(num,2),:);
    end
    NameValueArgs.Building.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.roofTemp = bldgRoofSurfRoomT;

    buildingDataWithTemp = NameValueArgs.Building;
end