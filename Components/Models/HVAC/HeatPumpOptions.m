classdef HeatPumpOptions < int32
% Heat Pump option definition.
    
% Copyright 2024 The MathWorks, Inc.

    enumeration
        singleUnit (1)
        assembly   (2)
    end
    methods(Static)
        function map = displayText()
            map = containers.Map;
            map('singleUnit') = 'Single Heat Pump';
            map('assembly') = 'Assembly of Heat Pumps';
        end
    end
end