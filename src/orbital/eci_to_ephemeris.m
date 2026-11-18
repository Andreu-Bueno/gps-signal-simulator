function eph = eci_to_ephemeris(state_curr)
%ECEF__TO Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    state_curr struct
end

arguments (Output)
    eph struct
end

% WGS84 CONSTANTS
mu = 3.986005e14;          % m^3/s^2
omega_e = 7.2921151467e-5; % rad/s (Earth's rotation)

r_vec = state_curr.pos_eci;
v_vec = state_curr.vel_eci;
r = norm(r_vec);
v = norm(v_vec);

% Specific orbital energy
epsilon = ((v^2)/2) - (mu/r);

% Semi-major axis (a)
a = -mu / (2 * epsilon);

% Angular momentum (h)
h_vec = cross(r_vec, v_vec);
h = norm(h_vec);

% Eccentricity vector (e)
e_vec = (cross(v_vec, h_vec) / mu) - (r_vec / r);
e = norm(e_vec);


% Orbital inclination (i0)
i0 = acos(h_vec(3) / h);

% Approximated ascendant node (RAAN)
n_vec = cross([0 0 1], h_vec);
n = norm(n_vec);
RAAN0 = atan2(n_vec(2), n_vec(1));
if RAAN0 < 0, RAAN0 = RAAN0 + 2*pi; end


% Argument of peregee (argp)
argp = atan2(dot(cross(n_vec, e_vec), h_vec/h), dot(n_vec, e_vec));
if argp < 0
    argp = argp + 2 * pi; % Ensure argp is positive
end


% True anomaly and mean anomaly (M0)
if dot(r_vec, v_vec) >= 0
    x = dot(e_vec,r_vec)/(e*r);
    x = max(min(x,1),-1);
    nu = acos(x);
else
    nu = 2*pi - acos(dot(e_vec, r_vec) / (e * r));
end

E_anom = 2 * atan( sqrt((1 - e) / (1 + e)) * tan(nu / 2));
M0 = E_anom - e * sin(E_anom);

% Mean motion

n0 = sqrt(mu/a^3);

% GPS corrections

Delta_n = 0;

% Convert radians -> semicircles

Omega0_sc = RAAN0/pi;
omega_sc = argp/pi;
i0_sc = i0/pi;
M0_sc = M0/pi;

% Output
eph = struct();
eph.sqrtA = sqrt(a);
eph.e = e;
eph.i0 = i0_sc;
eph.Omega0 = Omega0_sc;
eph.omega = omega_sc;
eph.M0 = M0_sc;
eph.toe = state_curr.sow;


eph.Delta_n = Delta_n; eph.IDOT = 0; eph.Omega_dot = -omega_e/pi; 
eph.Cuc = 0; eph.Cus = 0; eph.Crc = 0; eph.Crs = 0; eph.Cic = 0; eph.Cis = 0;

end