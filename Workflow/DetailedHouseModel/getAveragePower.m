function res = getAveragePower(data)
% Function to find average power in Detailed House workflow.

% Copyright 2025 The MathWorks, Inc.

    dt = diff(data.Time);
    Q = data.Q(2:end);
    res = sum(dt.*Q)/(data.Time(end)-data.Time(1));
end