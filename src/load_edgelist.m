function [adj] = load_edgelist(filename,nNodes)
%LOAD_EDGELIST Summary of this function goes here
%   Detailed explanation goes here
    edgelist = readmatrix(filename);
    nEdges = size(edgelist,1);
    adj = zeros(nNodes);
    for i = 1:nEdges
        u = edgelist(i,1);
        v = edgelist(i,2);
        adj(u,v) = 1;
        adj(v,u) = 1;
    end
    adj = sparse(adj);
end

