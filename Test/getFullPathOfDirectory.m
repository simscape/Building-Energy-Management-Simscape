function dirLocationName = getFullPathOfDirectory(NameValueArgs)
%Get full path for a directory location

% Copyright 2025 The MathWorks, Inc.

    arguments
        NameValueArgs.ListOfDir (1,:) string {mustBeNonempty}
    end

    dirLocationName = currentProject().RootFolder;
    for i = 1:length(NameValueArgs.ListOfDir)
        dirLocationName = strcat(dirLocationName,filesep,NameValueArgs.ListOfDir(1,i));
    end
end