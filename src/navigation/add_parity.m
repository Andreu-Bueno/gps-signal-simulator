function [word, D29, D30] = add_parity(data, D29_prev, D30_prev)

arguments (Input)
    data (1,24) logical
    D29_prev (1,1) logical = false
    D30_prev (1,1) logical = false
end

arguments (Output)
    word (1,30) logical
    D29 (1,1) logical
    D30 (1,1) logical
end

% 1. Data encoding (D1–D24)
data_tx = xor(data, D30_prev);

% 2. Parity bits
D25 = calc_D25(data, D29_prev);
D26 = calc_D26(data, D30_prev);
D27 = calc_D27(data, D29_prev);
D28 = calc_D28(data, D30_prev);
D29 = calc_D29(data, D30_prev);
D30 = calc_D30(data, D29_prev);

% 3. Build word
word = [data_tx, D25, D26, D27, D28, D29, D30];

% 4. Update memory
D29 = word(29);
D30 = word(30);

end

%% D25
function D25 = calc_D25(d, D29_prev)

    D25 = D29_prev;
    
    idx = [1 2 3 5 6 10 11 12 13 14 17 18 20 23];
    
    for i = idx
        D25 = xor(D25, d(i));
    end

end

%% D26
function D26 = calc_D26(d, D30_prev)

    D26 = D30_prev;
    
    idx = [2 3 4 6 7 11 12 13 14 15 18 19 21 24];
    
    for i = idx
        D26 = xor(D26, d(i));
    end

end


%% D27
function D27 = calc_D27(d, D29_prev)

    D27 = D29_prev;
    
    idx = [1 3 4 5 7 8 12 13 14 15 16 19 20 22];
    
    for i = idx
        D27 = xor(D27, d(i));
    end

end

%% D28
function D28 = calc_D28(d, D30_prev)

    D28 = D30_prev;
    
    idx = [2 4 5 6 8 9 13 14 15 16 17 20 21 23];
    
    for i = idx
        D28 = xor(D28, d(i));
    end

end


%% D29
function D29 = calc_D29(d, D30_prev)

    D29 = D30_prev;
    
    idx = [1 3 5 6 7 9 10 14 15 16 17 18 21 22 24];
    
    for i = idx
        D29 = xor(D29, d(i));
    end

end

%% D30
function D30 = calc_D30(d, D29_prev)

    D30 = D29_prev;
    
    idx = [3 5 6 8 9 10 11 13 15 19 22 23 24];
    
    for i = idx
        D30 = xor(D30, d(i));
    end

end