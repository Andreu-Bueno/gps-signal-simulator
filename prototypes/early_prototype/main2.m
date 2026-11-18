clc; clear; close all;
addpath('src');

%% ================================
% 1. CONFIGURACIÓN TEMPORAL (PRO)
% ================================
startTime = datetime('now','TimeZone','UTC');
stopTime  = startTime + hours(12);
dt = 10; % segundos

% Vector de tiempo (ESTÁNDAR INDUSTRIA)
time_vec = startTime:seconds(dt):stopTime;
num_steps = length(time_vec);

%% ================================
% 2. ESCENARIO (SIN AUTO SIM)
% ================================
sc = satelliteScenario(startTime, stopTime, dt, ...
    'AutoSimulate', false);

%% ================================
% 3. SATÉLITE
% ================================
sat_gps = init_gps_constellation(sc);

%% ================================
% 4. RECEPTOR
% ================================
receptor = groundStation(sc, 40.4168, -3.7038, ...
    'Altitude',600);

%% ================================
% 5. STORAGE (preallocación)
% ================================
all_states     = cell(num_steps,1);
all_bitstreams = cell(num_steps,1);

%% ================================
% 6. LOOP PRINCIPAL GNSS
% ================================

for k = 1:num_steps
    
    t = time_vec(k);  % ← CONTROL TOTAL DEL TIEMPO
    
    %% 6.1 Estado del satélite
    state = extract_satellite_state(sat_gps, t);
    all_states{k} = state;
    
    %% 6.2 Selección subframe (GPS real: 5 subframes)
    subframe_id = mod(floor((k-1)/30),5) + 1;
    
    %% 6.3 Codificación a bits
    bits = data_to_bits(state, subframe_id);
    all_bitstreams{k} = bits;
    
    %% 6.4 LOG (monitorización)
    if mod(k,100) == 0
        fprintf(['[%d/%d] t = %s | Pos = [%.1f %.1f %.1f] km | ' ...
                 'Subframe = %d\n'], ...
                 k, num_steps, ...
                 datestr(t,'HH:MM:SS'), ...
                 state.pos_ecef/1000, ...
                 subframe_id);
    end
end

%% ================================
% 7. VISUALIZACIÓN
% ================================

disp('Lanzando visor 3D...');
disp('Iniciando simulación GNSS...');
sc.AutoSimulate = true;

v = satelliteScenarioViewer(sc, 'ShowDetails', true);

% Reproducir la simulación (puedes ajustar la velocidad en la UI)
play(sc);
disp('Simulación completada.');