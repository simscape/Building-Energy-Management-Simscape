function tblWinVentData = visualizeBuildingWallsToAddWindowsVents(NameValueArgs)
% Function to visualize building external walls and their indices so that 
% windows and vent could be specified.

% Copyright 2024 - 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.FloorPlan struct {mustBeNonempty}
        NameValueArgs.Tol (1,1) {mustBeNonnegative,mustBeLessThan(NameValueArgs.Tol,1)} = 0.01
        NameValueArgs.Plot {mustBeNonempty} = true
    end

    mergedFloorPlan = mergeFloorPlanTogether(NameValueArgs.FloorPlan,NameValueArgs.Plot);

    numRoomWallOverlap = [];
    allExtVert = mergedFloorPlan.apartment1.room1.geometry.dim.allExtWallVertices;
    numExtVert = size(allExtVert,1);
    for i = 1:numExtVert
        % Find room wall overlapping with External Wall
        if i == numExtVert
            id1 = numExtVert;
            id2 = 1;
        else
            id1 = i;
            id2 = i+1;
        end
        testExtrVert = allExtVert([id1,id2],:);
        [m1,c1] = slopeOfLineThroughTwoPoint(testExtrVert,NameValueArgs.Tol);
    
        nApt = numel(fieldnames(NameValueArgs.FloorPlan));
        for j = 1:nApt
            nRoom = numel(fieldnames(NameValueArgs.FloorPlan.("apartment"+j)));
            for k = 1:nRoom
                roomVert = NameValueArgs.FloorPlan.("apartment"+j).("room"+k).floorPlan.Vertices;
                for w = 1:size(roomVert,1)
                    if w == size(roomVert,1)
                        testRoomVert = roomVert([size(roomVert,1),1],:);
                    else
                        testRoomVert = roomVert(w:w+1,:);
                    end
                    [m2,c2] = slopeOfLineThroughTwoPoint(testRoomVert,NameValueArgs.Tol);
                    if ismembertol(m1,m2,NameValueArgs.Tol) && ismembertol(c1,c2,NameValueArgs.Tol)
                        [wallFracVal,~] = testParallelLineOverlapLength(testExtrVert,testRoomVert,NameValueArgs.Tol);
                        if wallFracVal > 0
                            numRoomWallOverlap = [numRoomWallOverlap;[id1,id2,j,k,w]]; % Ext Wall id1 & id2, Apt num, Room num, Wall num
                        end
                    end
                end
            end
        end
    end

    varTypes = ["double","double","string","double","double","string"];
    varNames = ["From Point","To Point","Wall of Room","Window (0-1)","Vent (0-1)","Wall Index"];
    sz = [size(numRoomWallOverlap,1), size(varTypes,2)];
    tblWinVentData = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
    for i = 1:sz(1,1)
        tblWinVentData.("From Point")(i,1) = numRoomWallOverlap(i,1);
        tblWinVentData.("To Point")(i,1) = numRoomWallOverlap(i,2);
        tblWinVentData.("Wall of Room")(i,1) = NameValueArgs.FloorPlan.("apartment"+numRoomWallOverlap(i,3)).("room"+numRoomWallOverlap(i,4)).name;
        tblWinVentData.("Wall Index")(i,1) = mat2str([numRoomWallOverlap(i,3),numRoomWallOverlap(i,4),numRoomWallOverlap(i,5)]);
    end
    
    if NameValueArgs.Plot
        disp("*** Default window and vent data")
        disp(" ");
        disp(tblWinVentData);
        disp(" ");
        disp("Use function addOpeningOnWallSection() to add windows or vent to the walls.");
    end
end