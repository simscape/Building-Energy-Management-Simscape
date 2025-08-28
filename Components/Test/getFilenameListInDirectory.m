function fileNames = getFilenameListInDirectory(dirName)
% Function to get list of files (filenames) in a directory.

% Copyright 2025 The MathWorks, Inc.

    prjRoot = currentProject().RootFolder;
    dirFullPath = fullfile(prjRoot, "Components","Test",dirName);

    dataStruct = dir(dirFullPath);
    [m,~] = size(dataStruct);
    
    numDir=0;
    for i = 1:m
        if dataStruct(i,1).isdir
            numDir = numDir+1;
        end
    end

    if m-numDir > 0
        fileNames = cell(m-numDir,1);
        
        for i = numDir+1:m
            fileNames{i-numDir,1} = dataStruct(i,1).name;
        end
    else
        disp("ERROR: No files found.");
        fileNames = cell(1,1);
    end
end