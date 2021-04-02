function [ sim ] = Jaccard( train)
    sim = train * train;               
    deg_row = repmat(sum(train,1), [size(train,1),1]);
    deg_row = deg_row .* spones(sim);                               
    deg_row = triu(deg_row) + triu(deg_row');                      
    sim = sim./(deg_row.*spones(sim)-sim); clear deg_row;           
    sim(isnan(sim)) = 0; sim(isinf(sim)) = 0;
end