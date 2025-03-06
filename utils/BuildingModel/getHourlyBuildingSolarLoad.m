function buildingSolarLoad = getHourlyBuildingSolarLoad(NameValueArgs)
% Function to calculate solar load on an apartment (Building) from time
% t=StartTime to time t=EndTime, at location specified by Location. The data is
% estimated on an hourly basis.

% Copyright 2024 - 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.Building struct {mustBeNonempty}
        NameValueArgs.Location (1,3) table {mustBeNonempty}
        NameValueArgs.DayLightSavingHrs (1,1) {mustBeReal}
        NameValueArgs.StartTime datetime {mustBeNonempty}
        NameValueArgs.EndTime datetime {mustBeNonempty}
    end
    
    dataErr = false;
    if NameValueArgs.StartTime < NameValueArgs.EndTime
        dateTimeHourlyDataVec = NameValueArgs.StartTime:hours(1):NameValueArgs.EndTime;
    elseif NameValueArgs.EndTime < NameValueArgs.StartTime
        dateTimeHourlyDataVec = NameValueArgs.EndTime:hours(1):NameValueArgs.StartTime;
    else
        disp("You must provide different datetime start and end values.")
        dataErr = true;
        dateTimeHourlyDataVec = [];
    end

    totalHrs = length(dateTimeHourlyDataVec);% 24;
    if totalHrs <= 1
        disp("This function calculates hourly data. You must provide datetime to capture more than 1 hour data.");
        dataErr = true;
    end

    if ~dataErr
        buildingSolarLoad = NameValueArgs.Building;
        % Set all walls and roof to ZERO sunlight fration. This is required so
        % that all struct() are properly updated. The external walls and roof
        % receiving sunlight are updated in the section below this for-loop.
        [nApt, ~] = getNumAptAndRoomsFromFloorPlan(NameValueArgs.Building);
        solarRadWattPerMeterSq = zeros(1,totalHrs);
        for i = 1:nApt
            numRooms = numel(fieldnames(NameValueArgs.Building.("apartment"+num2str(i))));
            for j = 1:numRooms
                roomVerticesMat = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).floorPlan.Vertices;
                numWalls = size(roomVerticesMat,1);
                for k = 1:numWalls
                    buildingSolarLoad.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).sunlightWattPerMeterSq = solarRadWattPerMeterSq;
                end
                buildingSolarLoad.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.sunlightWattPerMeterSq = solarRadWattPerMeterSq;
            end
        end
    
        % Update sunlight received on walls and roofs.
        aptRoomWallNumMat = NameValueArgs.Building.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.wall;
        aptRoomRoofNumMat = NameValueArgs.Building.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.roof;
        nWall = size(aptRoomWallNumMat,1);
        nRoof = size(aptRoomRoofNumMat,1);
        for wall = 1:nWall
            i = aptRoomWallNumMat(wall,1);
            j = aptRoomWallNumMat(wall,2);
            k = aptRoomWallNumMat(wall,3);
            wallSlope = 90;
            unitVecOutwards = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).unitvecDir;
            
            solarRadWattPerMeterSq = zeros(1,totalHrs);
            for numHour = 1:totalHrs
                dateTimeVal = dateTimeHourlyDataVec(1,numHour);
                nHrs = hour(dateTimeVal);
                nDay = day(dateTimeVal,'dayofyear');
                nYr  = year(dateTimeVal);
                solarRadWattPerMeterSq(1,numHour) = getSurfSolarRadWattPerMeterSq(SurfAngle=wallSlope,...
                                                                                  SurfUnitNormal=unitVecOutwards,...
                                                                                  Year=nYr,...
                                                                                  DayOfTheYear=nDay,...
                                                                                  HourOfTheDay=nHrs,...
                                                                                  Location=NameValueArgs.Location,...
                                                                                  DayLightSaving=NameValueArgs.DayLightSavingHrs);
            end
            buildingSolarLoad.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).sunlightWattPerMeterSq = solarRadWattPerMeterSq;
        end
        
        if isfield(buildingSolarLoad.apartment1.room1.geometry.dim,"inclinedRoof")
            roofRoomConn = buildingSolarLoad.apartment1.room1.geometry.dim.inclinedRoof.roofRoomConnectivity;
            lenRoofRoomConn = size(roofRoomConn,1);
            solarRadInclRoofElements = zeros(lenRoofRoomConn,totalHrs);
        end
        
        for roof = 1:nRoof
            i = aptRoomRoofNumMat(roof,1);
            j = aptRoomRoofNumMat(roof,2);
            if isfield(buildingSolarLoad.apartment1.room1.geometry.dim,"inclinedRoof")
                % Inclined roof
                solarRadWatt = zeros(1,totalHrs);
                roomFlatRoofArea = buildingSolarLoad.("apartment"+num2str(i)).("room"+num2str(j)).floorPlan.area;
                idx = find(and(roofRoomConn(:,1)==i,roofRoomConn(:,2)==j));
                for numHour = 1:totalHrs
                    dateTimeVal = dateTimeHourlyDataVec(1,numHour);
                    nHrs = hour(dateTimeVal);
                    nDay = day(dateTimeVal,'dayofyear'); 
                    nYr  = year(dateTimeVal);
                    for k = 1:size(idx,1)
                        id = idx(k,1);
                        unitVecOutwards = buildingSolarLoad.apartment1.room1.geometry.dim.inclinedRoof.unitVecNormal(id,:);
                        roofSlope = buildingSolarLoad.apartment1.room1.geometry.dim.inclinedRoof.roofAngleDegrees(id,1);
                        solarRadInclRoofElements(id,numHour) = getSurfSolarRadWattPerMeterSq(SurfAngle=roofSlope,...
                            SurfUnitNormal=unitVecOutwards,Year=nYr,DayOfTheYear=nDay,HourOfTheDay=nHrs,...
                            Location=NameValueArgs.Location,DayLightSaving=NameValueArgs.DayLightSavingHrs);
                        roofPatchArea = buildingSolarLoad.apartment1.room1.geometry.dim.inclinedRoof.roofPanelArea(id,1);
                        % Add contribution to room due to all roof elements
                        solarRadWatt(1,numHour) = solarRadWatt(1,numHour) + roofPatchArea*solarRadInclRoofElements(id,numHour);
                    end
                end
                % Inclined roof data is also stored at same place as the
                % flat roof data. The inclined roof data is later
                % multiplied by the flat roof area to calculate Watts of
                % energy from the Sun. Hence, for inclined roofs, where
                % multiple elements may connect to a room, each patch
                % element is multiplied to radiation in W/m^2 and then the
                % sum total of that is divided by the flat roof area (to
                % keep solar radiation input in terms of value). The solar
                % radiation is in W/m^2 as the window/vent/wall area is
                % multiplied later to find actual heat going in.
                buildingSolarLoad.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.sunlightWattPerMeterSq = solarRadWatt/roomFlatRoofArea;
                % The data stored below is used to plot radiation on the
                % inclined roof elements.
                buildingSolarLoad.apartment1.room1.geometry.dim.inclinedRoof.solarRadWattPerSqMeter = solarRadInclRoofElements;
            else
                % Flat roof
                solarRadWattPerMeterSq = zeros(1,totalHrs);
                roofSlope = 0;
                unitVecOutwards = [0 -1]; % default : south facing for roof
                for numHour = 1:totalHrs
                    dateTimeVal = dateTimeHourlyDataVec(1,numHour);
                    nHrs = hour(dateTimeVal);
                    nDay = day(dateTimeVal,'dayofyear'); 
                    nYr  = year(dateTimeVal);
                    solarRadWattPerMeterSq(1,numHour) = getSurfSolarRadWattPerMeterSq(SurfAngle=roofSlope,...
                                                                                      SurfUnitNormal=unitVecOutwards,...
                                                                                      Year=nYr,...
                                                                                      DayOfTheYear=nDay,...
                                                                                      HourOfTheDay=nHrs,...
                                                                                      Location=NameValueArgs.Location,...
                                                                                      DayLightSaving=NameValueArgs.DayLightSavingHrs);
                end
                buildingSolarLoad.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.sunlightWattPerMeterSq = solarRadWattPerMeterSq;
            end
        end
    else
        buildingSolarLoad = [];
    end
end