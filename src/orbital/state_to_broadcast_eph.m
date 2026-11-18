function eph = state_to_broadcast_eph(state_prev, state_curr)
%ECI_TO_KEPLER Converts two ECI satellite states to GPS Broadcast Ephemeris.
%   Uses state_curr for Keplerian elements and state_prev to numerically
%   estimate dynamic rates (RAAN_dot, IDOT, delta_n).
% -----------------------------------------------------------------------
% Inputs:
%   state_prev  struct  satellite state 1 second before state_curr
%   state_curr  struct  satellite state at time of ephemeris
% Output:
%   eph         struct  broadcast ephemeris ready for IS-GPS-200 subframes
% -----------------------------------------------------------------------
arguments (Input)
    state_prev struct
    state_curr struct
end
arguments (Output)
    eph struct
end

% WGS84 CONSTANTS
mu      = 3.986004418e14;   % [m^3/s^2] gravitational parameter
% omega_e = 7.2921151467e-5;  % [rad/s] Earth rotation (not used directly)

% ── CURRENT STATE ────────────────────────────────────────────────────────
r_vec = state_curr.pos_eci;
v_vec = state_curr.vel_eci;
r = norm(r_vec);
v = norm(v_vec);

% Specific orbital energy → semi-major axis
a = -mu / (2 * (v^2/2 - mu/r));

% Angular momentum
h_vec = cross(r_vec, v_vec);
h = norm(h_vec);

% Eccentricity vector
e_vec = cross(v_vec, h_vec)/mu - r_vec/r;
e = norm(e_vec);

% Inclination
i0 = acos(h_vec(3) / h);

% Node line (ascending node)
n_vec = cross([0 0 1], h_vec);
n_node = norm(n_vec);

% RAAN — protect against equatorial orbit (n_node ≈ 0)
if n_node < 1e-10
    RAAN0 = 0;
else
    RAAN0 = atan2(n_vec(2), n_vec(1));
    if RAAN0 < 0, RAAN0 = RAAN0 + 2*pi; end
end

% Argument of perigee — protect against circular orbit (e ≈ 0)
if e < 1e-10
    argp = 0;
else
    argp = atan2(dot(cross(n_vec, e_vec), h_vec/h), dot(n_vec, e_vec));
    if argp < 0, argp = argp + 2*pi; end
end

% True anomaly → eccentric anomaly → mean anomaly
nu = atan2(dot(cross(e_vec, r_vec), h_vec/h), dot(e_vec, r_vec));
if nu < 0, nu = nu + 2*pi; end

E_anom = 2 * atan2(sqrt(1-e)*sin(nu/2), sqrt(1+e)*cos(nu/2));
if E_anom < 0, E_anom = E_anom + 2*pi; end

M0 = E_anom - e*sin(E_anom);
if M0 < 0, M0 = M0 + 2*pi; end

% ── PREVIOUS STATE (for dynamic rates) ───────────────────────────────────
r_prev = state_prev.pos_eci;
v_prev = state_prev.vel_eci;

h_prev_vec = cross(r_prev, v_prev);
h_prev = norm(h_prev_vec);

% RAAN at previous epoch
n_prev_vec = cross([0 0 1], h_prev_vec);
n_prev_node = norm(n_prev_vec);
if n_prev_node < 1e-10
    RAAN_prev = 0;
else
    RAAN_prev = atan2(n_prev_vec(2), n_prev_vec(1));
    if RAAN_prev < 0, RAAN_prev = RAAN_prev + 2*pi; end
end

% Inclination at previous epoch
i_prev = acos(h_prev_vec(3) / h_prev);

% Mean anomaly at previous epoch
e_prev_vec = cross(v_prev, h_prev_vec)/mu - r_prev/norm(r_prev);
e_prev = norm(e_prev_vec);
nu_prev = atan2(dot(cross(e_prev_vec, r_prev), h_prev_vec/h_prev), ...
                dot(e_prev_vec, r_prev));
if nu_prev < 0, nu_prev = nu_prev + 2*pi; end
E_prev = 2*atan2(sqrt(1-e_prev)*sin(nu_prev/2), sqrt(1+e_prev)*cos(nu_prev/2));
if E_prev < 0, E_prev = E_prev + 2*pi; end
M_prev = E_prev - e_prev*sin(E_prev);
if M_prev < 0, M_prev = M_prev + 2*pi; end

% ── RATES BY FINITE DIFFERENCE ───────────────────────────────────────────
dt = state_curr.sow - state_prev.sow;
if abs(dt) < 1e-6, dt = 1; end  % fallback: assume 1 second separation

% RAAN_dot — correct for 2*pi wraparound
RAAN_dot = (RAAN0 - RAAN_prev) / dt;
if RAAN_dot < -pi/abs(dt), RAAN_dot = RAAN_dot + 2*pi/abs(dt); end
if RAAN_dot >  pi/abs(dt), RAAN_dot = RAAN_dot - 2*pi/abs(dt); end

% IDOT
IDOT = (i0 - i_prev) / dt;

% delta_n: difference between observed mean motion and Keplerian mean motion
n0    = sqrt(mu / a^3);          % theoretical Keplerian mean motion [rad/s]

dM = M0 - M_prev;
if dM < -pi
    dM = dM + 2*pi;  % Adjust for wraparound if necessary
elseif dM > pi
    dM = dM - 2*pi;
end
n_obs = dM / dt;     % observed mean motion [rad/s]
delta_n = n_obs - n0;

% ── OUTPUT STRUCT ─────────────────────────────────────────────────────────
eph = struct( ...
    'sqrt_a',   sqrt(a),  ...   % [m^0.5]
    'e',        e,        ...   % [-]
    'i0',       i0,       ...   % [rad]
    'RAAN0',    RAAN0,    ...   % [rad]
    'argp',     argp,     ...   % [rad]
    'M0',       M0,       ...   % [rad]
    'toe',      state_curr.sow, ... % [s] time of ephemeris
    'delta_n',  delta_n,  ...   % [rad/s]  ← estimated, not zero
    'RAAN_dot', RAAN_dot, ...   % [rad/s]  ← estimated, not -omega_e
    'IDOT',     IDOT,     ...   % [rad/s]  ← estimated, not zero
    'Cuc', 0, 'Cus', 0,  ...   % harmonic corrections (zero for simulator)
    'Crc', 0, 'Crs', 0,  ...
    'Cic', 0, 'Cis', 0   );

end