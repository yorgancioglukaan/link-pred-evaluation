function [ ] = save_edgelist( adj, dir, filename )
%SAVE_EDGELIST Summary of this function goes here
%   Detailed explanation goes here
    [row,col] = find(triu(adj,1));
    %csvwrite(strcat(filename,'.edgelist'),horzcat(row,col))
    writematrix(horzcat(row,col),strcat(dir,"/",filename),'Delimiter', 'space')
end

