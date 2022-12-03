
%% Load Image
%video = VideoReader('samples/GolfCartRun.mp4');
%testFrame = read(video, 700);
%frameTheta = calculate_slip_angle(testFrame, 1);
%disp(strcat('Slip Angle = ', num2str(frameTheta, 5)));

function retval = calculate_slip_angle(testFrame, show_frames)
    %% Gray Scale
    % Remove color data
    testFrame = rgb2gray(testFrame);
    
    if show_frames == 1
        figure(1);
        idisp(testFrame);
    end

    %% Niblack Relative Comparisons
    % Transform gray scale data to binary data
    % Creates pixel clusters of value 1 pixels that are
    % shaped in the general direction of travel
    niblack_testFrame = niblack(testFrame, -0.1, 20);
    niblack_testFrame = testFrame >= abs(niblack_testFrame);
    niblack_testFrame = niblack_testFrame(20:460, 20:620);
    
    if show_frames == 1
        figure(2);
        idisp(niblack_testFrame);
    end

    %% Erosion
    % Reduce noise and data considered
    morph_testFrame = ierode(niblack_testFrame, ones(3, 3), 2);
    
    if show_frames == 1
        figure(3);
        idisp(morph_testFrame);
    end

    %% Check if Plus Filter Has 2 Neighbors, else Remove Pixel
    % Removes pixels that aren't worth considering
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
    
    if show_frames == 1
        figure(4);
        idisp(conv_testFrame);
    end

    %% Pixel Clustering, Best Fit Line, and Slip Angle Calculation
    cluster_coords = [];
    slip_angles = [];
    cluster_testFrame = conv_testFrame;

    if show_frames == 1
        figure(5);
        hold on
    end

    %Start at the top left of the image and iterate over each pixel
    % until the bottom right is reached
    for i = 2:1:height(cluster_testFrame)-1
        for j = 2:1:width(cluster_testFrame)-1
            coords = [i j];

            %If a pixel is 1, then it's an unvisited cluster
            if cluster_testFrame(i, j)==1

                %Iterate over the cluster and return all the image
                % coordinates in that cluster
                cluster_coords = cluster_iterate(cluster_testFrame, coords);

                %Set all pixel values in the returned cluster to 0.5
                for k=1:1:height(cluster_coords)
                    cluster_testFrame(cluster_coords(k,1), cluster_coords(k,2)) = 0.5;
                end

                %For clusters with more than 200 pixels
                if height(cluster_coords)>200
                    %Find the linear equation of the best fit line over the
                    % cluster
                    line = polyfit(cluster_coords(:,1), cluster_coords(:,2), 1);

                    X = cluster_coords(:,1);
                    Y = line(1)*X + line(2);
                    
                    if show_frames == 1
                        plot(Y,X);
                    end

                    %Find the angle from the vertical axis with arctan
                    % using the y-intercept and x-intercept distances
                    if line(1)>0
                        theta = atan((line(2)/line(1))/line(2));
                        theta = (pi/2) - theta;
                        theta = rad2deg(theta);
                        slip_angles = [slip_angles theta];
    %                     disp(strcat('Slip Angle = ', num2str(theta, 5)));
                    elseif line(1)<0
                        theta = atan(abs(line(2)/line(1))/line(2));
                        theta = pi - theta;
                        theta = (pi/2) - theta;
                        theta = rad2deg(theta);
                        slip_angles = [slip_angles theta];
    %                     disp(strcat('Slip Angle = ', num2str(theta, 5)));
                    end
                end
            end
        end
    end
    
    if show_frames == 1
        %Calculate the slip angle for this video frame by averaging all angles
        disp(strcat('Slip Angle = ', num2str(mean(slip_angles), 5)));
        hold off
        figure(6);
        idisp(cluster_testFrame);
        copyobj(findobj(5,'type','line'), findobj(6,'type','axes'));
    end
    
    retval = mean(slip_angles);
end

%% Cluster Function
% This function starts at an input coordinate pair that has a value of 1
% From this coordinate, the function iterates down to the bottom of the
% pixel cluster. While iterating downwards, the function counts the 
% number of pixels visited that are equal to 1 and returns
% the array of counted pixels. The result can be displayed and
% used to calculate the best fit line across the visited pixels.
function coords = cluster_iterate(image, startCoords)

    testCoords = startCoords;
    return_value = [];

    while ~isequal(testCoords, -1)
        nextCoords = -1;
        if 1<testCoords(1) && testCoords(1)<height(image) && 1<testCoords(2) && testCoords(2)<width(image)
            return_value = [return_value; testCoords];
            if image(testCoords(1)+1, testCoords(2))==1
                nextCoords = [testCoords(1)+1 testCoords(2)];
            end
        
            while testCoords(2)+1<width(image) && image(testCoords(1), testCoords(2)+1)==1
                return_value = [return_value; [testCoords(1) testCoords(2)+1]];
                if image(testCoords(1)+1, testCoords(2)+1)==1
                    nextCoords = [testCoords(1)+1 testCoords(2)+1];
                end
                testCoords = [testCoords(1) testCoords(2)+1];
            end
        
            while ~isequal(nextCoords, -1) && 1<nextCoords(2)-1 && image(nextCoords(1), nextCoords(2)-1)~=0
                nextCoords = [nextCoords(1) nextCoords(2)-1];
            end
        end
        testCoords = nextCoords;
    end

    coords = return_value;
end

%% Recursive Cluster Function

function coords = cluster(image, visited, next_coord)

    coords = next_coord;
    visited = [visited; next_coord];

    for i = -1:1:1
        if next_coord(1)+i >= 1 && next_coord(2)-1 >= 1
            if image(next_coord(1)+i, next_coord(2)-1)==1 && hasCoordinates(visited, [next_coord(1)+i next_coord(2)-1])==0
                coords = [coords; cluster(image, visited, [next_coord(1)+i next_coord(2)-1])];
                return;
            end
        end
    end

    for i = 0:1:1
        if next_coord(1)+1 >= 1 && next_coord(2)+i >= 1
            if image(next_coord(1)+1, next_coord(2)+i)==1 && hasCoordinates(visited, [next_coord(1)+1 next_coord(2)+i])==0
                coords = [coords; cluster(image, visited, [next_coord(1)+1 next_coord(2)+i])];
                return;
            end
        end
    end

    for i = 0:-1:-1
        if next_coord(1)+i >= 1 && next_coord(2)+1 >= 1
            if image(next_coord(1)+i, next_coord(2)+1)==1 && hasCoordinates(visited, [next_coord(1)+i next_coord(2)+1])==0
                coords = [coords; cluster(image, visited, [next_coord(1)+i next_coord(2)+1])];
                return;
            end
        end
    end

    if next_coord(1)-1 >= 1 && next_coord(2) >= 1
        if image(next_coord(1)-1, next_coord(2))==1 && hasCoordinates(visited, [next_coord(1)-1 next_coord(2)])==0
            coords = [coords; cluster(image, visited, [next_coord(1)-1 next_coord(2)])];
            return;
        end
    end

%     for i = -1:1:1
%         for j = -1:1:1
%             if next_coord(1)+i >= 1 && next_coord(2)+j >= 1
%                 if image(next_coord(1)+i, next_coord(2)+j)==1 && hasCoordinates(visited, [next_coord(1)+i next_coord(2)+j])==0
%                     coords = [coords; cluster(image, visited, [next_coord(1)+i next_coord(2)+j])];
%                     return;
%                 end
%             end
%         end
%     end

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


