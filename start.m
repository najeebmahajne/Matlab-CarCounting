function count=start(val)
carVideoReader = VideoReader(val);
carMaskPlayer = vision.VideoPlayer('Position', [20, 65, 690, 350]);
carVideoPlayer = vision.VideoPlayer('Position', [20, 460, 690, 350]);
carDetector = vision.ForegroundDetector('NumGaussians', 3, ...
     'NumTrainingFrames', 300, 'MinimumBackgroundRatio', 0.69);
carBlobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
'AreaOutputPort', true, 'CentroidOutputPort', true, ...
'MinimumBlobArea', 7500);
tracks = struct(...
'bbox', {}, ...
'kalmanFilter', {}, ...
'age', {}, ...
'totalVisibleCount', {}, ...
'consecutiveInvisibleCount', {});
nextId =1;        
       
while hasFrame(carVideoReader)
    frame = readFrame(carVideoReader);
    mask = carDetector.step(frame);
    mask = medfilt2(mask);
    mask = bwareafilt(mask,[4000,200000]);
    mask = imclose(mask,strel('square', 3));
    [~, centroids, bboxes] = carBlobAnalyser.step(mask);
    for i = 1:length(tracks)
            bbox = tracks(i).bbox;
            predictedCentroid = predict(tracks(i).kalmanFilter);
            predictedCentroid = int32(predictedCentroid) - bbox(3:4) / 2;
            tracks(i).bbox = [predictedCentroid, bbox(3:4)];
    end    
    nTracks = length(tracks);
    nDetections = size(centroids, 1);
    cost = zeros(nTracks, nDetections);
    for i = 1:nTracks
    cost(i, :) = distance(tracks(i).kalmanFilter, centroids);
    end
    costOfNonAssignment = 25;
    [assignments, unassignedTracks, unassignedDetections] = ...
        assignDetectionsToTracks(cost, costOfNonAssignment);
    numAssignedTracks = size(assignments, 1);
    for i = 1:numAssignedTracks
            trackIdx = assignments(i, 1);
            detectionIdx = assignments(i, 2);
            centroid = centroids(detectionIdx, :);
            bbox = bboxes(detectionIdx, :);
            correct(tracks(trackIdx).kalmanFilter, centroid);
            tracks(trackIdx).bbox = bbox;
            tracks(trackIdx).age = tracks(trackIdx).age + 1;
            tracks(trackIdx).totalVisibleCount = ...
                tracks(trackIdx).totalVisibleCount + 1;
            tracks(trackIdx).consecutiveInvisibleCount = 0;
    end
    for i = 1:length(unassignedTracks)
            ind = unassignedTracks(i);
            tracks(ind).age = tracks(ind).age + 1;
            tracks(ind).consecutiveInvisibleCount = ...
                tracks(ind).consecutiveInvisibleCount + 1;
    end
    if ~isempty(tracks)
        invisibleForTooLong = 15;
        ageThreshold = 2;
        ages = [tracks(:).age];
        totalVisibleCounts = [tracks(:).totalVisibleCount];
        visibility = totalVisibleCounts ./ ages;
        lostInds = (ages < ageThreshold & visibility < 0.6) | ...
            [tracks(:).consecutiveInvisibleCount] >= invisibleForTooLong;
        tracks = tracks(~lostInds);
    end
    centroids = centroids(unassignedDetections, :);
    bboxes = bboxes(unassignedDetections, :);

    for i = 1:size(centroids, 1)
            centroid = centroids(i,:);
            bbox = bboxes(i, :);
            kalmanFilter = configureKalmanFilter('ConstantVelocity', ...
                centroid, [1000, 1000], [300, 250], 200);
            newTrack = struct(...
                'bbox', bbox, ...
                'kalmanFilter', kalmanFilter, ...
                'age', 1, ...
                'totalVisibleCount', 1, ...
                'consecutiveInvisibleCount', 0);
            tracks(end + 1) = newTrack;
            nextId = nextId + 1;
    end
        frame = im2uint8(frame);
        mask = uint8(repmat(mask, [1, 1, 3])) .* 255;
        minVisibleCount = 10;
        if ~isempty(tracks)
            reliableTrackInds = ...
                [tracks(:).totalVisibleCount] > minVisibleCount;
            reliableTracks = tracks(reliableTrackInds);
            if ~isempty(reliableTracks)
                bboxes = cat(1, reliableTracks.bbox);
                labels = cellstr('');
                frame = insertObjectAnnotation(frame, 'rectangle', ... 
                    bboxes,labels);
                mask = insertObjectAnnotation(mask, 'rectangle', ...
                    bboxes,labels);
            end
        end
        carMaskPlayer.step(mask);
        carVideoPlayer.step(frame);
end
nextId=nextId-1;
count=nextId;
end

