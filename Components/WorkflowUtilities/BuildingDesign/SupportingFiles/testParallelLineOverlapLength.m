% Find parallel line overlap length rquired for find room-to-room wall
% overlap.

% Copyright 2024 The MathWorks, Inc.

function [overlapValue,overlapVertices]= testParallelLineOverlapLength(testCoord,wallCoord,tolr)

    overlapValue = 0;
    overlapVertices = zeros(2,2);
    
    % Wall segment endpoints
    x1 = wallCoord(1,1); y1 = wallCoord(1,2);
    x2 = wallCoord(2,1); y2 = wallCoord(2,2);
    
    % Test segment endpoints
    a1 = testCoord(1,1); b1 = testCoord(1,2);
    a2 = testCoord(2,1); b2 = testCoord(2,2);
    
    % Wall segment length
    wallLength = sqrt((x2 - x1)^2 + (y2 - y1)^2);
    
    if wallLength < tolr
        return;
    end
    
    % Project both segments onto the wall direction to reduce to 1D overlap
    dx = x2 - x1;
    dy = y2 - y1;
    
    % Parameterize along wall direction: t=0 at (x1,y1), t=1 at (x2,y2)
    % Wall spans [0, 1] in parameter space
    tWallStart = 0;
    tWallEnd   = 1;
    
    % Project test segment endpoints onto wall direction
    tTestStart = ((a1 - x1)*dx + (b1 - y1)*dy) / (wallLength^2);
    tTestEnd   = ((a2 - x1)*dx + (b2 - y1)*dy) / (wallLength^2);
    
    % Ensure test parameter range is ordered
    tTestMin = min(tTestStart, tTestEnd);
    tTestMax = max(tTestStart, tTestEnd);
    
    % Compute overlap in parameter space
    tOverlapStart = max(tWallStart, tTestMin);
    tOverlapEnd   = min(tWallEnd, tTestMax);
    
    % Check if there is valid overlap
    overlapParam = tOverlapEnd - tOverlapStart;
    
    if overlapParam < tolr
        return;
    end
    
    % Overlap fraction relative to wall length
    overlapValue = max(0, min(1, overlapParam));
    
    % Compute overlap vertices in 2D from parameter values
    overlapVertices(1,:) = [x1 + tOverlapStart*dx, y1 + tOverlapStart*dy];
    overlapVertices(2,:) = [x1 + tOverlapEnd*dx,   y1 + tOverlapEnd*dy];

    % overlapValue = 0;
    % x1 = wallCoord(1,1);y1 = wallCoord(1,2);
    % x2 = wallCoord(2,1);y2 = wallCoord(2,2);
    % a1 = testCoord(1,1);b1 = testCoord(1,2);
    % a2 = testCoord(2,1);b2 = testCoord(2,2);
    % 
    % overlapVertices = zeros(2,2);
    % overlappingPts = 0;
    % if ismembertol([x1,x2,y1,y2],[a1,a2,b1,b2],tolr) 
    %     overlappingPts = 1;
    %     overlapValue = 1;
    %     overlapVertices = wallCoord;
    % end
    % 
    % if ismembertol([x2,x1,y2,y1],[a1,a2,b1,b2],tolr) 
    %     overlappingPts = 1;
    %     overlapValue = 1;
    %     overlapVertices = wallCoord;
    % end
    % 
    % if overlappingPts == 0
    %     isa1b1BetweenXY = isPointBetween([a1,b1],[x1,y1],[x2,y2],tolr);
    %     isa2b2BetweenXY = isPointBetween([a2,b2],[x1,y1],[x2,y2],tolr);
    %     isx1y1BetweenAB = isPointBetween([x1,y1],[a1,b1],[a2,b2],tolr);
    %     isx2y2BetweenAB = isPointBetween([x2,y2],[a1,b1],[a2,b2],tolr);
    %     if isa1b1BetweenXY==1 && isa2b2BetweenXY==1
    %         % Both (ab) points between (xy) points
    %         overlapVertices = testCoord;
    %         overlapValue = sqrt((a1-a2)^2+(b1-b2)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
    %     elseif isx1y1BetweenAB==1 && isx2y2BetweenAB==1
    %         % Both (xy) points between (ab) points
    %         overlapVertices = wallCoord; 
    %         % overlapValue = wallLength; % 1;
    %         overlapValue = sqrt((x1-x2)^2+(y1-y2)^2)/sqrt((a1-a2)^2+(b1-b2)^2);
    %     elseif isa1b1BetweenXY==1 && isa2b2BetweenXY~=1
    %         if isx1y1BetweenAB
    %             overlapVertices(1,:) = [x1,y1];
    %             overlapVertices(2,:) = [a2,b2];
    %             overlapValue = sqrt((x1-a2)^2+(y1-b2)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
    %         else % isx2y2BetweenAB
    %             overlapVertices(1,:) = [a1,b1];
    %             overlapVertices(2,:) = [x2,y2];
    %             overlapValue = sqrt((x2-a1)^2+(y2-b1)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
    %         end
    %     elseif isa1b1BetweenXY~=1 && isa2b2BetweenXY==1
    %         if isx1y1BetweenAB
    %             overlapVertices(1,:) = [x1,y1];
    %             overlapVertices(2,:) = [a2,b2];
    %             overlapValue = sqrt((x1-a2)^2+(y1-b2)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
    %         else % isx2y2BetweenAB
    %             overlapVertices(1,:) = [a1,b1];
    %             overlapVertices(2,:) = [x2,y2];
    %             overlapValue = sqrt((x2-a1)^2+(y2-b1)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
    %         end
    %     elseif isx1y1BetweenAB==1 && isx2y2BetweenAB~=1
    %         if isa1b1BetweenXY
    %             overlapVertices(1,:) = [a1,b1];
    %             overlapVertices(2,:) = [x2,y2];
    %             overlapValue = sqrt((a1-x2)^2+(b1-y2)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
    %         else % isa2b2BetweenXY
    %             overlapVertices(1,:) = [x1,y1];
    %             overlapVertices(2,:) = [a2,b2];
    %             overlapValue = sqrt((a2-x1)^2+(b2-y1)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
    %         end
    %     elseif isx1y1BetweenAB~=1 && isx2y2BetweenAB==1
    %         if isa1b1BetweenXY
    %             overlapVertices(1,:) = [a1,b1];
    %             overlapVertices(2,:) = [x2,y2];
    %             overlapValue = sqrt((a1-x2)^2+(b1-y2)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
    %         else % isa2b2BetweenXY
    %             overlapVertices(1,:) = [x1,y1];
    %             overlapVertices(2,:) = [a2,b2];
    %             overlapValue = sqrt((a2-x1)^2+(b2-y1)^2)/sqrt((x1-x2)^2+(y1-y2)^2);
    %         end
    %     else
    %         overlapVertices = zeros(2,2);
    %         overlapValue = 0;
    %     end
    % end
    % 
    % overlapValue = max(0,min(1,overlapValue));

    if overlapValue < tolr
        overlapValue = 0;
        overlapVertices = zeros(2,2);
    end
end