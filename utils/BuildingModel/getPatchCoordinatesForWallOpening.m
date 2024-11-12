% Function to find window or vent patch size for wall plot

% Copyright 2024 The MathWorks, Inc.

function [X,Y,Z] = getPatchCoordinatesForWallOpening(wallVert_X,wallVert_Y,wallVert_Z,openingAreaFrac)
    midVal_X = mean(wallVert_X);
    midVal_Y = mean(wallVert_Y);
    midVal_Z = mean(wallVert_Z);
    X = wallVert_X;
    Y = wallVert_Y;
    Z = wallVert_Z;

    % openingArea = openingAreaFrac * ...
    %     ((wallVert_X(1,1)-wallVert_X(1,2))^2+(wallVert_Y(1,1)-wallVert_Y(1,2))^2+(wallVert_Z(1,1)-wallVert_Z(1,2))^2) * ...
    %     ((wallVert_X(1,2)-wallVert_X(1,3))^2+(wallVert_Y(1,2)-wallVert_Y(1,3))^2+(wallVert_Z(1,2)-wallVert_Z(1,3))^2);

    for i = 1:4
        id1 = i;
        if i == 4
            id2 = 1;
        else
            id2 = id1+1;
        end
        delta_x = mean(wallVert_X(wallVert_X>midVal_X)) - mean(wallVert_X(wallVert_X<midVal_X));
        delta_y = mean(wallVert_Y(wallVert_Y>midVal_Y)) - mean(wallVert_Y(wallVert_Y<midVal_Y));
        delta_z = mean(wallVert_Z(wallVert_Z>midVal_Z)) - mean(wallVert_Z(wallVert_Z<midVal_Z));
        if wallVert_X(1,i) < midVal_X
            X(1,i) = X(1,i) + delta_x*(1-sqrt(openingAreaFrac))/2;
        else
            X(1,i) = X(1,i) - delta_x*(1-sqrt(openingAreaFrac))/2;
        end
        if wallVert_Y(1,i) < midVal_Y
            Y(1,i) = Y(1,i) + delta_y*(1-sqrt(openingAreaFrac))/2;
        else
            Y(1,i) = Y(1,i) - delta_y*(1-sqrt(openingAreaFrac))/2;
        end
        if wallVert_Z(1,i) < midVal_Z
            Z(1,i) = Z(1,i) + delta_z*(1-sqrt(openingAreaFrac))/2;
        else
            Z(1,i) = Z(1,i) - delta_z*(1-sqrt(openingAreaFrac))/2;
        end
    end
end