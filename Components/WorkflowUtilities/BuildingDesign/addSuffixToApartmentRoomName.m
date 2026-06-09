function listOfApts = addSuffixToApartmentRoomName(NameValueArgs)
% Function to add unique strings to names of all rooms specified

% Copyright 2026 The MathWorks, Inc.

    arguments
        NameValueArgs.ApartmentList (:,1) cell {mustBeNonempty}
        NameValueArgs.UniqueNameStr (:,1) string {mustBeNonempty}
    end

    listOfApts = NameValueArgs.ApartmentList;
    if size(NameValueArgs.ApartmentList,1) == size(NameValueArgs.UniqueNameStr,1)
        for j = 1:size(NameValueArgs.UniqueNameStr,1)
            for i = 1:length(fieldnames(listOfApts{j,1}))
                listOfApts{j,1}.("room"+i).name = strcat(listOfApts{j,1}.("room"+i).name,NameValueArgs.UniqueNameStr(j,1));
            end
        end
    else
        disp("*** Error: Apartment room name not appended with the string provided.")
    end
end
