using JuMP
using CPLEX

function cplexSolve(G::Matrix{Int})

    l = size(G, 1)
    c = size(G, 2)


    model = Model(CPLEX.Optimizer)

    @variable(model, x[1:l, 1:c], Bin)

    @objective(model, Max, 1)

    # Même nombre de carrés noirs et blancs par ligne/colonne
    @constraint(model, [i in 1:l], sum(x[i, j] for j in 1:c) == round(Int, c / 2))
    @constraint(model, [j in 1:c], sum(x[i, j] for i in 1:l) == round(Int, l / 2))

    # On ne peut pas avoir 3 carrés noirs ou blancs alignés sur une colonne
    @constraint(model, [i in 1:l, j in 1:(c-2)], sum(x[i, j+k] for k in 0:2) >= 1)
    @constraint(model, [i in 1:l, j in 1:(c-2)], sum(x[i, j+k] for k in 0:2) <= 2)

    # On ne peut pas avoir 3 carrés noirs ou blancs alignés sur une ligne
    @constraint(model, [i in 1:(l-2), j in 1:c], sum(x[i+k, j] for k in 0:2) >= 1)
    @constraint(model, [i in 1:(l-2), j in 1:c], sum(x[i+k, j] for k in 0:2) <= 2)

    # On fixe les cases déjà remplies
    @constraint(model, [i in 1:l, j in 1:c; G[i, j] != -1], x[i, j] == G[i, j])

    set_silent(model)
    optimize!(model)

    if primal_status(model) == MOI.FEASIBLE_POINT
        return round.(Int, value.(x))
    else
        println("Aucun solution trouvée.")
        return -1
    end
end

