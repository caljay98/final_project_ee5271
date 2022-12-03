
%% Load Image
video = VideoReader('GolfCartRun.mp4');
testFrame = read(video, 700);

%% Gray Scale
figure(1);
testFrame = rgb2gray(testFrame);
idisp(testFrame);

%% Niblack Relative Comparisons
figure(2);
niblack_testFrame = niblack(testFrame, -0.1, 20);
niblack_testFrame = testFrame >= abs(niblack_testFrame);
niblack_testFrame = niblack_testFrame(20:460, 20:620);
idisp(niblack_testFrame);

%% Erosion
figure(3);
morph_testFrame = ierode(niblack_testFrame, ones(3, 3), 2);
idisp(morph_testFrame);

%% Check if Plus Filter Has 2 Neighbors, else Remove Pixel
filter = [0 1 0; 1 0 1; 0 1 0];
conv_testFrame = iconvolve(morph_testFrame, filter, 'same');

for i = 1:1:height(conv_testFrame)
    for j = 1:1:width(conv_testFrame)
        if conv_testFrame(i, j) < 3
            conv_testFrame(i, j) = 0;
        else
            conv_testFrame(i, j) = 1;
        end
    end
end
figure(4);
idisp(conv_testFrame);

%% Test
testCoords = [6 147];
cluster_coords = cluster(morph_testFrame, [], testCoords);

% cluster_coords = cluster_iterate(morph_testFrame);

cluster_testFrame = morph_testFrame;
for i=1:1:height(cluster_coords)
    cluster_testFrame(cluster_coords(i,1), cluster_coords(i,2)) = 0.5;
end
figure(5);
idisp(cluster_testFrame);

%% Best Fit Line
line = polyfit(cluster_coords(:,1), cluster_coords(:,2), 1);
X = cluster_coords(:,1);
Y = line(1)*X + line(2);
hold on
plot(Y,X);
hold off

theta = atan((line(2)/line(1))/line(2));
% theta = pi - theta;
theta = (pi/2) - theta;
theta = rad2deg(theta);
disp(strcat('Slip Angle = ', num2str(theta, 5)));


%% Recursive Cluster Function

function coords = cluster(image, visited, next_coord)

    coords = next_coord;
    visited = [visited; next_coord];

    for i = -1:1:1
        for j = -1:1:1
            if next_coord(1)+i >= 1 && next_coord(2)+j >= 1
                if image(next_coord(1)+i, next_coord(2)+j)==1 && hasCoordinates(visited, [next_coord(1)+i next_coord(2)+j])==0
                    coords = [coords; cluster(image, visited, [next_coord(1)+i next_coord(2)+j])];
                    return;
                end
            end
        end
    end

end

%% Cluster Function
function coords = cluster_iterate(image)

    testCoords = [1 433];
    return_value = [testCoords];

    while ~isequal(testCoords, -1)
        nextCoords = -1;
        return_value = [return_value; testCoords];
        if image(testCoords(1)+1, testCoords(2))==1
            nextCoords = [testCoords(1)+1 testCoords(2)];
        end
    
        while image(testCoords(1), testCoords(2)+1)==1
            return_value = [return_value; [testCoords(1) testCoords(2)+1]];
            if image(testCoords(1)+1, testCoords(2)+1)==1
                nextCoords = [testCoords(1)+1 testCoords(2)+1];
            end
            testCoords = [testCoords(1) testCoords(2)+1];
        end
    
        while ~isequal(nextCoords, -1) && image(nextCoords(1), nextCoords(2)-1)~=0
            nextCoords = [nextCoords(1) nextCoords(2)-1];
        end
        testCoords = nextCoords;
    end

    coords = return_value;
end

%% Check if coordinate pair is in matrix
function contains = hasCoordinates(input, coords)
    contains = 0;
    for i=1:1:height(input)
        if input(i,:)==coords
            contains = 1;
            return
        end
    end
end


