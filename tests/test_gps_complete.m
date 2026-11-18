%% TEST COMPLETO DE INTEGRIDAD GPS
clear; clc;

addpath('../src/navigation');
addpath('../data');

fprintf('\n========== TEST COMPLETO GPS ==========\n\n');

data = gps_data();
params = gps_icd();

%% Valores de prueba
data.week      = mod(2280,1024);
data.SV_health = 15;
data.TGD       = -4.6566e-9;
data.IODC      = 123;
data.IODE      = 123;
data.toc       = 432000;
data.af2       = -2^-55;
data.af1       = 1.1368e-12;
data.af0       = -1.2345e-4;
data.Crs       = 120;
data.Delta_n   = 3e-9;
data.M0        = 0.5;
data.Cuc       = 1e-6;
data.e         = 0.0054321;
data.Cus       = -2e-6;
data.sqrtA     = 5153.6543;
data.toe       = 432000;
data.Cic       = 1e-6;
data.Omega0    = 0.25;
data.Cis       = -2e-6;
data.i0        = 0.30;
data.Crc       = 250;
data.omega     = -0.10;
data.Omega_dot = -5e-8;
data.IDOT      = 2e-10;

frame = build_nav_frame(data,params,432000);
words = recover_words(frame);

fprintf("Trama generada correctamente.\n\n");

w = cell(50,1);
for k=1:50, w{k}=words(k,:); end

% SF1
check("week",mod(data.week,1024),decode(w{3}(1:10),params.week),params.week);
check("SV_health",data.SV_health,decode(w{3}(17:22),params.SV_health),params.SV_health);
check("IODC",data.IODC,decode([w{3}(23:24) w{8}(1:8)],params.IODC),params.IODC);
check("TGD",data.TGD,decode(w{7}(17:24),params.TGD),params.TGD);
check("toc",data.toc,decode(w{8}(9:24),params.toc),params.toc);
check("af2",data.af2,decode(w{9}(1:8),params.af2),params.af2);
check("af1",data.af1,decode(w{9}(9:24),params.af1),params.af1);
check("af0",data.af0,decode(w{10}(1:22),params.af0),params.af0);

% SF2
check("IODE",data.IODE,decode(w{13}(1:8),params.IODE),params.IODE);
check("Crs",data.Crs,decode(w{13}(9:24),params.Crs),params.Crs);
check("Delta_n",data.Delta_n,decode(w{14}(1:16),params.Delta_n),params.Delta_n);
check("M0",data.M0,decode([w{14}(17:24) w{15}(1:24)],params.M0),params.M0);
check("Cuc",data.Cuc,decode(w{16}(1:16),params.Cuc),params.Cuc);
check("e",data.e,decode([w{16}(17:24) w{17}(1:24)],params.e),params.e);
check("Cus",data.Cus,decode(w{18}(1:16),params.Cus),params.Cus);
check("sqrtA",data.sqrtA,decode([w{18}(17:24) w{19}(1:24)],params.sqrtA),params.sqrtA);
check("toe",data.toe,decode(w{20}(1:16),params.toe),params.toe);

% SF3
check("Cic",data.Cic,decode(w{23}(1:16),params.Cic),params.Cic);
check("Omega0",data.Omega0,decode([w{23}(17:24) w{24}(1:24)],params.Omega0),params.Omega0);
check("Cis",data.Cis,decode(w{25}(1:16),params.Cis),params.Cis);
check("i0",data.i0,decode([w{25}(17:24) w{26}(1:24)],params.i0),params.i0);
check("Crc",data.Crc,decode(w{27}(1:16),params.Crc),params.Crc);
check("omega",data.omega,decode([w{27}(17:24) w{28}(1:24)],params.omega),params.omega);
check("Omega_dot",data.Omega_dot,decode(w{29}(1:24),params.Omega_dot),params.Omega_dot);
check("IODE(2)",data.IODE,decode(w{30}(1:8),params.IODE),params.IODE);
check("IDOT",data.IDOT,decode(w{30}(9:22),params.IDOT),params.IDOT);

fprintf("\n=========== FIN DEL TEST ===========\n");

function words = recover_words(frame)
words=false(50,24);
D30_prev=false;
for k=1:50
    words(k,:)=xor(frame(k,1:24),D30_prev);
    D30_prev=frame(k,30);
end
end

function value=decode(bits,param)
if param.signed
    i=bit_to_int(bits,true);
else
    i=bit_to_int(bits,false);
end
value=i*param.scale;
end

function val=bit_to_int(bits,is_signed)
n=length(bits);
if is_signed
    if bits(1), val=-2^(n-1); else, val=0; end
    for k=2:n, val=val+bits(k)*2^(n-k); end
else
    val=0;
    for k=1:n, val=val+bits(k)*2^(n-k); end
end
end

function check(name,orig,dec,param)

% Comparar el entero realmente transmitido por el mensaje GPS
q_orig = round(orig / param.scale);
q_dec  = round(dec  / param.scale);

if q_orig == q_dec
    fprintf("%-12s OK      %.12g\n",name,dec);
else
    fprintf("%-12s ERROR   %.12g -> %.12g\n",...
        name,orig,dec);

    fprintf("             Entero esperado = %d\n",q_orig);
    fprintf("             Entero recibido = %d\n",q_dec);
end

end
