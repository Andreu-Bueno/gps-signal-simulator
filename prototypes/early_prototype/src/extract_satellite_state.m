function state = extract_satellite_state(sat, time_epoch)
% EXTRACT_SATELLITE_STATE
% ============================================================
% Extrae el estado orbital de un satélite propagado con SGP4
% y lo convierte a formato útil para simulación GNSS.
%
% INPUTS:
%   sat         (satellite)  → objeto satelliteScenario
%   time_epoch  (datetime)   → instante de simulación (UTC)
%
% OUTPUT:
%   state (struct) con:
%       .pos_ecef   [1x3 double] posición (m)
%       .vel_ecef   [1x3 double] velocidad (m/s)
%       .gps_week   [uint16]     semana GPS
%       .sow        [double]     segundos de semana
%       .clock_bias [double]     bias reloj (s)
%       .health     [uint8]      estado satélite
% ============================================================
arguments (Input)
    sat     
    time_epoch  datetime
end

arguments (Output)
    state struct
end

%% 1. POSICIÓN Y VELOCIDAD (ECEF)
[pos_ecef, vel_ecef] = states(sat, time_epoch, ...
    'CoordinateFrame','ecef');

pos_ecef = pos_ecef(:)' * 1000;
vel_ecef = vel_ecef(:)' * 1000;

%% 2. TIEMPO GPS
gps_epoch = datetime(1980,1,6,0,0,0,'TimeZone','UTC');

dt = seconds(time_epoch - gps_epoch);

gps_week = floor(dt / 604800);
sow      = mod(dt, 604800);

%% 3. CLOCK BIAS
clock_bias = randn * 1e-9;

%% 4. SALUD
health_flag = uint8(0);

%% 5. STRUCT
state = struct( ...
    'pos_ecef',   pos_ecef, ...
    'vel_ecef',   vel_ecef, ...
    'gps_week',   uint16(gps_week), ...
    'sow',        sow, ...
    'clock_bias', clock_bias, ...
    'health',     health_flag );

end