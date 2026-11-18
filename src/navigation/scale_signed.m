function bits = scale_signed(val, scale_exp, n_bits)
% SCALE_SIGNED  Convert signed real value to n-bit two's-complement binary.
%
% GPS parameters have specific scale factors 2^(scale_exp).
% This function:
%   1. Divides the value by LSB = 2^scale_exp
%   2. Rounds to nearest integer
%   3. Clips to valid range [-2^(n_bits-1), 2^(n_bits-1)-1]
%   4. Converts to two's complement if negative
%   5. Returns MSB-first bit vector
%
% Example:
%   M0 in GPS has scale 2^-31 rad, stored in 32 bits.
%   bits = scale_signed(M0, -31, 32);
%   → bits is 1x32, MSB first, encodes M0 ± 2^-31 resolution

arguments (Input)
    val       (1,1) double                   % value to encode [physical units]
    scale_exp (1,1) double                   % scale exponent (2^scale_exp = LSB)
    n_bits    (1,1) double {mustBePositive}  % number of bits
end

arguments (Output)
    bits (1, :) double
end

LSB = 2^scale_exp;
quantized = round(val/LSB);

% Clip to valid range
max_val = 2^(n_bits-1)-1;
min_val = -2^(n_bits-1);
quantized = max(min_val, min(max_val, quantized));

% Two's complement for negative values
if quantized < 0
    quantized = quantized + 2^n_bits;
end

% Convert to binary, MSB-first
bits = double(bitget(uint64(quantized), n_bits:-1:1));
end