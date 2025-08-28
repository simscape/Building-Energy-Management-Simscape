function displayBuildingPicture(filename)
% Function to display building BIM picture in workflow.

% Copyright 2025 The MathWorks, Inc.

    if ~isempty(filename)
        imgData = imread(filename);
        imshow(imgData);
    else
        disp("No pre-saved building picture found.");
    end
end