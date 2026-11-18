% =========================================================================
% TEST FASE 1: MECÁNICA ORBITAL
% =========================================================================
clc; clear; close all;
addpath('../src/orbital');

disp('=================================================================');
disp('TEST FASE 1: MECÁNICA ORBITAL');
disp('=================================================================');

% ── CONFIGURACIÓN ─────────────────────────────────────────────────────────
% sampleTime = 1s es necesario para calcular tasas (RAAN_dot, IDOT, delta_n)
startTime = datetime(2023, 10, 12, 12, 0, 0, 'TimeZone', 'UTC');
sc = satelliteScenario(startTime, startTime + hours(1), 1);

% ── TEST 1: CONSTELACIÓN ──────────────────────────────────────────────────
fprintf('\n[1/6] Cargando constelación...\n');
sats = init_constellation(sc);
assert(length(sats) >= 24, ...
    sprintf('FALLO: %d satelites cargados, minimo 24', length(sats)));
fprintf('      OK: %d satelites cargados\n', length(sats));

% ── TEST 2: VISIBILIDAD ───────────────────────────────────────────────────
fprintf('\n[2/6] Visibilidad desde Madrid (elev > 5 grados)...\n');
madrid = groundStation(sc, 40.4, -3.7, 'Altitude', 600, 'MinElevationAngle', 5);
ac = access(madrid, sats);
v_status = accessStatus(ac, startTime);
visibles = sum(v_status);
fprintf('      Satelites visibles: %d\n', visibles);
assert(visibles >= 6 && visibles <= 14, ...
    sprintf('FALLO: %d satelites visibles (rango esperado 6-14)', visibles));
fprintf('      OK: visibilidad correcta\n');

% ── TEST 3: UNIDADES ECI ─────────────────────────────────────────────────
fprintf('\n[3/6] Unidades del vector de estado ECI...\n');
time_prev = sc.StartTime;
time_curr = sc.StartTime + seconds(1); 
state_curr = extract_state(sats(1), time_curr);
state_prev = extract_state(sats(1), time_prev);

dist_km = norm(state_curr.pos_eci) / 1000;
fprintf('      Radio orbital: %.2f km (esperado ~26560 km)\n', dist_km);
assert(dist_km > 26000 && dist_km < 27000, ...
    sprintf('FALLO: radio fuera de rango (%.1f km)', dist_km));
fprintf('      OK: unidades correctas\n');

% ── TEST 4: ELEMENTOS KEPLERIANOS ─────────────────────────────────────────
fprintf('\n[4/6] Elementos Keplerianos y tasas dinamicas...\n');
eph = state_to_broadcast_eph(state_prev, state_curr);

% Verificar campos obligatorios IS-GPS-200
campos = {'sqrt_a','e','i0','RAAN0','argp','M0','toe', ...
          'delta_n','RAAN_dot','IDOT', ...
          'Cuc','Cus','Crc','Crs','Cic','Cis'};
for k = 1:length(campos)
    assert(isfield(eph, campos{k}), ...
        sprintf('FALLO: falta campo eph.%s', campos{k}));
end

% Verificar rangos fisicamente coherentes para GPS
a = eph.sqrt_a^2;
fprintf('      Semieje mayor a:   %.1f km (esperado ~26560 km)\n', a/1000);
fprintf('      Excentricidad e:   %.6f   (GPS tipico < 0.02)\n',   eph.e);
fprintf('      Inclinacion i0:    %.2f deg (GPS tipico ~55 deg)\n', rad2deg(eph.i0));
fprintf('      RAAN_dot:          %.3e rad/s\n', eph.RAAN_dot);
fprintf('      IDOT:              %.3e rad/s\n', eph.IDOT);
fprintf('      delta_n:           %.3e rad/s\n', eph.delta_n);

assert(a > 26e6 && a < 27e6, ...
    sprintf('FALLO: semieje mayor fuera de rango (%.1f km)', a/1000));
assert(eph.e >= 0 && eph.e < 0.02, ...
    sprintf('FALLO: excentricidad fuera de rango (%.6f)', eph.e));
assert(eph.i0 > 0.8 && eph.i0 < 1.1, ...   % ~55 deg en radianes
    sprintf('FALLO: inclinacion fuera de rango (%.4f rad)', eph.i0));
assert(abs(eph.RAAN_dot) < 1e-7, ...
    sprintf('FALLO: RAAN_dot fuera de rango (%.3e)', eph.RAAN_dot));
fprintf('      OK: elementos Keplerianos en rango GPS\n');

% ── TEST 5: RECONSTRUCCIÓN ECEF ───────────────────────────────────────────
fprintf('\n[5/6] Reconstruccion ECEF desde Keplerianos...\n');

% Resolver Kepler: M → E (iterativo)
M  = eph.M0;
E  = M;
for iter = 1:10
    E = M + eph.e * sin(E);
end

% E → nu → posición en plano orbital
nu_r = 2 * atan2(sqrt(1+eph.e)*sin(E/2), sqrt(1-eph.e)*cos(E/2));
r_orb = eph.sqrt_a^2 * (1 - eph.e*cos(E));
x_orb = r_orb * cos(nu_r);
y_orb = r_orb * sin(nu_r);

% Rotar al ECI: R3(-RAAN) * R1(-i) * R3(-argp)
Rz_argp = [ cos(eph.argp) -sin(eph.argp) 0; ...
             sin(eph.argp)  cos(eph.argp) 0; 0 0 1];
Rx_i    = [1 0 0; 0 cos(eph.i0) -sin(eph.i0); 0 sin(eph.i0) cos(eph.i0)];
Rz_RAAN = [ cos(eph.RAAN0) -sin(eph.RAAN0) 0; ...
             sin(eph.RAAN0)  cos(eph.RAAN0) 0; 0 0 1];

pos_recon = Rz_RAAN * Rx_i * Rz_argp * [x_orb; y_orb; 0];
error_m   = norm(pos_recon' - state_curr.pos_eci);

fprintf('      Error de reconstruccion: %.2f m\n', error_m);
assert(error_m < 1000, ...
    sprintf('FALLO: error demasiado grande (%.1f m)', error_m));
fprintf('      OK: reconstruccion valida\n');

% ── TEST 6: PDOP ──────────────────────────────────────────────────────────
fprintf('\n[6/6] Geometria DOP...\n');
vis_idx  = find(v_status);
rec_ecef = lla2ecef([40.4, -3.7, 600]);
H        = zeros(length(vis_idx), 4);

for k = 1:length(vis_idx)
    [pos_sv, ~] = states(sats(vis_idx(k)), startTime, 'CoordinateFrame', 'ecef');
    los         = pos_sv(:)' - rec_ecef;
    H(k,:)      = [-los/norm(los), 1];
end

PDOP = sqrt(trace(inv(H'*H) * diag([1 1 1 0])));
fprintf('      PDOP: %.2f (debe ser < 6)\n', PDOP);
assert(PDOP < 6, sprintf('FALLO: PDOP = %.2f', PDOP));
fprintf('      OK: geometria correcta\n');

% ── RESUMEN ───────────────────────────────────────────────────────────────
fprintf('\n=================================================================\n');
fprintf('TODOS LOS TESTS FASE 1 SUPERADOS\n');
fprintf('=================================================================\n');
fprintf('Siguiente paso: tests/test_navigation.m (Fase 2)\n\n');