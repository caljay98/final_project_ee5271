% Calvin Molitor
% Sam Benscoter
% EE 5271

% import a video file as an array of frames
video = VideoReader('samples/GolfCartRun.mp4');
% DEBUG only a few frames for now
%numframes = video.NumFrames;
numframes = 10;
video.CurrentTime = 20;

vidframes = zeros(video.Height, video.Width, 3, numframes, 'uint8');
for c = 1:numframes
    vidframes(:, :, :, c) = readFrame(video);
end

imshow(vidframes(:, :, :, 1))



% process each frame to remove fisheye, increase contrast, and other things
% if needed

% calculate the number of frames in the video and other details

% find the slip angle of each frame. Save the data to an array

% Export the array with each slip angle along with a timestamp to a CSV

% also export as a GDAT so it can be imported to i2

