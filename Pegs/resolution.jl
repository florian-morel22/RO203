using JuMP
using CPLEX

include("io.jl")

function cplexSolve(G::Matrix{Int})

    l = size(G, 1)
    c = size(G, 2)
    n = 32

    model = Model(CPLEX.Optimizer)

    @variable(model, x[1:n, 1:l, 1:c, 1:3], Bin)

    @objective(model, Min, sum(k * x[n, i, j, k] for i in 1:l for j in 1:c for k in 1:3))

    @constraint(model, [s in 1:n, i in 1:l, j in 1:c], sum(x[s, i, j, k] for k in 1:3) == 1)

    @constraint(model, [s in 1:n, i in 1:l, j in 1:c; G[i, j] == 1], x[s, i, j, 1] == 1)
    @constraint(model, [s in 1:n, i in 1:l, j in 1:c; G[i, j] > 1], x[s, i, j, 1] == 0)

    @constraint(model, [s in 1:(n-1)], sum(x[s, i, j, 3] for i in 1:l, j in 1:c) - sum(x[s+1, i, j, 3] for i in 1:l, j in 1:c) <= 1) #Entre les étapes i et i+1, il y a au plus 1 pion retiré
    #@constraint(model, [s in 1:(n-1)], sum(x[s, i, j, 2] - x[s+1, i, j, 2] for i in 1:l, j in 1:c) <= 1) #Entre les étapes i et i+1, seules 3 pièces ou 0 peuvent avoir changé de couleur






    @constraint(model, [i in 1:l, j in 1:c], x[1, i, j, G[i, j]] == 1) # La première étape doit être la même que la grille de départ

    @constraint(model, [s in 1:n], sum(x[s, i, j, 3] for k in 1:3, i in 1:l, j in 1:c) >= 1) # Il doit rester au moins un pion sur le plateau à chaque étape ## POURRA ETRE SUPPRIMER !

    set_silent(model)
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
        println("Aucune solution trouvée.")
        return -1
    end

end


sol = cplexSolve(readInputFile("instanceTest.txt"))
if sol != -1
    displaySolution(sol)
end