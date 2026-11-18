% ================================================================
% SIMULADOR GPS REALISTA - FASE 1: GEOMETRÍA Y ÓRBITA
% ================================================================
clc; clear; close all;
addpath('src'); % Añadir la carpeta de funciones al path

%% 1. DEFINIR EL ESCENARIO ESPACIO-TEMPORAL
% Establecemos el tiempo de inicio y fin de la simulación
startTime = datetime('now', 'TimeZone', 'UTC');
stopTime  = startTime + hours(12); % Simularemos 12 horas (aprox media órbita GPS)
sampleTime = 10; % Segundos entre cada iteración del simulador

% Crear el escenario base
sc = satelliteScenario(startTime, stopTime, sampleTime);

%% 2. INICIALIZAR SATÉLITE (Mecánica Orbital con Perturbaciones)
disp('Inicializando mecánica orbital SGP4...');
sat_gps = init_gps_constellation(sc);

%% 3. INICIALIZAR RECEPTOR (Ground Station)
% Colocamos nuestro receptor (ej: en el centro de Madrid)
lat_rec = 40.4168;
lon_rec = -3.7038;
alt_rec = 600; % metros sobre el nivel del mar

receptor = groundStation(sc, lat_rec, lon_rec, ...
    'Altitude', alt_rec, ...
    'Name', 'Receptor Base');

%% 4. ANÁLISIS DE VISIBILIDAD Y LOS (Line of Sight)
% Calculamos cuándo el satélite es visible desde el receptor
ac = access(receptor, sat_gps);

%% 5. VISUALIZACIÓN 3D INTERACTIVA
disp('Lanzando visor 3D...');
v = satelliteScenarioViewer(sc, 'ShowDetails', true);

% Reproducir la simulación (puedes ajustar la velocidad en la UI)
play(sc);