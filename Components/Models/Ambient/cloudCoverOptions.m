classdef cloudCoverOptions < int32
% Cloud cover option definition.

% Copyright 2024 The MathWorks, Inc.
    
    enumeration
        hourly (1)
        daily  (2)
    end
    methods(Static)
        function map = displayText()
            map = containers.Map;
            map('hourly') = 'Hourly data';
            map('daily')  = 'Day-wise data';
        end
    end
end