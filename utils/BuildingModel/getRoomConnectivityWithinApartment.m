% Function to find room connectivity from apartment unit data.

% Copyright 2024 The MathWorks, Inc.

function aptUnit = getRoomConnectivityWithinApartment(apartmentUnit,tol)
    aptUnit = apartmentUnit;
    nRooms = numel(fieldnames(apartmentUnit));
    for j = 1:nRooms-1
        for k = j+1:nRooms
            optStr = ["x+","x-","y+","y-"];
            for i = 1:length(optStr)
                overlapLength = getCommonWallLenBetweenTwoRooms(apartmentUnit,j,k,tol,optStr(1,i));
                if overlapLength > 0
                    aptUnit.("room"+num2str(j)).geometry.connectivity.("room"+num2str(k)).length = overlapLength;
                    aptUnit.("room"+num2str(k)).geometry.connectivity.("room"+num2str(j)).length = overlapLength;
                end
            end
        end
    end
end