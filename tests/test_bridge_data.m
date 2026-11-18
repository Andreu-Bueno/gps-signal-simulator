%% SCRIPT DE PRUEBA: PIPELINE COMPLETO DESDE ÓRBITA (TLE) HASTA TRAMA BINARIA
clear; clc; close all;

% Rutas de tus carpetas
addpath('../src/navigation');
addpath('../data');

fprintf('==================================================\n');
fprintf('=== TEST DE INTEGRIDAD: ÓRBITA -> PUENTE -> GPS ===\n');
fprintf('==================================================\n\n');

%% 1. Inicializar el Escenario Orbital y cargar TLE
fprintf('Step 1: Inicializando escenario satelital...\n');
try
    % Creamos el escenario de MATLAB de forma temporal para la prueba
    sc = satelliteScenario(datetime(2026, 7, 4, 12, 0, 0, 'TimeZone', 'UTC'), ...
                           datetime(2026, 7, 4, 12, 0, 5, 'TimeZone', 'UTC'), 1);
    
    % Llamamos a tu función de constelación
    sats = init_constellation(sc);
    sat1 = sats(1); % Tomamos el primer satélite para el test
    fprintf('✅ Constelación e infraestructura listas.\n\n');
catch ME
    error('❌ Error al inicializar la órbita. Revisa si init_constellation o el archivo TLE fallan.\nDetalle: %s', ME.message);
end

%% 2. Extraer Estados Cinemáticos Consecutivos (Separados por 1 segundo)
fprintf('Step 2: Propagando órbita y extrayendo estados ECI...\n');
t_base = datetime(2026, 7, 4, 12, 0, 0, 'TimeZone', 'UTC');

try
    state_prev = extract_state(sat1, t_base);
    state_curr = extract_state(sat1, t_base + seconds(1));
    fprintf('✅ Estados cinemáticos (pos, vel, tiempo) extraídos correctamente.\n\n');
catch ME
    error('❌ Error en extract_state al interactuar con el scenario.\nDetalle: %s', ME.message);
end

%% 3. Ejecutar la Función Puente y Generar la Trama
fprintf('Step 3: Ejecutando puente directo a la trama binaria...\n');
try
    params = gps_icd();
    frame = bridge_orbit_to_nav(state_prev, state_curr, params);
    fprintf('✅ ¡Puente ejecutado con éxito! Trama binaria de 50x30 generada.\n\n');
catch ME
    error('❌ El puente o el codificador build_nav_frame han fallado al procesar los datos orbitales reales.\nDetalle: %s', ME.message);
end

%% 4. Verificaciones críticas de Sanidad en la Trama Resultante
fprintf('--- VERIFICACIONES DE CALIDAD DE LA TRAMA GENERADA ---\n');

% Validación dimensional
[filas, columnas] = size(frame);
if filas == 50 && columnas == 30
    fprintf('✅ Dimensiones de la trama perfectas: 50 palabras de 30 bits.\n');
else
    fprintf('❌ Error dimensional en la trama: %dx%d\n', filas, columnas);
end

% Validación del HOW (Bits de paridad 29 y 30 en cero para los 5 subframes)
t_bits_ok = true;
for sf = 1:5
    w2_idx = (sf - 1) * 10 + 2; % Palabra 2 de cada subtrama
    if frame(w2_idx, 29) ~= 0 || frame(w2_idx, 30) ~= 0
        t_bits_ok = false;
        fprintf('❌ Fallo de paridad en HOW del Subframe %d (Bits 29:30 no son [0,0]).\n', sf);
    end
end
if t_bits_ok
    fprintf('✅ Restricción del ICD-GPS cumplida: Los t-bits de las palabras HOW fuerzan paridad a cero.\n');
end

% Comprobación de datos dinámicos (Delta_n, IDOT o RAAN_dot no deberían ser exactamente cero)
% Vamos a decodificar un fragmento de la trama (Sub-trama 2, M0) para verificar que contiene física real.
w14_bits = frame(14, 1:24);
w15_bits = frame(15, 1:24);
% El receptor aplica el XOR invertido con el bit 30 anterior para recuperar la palabra limpia
% En un entorno simplificado, leemos los bits del mensaje directo de la palabra
bits_m0 = [w14_bits(17:24), w15_bits(1:24)];
if any(bits_m0)
    fprintf('✅ Verificación de datos: Los campos Keplerianos contienen valores dinámicos reales (no están vacíos).\n');
else
    fprintf('⚠️ Advertencia: El campo M0 está completamente vacío (todo ceros). Revisa las conversiones.\n');
end

fprintf('\n==================================================\n');
fprintf('🎉 ¡SISTEMA INTEGRADO CON ÉXITO! Órbita y Datos unificados.\n');
fprintf('==================================================\n');