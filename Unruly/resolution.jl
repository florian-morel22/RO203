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
        return -1
    end
end

function solveDataSet(path::String)

    for i in 1:size(readdir(path), 1) # enumerate ne fonctionne pas car ça lit les fichiers dans un ordre aléatoire

        G, filling = readInputFile(joinpath(path, "instance_$i.txt"))
        out = @timed cplexSolve(G)
        x = out.value

        l = size(x, 1)
        c = size(x, 2)
        text = ""

        if x != -1
            for i in 1:l
                for j in 1:c
                    if x[i, j] == 0
                        text = string(text, " 0,")
                    elseif x[i, j] == 1
                        text = string(text, " 1,")
                    else
                        text = string(text, "  ,")
                    end
                end
                text = chop(text, head=0, tail=1)
                if i != l
                    text = string(text, "\n")
                end
            end

            text = string(text, "\n\n")

            for i in 1:l
                for j in 1:c
                    if x[i, j] == 0
                        text = string(text, " ■")
                    elseif x[i, j] == 1
                        text = string(text, " □")
                    end
                end

                if i != l
                    text = string(text, "\n")
                end
            end
        end
        file = open("res/cplex/cplex_$i.txt", "w")
        write(file, "taille instance = ", string(l), " x ", string(c), "\n")
        write(file, "pourcentage de cases initialement remplies = ", string(filling), " %\n")
        write(file, "solveTime = ", string(out.time), " s\n")
        if x != -1
            write(file, "isOptimal = true\n\n")
        else
            write(file, "isOptimal = false\n\n")
        end
        write(file, text)
        close(file)
    end
    return 1
end
