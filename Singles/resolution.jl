using JuMP
using CPLEX

function cplexSolve(G::Matrix{Int})

    l = size(G, 1)
    c = size(G, 2)
    n = max(l, c)

    model = Model(CPLEX.Optimizer)

    @variable(model, x[1:l, 1:c, 1:n], Bin)

    @objective(model, Max, 1)


    # Dans chaque ligne et colonne, on a une occurence de chaque numéro maximale de 1
    @constraint(model, [i in 1:l, k in 1:n], sum(x[i, j, k] for j in 1:l) <= 1)
    @constraint(model, [j in 1:c, k in 1:n], sum(x[i, j, k] for i in 1:c) <= 1)

    @constraint(model, [i in 1:l, j in 1:(c-1)], sum(x[i, j, k] + x[i, j+1, k] for k in 1:n) >= 1)
    @constraint(model, [i in 1:(l-1), j in 1:c], sum(x[i, j, k] + x[i+1, j, k] for k in 1:n) >= 1)



    @constraint(model, [i in 1:l, j in 1:c], sum(x[i, j, k] for k in 1:n) <= 1)

    @constraint(model, [i in 1:l, j in 1:c, k in 1:n; k != G[i, j]], x[i, j, k] == 0)

    set_silent(model)
    optimize!(model)

    res = fill(0, l, c)

    if primal_status(model) == MOI.FEASIBLE_POINT
        for i in 1:l
            for j in 1:c
                if sum(value(x[i, j, k]) for k in 1:n) == 1
                    for k in 1:n
                        if value(x[i, j, k]) == 1
                            res[i, j] = k
                        end
                    end
                end
            end
        end
    else
        println("Aucun solution trouvée.")
        return -1
    end


    return res
end