function [separability, cuttoffmax, I, cutoffs] = computeSeparability( A, B )
    A = reshape(A, [], 1);
    B = reshape(B, [], 1);
     
     isA = [true(size(A)); false(size(B))];
     [S, si] = sort([A; B], 'ascend');
     isA = isA(si);
     mA = cumsum(isA);
     mB = (1:length(isA))' - mA;
     [cutoffs, cutoffIndices] = unique(S);
%     [~, co_indicesA] = ismember(cutoffs, A);
%     [~, co_indicesB] = ismember(cutoffs, B);
%     [~, co_indicesA] = intersect(A, cutoffs, 'stable');
%     [~, co_indicesB] = intersect(B, cutoffs, 'stable');
    
    nA = length(A);
    nB = length(B);
    
    informedness1 = (mA / nA) - (mB / nB);
    informedness2 = ((nA - mA) / nA) - ((nB - mB) / nB);
    I = max(informedness1, informedness2);
    I = I(cutoffIndices);
%     for iCutoff = 1:length(cutoffs)
%         co = cutoffs(iCutoff);
% %         mA = co_indicesA(iCutoff);
% %         mB = co_indicesB(iCutoff);
%         mA = nnz(A > co);
%         mB = nnz(B > co);
% %         mA2 = nnz(A < co);
% %         mB2 = nnz(B < co);
%         
%         informedness1 = (mA / nA) - (mB / nB);
%         informedness2 = ((nA - mA) / nA) - ((nB - mB) / nB);
% %         informedness2 = ((mA2) / nA) - ((mB2) / nB);
%         informedness = max(informedness1, informedness2);
%         I(iCutoff) = informedness;
%     end
    [separability, mi] = max(I);
    cuttoffmax = cutoffs(mi);
end







