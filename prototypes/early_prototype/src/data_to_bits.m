function bit_stream = data_to_bits(state, subframe_id)
% DATA_TO_BITS
% ============================================================
% Convierte estado orbital en subtrama GPS de 300 bits
%
% INPUTS:
%   state        (struct) → salida de extract_satellite_state
%   subframe_id  (double) → [1..5]
%
% OUTPUT:
%   bit_stream   (1x300 double) → bits {0,1}
% ============================================================
arguments (Input)
    state struct
    subframe_id (1, 1) double
end

arguments (Output)
    bit_stream (1, 300)
end

%% INIT
bit_stream = zeros(1,300);
idx = 1;

%% 1. PREAMBLE
preamble = [1 0 0 0 1 0 1 1];
bit_stream(idx:idx+7) = preamble;
idx = idx + 8;

%% 2. GPS WEEK (10 bits)
week_mod = mod(state.gps_week,1024);
week_bits = dec2bin(week_mod,10) - '0';

bit_stream(idx:idx+9) = week_bits;
idx = idx + 10;

%% 3. SUBFRAME ID (3 bits)
sf_bits = dec2bin(subframe_id,3) - '0';
bit_stream(idx:idx+2) = sf_bits;
idx = idx + 3;

%% 4. DATOS SEGÚN SUBTRAMA

switch subframe_id
    
    case 1
        % CLOCK BIAS
        val = int32(state.clock_bias * 2^31);
        bits = bitget(typecast(val,'uint32'),1:32);
        bit_stream(idx:idx+31) = bits;
        idx = idx + 32;
        
        % HEALTH
        bit_stream(idx:idx+5) = zeros(1,6);
        idx = idx + 6;
        
    case 2
        % POSICIÓN X,Y,Z
        
        scale = 2^23;
        
        x = int32(state.pos_ecef(1)/scale);
        y = int32(state.pos_ecef(2)/scale);
        z = int32(state.pos_ecef(3)/scale);
        
        bit_stream(idx:idx+31) = bitget(typecast(x,'uint32'),1:32);
        idx = idx + 32;
        
        bit_stream(idx:idx+31) = bitget(typecast(y,'uint32'),1:32);
        idx = idx + 32;
        
        bit_stream(idx:idx+31) = bitget(typecast(z,'uint32'),1:32);
        idx = idx + 32;
        
    case 3
        % VELOCIDADES
        
        scale = 2^16;
        
        vx = int32(state.vel_ecef(1)/scale);
        vy = int32(state.vel_ecef(2)/scale);
        vz = int32(state.vel_ecef(3)/scale);
        
        bit_stream(idx:idx+31) = bitget(typecast(vx,'uint32'),1:32);
        idx = idx + 32;
        
        bit_stream(idx:idx+31) = bitget(typecast(vy,'uint32'),1:32);
        idx = idx + 32;
        
        bit_stream(idx:idx+31) = bitget(typecast(vz,'uint32'),1:32);
        idx = idx + 32;
        
    otherwise
        % Subframes 4 y 5 simplificados
        % (en GPS real contienen almanaque, iono, etc.)
end

%% 5. PADDING
bit_stream(idx:end) = 0;

end