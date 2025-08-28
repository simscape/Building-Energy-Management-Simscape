classdef NominalConditionDeviationModel < int32
% Nominal Condition Deviation Model definition for heat pumps.
    
% Copyright 2024 The MathWorks, Inc.

    enumeration
        enabled  (1)
        disabled (2)
    end
    methods(Static)
        function map = displayText()
            map = containers.Map;
            map('enabled') = 'Enable';
            map('disabled') = 'Disable';
        end
    end
end