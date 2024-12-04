% Function to process data for internal walls and floors. Used in
% buildingModel.ssc file for extracting room and floor connectivity data.

% Copyright 2024 The MathWorks, Inc.

function [numOfRoomConn,intWallAreaVec,intWallSolidFr,...
          numOfFloorConn,intFloorAreaVec,intFloorSolidFr] = ...
          getInternalWallAndFloorData(roomConnMat,floorConnMat)
    numOfRoomConn = size(roomConnMat,1);
    if numOfRoomConn > 0
        intWallAreaVec = roomConnMat(:,5);
        intWallSolidFr = roomConnMat(:,6);
    else
        intWallAreaVec = 0;
        intWallSolidFr = 1;
    end

    numOfFloorConn = size(floorConnMat,1);
    if numOfFloorConn > 0
        intFloorAreaVec = floorConnMat(:,5);
        intFloorSolidFr = floorConnMat(:,6);
    else
        intFloorAreaVec = 0;
        intFloorSolidFr = 1;
    end
end