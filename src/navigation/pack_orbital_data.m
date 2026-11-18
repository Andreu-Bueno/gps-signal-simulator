function data_vec = pack_orbital_data(sim_time_seconds)
    % 1. Extraer los objetos del Workspace de MATLAB
    sat_obj = evalin('base', 'sat_to_simulate');
    start_time = evalin('base', 'start_time');

    % 2. Calcular los datetimes
    t_curr = start_time + seconds(sim_time_seconds);
    t_prev = t_curr - seconds(1);

    % 3. Llamar a tus funciones físicas originales
    state_prev = extract_state(sat_obj, t_prev);
    state_curr = extract_state(sat_obj, t_curr);
    eph = state_to_broadcast_eph(state_prev, state_curr);

    % 4. EMPAQUETAR Y ADAPTAR UNIDADES ESTRICTAMENTE PARA TU ICD
    data_vec = zeros(25, 1);

    % --- Parámetros de Tiempo, Salud y Reloj ---
    data_vec(1)  = mod(double(state_curr.gps_week), 1024); % FIX: week rolls over every 1024 weeks
    data_vec(2)  = double(state_curr.health);
    data_vec(3)  = state_curr.TGD;
    data_vec(4)  = double(state_curr.IODC);
    data_vec(5)  = double(mod(state_curr.IODC, 256)); % IODE = IODC's 8 LSBs
    data_vec(6)  = state_curr.toc;
    data_vec(7)  = state_curr.af2;
    data_vec(8)  = state_curr.af1;
    data_vec(9)  = state_curr.af0;

    % --- Correcciones orbitales perturbativas (Armónicos, ya en unidades ICD) ---
    data_vec(10) = eph.Crs;
    data_vec(13) = eph.Cuc;
    data_vec(15) = eph.Cus;
    data_vec(18) = eph.Cic;
    data_vec(20) = eph.Cis;
    data_vec(22) = eph.Crc;

    % --- Elementos de Kepler principales: envolver a semicírculos ---
    % state_to_broadcast_eph fuerza estos ángulos a [0, 2*pi) ("+2*pi si
    % negativo"), así que un /pi simple da valores hasta ~2, fuera del
    % rango válido [-1, 1). wrap_to_semi corrige esto.
    data_vec(12) = wrap_to_semi(eph.M0);      % M0
    data_vec(14) = eph.e;                     % Excentricidad (adimensional)
    data_vec(16) = eph.sqrt_a;                % Raíz de a (metros^0.5)
    data_vec(17) = eph.toe;                   % Time of Ephemeris
    data_vec(19) = wrap_to_semi(eph.RAAN0);   % Omega0
    data_vec(21) = wrap_to_semi(eph.i0);      % i0
    data_vec(23) = wrap_to_semi(eph.argp);    % omega

    % --- Tasas: convertir a semicírculos/seg, SIN restar omega_e ---
    % IS-GPS-200N Table 20-IV ya resta Omega_dot_e dentro de la ecuación
    % del RECEPTOR:  Omega_k = Omega0 + (Omega_dot - Omega_dot_e)*tk - Omega_dot_e*toe
    % Por tanto Omega_dot difundido debe ser la tasa de precesión inercial
    % pura, NO (RAAN_dot - omega_e). Restar omega_e aquí difunde un valor
    % cercano a -omega_e (~-7.29e-5 rad/s), ~100x fuera del rango válido
    % ICD de +/-6.33e-7 semicírculos/s.
    %
    % clamp_rate se mantiene como red de seguridad: la diferenciación
    % numérica de 1 segundo sobre una órbita propagada con SGP4 captura
    % perturbaciones (J2, drag) mucho mayores que el pequeño término
    % periódico que estos campos ICD están pensados para representar.
    data_vec(11) = clamp_rate(eph.delta_n  / pi, 16, -43); % Delta_n
    data_vec(24) = clamp_rate(eph.RAAN_dot / pi, 24, -43); % Omega_dot (FIX: sin restar omega_e)
    data_vec(25) = clamp_rate(eph.IDOT     / pi, 14, -43); % IDOT
end

function semi = wrap_to_semi(rad_val)
% Envuelve un ángulo en radianes a semicírculos [-1, 1).
    wrapped = atan2(sin(rad_val), cos(rad_val)) / pi;
    if wrapped >= 1.0
        wrapped = -1.0;  % +1.0 y -1.0 son el mismo ángulo; solo -1.0 es representable
    end
    semi = wrapped;
end

function val_clamped = clamp_rate(val, n_bits, scale_exp)
% Limita el valor al máximo y mínimo representable por el ICD.
    max_val =  (2^(n_bits-1) - 1) * 2^scale_exp;
    min_val = -(2^(n_bits-1))     * 2^scale_exp;
    val_clamped = max(min_val, min(max_val, val));
end