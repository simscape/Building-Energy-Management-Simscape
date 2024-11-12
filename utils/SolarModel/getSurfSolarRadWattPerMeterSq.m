% Function to find solar radiation on a plane surface inclined at a 
% particular angle.

% Copyright 2024 The MathWorks, Inc.

function solarRadWattPerMeterSq = getSurfSolarRadWattPerMeterSq(surfAngle,surfUnitNormal,nYr,nDay,nHrs,geoLocation,dayLightSaving)
    arguments
        surfAngle (1,1) {mustBeInRange(surfAngle,[0,90])}
        surfUnitNormal (1,2) {mustBeNonempty, mustBeNonNan}
        nYr (1,1) {mustBeInteger}
        nDay (1,1) {mustBeInRange(nDay,[1 366])}
        nHrs (1,1) {mustBeInRange(nHrs,[0,24])}
        geoLocation struct {mustBeNonempty}
        dayLightSaving (1,1) {mustBeNonNan}
    end
    cosineAngleOfIncidence = getAngleSunRaysOnSurface(surfAngle,surfUnitNormal,nYr,nDay,nHrs,geoLocation,dayLightSaving);
    solarRadWattPerMeterSq = cosineAngleOfIncidence*getSunRadiationOnTheDay(geoLocation,nYr,nDay,nHrs,dayLightSaving);
end