function plot_nav_frame(frame)
%PLOT_NAV_FRAME Visualiza una trama LNAV de 50x30 bits en dos ventanas
% independientes - mapa de bits y señal NRZ - que puedes mover y
% redimensionar libremente, como cualquier ventana de escritorio.
% Se llama vía coder.extrinsic desde un MATLAB Function block de
% Simulink (frame_display.m); esta función en sí NO es codegenerable.
%
% frame  50x30 logical/double, una fila por palabra transmitida,
%        MSB-first, tal como la produce build_nav_frame.
%
% Las ventanas se crean UNA sola vez (vía persistent) y en las llamadas
% siguientes solo se actualizan los datos, no la posición/tamaño - así
% que una vez las coloques donde quieras, se quedan ahí.

persistent fig_bitmap img_handle
persistent fig_nrz nrz_handle

frame = double(frame);

% ===================== VENTANA 1: MAPA DE BITS =====================
if isempty(fig_bitmap) || ~isvalid(fig_bitmap)
    fig_bitmap = figure( ...
        'Name','GPS LNAV - Mapa de bits', ...
        'NumberTitle','off', ...
        'WindowStyle','normal');
    movegui(fig_bitmap,'center');
    
    ax = axes(fig_bitmap);
    img_handle = imagesc(ax, frame);
    axis(ax, 'tight');
    colormap(ax, gray(2));
    caxis(ax, [0 1]);
    xlabel(ax, 'Posición del bit en la palabra (1-30, MSB primero)');
    ylabel(ax, 'Número de palabra (1-50)');
    title(ax, 'Mapa de bits de la trama LNAV (5 subtramas x 10 palabras)');
    set(ax, 'YTick', 1:10:50, 'YTickLabel', {'SF1','SF2','SF3','SF4','SF5'});

    hold(ax, 'on');
    % Rejilla fina para distinguir cada bit y cada palabra individualmente
    % (2 objetos 'line' con segmentos separados por NaN, en vez de 80
    % objetos sueltos, para no penalizar el refresco)
    xg = 0.5:1:30.5;
    Xv = reshape([xg; xg; nan(1, numel(xg))], 1, []);
    Yv = reshape(repmat([0.5; 50.5; NaN], 1, numel(xg)), 1, []);
    plot(ax, Xv, Yv, 'Color', [0.6 0.6 0.6 0.35], 'LineWidth', 0.5);

    yg = 0.5:1:50.5;
    Xh = reshape(repmat([0.5; 30.5; NaN], 1, numel(yg)), 1, []);
    Yh = reshape([yg; yg; nan(1, numel(yg))], 1, []);
    plot(ax, Xh, Yh, 'Color', [0.6 0.6 0.6 0.35], 'LineWidth', 0.5);

    % Límites de subtrama bien marcados, por encima de la rejilla fina
    for sf_boundary = 10.5:10:40.5
        yline(ax, sf_boundary, 'r-', 'LineWidth', 1.5);
    end
    hold(ax, 'off');

    % Si prefieres celdas perfectamente cuadradas en vez de rectangulares,
    % descomenta la siguiente línea (hará la ventana efectivamente más
    % alargada verticalmente al redimensionar):
    % axis(ax, 'image');
else
    % Ya existe: solo actualizamos los datos, sin tocar posición/tamaño
    img_handle.CData = frame;
end

% ===================== VENTANA 2: SEÑAL NRZ =====================
bitstream = reshape(frame.', 1, []);   % serializa MSB-first, palabra a palabra
bit_period = 0.02;                     % 20 ms/bit (50 bps)
n = numel(bitstream);
t = (0:n-1) * bit_period;
levels = 1 - 2*bitstream;              % NRZ-L: bit 0 -> +1, bit 1 -> -1
t_stairs = [t, t(end) + bit_period];
levels_stairs = [levels, levels(end)];

if isempty(fig_nrz) || ~isvalid(fig_nrz)
    fig_nrz = figure( ...
        'Name','GPS LNAV - Señal NRZ', ...
        'NumberTitle','off', ...
        'WindowStyle','normal');
    movegui(fig_nrz,'center');

    ax2 = axes(fig_nrz);
    nrz_handle = stairs(ax2, t_stairs, levels_stairs, 'LineWidth', 1);
    ylim(ax2, [-1.5 1.5]);
    xlabel(ax2, 'Tiempo (s)');
    ylabel(ax2, 'Nivel NRZ');
    title(ax2, 'Bitstream de datos de navegación (NRZ, 50 bps)');
    grid(ax2, 'on');
else
    nrz_handle.XData = t_stairs;
    nrz_handle.YData = levels_stairs;
end

drawnow limitrate nocallbacks

end