classdef roomControlOption < int32
% Room Control Option.

% Copyright 2026 The MathWorks, Inc.
    
    enumeration
        heat  (1)
        valve (2)
    end
    methods(Static)
        function map = displayText()
            map = containers.Map;
            map('heat')  = 'Port S';
            map('valve') = 'Port V';
        end
    end
end