function [emb] = load_embedding(dir, filename, nnodes)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
    filename = strcat(dir, "/", filename, ".csv");
    emb_raw = readtable(filename, "NumHeaderLines", 1);
    emb_raw = table2array(emb_raw);
    emb = zeros(nnodes, size(emb_raw,2) -1);
    for i = 1:size(emb_raw,1)
        node = emb_raw(i,1);
        emb(node,:) = emb_raw(i,2:end);
    end
    
end

