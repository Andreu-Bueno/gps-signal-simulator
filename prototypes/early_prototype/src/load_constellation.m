function sats = load_constellation(sc, numSats)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
arguments (Input)
    sc satelliteScenario
    numSats double
end

arguments (Output)
    sats satelliteScenario.Satellite
end

tleFile = 'gps_constellation.tle';
    
if ~exist(tleFile, 'file')
    error('No se encuentra el archivo gps_constellation.tle. Descárgalo de CelesTrak.');
end

allSats = satellite(sc, tleFile, 'OrbitPropagator', 'sgp4');

n = min(numSats, length(allSats));
sats = allSats(1:n);

for i = 1:length(sats)
    sats(i).Name = sprintf('GPS-PRN%02d', i);
end

fprintf('Cargados %d satélites correctamente.\n', n);

end