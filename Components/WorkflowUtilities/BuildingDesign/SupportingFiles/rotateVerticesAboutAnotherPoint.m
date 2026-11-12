% Internal function to rotate a point about another one.

% Copyright 2024 The MathWorks, Inc.

function [delX,delY] = rotateVerticesAboutAnotherPoint(vertex,rotateAboutVertex,degVal)
    relVec = vertex - rotateAboutVertex;
    l = sqrt(sum(relVec.^2));
    degValRel = rad2deg(atan2(relVec(1,2), relVec(1,1)));
    delX = l*cos(deg2rad(degValRel)) - l*cos(deg2rad(degValRel+degVal));
    delY = l*sin(deg2rad(degValRel)) - l*sin(deg2rad(degValRel+degVal));
end