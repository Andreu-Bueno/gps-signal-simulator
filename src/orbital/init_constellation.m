function sats = init_constellation(sc)
%INIT_CONSTELLATION Loads the GPS constellation from a tle file for
%orbital simulation.
%===============================
% Inputs:
%   - sc: type satellitScenario, from matlab toolbox
% Outputs:
%   - sats: list of satellites to simulate

arguments (Input)
    sc satelliteScenario
end

arguments (Output)
    sats
end


tleFile = '../data/gps_constellation.tle';

if ~exist(tleFile, 'file')
    error(['File -gps_constellation.tle- is missing. You can download it' ...
        'from CelesTrack and save it in the root of the project.'])
end

allSats = satellite(sc, tleFile, 'OrbitPropagator', 'sgp4');

sats = allSats;
fprintf('Constellation loaded: %d satellites intialized.\n', length(sats));

end