% Calvin Molitor
% Sam Benscoter
% EE 5271

% what video we are analyzing
vidname = 'samples/11-26-22-sam-drive2.MOV';

% import a video file as an array of frames
video = VideoReader(vidname);
numframes = video.NumFrames;

% video too big
numframes = 3000;

% create all of the output arrays
timestamps = 0:(1/video.FrameRate):((numframes-1)/video.FrameRate);
angles = zeros(1, numframes);

% find the slip angle of each frame. Save the data to an array
for c = 1:numframes
    this_frame = imrotate(readFrame(video), 90);
    fprintf('frame: %d / %d\n', c, numframes);
    angles(c) = calculate_slip_angle(this_frame, 0);
end

% Export the array with each slip angle along with a timestamp to a CSV
csv_file_name = strcat(video.Name, '.csv');
csv_file = fopen(csv_file_name, 'w+');

% make sure the file actually opened
if csv_file == -1
    error('Failed to open file!')
end

% print the header for the CSV
fprintf(csv_file, 'Timestamp (s), Slip Angle (deg)\n');
for c = 1:numframes
    fprintf(csv_file, '%f, %f\n', timestamps(c), angles(c));
end

% also export as a GDAT so it can be imported to i2
gdat_file_name = strcat(video.Name, '.gdat');
gdat_file = fopen(gdat_file_name, 'w+');

% make sure the file actually opened
if gdat_file == -1
    error('Failed to open file!')
end

% write the gdat header
fprintf(gdat_file, '/dlm_data_11112233_445566.gdat:\r\n');
for c = 1:numframes
    print_gdat_data_point(gdat_file, timestamps(c), angles(c));
end

% make sure all files are closed
fclose('all');

% helper functions
function print_gdat_data_point(file, ts, data)
    % first byte point is 0x7E
    fwrite(file, 0x7e);
    
    % for all of the bytes in the actual message, check to make sure they
    % are not 0x7e or 0x7e. If they are, use the escape byte (0x7d) to
    % properly encode the data

    % convert the timestamp to ms (uint32). Theoredically the 'swapbytes'
    % function accounts for endieness but this has only been tested on an
    % intel system
    ts_ms = uint32(ts * 1000);
    ts_bytes = swapbytes(typecast(ts_ms, 'uint8'));
    
    % append the bytes, MSB first
    gdat_byte_write(file, ts_bytes(4));
    gdat_byte_write(file, ts_bytes(3));
    gdat_byte_write(file, ts_bytes(2));
    gdat_byte_write(file, ts_bytes(1));
    
    % add the sensor ID (2bytes). this will always be 0x00 0x01 for this demo
    gdat_byte_write(file, 0);
    gdat_byte_write(file, 1);
    
    % convert the data to a 32bit float and append it, MSB first
    data_bytes = swapbytes(typecast(single(data), 'uint8'));
    gdat_byte_write(file, data_bytes(4));
    gdat_byte_write(file, data_bytes(3));
    gdat_byte_write(file, data_bytes(2));
    gdat_byte_write(file, data_bytes(1));
end

function gdat_byte_write(file, byte)
    % check for 0x7e or 0x7d in the data. If there is, use the escape
    % byte and XOR the next byte with 0x20
    if byte == 0x7e || byte == 0x7d
        fwrite(file, 0x7d);
        fwrite(file, bitxor(byte, 0x20));
    else
        % just write the byte normally
        fwrite(file, byte);
    end
end
