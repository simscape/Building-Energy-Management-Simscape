function adjustedApt = adjustRoomContact(NameValueArgs)
% adjustRoomContact  Adjust room dimensions to fix overlaps and gaps.
%
%   adjustedApt = adjustRoomContact(Apartment=oneAptUnit)
%   adjustedApt = adjustRoomContact(Apartment=oneAptUnit, Tol=0.5)
%   adjustedApt = adjustRoomContact(..., MaxIter=15, Plot=true)
%
%   This function corrects two types of unintentional drawing errors in an
%   apartment floor plan:
%
%     1. OVERLAPS — Two rooms sharing a small area of intersection. The
%        function shrinks the intruding dimension or shifts the vertex of
%        the offending room to eliminate the overlap.
%
%     2. GAPS — Two rooms whose edges are close but not touching. The
%        function extends the width or length of one room so that the
%        edges meet, establishing proper internal wall contact.
%
%   The algorithm operates iteratively:
%     - Phase 1: Resolve all overlaps (higher priority).
%     - Phase 2: Close all gaps.
%     - Repeat until no issues remain or MaxIter is reached.
%   A convergence guard detects oscillating corrections and terminates
%   early if the geometry snapshot is unchanged after a correction pass.
%
%   Oscillation avoidance: When closing a gap would extend a room into an
%   already-touching neighbor (creating overlap that gets reverted next
%   iteration), the algorithm shifts the gap-side room's vertex instead.
%
%   After correction, each room pair either shares exact line contact
%   (internal wall) or is clearly separated (no connection intended).
%
% INPUTS (Name-Value):
%   Apartment - (required) 1xN struct array from addRoomToFloorPlan.
%               Each element must contain the fields:
%                 .floorPlan           - polyshape object
%                 .name                - string (room identifier)
%                 .geometry.dim.vertex - [x, y] bottom-left corner
%                 .geometry.dim.width  - scalar (X-extent)
%                 .geometry.dim.length - scalar (Y-extent)
%                 .geometry.dim.theta  - scalar (rotation in degrees)
%
%   Tol       - (optional) Maximum gap or overlap size to treat as
%               unintentional. Issues larger than Tol are ignored.
%               Units must match the room geometry units. Default: 1.0
%
%   MaxIter   - (optional) Maximum number of correction iterations.
%               Prevents infinite loops for unresolvable configurations.
%               Default: 10
%
%   Plot      - (optional) Logical flag. When true, displays the adjusted
%               floor plan using plotFloorPlanLayout. Default: false
%
% OUTPUT:
%   adjustedApt - 1xN struct array with the same format as input.
%                 Room dimensions are adjusted so that near-miss walls
%                 achieve exact line contact and overlaps are removed.
%
% EXAMPLE:
%   % Create rooms with a small gap (0.3 ft) between them:
%   oneAptUnit = [];
%   oneAptUnit = addRoomToFloorPlan(FloorPlan=oneAptUnit, ...
%       NewRoom="LivingRoom", Vertex=simscape.Value([0,0],"ft"), ...
%       Length=simscape.Value(8,"ft"), Width=simscape.Value(10,"ft"));
%   oneAptUnit = addRoomToFloorPlan(FloorPlan=oneAptUnit, ...
%       NewRoom="Bedroom", Vertex=simscape.Value([10.3,0],"ft"), ...
%       Length=simscape.Value(10,"ft"), Width=simscape.Value(8,"ft"));
%
%   % Fix the gap automatically:
%   oneAptUnit = adjustRoomContact(Apartment=oneAptUnit, Tol=1.0, Plot=true);
%
%   % Proceed with apartment definition:
%   modelApt = defineSingleApartmentUnit(Apartment=oneAptUnit, Tol=0.01);
%
% See also: addRoomToFloorPlan, defineSingleApartmentUnit, plotFloorPlanLayout
%
% Copyright 2024 - 2026 The MathWorks, Inc.

    arguments
        NameValueArgs.Apartment struct {mustBeNonempty}
        NameValueArgs.Tol (1,1) {mustBePositive} = 1.0
        NameValueArgs.MaxIter (1,1) {mustBePositive, mustBeInteger} = 10
        NameValueArgs.Plot (1,1) logical = false
    end

    %% Extract and validate inputs
    rooms   = NameValueArgs.Apartment;
    tol     = NameValueArgs.Tol;
    maxIter = NameValueArgs.MaxIter;
    nRooms  = numel(rooms);

    validateRoomStruct(rooms);

    if nRooms < 2
        adjustedApt = rooms;
        return;
    end

    %% Iterative correction loop
    converged    = false;
    prevSnapshot = captureGeometrySnapshot(rooms);

    for iter = 1:maxIter %#ok<FXUP>
        % Phase 1: Resolve overlaps (higher priority than gaps)
        overlapAdj = detectOverlaps(rooms, tol);
        if ~isempty(overlapAdj)
            rooms = applyCorrections(rooms, overlapAdj);
            rooms = rebuildPolyshapes(rooms);

            if hasOscillated(rooms, prevSnapshot)
                break;
            end
            prevSnapshot = captureGeometrySnapshot(rooms);
            continue;
        end

        % Phase 2: Close gaps to establish wall contact
        gapAdj = detectGaps(rooms, tol);
        if ~isempty(gapAdj)
            rooms = applyCorrections(rooms, gapAdj);
            rooms = rebuildPolyshapes(rooms);

            if hasOscillated(rooms, prevSnapshot)
                break;
            end
            prevSnapshot = captureGeometrySnapshot(rooms);
            continue;
        end

        % Both phases found nothing to fix — converged
        converged = true;
        break;
    end

    %% Report if convergence was not achieved
    if ~converged
        nOverlaps = numel(detectOverlaps(rooms, tol));
        nGaps     = numel(detectGaps(rooms, tol));
        if (nOverlaps + nGaps) > 0
            warning('adjustRoomContact:maxIterReached', ...
                ['Maximum iterations (%d) reached. ' ...
                 '%d overlap(s) and %d gap(s) may remain. ' ...
                 'Consider increasing Tol or MaxIter.'], ...
                maxIter, nOverlaps, nGaps);
        end
    end

    %% Plot if requested
    if NameValueArgs.Plot
        figure('Name', 'Adjusted Room Contact');
        plotFloorPlanLayout(PlotData=rooms, Type="room");
        title('Room Layout After Contact Adjustment');
    end

    adjustedApt = rooms;
end


%% ========================================================================
%  CONSTANTS
%  ========================================================================

function eps = epsGap()
% epsGap  Minimum gap threshold below which distances are floating-point noise.
    eps = 1e-6;
end

function eps = epsArea()
% epsArea  Minimum overlap area below which intersections are floating-point noise.
    eps = 1e-6;
end


%% ========================================================================
%  INPUT VALIDATION
%  ========================================================================

function validateRoomStruct(rooms)
% validateRoomStruct  Verify that each room has the required struct fields.
%   Throws an informative error identifying which room and field is missing.

    requiredTopFields = {'floorPlan', 'name', 'geometry'};
    requiredDimFields = {'vertex', 'width', 'length', 'theta'};

    for i = 1:numel(rooms)
        % Check top-level fields
        for f = 1:numel(requiredTopFields)
            if ~isfield(rooms(i), requiredTopFields{f})
                error('adjustRoomContact:missingField', ...
                    'Room %d is missing required field "%s".', ...
                    i, requiredTopFields{f});
            end
        end

        % Check geometry.dim sub-structure
        if ~isfield(rooms(i).geometry, 'dim')
            error('adjustRoomContact:missingField', ...
                'Room %d ("%s") is missing "geometry.dim".', i, rooms(i).name);
        end

        dim = rooms(i).geometry.dim;
        for f = 1:numel(requiredDimFields)
            if ~isfield(dim, requiredDimFields{f})
                error('adjustRoomContact:missingField', ...
                    'Room %d ("%s") is missing "geometry.dim.%s".', ...
                    i, rooms(i).name, requiredDimFields{f});
            end
        end

        % Validate dimension values are positive
        if dim.width <= 0
            error('adjustRoomContact:invalidDimension', ...
                'Room %d ("%s") has non-positive width (%.4f).', ...
                i, rooms(i).name, dim.width);
        end
        if dim.length <= 0
            error('adjustRoomContact:invalidDimension', ...
                'Room %d ("%s") has non-positive length (%.4f).', ...
                i, rooms(i).name, dim.length);
        end

        % Validate vertex is a 1x2 numeric vector
        if ~isnumeric(dim.vertex) || numel(dim.vertex) ~= 2
            error('adjustRoomContact:invalidVertex', ...
                'Room %d ("%s") vertex must be a 1x2 numeric vector.', ...
                i, rooms(i).name);
        end

        % Validate floorPlan is a polyshape
        if ~isa(rooms(i).floorPlan, 'polyshape')
            error('adjustRoomContact:invalidPolyshape', ...
                'Room %d ("%s") floorPlan must be a polyshape object.', ...
                i, rooms(i).name);
        end
    end
end


%% ========================================================================
%  OVERLAP DETECTION AND RESOLUTION
%  ========================================================================

function adjustments = detectOverlaps(rooms, tol)
% detectOverlaps  Find all overlapping room pairs within tolerance.
%   Examines every unique pair (j,k) and returns a struct array of
%   correction actions needed to eliminate the overlaps.
%
%   Only overlaps where the narrower extent is <= tol are treated as
%   unintentional drawing errors. Larger overlaps are left untouched.

    adjustments = emptyCorrections();
    nRooms = numel(rooms);

    for j = 1:nRooms-1
        for k = j+1:nRooms
            adj = computeOverlapCorrection(rooms(j), rooms(k), tol);
            if ~isempty(adj)
                adjustments(end+1) = adj; %#ok<AGROW>
            end
        end
    end
end


function adj = computeOverlapCorrection(roomA, roomB, tol)
% computeOverlapCorrection  Determine correction for a single overlap pair.
%   Returns a correction struct or [] if no actionable overlap exists.

    adj = [];

    % Compute intersection polygon
    try
        intersectionPoly = intersect(roomA.floorPlan, roomB.floorPlan);
    catch
        return;  % Malformed polyshape — skip this pair
    end

    if intersectionPoly.area <= epsArea()
        return;  % No meaningful overlap
    end

    % Measure overlap bounding box extents
    [xLim, yLim] = boundingbox(intersectionPoly);
    overlapX = xLim(2) - xLim(1);
    overlapY = yLim(2) - yLim(1);

    % Ignore large overlaps (intentional or beyond scope)
    if min(overlapX, overlapY) > tol
        return;
    end

    % Route to resolution strategy based on room alignment
    boundsA = getAxisAlignedBounds(roomA);
    boundsB = getAxisAlignedBounds(roomB);

    if boundsA.aligned && boundsB.aligned
        adj = resolveAxisAlignedOverlap(roomA, roomB, boundsA, boundsB, ...
                                         overlapX, overlapY);
    else
        adj = resolveRotatedOverlap(roomA, roomB, overlapX, overlapY);
    end
end


function adj = resolveAxisAlignedOverlap(roomA, roomB, boundsA, boundsB, ...
                                          overlapX, overlapY)
% resolveAxisAlignedOverlap  Fix overlap between two axis-aligned rooms.
%   Corrects along the axis with the smaller overlap (minimal disturbance).

    if overlapX <= overlapY
        adj = resolveDirectionalOverlap(roomA, roomB, boundsA, boundsB, ...
                                         'x', overlapX);
    else
        adj = resolveDirectionalOverlap(roomA, roomB, boundsA, boundsB, ...
                                         'y', overlapY);
    end
end


function adj = resolveDirectionalOverlap(roomA, roomB, boundsA, boundsB, ...
                                          axis, overlapAmount)
% resolveDirectionalOverlap  Fix an overlap along a single axis.
%   Determines which room's edge intrudes: if a room's far edge crossed
%   the other's near edge, shrink it. If its vertex is inside the other,
%   shift it outward.
%
%   axis: 'x' or 'y'
%   Maps: x → width (shrink) / x (shift), y → length (shrink) / y (shift)

    if strcmp(axis, 'x')
        dimField = 'width';
        aMin = boundsA.xmin; aMax = boundsA.xmax;
        bMin = boundsB.xmin; bMax = boundsB.xmax;
    else
        dimField = 'length';
        aMin = boundsA.ymin; aMax = boundsA.ymax;
        bMin = boundsB.ymin; bMax = boundsB.ymax;
    end

    if aMax > bMin && aMin < bMin
        % A's far edge extends past B's near edge — shrink A
        adj = makeCorrection(roomA.name, 'shrink', dimField, overlapAmount);
    elseif bMax > aMin && bMin < aMin
        % B's far edge extends past A's near edge — shrink B
        adj = makeCorrection(roomB.name, 'shrink', dimField, overlapAmount);
    elseif aMin >= bMin && aMin < bMax
        % A's vertex is inside B — shift A in the positive direction
        adj = makeCorrection(roomA.name, 'shiftVertex', axis, overlapAmount);
    else
        % B's vertex is inside A — shift B in the positive direction
        adj = makeCorrection(roomB.name, 'shiftVertex', axis, overlapAmount);
    end
end


function adj = resolveRotatedOverlap(roomA, roomB, overlapX, overlapY)
% resolveRotatedOverlap  Fix overlap between rotated (non-axis-aligned) rooms.
%   Shrinks the smaller room's dimension (more likely drawn imprecisely).

    areaA = roomA.geometry.dim.width * roomA.geometry.dim.length;
    areaB = roomB.geometry.dim.width * roomB.geometry.dim.length;

    if areaA <= areaB
        targetName = roomA.name;
    else
        targetName = roomB.name;
    end

    if overlapX <= overlapY
        adj = makeCorrection(targetName, 'shrink', 'width', overlapX);
    else
        adj = makeCorrection(targetName, 'shrink', 'length', overlapY);
    end
end


%% ========================================================================
%  GAP DETECTION AND RESOLUTION
%  ========================================================================

function adjustments = detectGaps(rooms, tol)
% detectGaps  Find all room pairs with small gaps and compute corrections.
%   Examines every unique pair (j,k) and returns a struct array of
%   correction actions to close gaps smaller than tol.
%
%   A pair may produce multiple corrections (e.g., corner cases where
%   both X and Y gaps need closing simultaneously).

    adjustments = emptyCorrections();
    nRooms = numel(rooms);

    for j = 1:nRooms-1
        for k = j+1:nRooms
            adjs = computeGapCorrection(rooms(j), rooms(k), tol, rooms);
            if ~isempty(adjs)
                adjustments = [adjustments, adjs]; %#ok<AGROW>
            end
        end
    end
end


function adjs = computeGapCorrection(roomA, roomB, tol, allRooms)
% computeGapCorrection  Determine corrections for a gap between two rooms.
%   Returns a struct array of corrections (may be multiple for corner gaps)
%   or [] if no actionable gap exists.
%
%   allRooms is passed through so gap resolution can detect touching
%   neighbors and avoid corrections that would create new overlaps.

    adjs = [];

    boundsA = getAxisAlignedBounds(roomA);
    boundsB = getAxisAlignedBounds(roomB);

    % Quick reject: bounding boxes far apart in both directions
    xSep = max(boundsA.xmin, boundsB.xmin) - min(boundsA.xmax, boundsB.xmax);
    ySep = max(boundsA.ymin, boundsB.ymin) - min(boundsA.ymax, boundsB.ymax);
    if xSep > tol && ySep > tol
        return;
    end

    % Route to strategy based on room alignment
    if boundsA.aligned && boundsB.aligned
        adjs = resolveAxisAlignedGap(boundsA, roomA, boundsB, roomB, ...
                                      tol, allRooms);
    else
        adjs = resolveRotatedGap(roomA, roomB, tol);
    end
end


function adjs = resolveAxisAlignedGap(boundsA, roomA, boundsB, roomB, ...
                                       tol, allRooms)
% resolveAxisAlignedGap  Find and fix gaps between two axis-aligned rooms.
%
%   Detects gaps in X and Y directions, then selects the appropriate
%   correction strategy:
%
%   STANDARD CASE — Gap exists along one axis with perpendicular overlap
%   (rooms share a span on the other axis). The smallest such gap is fixed.
%
%   CORNER CASE — Both X and Y gaps exist but neither has perpendicular
%   overlap (rooms are diagonally offset). Both corrections are returned
%   so successive iterations close the corner completely.
%
%   OSCILLATION AVOIDANCE — Before extending a room, checks if it already
%   touches another room on the extension side. If so, shifts the gap-side
%   room's vertex instead. This prevents the extend/overlap/shrink cycle
%   that causes the algorithm to stall without fixing the gap.

    adjs = [];

    % Shared span in each perpendicular direction
    yOverlap = min(boundsA.ymax, boundsB.ymax) - max(boundsA.ymin, boundsB.ymin);
    xOverlap = min(boundsA.xmax, boundsB.xmax) - max(boundsA.xmin, boundsB.xmin);

    % Detect gaps in X and Y directions
    xAdj = detectDirectionalGap(boundsA, roomA, boundsB, roomB, 'x', tol, allRooms);
    yAdj = detectDirectionalGap(boundsA, roomA, boundsB, roomB, 'y', tol, allRooms);

    xGapValid = ~isempty(xAdj);
    yGapValid = ~isempty(yAdj);

    % Corner case: both gaps exist but neither has perpendicular overlap
    if xGapValid && yGapValid && yOverlap <= 0 && xOverlap <= 0
        adjs = [xAdj, yAdj];
        return;
    end

    % Standard case: return only gaps that have perpendicular overlap
    candidates = emptyCorrections();
    if xGapValid && yOverlap > 0
        candidates(end+1) = xAdj;
    end
    if yGapValid && xOverlap > 0
        candidates(end+1) = yAdj;
    end

    % Select the smallest gap correction (by magnitude)
    if ~isempty(candidates)
        [~, idx] = min(abs([candidates.delta]));
        adjs = candidates(idx);
    end
end


function adj = detectDirectionalGap(boundsA, roomA, boundsB, roomB, ...
                                     axis, tol, allRooms)
% detectDirectionalGap  Detect and build correction for a gap along one axis.
%
%   Checks if room A's far edge has a small gap to room B's near edge
%   (or vice versa). If a gap is found within (epsGap, tol), builds the
%   correction with oscillation-aware strategy selection:
%     - Extend the trailing room if its extension side is free.
%     - Shift the leading room's vertex if extension would cause overlap.
%
%   axis: 'x' or 'y'
%   Returns a single correction struct, or [] if no gap found.

    adj = [];

    if strcmp(axis, 'x')
        % Gap in X: A-left-of-B or B-left-of-A
        gapAB = boundsB.xmin - boundsA.xmax;  % A is left of B
        gapBA = boundsA.xmin - boundsB.xmax;  % B is left of A
        extendSide = 'right';
        dimField   = 'width';
        shiftAxis  = 'x';
    else
        % Gap in Y: A-below-B or B-below-A
        gapAB = boundsB.ymin - boundsA.ymax;  % A is below B
        gapBA = boundsA.ymin - boundsB.ymax;  % B is below A
        extendSide = 'top';
        dimField   = 'length';
        shiftAxis  = 'y';
    end

    if gapAB > epsGap() && gapAB < tol
        % A trails, B leads — extend A or shift B
        adj = buildGapCorrection(roomA, roomB, gapAB, ...
                                  extendSide, dimField, shiftAxis, allRooms);
    elseif gapBA > epsGap() && gapBA < tol
        % B trails, A leads — extend B or shift A
        adj = buildGapCorrection(roomB, roomA, gapBA, ...
                                  extendSide, dimField, shiftAxis, allRooms);
    end
end


function adj = buildGapCorrection(trailingRoom, leadingRoom, gapSize, ...
                                   extendSide, dimField, shiftAxis, allRooms)
% buildGapCorrection  Choose between extend and shift to close a gap.
%
%   trailingRoom — the room whose far edge is near the leading room's near
%                  edge. Normally extended to close the gap.
%   leadingRoom  — the room on the other side of the gap. Shifted toward
%                  the trailing room if extension would cause oscillation.
%
%   Strategy:
%     If trailingRoom already touches another room on its extension side,
%     extending would overlap that neighbor. Instead, shift leadingRoom's
%     vertex toward trailingRoom (negative direction) to close the gap.

    if roomTouchesOnSide(trailingRoom, extendSide, allRooms)
        % Shift leading room's vertex toward trailing room
        adj = makeCorrection(leadingRoom.name, 'shiftVertex', shiftAxis, -gapSize);
    else
        % Extend trailing room's dimension to close the gap
        adj = makeCorrection(trailingRoom.name, 'extend', dimField, gapSize);
    end
end


function adjs = resolveRotatedGap(roomA, roomB, tol)
% resolveRotatedGap  Close a gap between rotated (non-axis-aligned) rooms.
%   Uses polyshape distance to measure the gap, then extends the
%   appropriate dimension based on nearest-vertex analysis.
%
%   For diagonal gaps (both X and Y components are comparable), returns
%   corrections for both axes.

    adjs = [];

    % Measure distance between the two polyshapes
    try
        dist = distance(roomA.floorPlan, roomB.floorPlan);
    catch
        return;  % Malformed polyshape — skip
    end

    if dist <= epsGap() || dist >= tol
        return;  % Already touching, or too far apart
    end

    % Determine gap direction from nearest vertices
    vertsA = roomA.floorPlan.Vertices;
    vertsB = roomB.floorPlan.Vertices;

    [~, ~, indA] = nearestvertex(roomA.floorPlan, roomB.floorPlan);
    ptA = vertsA(indA, :);

    vertDists = sqrt(sum((vertsB - ptA).^2, 2));
    [~, indB] = min(vertDists);
    ptB = vertsB(indB, :);

    gapX = abs(ptB(1) - ptA(1));
    gapY = abs(ptB(2) - ptA(2));

    % Diagonal gap: both components significant (within 2x of each other)
    if gapX > epsGap() && gapY > epsGap() && ...
       max(gapX, gapY) < 2 * min(gapX, gapY)
        adjs = [makeCorrection(roomA.name, 'extend', 'width', gapX), ...
                makeCorrection(roomA.name, 'extend', 'length', gapY)];
    elseif gapX >= gapY
        adjs = makeCorrection(roomA.name, 'extend', 'width', dist);
    else
        adjs = makeCorrection(roomA.name, 'extend', 'length', dist);
    end
end


%% ========================================================================
%  CORRECTION APPLICATION
%  ========================================================================

function rooms = applyCorrections(rooms, corrections)
% applyCorrections  Apply a batch of corrections to room geometry.
%   Each correction modifies one room's width, length, or vertex position.
%
%   Supported actions:
%     'extend'      — increase width or length (close a gap)
%     'shrink'      — decrease width or length (remove an overlap)
%     'shiftVertex' — translate vertex in x or y (move room)
%
%   If a shrink would produce a non-positive dimension, the correction is
%   reverted and a warning is issued.

    for i = 1:numel(corrections)
        c = corrections(i);

        idx = findRoomByName(rooms, c.roomIdx);
        if isempty(idx)
            warning('adjustRoomContact:roomNotFound', ...
                'Room "%s" not found. Skipping correction.', c.roomIdx);
            continue;
        end

        switch c.action
            case 'extend'
                rooms(idx) = modifyDimension(rooms(idx), c.field, +c.delta);

            case 'shrink'
                rooms(idx) = modifyDimension(rooms(idx), c.field, -c.delta);
                if rooms(idx).geometry.dim.width <= 0 || ...
                   rooms(idx).geometry.dim.length <= 0
                    warning('adjustRoomContact:negativeDimension', ...
                        'Shrink would make room "%s" non-positive. Reverting.', ...
                        c.roomIdx);
                    rooms(idx) = modifyDimension(rooms(idx), c.field, +c.delta);
                end

            case 'shiftVertex'
                rooms(idx) = shiftVertex(rooms(idx), c.field, c.delta);

            otherwise
                warning('adjustRoomContact:unknownAction', ...
                    'Unknown action "%s" for room "%s". Skipping.', ...
                    c.action, c.roomIdx);
        end
    end
end


function room = modifyDimension(room, field, delta)
% modifyDimension  Add delta to a room's width or length.

    switch field
        case 'width'
            room.geometry.dim.width = room.geometry.dim.width + delta;
        case 'length'
            room.geometry.dim.length = room.geometry.dim.length + delta;
        otherwise
            error('adjustRoomContact:invalidField', ...
                'Expected "width" or "length", got "%s".', field);
    end
end


function room = shiftVertex(room, axis, delta)
% shiftVertex  Translate a room's vertex along one axis.

    switch axis
        case 'x'
            room.geometry.dim.vertex(1) = room.geometry.dim.vertex(1) + delta;
        case 'y'
            room.geometry.dim.vertex(2) = room.geometry.dim.vertex(2) + delta;
        otherwise
            error('adjustRoomContact:invalidAxis', ...
                'Expected "x" or "y", got "%s".', axis);
    end
end


%% ========================================================================
%  POLYSHAPE REBUILD
%  ========================================================================

function rooms = rebuildPolyshapes(rooms)
% rebuildPolyshapes  Recreate each room's polyshape from current dimensions.
%   Must be called after any geometry modification to keep .floorPlan
%   consistent with .geometry.dim values.
%
%   Construction (matches addNewRoomToFloorPlan):
%     1. Axis-aligned rectangle from vertex + width + length.
%     2. Rotate by theta degrees about the vertex (bottom-left corner).

    for i = 1:numel(rooms)
        v     = rooms(i).geometry.dim.vertex;
        w     = rooms(i).geometry.dim.width;
        l     = rooms(i).geometry.dim.length;
        theta = rooms(i).geometry.dim.theta;

        corners = [v(1),   v(2);   ...
                   v(1)+w, v(2);   ...
                   v(1)+w, v(2)+l; ...
                   v(1),   v(2)+l];

        polyRect = polyshape(corners(:,1)', corners(:,2)');
        rooms(i).floorPlan = rotate(polyRect, theta, corners(1,:));
    end
end


%% ========================================================================
%  NEIGHBOR CONTACT DETECTION
%  ========================================================================

function touches = roomTouchesOnSide(room, side, allRooms)
% roomTouchesOnSide  Check if a room touches any other room on a given side.
%   Returns true if at least one other room shares an edge (within epsGap)
%   on the specified side of the target room.
%
%   Sides: 'right' (xmax), 'left' (xmin), 'top' (ymax), 'bottom' (ymin)
%
%   Contact requires both:
%     1. Edge alignment — edges are within epsGap of each other.
%     2. Shared span — rooms overlap on the perpendicular axis (actual
%        wall contact, not just corner-touching).
%
%   Used by gap resolution to detect when extending a room would create
%   an overlap with an already-touching neighbor.

    touches = false;
    boundsR = getAxisAlignedBounds(room);

    for i = 1:numel(allRooms)
        if strcmp(allRooms(i).name, room.name)
            continue;
        end

        boundsI = getAxisAlignedBounds(allRooms(i));

        if checkEdgeContact(boundsR, boundsI, side)
            touches = true;
            return;
        end
    end
end


function contact = checkEdgeContact(boundsR, boundsI, side)
% checkEdgeContact  Test if two rooms share wall contact on a given side.
%   boundsR: bounds of the room being tested.
%   boundsI: bounds of the candidate neighbor.
%   side: which edge of boundsR to test ('right', 'left', 'top', 'bottom').
%
%   Returns true if the edges are within epsGap AND the perpendicular
%   shared span exceeds epsGap (distinguishes wall contact from coincidental
%   corner alignment).

    contact = false;
    EPS = epsGap();

    switch side
        case 'right'
            edgeAligned = abs(boundsR.xmax - boundsI.xmin) <= EPS;
            sharedSpan  = min(boundsR.ymax, boundsI.ymax) - ...
                          max(boundsR.ymin, boundsI.ymin);
        case 'left'
            edgeAligned = abs(boundsR.xmin - boundsI.xmax) <= EPS;
            sharedSpan  = min(boundsR.ymax, boundsI.ymax) - ...
                          max(boundsR.ymin, boundsI.ymin);
        case 'top'
            edgeAligned = abs(boundsR.ymax - boundsI.ymin) <= EPS;
            sharedSpan  = min(boundsR.xmax, boundsI.xmax) - ...
                          max(boundsR.xmin, boundsI.xmin);
        case 'bottom'
            edgeAligned = abs(boundsR.ymin - boundsI.ymax) <= EPS;
            sharedSpan  = min(boundsR.xmax, boundsI.xmax) - ...
                          max(boundsR.xmin, boundsI.xmin);
    end

    contact = edgeAligned && sharedSpan > EPS;
end


%% ========================================================================
%  GEOMETRY UTILITIES
%  ========================================================================

function bounds = getAxisAlignedBounds(room)
% getAxisAlignedBounds  Compute bounding box edges for a room.
%   For axis-aligned rooms (theta ~ 0 mod 360): exact edges from geometry.
%   For rotated rooms: polyshape bounding box (less precise but valid).
%
%   Output struct: .xmin, .xmax, .ymin, .ymax, .aligned (bool)

    v     = room.geometry.dim.vertex;
    w     = room.geometry.dim.width;
    l     = room.geometry.dim.length;
    theta = room.geometry.dim.theta;

    if abs(mod(theta, 360)) < epsGap()
        bounds.xmin = v(1);
        bounds.xmax = v(1) + w;
        bounds.ymin = v(2);
        bounds.ymax = v(2) + l;
        bounds.aligned = true;
    else
        [xBB, yBB] = boundingbox(room.floorPlan);
        bounds.xmin = xBB(1);
        bounds.xmax = xBB(2);
        bounds.ymin = yBB(1);
        bounds.ymax = yBB(2);
        bounds.aligned = false;
    end
end


%% ========================================================================
%  CONVERGENCE DETECTION
%  ========================================================================

function oscillated = hasOscillated(rooms, prevSnapshot)
% hasOscillated  Check if geometry is unchanged after a correction pass.
%   Returns true if the current geometry matches the previous snapshot,
%   indicating the algorithm is stuck in a cycle.

    currSnapshot = captureGeometrySnapshot(rooms);
    oscillated = isequal(prevSnapshot, currSnapshot);
end


function snapshot = captureGeometrySnapshot(rooms)
% captureGeometrySnapshot  Numeric fingerprint of all room geometry.
%   Returns a rounded matrix (nRooms x 4): [vertex_x, vertex_y, width, length]
%   Rounded to 10 decimal places to absorb floating-point noise while
%   detecting real changes.

    nRooms = numel(rooms);
    snapshot = zeros(nRooms, 4);
    for i = 1:nRooms
        snapshot(i,:) = round([ ...
            rooms(i).geometry.dim.vertex(1), ...
            rooms(i).geometry.dim.vertex(2), ...
            rooms(i).geometry.dim.width, ...
            rooms(i).geometry.dim.length], 10);
    end
end


%% ========================================================================
%  STRUCT UTILITIES
%  ========================================================================

function idx = findRoomByName(rooms, name)
% findRoomByName  Return the index of the first room matching name, or [].

    idx = [];
    for r = 1:numel(rooms)
        if strcmp(rooms(r).name, name)
            idx = r;
            return;
        end
    end
end


function adj = makeCorrection(roomName, action, field, delta)
% makeCorrection  Construct a correction struct.
%   Fields: roomIdx (string), action (string), field (string), delta (scalar)

    adj.roomIdx = roomName;
    adj.action  = action;
    adj.field   = field;
    adj.delta   = delta;
end


function s = emptyCorrections()
% emptyCorrections  Return an empty struct array with correction fields.
    s = struct('roomIdx', {}, 'action', {}, 'field', {}, 'delta', {});
end
