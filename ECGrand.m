
clc
clear all
close all

%%% Lectura de los ficheros
cd data_all; %Moverse a la carpeta con todos los ficheros con las señales
current_folder = pwd; %Almacenar la direccion de la carpeta
input_folder = current_folder;
cd ..; %Volver a la carpeta con el programa principal
% Leer todos los ficheros de la carpeta 'data_all' que sean '*.mat'
files = dir(fullfile(input_folder, '*.mat'));
% Coger la ruta absoluta de cada uno de los ficheros de 'data_all'
file_paths = fullfile({files.folder}, {files.name});
signal_data = cell([numel(file_paths) 1]); % Preparar un array de celdas igual al numero de ficheros que hay
for i=1:numel(file_paths)
    signal_data{i} = load(file_paths{i}); % Añadir los valores de cada fichero a la posicion i del array de celdas
end
%Borrar variables que ya no son necesarias
clear current_folder file_paths files i input_folder;
%% Prepare File to write results
first_file = 1;
%% Procesamiento de las señales 
%Inicio For. Recorrer todos los ficheros con las señales
for j=1:numel(signal_data)
    %% Pass-band filter
    fs = 128;
    %Setting Parameters
    wo = 45/(fs/2);
    bw = wo/35;
    [b,a] = iirnotch(wo,bw);
    c1 = [signal_data{j}.val(2,:)];
    %Visualizacion de la señal
    % N = length (c1);       % Signal length
    % t = [0:N-1]/fs;        % time index
    % plot(t,c1);
    %axis([0  240    ylim]);

    %Filtrar la señal
    c1 = c1-mean(c1);
    c1 = filter(b,a,c1);
    c12=[]; c13=[];  c14=[]; c15=[];  c16=[];
    display(numel(c1));
    %% Comprobar ratio
    ratio_dividir = 120;
    factor = floor(size(c1,2)/ratio_dividir);
    num_array = factor*ratio_dividir;
    elem_perdidos = (numel(c1))-num_array;
    c1 = c1(:,1:num_array);
    %% Extract Randomness
    c12 = reshape(c1,ratio_dividir,factor)';
    for i=1:size(c12,1)   
        aux = c12(i,:);
        [c,l]=wavedec(aux,6,'db4');
        c13(i,:)= abs(appcoef(c,l,'db4',1));
    end
    %% Get decimals and make shifts
    c14 = uint32(c13*10000);
    e3 = bitshift(c14,24);
    e3 = bitshift(e3,-24);
    c15 = uint8(e3);
    %% Eliminate BIAS
    %Se divide la matriz en 2
    n_mat = floor(numel(c15)/2);
    mat1 = c15(1:n_mat);
    mat1_bin = de2bi(mat1);
    mat2 = c15(n_mat+1:2*n_mat);
    mat2_bin = de2bi(mat2);
    elem_lost = numel(c15)-(numel(mat1)+numel(mat2));
    disp(elem_lost);
    mat3_bin = xor(mat1_bin,mat2_bin);
    mat3 = uint8(bi2de(mat3_bin));
    result = mat3;
    %% Compute histogram
    c16 = reshape(result,1,numel(result)); 
    histogram(c16)
    %% Estribir los resultados en el fichero
    if first_file == 1
        fid = fopen('ECGrand.bin','wb');
        fwrite(fid,result,'uint8');
        fclose(fid);
    else
        fid = fopen('ECGrand.bin','ab');
        fwrite(fid,result,'uint8');
        fclose(fid);
    end
    % Setear la variable para escribir codigo
    if j == 1
        first_file = 0;
    end
end