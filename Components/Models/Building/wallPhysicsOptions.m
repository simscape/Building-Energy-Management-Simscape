classdef wallPhysicsOptions < int32
% Wall physics option definition.
    
% Copyright 2024 The MathWorks, Inc.

    enumeration
        allWallSame     (1)
        allWallNotSame  (2)
    end
    methods(Static)
        function map = displayText()
            map = containers.Map;
            map('allWallSame') = 'All Walls with Same Properties';
            map('allWallNotSame')  = 'Different Walls with Different Properties';
        end
    end
end