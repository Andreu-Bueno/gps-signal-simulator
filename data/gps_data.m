function data = gps_data()
% GPS_DATA
% Contiene valores físicos reales del satélite (inputs del simulador)

data = struct();

% =========================
% 🔹 SUBFRAME 1
% =========================

data.week = mod(2200, 1024);
data.L2_P_data_flag = 0;
data.SV_accuracy = 0;
data.SV_health = 0;
data.TGD = 0;
data.IODC = 0;
data.toc = 0;

data.af2 = 0;
data.af1 = 0;
data.af0 = 0;

% =========================
% 🔹 SUBFRAME 2–3
% =========================

data.IODE = 0;
data.Crs = 0;
data.Delta_n = 0;
data.M0 = 0;
data.Cuc = 0;
data.e = 0.01;
data.Cus = 0;
data.sqrtA = 5153.795; % típico GPS
data.toe = 0;

data.Cic = 0;
data.Omega0 = 0;
data.Cis = 0;
data.i0 = 0;
data.Crc = 0;
data.omega = 0;

data.Omega_dot = 0;
data.IDOT = 0;

end