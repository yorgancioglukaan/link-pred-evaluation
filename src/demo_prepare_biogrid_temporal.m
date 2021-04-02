% filename1 = 'BIOGRID-ORGANISM-Homo_sapiens-3.0.68';
% filename2 = 'BIOGRID-ORGANISM-Homo_sapiens-4.0.189';
% filename1 = 'BIOGRID-ORGANISM-Arabidopsis_thaliana-3.0.68';
% filename2 = 'BIOGRID-ORGANISM-Arabidopsis_thaliana_Columbia-4.0.189';
filename1 = 'BIOGRID-ORGANISM-Drosophila_melanogaster-3.0.68';
filename2 = 'BIOGRID-ORGANISM-Drosophila_melanogaster-4.0.189';
%%
A = load(['out/biogrid/', filename1, '.mat']);
B = load(['out/biogrid/', filename2, '.mat']);
%%
nNode = length(A.proteins);
[b, ib] = ismember(B.proteins, A.proteins);

W1 = A.W;
W2 = sparse(nNode, nNode);
W2(ib(b), ib(b)) = B.W(b, b);
%%
% save('out/biogrid/processed_Homo_sapiens_3.0.68_4.0.189.mat', 'W1', 'W2');
save('out/biogrid/processed_Drosophila_melanogaster_3.0.68_4.0.189.mat', 'W1', 'W2');