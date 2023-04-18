using JuMP
using CPLEX

include("io.jl")

function cplexSolve(G::Matrix{Int})

    l = size(G, 1)
    c = size(G, 2)
    n = 3

    model = Model(CPLEX.Optimizer)

    @variable(model, x[1:n, 1:l, 1:c, 1:3], Bin)

    @objective(model, Min, sum(k * x[s, i, j, k] for i in 1:l for j in 1:c for k in 1:3 for s in 1:n))

    @constraint(model, [s in 1:n, i in 1:l, j in 1:c], sum(x[s, i, j, k] for k in 1:3) == 1)

    @constraint(model, [s in 1:n, i in 1:l, j in 1:c; G[i, j] == 1], x[s, i, j, 1] == 1)
    @constraint(model, [s in 1:n, i in 1:l, j in 1:c; G[i, j] > 1], x[s, i, j, 1] == 0)

    @constraint(model, [s in 1:(n-1)], sum(x[s, i, j, 2] - x[s, i, j, k] for i in 1:n, j in 1:c, k in 1:3) <= 1)

    @constraint(model, [i in 1:l, j in 1:c], x[1, i, j, G[i, j]] == 1) # La première étape doit être la même que la grille de départ


    #@constraint(model, [i in 2:(l-1), j in 2:(c-1); x[i+1, j, 3] == 1], x[i, j, 3] == 1)
    #@constraint(model, [j in 3:(c-2); x[l, j+1, 1] == 1], x[l, j, 3] == 1)
    # @constraint(model, [i in 2:(l-1), j in 1:c; (x[i+1, j, 2] == 1 && x[i-1, j, 3] == 1 && x[i, j, 3] == 1)], x[i, j, 2] == 1)
    # @constraint(model, [i in 2:(l-1), j in 1:c; (x[i+1, j, 2] == 1 && x[i-1, j, 3] == 1 && x[i, j, 3] == 1)], x[i+1, j, 3] == 1)


    optimize!(model)

    res = fill(-1, l, c, n)

    if primal_status(model) == MOI.FEASIBLE_POINT
        for s in 1:n
            for i in 1:l
                for j in 1:c
                    if value.(x[s, i, j, 1]) == 1
                        res[i, j, s] = 1
                    elseif value.(x[s, i, j, 2]) == 1
                        res[i, j, s] = 2
                    elseif value.(x[s, i, j, 3]) == 1
                        res[i, j, s] = 3
                    end
                end
            end
        end
        return round.(Int, res)
    else
        println("Aucun génération trouvée.")
        return -1
    end

end

displayGrid(cplexSolve(readInputFile("instanceTest.txt")))