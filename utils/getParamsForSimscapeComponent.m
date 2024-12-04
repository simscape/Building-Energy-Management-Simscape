function params = getParamsForSimscapeComponent(NameValueArgs)
% Function to combine all building data together so that the custom
% components for building energy simulation could be parameterized.

% Copyright 2024 The MathWorks, Inc.

    arguments
        NameValueArgs.Building struct {mustBeNonempty}
        NameValueArgs.PhysicsTableData table = []
    end
    hrsSolarData = length(NameValueArgs.Building.apartment1.room1.geometry.wall1.sunlightWattPerMeterSq);
    
    % roomEnvConnMat & roomEnvSolarRad
    totalDataPts    = size(NameValueArgs.Building.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.wall,1);
    roomEnvConnMat  = zeros(totalDataPts,6);
    roomEnvSolarRad = zeros(totalDataPts,hrsSolarData);
    roomEnvConnMat(:,1:3) = NameValueArgs.Building.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.wall;

    for i = 1:totalDataPts
        apt  = roomEnvConnMat(i,1);
        room = roomEnvConnMat(i,2);
        wall = roomEnvConnMat(i,3);
        
        roomEnvConnMat(i,4) = NameValueArgs.Building.("apartment"+num2str(apt)).("room"+num2str(room)).geometry.("wall"+num2str(wall)).AmbientWallSurfFrac * ...
                              NameValueArgs.Building.("apartment"+num2str(apt)).("room"+num2str(room)).geometry.("wall"+num2str(wall)).WallAreaTotal;
        roomEnvConnMat(i,5) = NameValueArgs.Building.("apartment"+num2str(apt)).("room"+num2str(room)).geometry.("wall"+num2str(wall)).AmbientWindowSurfFrac * ...
                              NameValueArgs.Building.("apartment"+num2str(apt)).("room"+num2str(room)).geometry.("wall"+num2str(wall)).WallAreaTotal;
        roomEnvConnMat(i,6) = NameValueArgs.Building.("apartment"+num2str(apt)).("room"+num2str(room)).geometry.("wall"+num2str(wall)).AmbientVentSurfFrac * ...
                              NameValueArgs.Building.("apartment"+num2str(apt)).("room"+num2str(room)).geometry.("wall"+num2str(wall)).WallAreaTotal;
    
        roomEnvSolarRad(i,:) = NameValueArgs.Building.("apartment"+num2str(apt)).("room"+num2str(room)).geometry.("wall"+num2str(wall)).sunlightWattPerMeterSq;
    end
    
    % roofEnvConnMat & roofEnvSolarRad
    totalRoofPts    = size(NameValueArgs.Building.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.roof,1);
    roofEnvConnMat  = zeros(totalRoofPts,3);
    roofEnvSolarRad = zeros(totalRoofPts,hrsSolarData);
    roofEnvConnMat(:,1:2) = NameValueArgs.Building.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.roof;
    for i = 1:totalRoofPts
        apt  = roofEnvConnMat(i,1);
        room = roofEnvConnMat(i,2);
        roofEnvConnMat(i,3)  = NameValueArgs.Building.("apartment"+num2str(apt)).("room"+num2str(room)).floorPlan.area;
        roofEnvSolarRad(i,:) = NameValueArgs.Building.("apartment"+num2str(apt)).("room"+num2str(room)).geometry.roof.sunlightWattPerMeterSq;
    end
    
    % roomConnMat & roomVolMat
    [nApt, nRooms] = getNumAptAndRoomsFromFloorPlan(NameValueArgs.Building);
    roomVolMat = zeros(nApt,max(nRooms));
    roomConnMat = [];
    minSolidWallFraction = 0.05;
    for i = 1:nApt
        for j = 1:nRooms(i,1)
            roomVolMat(i,j) = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).floorPlan.area * ...
                              NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.height;
            nameOfConnections = fieldnames(NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.connectivity);
            roomNumList = getConnectedRoomNumber(nameOfConnections);
            avoidDoubleCount = roomNumList(roomNumList>j);
            if ~isempty(avoidDoubleCount)
                for k = 1:length(avoidDoubleCount)
                    conn = avoidDoubleCount(1,k);
                    contactArea = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.dim.height * ...
                                  NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.connectivity.("room"+num2str(conn)).length;
                    intSolidWallFrac = max(minSolidWallFraction,min(1,NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.connectivity.("room"+num2str(conn)).wallFrac));
                    storeData = [i,j,i,conn,contactArea,intSolidWallFrac]; 
                    roomConnMat = [roomConnMat;storeData];
                end
            end
        end
    end

    % floorGrdConnMat
    totalFloorPts   = size(NameValueArgs.Building.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.floor,1);
    floorGrdConnMat = zeros(totalFloorPts,3);
    floorGrdConnMat(:,1:2) = NameValueArgs.Building.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.floor;
    for i = 1:totalFloorPts
        apt  = floorGrdConnMat(i,1);
        room = floorGrdConnMat(i,2);
        floorGrdConnMat(i,3) = NameValueArgs.Building.("apartment"+num2str(apt)).("room"+num2str(room)).floorPlan.area;
    end

    % To connect rooms across floors also (vertically):
    % 
    % Building 3D is created from a floorplan that is extruded in Z
    % direction. Hence, room 'i' of an apartment will contact room 'i' of
    % the apartment above. Apartments are numbered in sequence and so one
    % needs to back-calculate number of apartments per floor of the
    % building and the total number of floors in the building. 
    % 
    % If there are 4 apartments, and 3 rooms per apartment in a 5 storied
    % building, then apartment(1) roof will connect to apartment(4+1)
    % floor, apartment(4+1) roof will connect to apartment(4*2+1), and so
    % on. Rooms in each apartment having same number will overlap
    % completely with each other, and hence contact area = area of the room
    % floorplan.
    floorConnMat = NameValueArgs.Building.apartment1.room1.geometry.dim.floorConnMat;
    numFloorConnMat = size(floorConnMat,1);
    if numFloorConnMat > 0
        for i = 1:numFloorConnMat
            NameValueArgs.Building.apartment1.room1.geometry.dim.floorConnMat(i,6) = ...
                min(1,max(floorConnMat(i,6),minSolidWallFraction));
        end
    end
        
    params.nApt = nApt;
    params.MaxRoom = max(nRooms);
    params.roomEnvConnMat = roomEnvConnMat;
    params.roomEnvSolarRad = roomEnvSolarRad;
    params.roofEnvConnMat = roofEnvConnMat;
    params.roofEnvSolarRad = roofEnvSolarRad;
    params.roomConnMat = roomConnMat;
    params.floorConnMat = floorConnMat;
    params.roomVolMat = roomVolMat;
    params.floorRoomIDs = floorGrdConnMat;

    if ~isempty(NameValueArgs.PhysicsTableData)
        % Specify physics table parameters
        params.physTable = table2array(NameValueArgs.PhysicsTableData(:,[2:4,6:9]));
    end
end