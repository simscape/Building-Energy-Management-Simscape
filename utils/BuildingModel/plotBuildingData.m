% Function to create building plots.

% Copyright 2024 The MathWorks, Inc.

function plotBuildingData(model3Dbuilding,viewingAngle,colorScheme,ts)
    plotColorLowVal = 0.85;
    plotColorHighVal = 1;
    uppTs = ceil(ts);
    lowTs = floor(ts);
    if uppTs == lowTs
        interplData = false;
        interplDataScaleLow = 0;
    else
        interplData = true;
        interplDataScaleLow = min(1,max(0,(uppTs-ts)/(uppTs-lowTs)));
    end
    
    aptRoomWallNumMat = model3Dbuilding.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.wall;
    aptRoomRoofNumMat = model3Dbuilding.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.roof;
    
    nWall = size(aptRoomWallNumMat,1);
    nRoof = size(aptRoomRoofNumMat,1);

    if strcmp(colorScheme,"walls")
        nRoof = 0;
    end

    if strcmp(colorScheme,"roof")
        nWall = 0;
    end

    if isfield(model3Dbuilding.apartment1.room1.geometry.dim.buildingExtBoundaryWallData,"wallTemp")
        plotTroom = model3Dbuilding.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.wallTemp;
    end
    
    if isfield(model3Dbuilding.apartment1.room1.geometry.dim.buildingExtBoundaryWallData,"roofTemp")
        plotTroof = model3Dbuilding.apartment1.room1.geometry.dim.buildingExtBoundaryWallData.roofTemp;
    end

    if strcmp(colorScheme,"temperature")
        maxT = max(max(max(plotTroof)),max(max(plotTroom)));
        minT = min(min(min(plotTroof)),min(min(plotTroom)));
    end
    
    % With the assumption of all walls having 4 vertices
    listOfFaces_X = zeros(nWall+nRoof,4); % 4 vertices
    listOfFaces_Y = zeros(nWall+nRoof,4); % 4 vertices
    listOfFaces_Z = zeros(nWall+nRoof,4); % 4 vertices
    colorForFaces = zeros(nWall+nRoof,1); % RGB values

    listOfWindows_X = zeros(nWall,4); % 4 vertices
    listOfWindows_Y = zeros(nWall,4); % 4 vertices
    listOfWindows_Z = zeros(nWall,4); % 4 vertices
    colorForWindows = 0.5*ones(nWall,1); % RGB values


    if ~strcmp(colorScheme,"roof")
        for wall = 1:nWall
            i = aptRoomWallNumMat(wall,1);
            j = aptRoomWallNumMat(wall,2);
            k = aptRoomWallNumMat(wall,3);
            if strcmp(colorScheme,"random") 
                colorForFaces(wall,1) = rand(1,1);
            elseif strcmp(colorScheme,"sunlight")
                if interplData
                    sunlightFraction = (model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).sunlightFrac(1,lowTs)*interplDataScaleLow + ...
                                        model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).sunlightFrac(1,uppTs)*(1-interplDataScaleLow));
                else
                    sunlightFraction = model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).sunlightFrac(1,uppTs);
                end
                if sunlightFraction > 0
                    sunlightFractionCol = plotColorLowVal + (plotColorHighVal-plotColorLowVal)*sunlightFraction;
                else
                    sunlightFractionCol = sunlightFraction;
                end
                colorForFaces(wall,1) = sunlightFractionCol;
            elseif strcmp(colorScheme,"radiation")
                radiation = model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).sunlightWattPerMeterSq;
                if interplData
                    radiationVal = min(1,max(0,(radiation(1,uppTs)*(1-interplDataScaleLow)+radiation(1,lowTs)*interplDataScaleLow)/max(radiation)));
                else
                    radiationVal = min(1,max(0,radiation(1,uppTs)/max(radiation)));
                end
                if radiationVal > 0
                    radiationValCol = plotColorLowVal + (plotColorHighVal-plotColorLowVal)*radiationVal;
                else
                    radiationValCol = radiationVal;
                end
                colorForFaces(wall,1) = radiationValCol;
            elseif strcmp(colorScheme,"temperature")
                if interplData
                    colorForFaces(wall,1) = (plotTroom(wall,uppTs)*(1-interplDataScaleLow)+plotTroom(nWall,lowTs)*interplDataScaleLow);
                else
                    colorForFaces(wall,1) = plotTroom(wall,uppTs);
                end
            elseif strcmp(colorScheme,"wallsAndRoof")
                colorForFaces(wall,1) = 0;
            elseif strcmp(colorScheme,"walls")
                colorForFaces(wall,1) = 0;
            else
                colorForFaces(wall,1) = rand(1,1);
            end
            listOfFaces_X(wall,:) = model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).vertices(1,:);
            listOfFaces_Y(wall,:) = model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).vertices(2,:);
            listOfFaces_Z(wall,:) = model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).vertices(3,:);

            windowAreaFrac = model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).AmbientWindowSurfFrac;
            ventAreaFrac = model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.("wall"+num2str(k)).AmbientVentSurfFrac;

            [X,Y,Z] = getPatchCoordinatesForWallOpening(listOfFaces_X(wall,:),listOfFaces_Y(wall,:),listOfFaces_Z(wall,:),windowAreaFrac+ventAreaFrac);

            listOfWindows_X(wall,:) = X;
            listOfWindows_Y(wall,:) = Y;
            listOfWindows_Z(wall,:) = Z;
        end
    end

    if ~strcmp(colorScheme,"walls")
        for roof = 1:nRoof
            i = aptRoomRoofNumMat(roof,1);
            j = aptRoomRoofNumMat(roof,2);
            if strcmp(colorScheme,"random") 
                colorForFaces(nWall+roof,1) = rand(1,1);
            elseif strcmp(colorScheme,"sunlight")
                if interplData
                    sunlightFraction = (model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.sunlightFrac(1,uppTs)*(1-interplDataScaleLow) + ...
                                        model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.sunlightFrac(1,lowTs)*interplDataScaleLow);
                else
                    sunlightFraction = model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.sunlightFrac(1,uppTs);
                end
                if sunlightFraction > 0
                    sunlightFractionCol = plotColorLowVal + (plotColorHighVal-plotColorLowVal)*sunlightFraction;
                else
                    sunlightFractionCol = sunlightFraction;
                end
                colorForFaces(wall+roof,1) = sunlightFractionCol;
            elseif strcmp(colorScheme,"radiation")
                radiation = model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.sunlightWattPerMeterSq;
                if interplData
                    radiationVal = min(1,max(0,(radiation(1,uppTs)*(1-interplDataScaleLow)+radiation(1,lowTs)*interplDataScaleLow)/max(radiation)));
                else 
                    radiationVal = min(1,max(0,radiation(1,uppTs)/max(radiation)));
                end
                if radiationVal > 0
                    radiationValCol = plotColorLowVal + (plotColorHighVal-plotColorLowVal)*radiationVal;
                else
                    radiationValCol = radiationVal;
                end
                colorForFaces(nWall+roof,1) = radiationValCol;
            elseif strcmp(colorScheme,"temperature")
                if interplData
                    colorForFaces(nWall+roof,1) = (plotTroof(roof,uppTs)*(1-interplDataScaleLow)+plotTroof(roof,lowTs)*interplDataScaleLow);
                else
                    colorForFaces(nWall+roof,1) = plotTroof(roof,uppTs);
                end
            elseif strcmp(colorScheme,"wallsAndRoof")
                colorForFaces(nWall+roof,1) = 1;
            elseif strcmp(colorScheme,"roof")
                colorForFaces(nWall+roof,1) = 1;
            else
                colorForFaces(nWall+roof,1) = rand(1,1);
            end
            listOfFaces_X(roof+nWall,:) = model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.vertices(1,:);
            listOfFaces_Y(roof+nWall,:) = model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.vertices(2,:);
            listOfFaces_Z(roof+nWall,:) = model3Dbuilding.("apartment"+num2str(i)).("room"+num2str(j)).geometry.roof.vertices(3,:);
        end
    end

    p = patch([listOfFaces_X;listOfWindows_X]',...
              [listOfFaces_Y;listOfWindows_Y]',...
              [listOfFaces_Z;listOfWindows_Z]',...
              [colorForFaces;colorForWindows]'); 
    cparula = parula;
    colormap(cparula);

    if ~strcmp(colorScheme,"temperature")
        c = colorbar;
        if strcmp(colorScheme,"wallsAndRoof")
            c.Ticks = [0 1]; c.TickLabels = {'walls','roof'};
        elseif strcmp(colorScheme,"walls")
            c.Ticks = [0 1];
        elseif strcmp(colorScheme,"roof")
            c.Ticks = [0 1];
        else
            c.Ticks = 0:0.25:1; %c.TickLabels = {'Cold','Cool','Neutral','Warm','Hot'};
            c.Limits = [0 1];
        end
        clim([0 1]);
    else
        nGrid = 8;
        delT = (maxT - minT)/(nGrid+1);
        tickValues = round(minT+(0:nGrid)*delT,1);
        c = colorbar('Ticks',tickValues);
        c.Limits = [minT maxT];
        clim([minT maxT]);
    end
    c.Location = "eastoutside";

    xlabel('East');
    ylabel('North');
    zlabel('Height');
    view(viewingAngle);
end