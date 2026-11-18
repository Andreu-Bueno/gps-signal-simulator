% 1. Limpieza y rutas
clear; clc; close all;
addpath(genpath('../src'));
addpath(genpath('../data'));

% 2. DEFINIR EL TIEMPO CORRECTO (Asegúrate de que coincida con tu TLE)
% Usamos 2026 ya que es el año actual, pero pon el año/mes/día que requiera tu órbita.
start_time = datetime(2026, 7, 1, 0, 0, 0, 'TimeZone', 'UTC'); 
stop_time  = start_time + hours(24); % Le damos una ventana de 24 horas

% 3. Inicializar el escenario PASÁNDOLE los tiempos límites
sc = satelliteScenario(start_time - minutes(1), stop_time, 60);

% 4. Cargar la constelación (pasándole el escenario ya configurado)
sats = init_constellation(sc);

% Elegimos el satélite (PRN 01)
sat_to_simulate = sats(1); 

% 5. Abrir tu modelo de Simulink
open_system('gps_transmitter.slx');

fprintf("Simulation ready to run. ✅")