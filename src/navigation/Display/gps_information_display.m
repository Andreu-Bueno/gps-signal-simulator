function gps_information_display(data_vec)

persistent fig txt

% Crear la ventana solo una vez
if isempty(fig) || ~isvalid(fig)

    fig = uifigure( ...
        'Name','GPS Navigation Information', ...
        'Position',[150 100 620 700]);

    txt = uitextarea(fig, ...
        'Position',[10 10 600 680], ...
        'FontName','Consolas', ...
        'FontSize',13, ...
        'Editable','off');

end

%==================================================================
% Construcción del texto (cell array de char)
%==================================================================

L = {};

L{end+1} = '=========================================================';
L{end+1} = '             GPS NAVIGATION INFORMATION';
L{end+1} = '=========================================================';
L{end+1} = ' ';

L{end+1} = 'CLOCK PARAMETERS';
L{end+1} = '---------------------------------------------------------';

L{end+1} = sprintf('%-15s : %d','Week',round(data_vec(1)));
L{end+1} = sprintf('%-15s : %d','SV Health',round(data_vec(2)));
L{end+1} = sprintf('%-15s : %.6e','TGD',data_vec(3));
L{end+1} = sprintf('%-15s : %d','IODC',round(data_vec(4)));
L{end+1} = sprintf('%-15s : %d','IODE',round(data_vec(5)));
L{end+1} = sprintf('%-15s : %d','toc',round(data_vec(6)));
L{end+1} = sprintf('%-15s : %.6e','af2',data_vec(7));
L{end+1} = sprintf('%-15s : %.6e','af1',data_vec(8));
L{end+1} = sprintf('%-15s : %.6e','af0',data_vec(9));

L{end+1} = ' ';
L{end+1} = 'ORBIT CORRECTIONS';
L{end+1} = '---------------------------------------------------------';

L{end+1} = sprintf('%-15s : %.6f','Crs',data_vec(10));
L{end+1} = sprintf('%-15s : %.6f','Cuc',data_vec(13));
L{end+1} = sprintf('%-15s : %.6f','Cus',data_vec(15));
L{end+1} = sprintf('%-15s : %.6f','Cic',data_vec(18));
L{end+1} = sprintf('%-15s : %.6f','Cis',data_vec(20));
L{end+1} = sprintf('%-15s : %.6f','Crc',data_vec(22));

L{end+1} = ' ';
L{end+1} = 'KEPLERIAN ELEMENTS';
L{end+1} = '---------------------------------------------------------';

L{end+1} = sprintf('%-15s : %.6e','Delta n',data_vec(11));
L{end+1} = sprintf('%-15s : %.8f','M0',data_vec(12));
L{end+1} = sprintf('%-15s : %.10f','e',data_vec(14));
L{end+1} = sprintf('%-15s : %.4f','sqrt(A)',data_vec(16));
L{end+1} = sprintf('%-15s : %d','toe',round(data_vec(17)));
L{end+1} = sprintf('%-15s : %.8f','Omega0',data_vec(19));
L{end+1} = sprintf('%-15s : %.8f','i0',data_vec(21));
L{end+1} = sprintf('%-15s : %.8f','omega',data_vec(23));
L{end+1} = sprintf('%-15s : %.6e','Omega dot',data_vec(24));
L{end+1} = sprintf('%-15s : %.6e','IDOT',data_vec(25));

%==================================================================
% Actualizar ventana
%==================================================================

txt.Value = string(L(:));

drawnow limitrate

end