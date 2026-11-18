function frame = bridge_orbit_to_nav(state_prev, state_curr, params)
% BRIDGE_ORBIT_TO_NAV Une el simulador orbital con el generador de tramas.
arguments (Input)
    state_prev struct  
    state_curr struct  
    params     struct  
end
arguments (Output)
    frame      logical 
end

    omega_e = 7.2921151467e-5; % [rad/s]

    %% 1. Calcular las efemérides dinámicas
    eph_raw = state_to_broadcast_eph(state_prev, state_curr);
    
    %% 2. Construir el struct 'data'
    data = struct();
    
    data.week      = mod(double(state_curr.gps_week), 1024);
    data.SV_health = state_curr.health;
    data.TGD       = state_curr.TGD;
    data.IODC      = state_curr.IODC;
    data.IODE      = mod(state_curr.IODC, 256); 
    data.toc       = state_curr.toc;
    data.af0       = state_curr.af0;
    data.af1       = state_curr.af1;
    data.af2       = state_curr.af2;
    
    data.toe       = eph_raw.toe;
    data.sqrtA     = eph_raw.sqrt_a; 
    data.e         = eph_raw.e;      
    
    data.M0        = wrap_to_semi(eph_raw.M0);
    data.Omega0    = wrap_to_semi(eph_raw.RAAN0);
    data.omega     = wrap_to_semi(eph_raw.argp);
    data.i0        = wrap_to_semi(eph_raw.i0);
    
    % 🛠️ FIXED: Clampear las tasas instantáneas a los límites del ICD
    data.Delta_n   = clamp_rate(eph_raw.delta_n / pi, 16, -43); 
    data.IDOT      = clamp_rate(eph_raw.IDOT / pi, 14, -43);    
    
    omega_dot_ecef = eph_raw.RAAN_dot - omega_e;
    data.Omega_dot = clamp_rate(omega_dot_ecef / pi, 24, -43); 
    
    data.Cuc       = eph_raw.Cuc;
    data.Cus       = eph_raw.Cus;
    data.Crc       = eph_raw.Crc;
    data.Crs       = eph_raw.Crs;
    data.Cic       = eph_raw.Cic;
    data.Cis       = eph_raw.Cis;

    %% 3. Generar la Trama Binaria
    tow_start = state_curr.sow;
    frame = build_nav_frame(data, params, tow_start);
end

%% FUNCIONES AUXILIARES
function semi = wrap_to_semi(rad_val)
    % Mapea de radianes a semicírculos [-1, 1]
    wrapped_rad = atan2(sin(rad_val), cos(rad_val)); 
    semi = wrapped_rad / pi;
    
    % 🛡️ FIX COMPLEMENTO A 2: El límite máximo positivo no puede ser +1.0 exacto
    % Como +1.0 y -1.0 representan el mismo ángulo físico (180 grados),
    % lo forzamos al límite negativo representable.
    if semi >= 1.0
        semi = -1.0;
    end
end

function val_clamped = clamp_rate(val, n_bits, scale_exp)
    % Limita el valor al máximo y mínimo representable por el ICD
    max_val = (2^(n_bits-1) - 1) * (2^scale_exp);
    min_val = -(2^(n_bits-1)) * (2^scale_exp);
    val_clamped = max(min_val, min(max_val, val));
end