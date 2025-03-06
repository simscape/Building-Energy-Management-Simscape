% Function to find doors for internal wall plot

% Copyright 2024 - 2025 The MathWorks, Inc.

function [X,Y,Z] = getPatchCoordinatesForIntWallDoors(wallVert_X,wallVert_Y,wallVert_Z,solidWallAreaFrac)
    midVal_X = mean(wallVert_X);
    midVal_Y = mean(wallVert_Y);
    midVal_Z = mean(wallVert_Z);
    X = wallVert_X;
    Y = wallVert_Y;
    Z = wallVert_Z;

    delta_x = mean(wallVert_X(wallVert_X>midVal_X)) - mean(wallVert_X(wallVert_X<midVal_X));
    delta_y = mean(wallVert_Y(wallVert_Y>midVal_Y)) - mean(wallVert_Y(wallVert_Y<midVal_Y));
    delta_z = mean(wallVert_Z(wallVert_Z>midVal_Z)) - mean(wallVert_Z(wallVert_Z<midVal_Z));
    % typicalDoorHt = 0.75*delta_z;

    ratio_x = delta_x/(delta_x+delta_y+delta_z);
    ratio_y = delta_y/(delta_x+delta_y+delta_z);
    ratio_z = delta_z/(delta_x+delta_y+delta_z);

    for i = 1:4
        if wallVert_X(1,i) < midVal_X
            X(1,i) = X(1,i) + delta_x*(solidWallAreaFrac)/2;
        else
            X(1,i) = X(1,i) - delta_x*(solidWallAreaFrac)/2;
        end
        if wallVert_Y(1,i) < midVal_Y
            Y(1,i) = Y(1,i) + delta_y*(solidWallAreaFrac)/2;
        else
            Y(1,i) = Y(1,i) - delta_y*(solidWallAreaFrac)/2;
        end
        if wallVert_Z(1,i) < midVal_Z
            % Z(1,i) = Z(1,i);
            Z(1,i) = Z(1,i) ;%+ delta_z*(solidWallAreaFrac)/2;
        else
            % Z(1,i) = Z(1,i) - (delta_z-typicalDoorHt);
            Z(1,i) = Z(1,i) - 2*delta_z*(solidWallAreaFrac)/2;
        end
    end

    % sideLenVec = sqrt(diff(wallVert_X).^2+diff(wallVert_Y).^2+diff(wallVert_Z).^2);
    % wallArea = sideLenVec(1,1)*sideLenVec(1,2);
    % openingLenVec = sqrt(diff(X).^2+diff(Y).^2+diff(Z).^2);
    % openArea = openingLenVec(1,1)*openingLenVec(1,2);
    % calcFractionVal = max(0,1-openArea/wallArea);
    % disp(strcat("Expected fraction = ",num2str(round(solidWallAreaFrac,2)),", and calculated fraction = ",num2str(round(calcFractionVal,2))));
    % % If limits on X and Y have been reached, then increase the default
    % % door height as it might be a larger opening between the rooms.
    % numDivZ = 5;
    % increase_z = (delta_z-typicalDoorHt)/numDivZ;
    % if calcFractionVal < solidWallAreaFrac
    %     resultFound = 0;
    %     for z_itr = 1:numDivZ
    %         if ~resultFound
    %             if wallVert_Z(1,i) < midVal_Z
    %                 Z(1,i) = Z(1,i);
    %             else
    %                 Z(1,i) = Z(1,i) + z_itr*increase_z;
    %             end
    %         end
    %         openingLenVec = sqrt(diff(X).^2+diff(Y).^2+diff(Z).^2);
    %         if max(0,1-openingLenVec(1,1)*openingLenVec(1,2))/wallArea < solidWallAreaFrac
    %             resultFound = 1
    %         end
    %     end
    % end
end