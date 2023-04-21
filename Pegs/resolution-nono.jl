using JuMP
using CPLEX

include("io.jl")

function cplexSolve(G::Matrix{Int})

    l = size(G, 1)
    c = size(G, 2)
    num_of_balls = 32
    s = num_of_balls - 1 # nombre d'etapes necessaires

    model = Model(CPLEX.Optimizer)

    @variable(model, moves[1:l+4, 1:c+4, 1:s-1, 1:4], Bin)
    @variable(model, States[1:l+4, 1:c+4, 1:s], Bin) 
    println(model)  
    #contraintes 
    #bordure avec des boules et aucune d'elles ne peut bouger
    @constraint(model, [i in [1,2,l+3,l+4] , j in [1,2,c+3,c+4] , t in 1:s-1, d in 1:4 ] ,moves[i,j,t,d] == 0)
    @constraint(model, [i in [1,2,l+3,l+4] , j in [1,2,c+3,c+4] , t in 1:s] ,States[i,j,t] == 1)
    
    #boules en coins de pegs
    for i in 1:l
        for j in 1:c
            if G[i,j] == 1
                @constraint(model, [t in 1:s] , States[i+2,j+2,t] == 1)
                @constraint(model, [t in 1:s-1, d in 1:4] , moves[i+2,j+2,t,d] == 0)

            #initialise les états des boules
            elseif G[i,j] == 2
                @constraint(model, States[i+2,j+2,1] == 0)
            elseif G[i,j] == 3
                @constraint(model, States[i+2,j+2,1] == 1)
            end
        end
    end

    #EST
    @constraint(model,[i in 3:l+2, j in 3:c+2, t in 1:s-1] , moves[i,j,t,1] <= States[i,j,t] )
    @constraint(model,[i in 3:l+2, j in 3:c+2, t in 1:s-1] , moves[i,j,t,1] <= States[i+1,j,t] )
    @constraint(model,[i in 3:l+2, j in 3:c+2, t in 1:s-1] , moves[i,j,t,1] <= 1 - States[i+2,j,t] )
    #WEST+2+2
    @constraint(model,[i in 3:l+2, j in 3:c+2, t in 1:s-1] , moves[i,j,t,2] <= States[i,j,t] )
    @constraint(model,[i in 3:l+2, j in 3:c+2, t in 1:s-1] , moves[i,j,t,2] <= States[i-1,j,t] )
    @constraint(model,[i in 3:l+2, j in 3:c+2, t in 1:s-1] , moves[i,j,t,2] <= 1 - States[i-2,j,t] )
    #NORTH+2+2
    @constraint(model,[i in 3:l+2, j in 3:c+2, t in 1:s-1] , moves[i,j,t,3] <= States[i,j,t] )
    @constraint(model,[i in 3:l+2, j in 3:c+2, t in 1:s-1] , moves[i,j,t,3] <= States[i,j+1,t] )
    @constraint(model,[i in 3:l+2, j in 3:c+2, t in 1:s-1] , moves[i,j,t,3] <= 1 - States[i,j+2,t] )
    #SOUTH+2+2
    @constraint(model,[i in 3:l+2, j in 3:c+2, t in 1:s-1] , moves[i,j,t,4] <= States[i,j,t] )
    @constraint(model,[i in 3:l+2, j in 3:c+2, t in 1:s-1] , moves[i,j,t,4] <= States[i,j-1,t] )
    @constraint(model,[i in 3:l+2, j in 3:c+2, t in 1:s-1] , moves[i,j,t,4] <= 1 - States[i,j-2,t] )

    #contraintes sur les états
    @constraint(model,[i in 3:l+2, j in 3:c+2, t in 1:(s-1)] , States[i,j,t]-States[i,j,t + 1] == moves[i,j,t,1] + moves[i,j,t,2] + moves[i,j,t,3] + moves[i,j,t,4] + moves[i-1,j,t,1] - moves[i-2,j,t,1] + moves[i+1,j,t,2] - moves[i+2,j,t,2] + moves[i,j+2,t,3] - moves[i,j+2,t,3] + moves[i,j-1,t,4] - moves[i,j-2,t,4] )

    @constraint(model, [t in 1:s-1], sum(moves[i+2,j+2,t,d] for d in 1:4, i in 1:l, j in 1:c if G[i,j]>1) == 1 ) 



    set_silent(model)
    optimize!(model)

    res = fill(-1, l, c, s)

    if primal_status(model) == MOI.FEASIBLE_POINT
        for s in 1:s
            for i in 1:l
                for j in 1:c
                    if value.(States[i+2, j+2, s]) == 1 && G[i,j] == 1
                        res[i, j, s] = 1
                    elseif value.(States[i+2, j+2, s]) == 1 && G[i,j] > 1
                        res[i, j, s] = 3
                    elseif value.(States[i+2, j+2, s]) == 0
                        res[i, j, s] = 2
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


sol = cplexSolve(readInputFile("data/instance_1.txt"))
println(readInputFile("data/instance_1.txt"))
if sol != -1
    displaySolution(sol)
end