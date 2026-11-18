function frame = build_nav_frame(data, params, tow_start)
% BUILD_NAV_FRAME Construye la trama de 50 palabras resolviendo 
% la paridad palabra por palabra y empaquetando los bits según ICD-200N.

arguments (Input)
    data      struct
    params    struct
    tow_start double
end
arguments (Output)
    frame     logical
end

    frame = false(50, 30);
    word_idx = 1;
    
    % Estado inicial de paridad (asumido 0 al inicio de transmisión)
    D29 = false; 
    D30 = false;
    
    for sf = 1:5
        tow_next = tow_start + 6; 
        
        % ==========================================
        % PALABRA 1: TLM
        % ==========================================
        preamble = logical([1 0 0 0 1 0 1 1]);
        tlm_msg = false(1, 14);
        is_flag = false; 
        reserved = false;
        word1_24 = [preamble, tlm_msg, is_flag, reserved];
        
        [frame(word_idx, :), D29, D30] = add_parity(word1_24, D29, D30);
        word_idx = word_idx + 1;
        
        % ==========================================
        % PALABRA 2: HOW 
        % ==========================================
        tow_count = mod(floor(tow_next / 6), 100800);
        tow_bits = scale_unsigned(tow_count, 0, 17); 
        alert = false; anti_spoof = false;
        sf_id_bits = scale_unsigned(sf, 0, 3);
        
        known22_how = [tow_bits, alert, anti_spoof, sf_id_bits];
        [d23, d24] = solve_t_bits(known22_how, D29, D30);
        
        word2_24 = [known22_how, d23, d24];
        [frame(word_idx, :), D29, D30] = add_parity(word2_24, D29, D30);
        word_idx = word_idx + 1;
        
        % ==========================================
        % PALABRAS 3 A 10
        % ==========================================
        words_24 = cell(1, 7); % Para almacenar las palabras 3 a 9 temporalmente
        word10_22 = false(1, 22); % Los 22 primeros bits de la palabra 10
        
        switch sf
            case 1 % Reloj y Salud
                b_week   = encode(data.week, params.week);
                b_health = encode(data.SV_health, params.SV_health);
                b_TGD    = encode(data.TGD, params.TGD);
                b_IODC   = encode(data.IODC, params.IODC);
                b_toc    = encode(data.toc, params.toc);
                b_af2    = encode(data.af2, params.af2);
                b_af1    = encode(data.af1, params.af1);
                b_af0    = encode(data.af0, params.af0);
                
                % Rellenos de la subtrama 1
                code_L2 = false(1, 2); 
                ura = false(1, 4); 
                l2_p_flag = false;
                
                words_24{1} = [b_week, code_L2, ura, b_health, b_IODC(1:2)]; % Word 3
                words_24{2} = [l2_p_flag, false(1, 23)];                     % Word 4
                words_24{3} = false(1, 24);                                  % Word 5
                words_24{4} = false(1, 24);                                  % Word 6
                words_24{5} = [false(1, 16), b_TGD];                         % Word 7
                words_24{6} = [b_IODC(3:10), b_toc];                         % Word 8
                words_24{7} = [b_af2, b_af1];                                % Word 9
                word10_22   = b_af0;                                         % Word 10 (22 bits)
                
            case 2 % Efemérides 1
                b_IODE   = encode(data.IODE, params.IODE);
                b_Crs    = encode(data.Crs, params.Crs);
                b_Deltan = encode(data.Delta_n, params.Delta_n);
                b_M0     = encode(data.M0, params.M0);
                b_Cuc    = encode(data.Cuc, params.Cuc);
                b_e      = encode(data.e, params.e);
                b_Cus    = encode(data.Cus, params.Cus);
                b_sqrtA  = encode(data.sqrtA, params.sqrtA);
                b_toe    = encode(data.toe, params.toe);

                fit_flag = false; aodo = false(1, 5); % Valores por defecto
                
                words_24{1} = [b_IODE, b_Crs];                       % Word 3
                words_24{2} = [b_Deltan, b_M0(1:8)];                 % Word 4
                words_24{3} = b_M0(9:32);                            % Word 5
                words_24{4} = [b_Cuc, b_e(1:8)];                     % Word 6
                words_24{5} = b_e(9:32);                             % Word 7
                words_24{6} = [b_Cus, b_sqrtA(1:8)];                 % Word 8
                words_24{7} = b_sqrtA(9:32);                         % Word 9
                word10_22   = [b_toe, fit_flag, aodo];               % Word 10 (22 bits)

            case 3 % Efemérides 2
                b_Cic      = encode(data.Cic, params.Cic);
                b_Omega0   = encode(data.Omega0, params.Omega0);
                b_Cis      = encode(data.Cis, params.Cis);
                b_i0       = encode(data.i0, params.i0);
                b_Crc      = encode(data.Crc, params.Crc);
                b_omega    = encode(data.omega, params.omega);
                b_Omegadot = encode(data.Omega_dot, params.Omega_dot);
                b_IODE     = encode(data.IODE, params.IODE);
                b_IDOT     = encode(data.IDOT, params.IDOT);
                
                words_24{1} = [b_Cic, b_Omega0(1:8)];                % Word 3
                words_24{2} = b_Omega0(9:32);                        % Word 4
                words_24{3} = [b_Cis, b_i0(1:8)];                    % Word 5
                words_24{4} = b_i0(9:32);                            % Word 6
                words_24{5} = [b_Crc, b_omega(1:8)];                 % Word 7
                words_24{6} = b_omega(9:32);                         % Word 8
                words_24{7} = b_Omegadot;                            % Word 9
                word10_22   = [b_IODE, b_IDOT];                      % Word 10 (22 bits)
                
            otherwise % Sub-tramas 4 y 5 (Patrón Alternante)
                for w = 1:7
                    words_24{w} = repmat([true false], 1, 12);
                end
                word10_22 = repmat([true false], 1, 11);
        end
        
        % Procesar Palabras 3 a 9 (añadiendo paridad secuencialmente)
        for w = 1:7
            [frame(word_idx, :), D29, D30] = add_parity(words_24{w}, D29, D30);
            word_idx = word_idx + 1;
        end
        
        % Procesar Palabra 10 (Requiere resolver t-bits igual que el HOW)
        [d23, d24] = solve_t_bits(word10_22, D29, D30);
        word10_24 = [word10_22, d23, d24];
        [frame(word_idx, :), D29, D30] = add_parity(word10_24, D29, D30);
        word_idx = word_idx + 1;
        
        tow_start = tow_start + 6; % Avanzar tiempo para el siguiente subframe
    end
end


function [d23, d24] = solve_t_bits(known22, D29_prev, D30_prev)
% known22 = bits 1-22 of the word (source bits, before D30_prev XOR)
    idx29_no24 = [1 3 5 6 7 9 10 14 15 16 17 18 21 22];
    idx30_no2324 = [3 5 6 8 9 10 11 13 15 19 22];

    partial29 = D30_prev;
    for i = idx29_no24, partial29 = xor(partial29, known22(i)); end
    d24 = partial29;              % forces D29 = 0

    partial30 = D29_prev;
    for i = idx30_no2324, partial30 = xor(partial30, known22(i)); end
    d23 = xor(partial30, d24);    % forces D30 = 0
end

function bits = encode(value, def)

    if value < def.range(1) || value > def.range(2)
        warning('Value out of ICD range');
    end
    
    scale_exp = log2(def.scale);
    
    if def.signed
        bits = scale_signed(value, scale_exp, def.n_bits);
    else
        bits = scale_unsigned(value, scale_exp, def.n_bits);
    end

end