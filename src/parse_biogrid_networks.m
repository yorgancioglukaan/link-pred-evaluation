% filename = 'BIOGRID-ORGANISM-Homo_sapiens-3.0.68';
filename = 'BIOGRID-ORGANISM-Homo_sapiens-4.0.189';
% filename = 'BIOGRID-ORGANISM-Drosophila_melanogaster-3.0.68';
% filename = 'BIOGRID-ORGANISM-Drosophila_melanogaster-4.0.189';
%%
filepath = ['in/', filename, '.tab.txt'];
ds = datastore(filepath, 'NumHeaderLines', 35, 'ReadVariableNames', true, 'Delimiter', '\t');
ds.SelectedFormats = repmat({'%q'}, 1, length(ds.SelectedFormats));
% ds.Delimited = '\t'
% ds.TextscanFormats = {'%q', '%q', '%q', '%q', '%q', '%q', '%f'};
T = readall(ds);
%%
proteins = unique([T.INTERACTOR_A, T.INTERACTOR_B]);
[~, proteins1] = ismember(T.INTERACTOR_A, proteins);
[~, proteins2] = ismember(T.INTERACTOR_B, proteins);
valids = (proteins1 > 0) & (proteins2 > 0);
proteins1 = proteins1(valids);
proteins2 = proteins2(valids);

W = logical(sparse(proteins1, proteins2, 1, length(proteins), length(proteins)));
W = W | W';
W = logical(W - diag(diag(W)));

outPath = 'out/biogrid/';
if(~exist(outPath, 'dir')); mkdir(outPath); end

save([outPath, filename, '.mat'], 'W', 'proteins', 'T');
    


