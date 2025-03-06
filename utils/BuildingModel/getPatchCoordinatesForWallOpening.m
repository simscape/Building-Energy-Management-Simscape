% Function to find window or vent patch size for wall plot

% Copyright 2024 The MathWorks, Inc.

function [X,Y,Z] = getPatchCoordinatesForWallOpening(wallVert_X,wallVert_Y,wallVert_Z,openingAreaFrac)
    midVal_X = mean(wallVert_X);
    midVal_Y = mean(wallVert_Y);
    midVal_Z = mean(wallVert_Z);
    X = wallVert_X;
    Y = wallVert_Y;
    Z = wallVert_Z;
    if max(X) == min(X)
        % No change in X, calculating deltaX would give NaN
        delta_x = 0;
    else
        delta_x = mean(wallVert_X(wallVert_X>midVal_X)) - mean(wallVert_X(wallVert_X<midVal_X));
    end
    if max(Y) == min(Y)
        % No change in Y, calculating deltaY would give NaN
        delta_y = 0;
    else
        delta_y = mean(wallVert_Y(wallVert_Y>midVal_Y)) - mean(wallVert_Y(wallVert_Y<midVal_Y));
    end
    if max(Z) == min(Z)
        % No change in Z, calculating deltaZ would give NaN
        delta_z = 0;
    else
        delta_z = mean(wallVert_Z(wallVert_Z>midVal_Z)) - mean(wallVert_Z(wallVert_Z<midVal_Z));
    end

    for i = 1:4
        if wallVert_X(1,i) < midVal_X
            X(1,i) = X(1,i) + delta_x*(1-openingAreaFrac)/2;
        else
            X(1,i) = X(1,i) - delta_x*(1-openingAreaFrac)/2;
        end
        if wallVert_Y(1,i) < midVal_Y
            Y(1,i) = Y(1,i) + delta_y*(1-openingAreaFrac)/2;
        else
            Y(1,i) = Y(1,i) - delta_y*(1-openingAreaFrac)/2;
        end
        if wallVert_Z(1,i) < midVal_Z
            Z(1,i) = Z(1,i) + delta_z*(1-openingAreaFrac)/2;
        else
            Z(1,i) = Z(1,i) - delta_z*(1-openingAreaFrac)/2;
        end
    end
end