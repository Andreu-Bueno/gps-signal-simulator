function sat = init_gps_constellation(sc)
%INIT_GPS_CONSTELLATION Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    sc satelliteScenario
end

arguments (Output)
    sat 
end

tleLine1 = '1 28901U 05038A   23285.50000000 -.00000010  00000-0  00000+0 0  9990';
tleLine2 = '2 28901  55.4316  60.5284 0110307  41.9702 319.1673  2.00566373132646';

tleFilename = 'gps_prn17_temp.tle';
fid = fopen(tleFilename, 'w');
if fid == -1
    error('No se pudo crear el archivo TLE temporal.');
end
fprintf(fid, '%s\n%s\n', tleLine1, tleLine2);
fclose(fid);

sat = satellite(sc, tleFilename, ...
        'Name', 'GPS-PRN17', ...
        'OrbitPropagator', 'sgp4');

delete(tleFilename);

end