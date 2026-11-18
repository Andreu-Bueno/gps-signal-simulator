function state = extract_state(sat, time_epoch)
%EXTRACT_STATE Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    sat
    time_epoch datetime
end

arguments (Output)
    state struct
end

[pos_eci, speed_eci] = states(sat, time_epoch, 'CoordinateFrame', 'inertial');
pos_eci = pos_eci(:)';
speed_eci= speed_eci(:)';


gps_epoch = datetime(1980, 1, 6, 0, 0, 0, 'TimeZone', 'UTC');

dt = seconds(time_epoch - gps_epoch);
gps_week = floor(dt/604800);
sow      = mod(dt,604800);


af0 = 1e-4;
af1 = 1e-12;
af2 = 0;
toc = sow; % Reference time of the clock

dt_clock = sow - toc;
clock_bias = af0 + (af1 * dt_clock) + (af2 * (dt_clock^2));

state = struct(...
    'pos_eci',    pos_eci, ...
    'vel_eci',    speed_eci, ...
    'gps_week',   uint16(gps_week), ...
    'sow',        sow, ...
    'clock_bias', clock_bias, ...
    'health',     uint8(0), ... 
    'af0',        af0, ...
    'af1',        af1, ...
    'af2',        af2,...
    'toc',        sow, ...
    'TGD',        5e-9, ...
    'IODC',       mod(floor(sow/3600), 1024));

end