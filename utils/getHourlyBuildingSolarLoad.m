function buildingSolarLoad = getHourlyBuildingSolarLoad(NameValueArgs)
% Function to calculate solar load on an apartment (Building) from time
% t=StartTime to time t=EndTime, at location specified by Location. The data is
% estimated on an hourly basis.

% Copyright 2024 The MathWorks, Inc.

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
        cosineAngleOfIncidence = zeros(1,totalHrs);
        solarRadWattPerMeterSq = zeros(1,totalHrs);
        for i = 1:nApt
            numRooms = numel(fieldnames(NameValueArgs.Building.("apartment"+num2str(i))));
            for j = 1:numRooms
                roomVerticesMat = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).floorPlan.Vertices;
                numWalls = size(roomVerticesMat,1);
                for k = 1:numWalls
                    buildingSolarLoad.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).sunlightFrac = cosineAngleOfIncidence;
                    buildingSolarLoad.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).sunlightWattPerMeterSq = solarRadWattPerMeterSq;
                end
                buildingSolarLoad.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.sunlightFrac = cosineAngleOfIncidence;
                buildingSolarLoad.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.sunlightWattPerMeterSq = solarRadWattPerMeterSq;
            end
        end
    
        % Update sunlight received on walls and roofs.
        aptRoomWallNumMat = NameValueArgs.Building.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.wall;
        aptRoomRoofNumMat = NameValueArgs.Building.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.roof;
        nWall = size(aptRoomWallNumMat,1);
        nRoof = size(aptRoomRoofNumMat,1);
        cosineAngleOfIncidence = zeros(1,totalHrs);
        solarRadWattPerMeterSq = zeros(1,totalHrs);
        for wall = 1:nWall
            i = aptRoomWallNumMat(wall,1);
            j = aptRoomWallNumMat(wall,2);
            k = aptRoomWallNumMat(wall,3);
            wallSlope = 90;
            unitVecOutwards = NameValueArgs.Building.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).unitvecDir;
            cosineAngleOfIncidence = zeros(1,totalHrs);
            solarRadWattPerMeterSq = zeros(1,totalHrs);
            for numHour = 1:totalHrs
                dateTimeVal = dateTimeHourlyDataVec(1,numHour);
                nHrs = hour(dateTimeVal);
                nDay = day(dateTimeVal,'dayofyear'); 
                nYr  = year(dateTimeVal);
                cosineAngleOfIncidence(1,numHour) = getAngleSunRaysOnSurface(wallSlope,unitVecOutwards,nYr,nDay,nHrs,NameValueArgs.Location,NameValueArgs.DayLightSavingHrs);
                solarRadWattPerMeterSq(1,numHour) = cosineAngleOfIncidence(1,numHour)*getSunRadiationOnTheDay(NameValueArgs.Location,nYr,nDay,nHrs,NameValueArgs.DayLightSavingHrs);
            end

            buildingSolarLoad.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).sunlightFrac = cosineAngleOfIncidence;
            buildingSolarLoad.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).sunlightWattPerMeterSq = solarRadWattPerMeterSq;
        end
    
        cosineAngleOfIncidence = zeros(1,totalHrs);
        solarRadWattPerMeterSq = zeros(1,totalHrs);
        for roof = 1:nRoof
            i = aptRoomRoofNumMat(roof,1);
            j = aptRoomRoofNumMat(roof,2);
            roofSlope = 0;
            unitVecOutwards = [0 -1]; % default : south facing for roof
            cosineAngleOfIncidence = zeros(1,totalHrs);
            for numHour = 1:totalHrs
                dateTimeVal = dateTimeHourlyDataVec(1,numHour);
                nHrs = hour(dateTimeVal);
                nDay = day(dateTimeVal,'dayofyear'); 
                nYr  = year(dateTimeVal);
                cosineAngleOfIncidence(1,numHour) = getAngleSunRaysOnSurface(roofSlope,unitVecOutwards,nYr,nDay,nHrs,NameValueArgs.Location,NameValueArgs.DayLightSavingHrs);
                solarRadWattPerMeterSq(1,numHour) = cosineAngleOfIncidence(1,numHour)*getSunRadiationOnTheDay(NameValueArgs.Location,nYr,nDay,nHrs,NameValueArgs.DayLightSavingHrs);
            end
            buildingSolarLoad.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.sunlightFrac = cosineAngleOfIncidence;
            buildingSolarLoad.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.sunlightWattPerMeterSq = solarRadWattPerMeterSq;
        end
    else
        buildingSolarLoad = [];
    end
end