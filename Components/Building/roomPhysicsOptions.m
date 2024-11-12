classdef roomPhysicsOptions < int32
% Room physics option definition.
    
% Copyright 2024 The MathWorks, Inc.

    enumeration
        basicroom      (1)
        requirements   (2)
        roomRadiator   (3)
        roomRadiatorUF (4)
        roomUF         (5)
    end
    methods(Static)
        function map = displayText()
            map = containers.Map;
            map('basicroom')      = 'Thermal Load';
            map('requirements')   = 'Thermal Requirements';
            map('roomRadiator')   = 'HVAC: Room Radiator Only';
            map('roomRadiatorUF') = 'HVAC: Room Radiator with Underfloor Heating/Cooling';
            map('roomUF')         = 'HVAC: Room Underfloor Heating/Cooling Only';
        end
    end
end