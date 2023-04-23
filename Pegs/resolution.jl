using JuMP
using CPLEX



function cplexSolve(G::Matrix{Int})

    l = size(G, 1) + 4
    c = size(G, 2) + 4

    n = 0 # nombre d'étapes nécessaires pour retirer tous les pions (sauf 1)
    for i in 1:(l-4)
        for j in 1:(c-4)
            if G[i, j] == 3
                n += 1
            end
        end
    end
    println("Nombre d'étapes nécessaires : ", n)


    model = Model(CPLEX.Optimizer)

    @variable(model, x[1:n, 1:l, 1:c, 1:5], Bin)

    @objective(model, Min, sum(x[n, i, j, 5] for i in 1:l for j in 1:c)) # On minimise le nombre de cases non hors jeu avec un pion à la fin du jeu

    # @constraint(model, [s in 1:n], l * c - sum(x[s, i, j, 5] for i in 1:l, j in 1:c) >= s)
    # AJOUTER CONTRAINTE : le nb de trous à l'étape s+1 doit être +1 par rapport à l'étape s

    # @objective(model, Min, 1)
    # @constraint(model, [s in 1:n], l * c - sum(x[s, i, j, 5] for i in 1:l, j in 1:c) == s) # On ne peut pas avoir plusieurs pions sur une même case


    #On fixe les cases en rajoutées en bordure de la grille à 1 pour leur position (ils sonts bloquants) et 0 pour leur mouvement (ne peuvent pas bouger)
    @constraint(model, [s in 1:n, i in 1:2, j in 1:c, p in 1:4], x[s, i, j, p] == 0)
    @constraint(model, [s in 1:n, i in (l-1):l, j in 1:c, p in 1:4], x[s, i, j, p] == 0)
    @constraint(model, [s in 1:n, i in 1:l, j in 1:2, p in 1:4], x[s, i, j, p] == 0)
    @constraint(model, [s in 1:n, i in 1:l, j in (c-1):c, p in 1:4], x[s, i, j, p] == 0)

    @constraint(model, [s in 1:n, i in 1:2, j in 1:c], x[s, i, j, 5] == 1)
    @constraint(model, [s in 1:n, i in (l-1):l, j in 1:c], x[s, i, j, 5] == 1)
    @constraint(model, [s in 1:n, i in 1:l, j in 1:2], x[s, i, j, 5] == 1)
    @constraint(model, [s in 1:n, i in 1:l, j in (c-1):c], x[s, i, j, 5] == 1)


    # On fait pareil pour les cases hors jeu dans G directement
    @constraint(model, [s in 1:n, i in 3:(l-2), j in 3:(c-2), p in 1:4; G[i-2, j-2] == 1], x[s, i, j, p] == 0) # Les cases hors sont des pions immobiles
    @constraint(model, [s in 1:n, i in 3:(l-2), j in 3:(c-2); G[i-2, j-2] == 1], x[s, i, j, 5] == 1) # Les cases hors du jeu sont représentés comme des pions


    @constraint(model, [i in 3:(l-2), j in 3:(c-2); G[i-2, j-2] == 2], x[1, i, j, 5] == 0) # Les trous de G sont reportés sur la grille de l'étape 1
    @constraint(model, [i in 3:(l-2), j in 3:(c-2); G[i-2, j-2] == 3], x[1, i, j, 5] == 1) # Les pions de G sont reportés sur la grille de l'étape 1


    ### Contraintes de mouvement ###

    @constraint(model, [s in 1:(n-1), i in 1:l, j in 1:c, p in 1:4], x[s, i, j, p] <= x[s, i, j, 5]) # Si une case est un pion, le mouvement dans la direction p est faisable

    @constraint(model, [s in 1:(n-1), i in 2:l, j in 1:c], x[s, i, j, 1] <= x[s, i-1, j, 5]) # 1 left
    @constraint(model, [s in 1:(n-1), i in 1:(l-1), j in 1:c], x[s, i, j, 2] <= x[s, i+1, j, 5]) # 1 right
    @constraint(model, [s in 1:(n-1), i in 1:l, j in 2:c], x[s, i, j, 3] <= x[s, i, j-1, 5]) # 1 up
    @constraint(model, [s in 1:(n-1), i in 1:l, j in 1:(c-1)], x[s, i, j, 4] <= x[s, i, j+1, 5]) # 1 down

    @constraint(model, [s in 1:(n-1), i in 3:l, j in 1:c], x[s, i, j, 1] <= 1 - x[s, i-2, j, 5]) # 2 left
    @constraint(model, [s in 1:(n-1), i in 1:(l-2), j in 1:c], x[s, i, j, 2] <= 1 - x[s, i+2, j, 5]) # 2 right
    @constraint(model, [s in 1:(n-1), i in 1:l, j in 3:c], x[s, i, j, 3] <= 1 - x[s, i, j-2, 5]) # 2 up
    @constraint(model, [s in 1:(n-1), i in 1:l, j in 1:(c-2)], x[s, i, j, 4] <= 1 - x[s, i, j+2, 5]) # 2 down

    @constraint(model, [s in 1:(n-1)], sum(x[s, i, j, p] for i in 1:l, j in 1:c, p in 1:4) <= 1) # Un seul mouvement par étape est autorisé, tous pions confondus # <= 1 si le jeu n'est pas forcément résolvable

    ## Contrainte de mise à jour de la grille entre l'étape s et s+1 ##

    @constraint(model, [s in 1:(n-1), i in 3:(l-2), j in 3:(c-2)], x[s, i, j, 5] - x[s+1, i, j, 5] == sum(x[s, i, j, p] for p in 1:4) + x[s, i-1, j, 2] - x[s, i-2, j, 2] + x[s, i+1, j, 1] - x[s, i+2, j, 1] + x[s, i, j-1, 4] - x[s, i, j-2, 4] + x[s, i, j+1, 3] - x[s, i, j+2, 3]) # Si un pion se déplace, il n'est plus sur la case (i, j) à l'étape s+1


    set_optimizer_attribute(model, "CPXPARAM_TimeLimit", 120)
    set_silent(model)
    optimize!(model)



    res = fill(-1, n, l - 4, c - 4)

    number_of_pegs_last_step = 0

    if primal_status(model) == MOI.FEASIBLE_POINT
        for s in 1:n
            for i in 3:(l-2)
                for j in 3:(c-2)
                    if G[i-2, j-2] == 1
                        res[s, i-2, j-2] = 1
                    elseif value.(x[s, i, j, 5]) == 0
                        res[s, i-2, j-2] = 2
                    elseif value.(x[s, i, j, 5]) == 1
                        res[s, i-2, j-2] = 3
                        if s == n
                            number_of_pegs_last_step += 1
                        end
                    end
                end
            end
        end
        return round.(Int, res), n, number_of_pegs_last_step == 1
    else
        println("Aucune solution trouvée.")
        return -1
    end

end

function solveDataSet(path::String)


    for i in (length(readdir(path))+1):(length(readdir("res/cplex")))
        file = "res/cplex/cplex_$i.txt"
        rm(file)
    end

    for i in 1:size(readdir(path), 1) # enumerate ne fonctionne pas car ça lit les fichiers dans un ordre aléatoire

        G = readInputFile(joinpath(path, "instance_$i.txt"))
        out = @timed cplexSolve(G)
        x = out.value[1]
        nb_steps = out.value[2]
        isOptimal = out.value[3]

        n = size(x, 1)
        l = size(x, 2)
        c = size(x, 3)

        text = ""

        if x != -1
            for s in 1:n
                text = string(text, "Etape ", string(s), " : \n")
                for i in 1:l
                    for j in 1:c
                        if x[s, i, j] == 1
                            text = string(text, "  ")
                        elseif x[s, i, j] == 2
                            text = string(text, " □")
                        else
                            text = string(text, " ■")
                        end
                    end
                    if i != l
                        text = string(text, "\n")
                    end
                end
                text = string(text, "\n\n")
            end
        end

        file = open("res/cplex/cplex_$i.txt", "w")
        write(file, "taille instance = ", string(l), " x ", string(c), "\n")
        write(file, "solveTime = ", string(out.time), " s\n")
        write(file, "nombre d'étpes nécessaires à la resolution = ", string(nb_steps), "\n")
        if x != -1 && isOptimal
            write(file, "isOptimal = true\n\n")
        else
            write(file, "isOptimal = false\n\n")
        end
        write(file, text)
        close(file)
    end
    return 1
end

function heuristicSolve(G::Matrix{Int})

    l = size(G, 1)
    c = size(G, 2)
    println("initial Grid")
    displayGrid(G)
    listSteps = Matrix[]
    push!(listSteps, G)
    listOfPossibilities = []
    t = 0

    while t < 100
        t += 1
        listOfPossibilities = []
        #Pour chaque trou, si on a deux pions alignés à côté, on marque la possibilité dans listOfPossibilities
        for i in 1:l
            for j in 1:c
                if G[i, j] == 2 #trou
                    if i >= 3 && G[i-1, j] == 3 && G[i-2, j] == 3
                        push!(listOfPossibilities, [i, j, "left"])
                    end
                    if i <= l - 2 && G[i+1, j] == 3 && G[i+2, j] == 3
                        push!(listOfPossibilities, [i, j, "right"])
                    end
                    if j >= 3 && G[i, j-1] == 3 && G[i, j-2] == 3
                        push!(listOfPossibilities, [i, j, "up"])
                    end
                    if j <= c - 2 && G[i, j+1] == 3 && G[i, j+2] == 3
                        push!(listOfPossibilities, [i, j, "down"])
                    end
                end
            end
        end

        #println(listOfPossibilities)

        if length(listOfPossibilities) == 0
            break
        else
            k = Int(ceil(rand() * length(listOfPossibilities)))
            i_hole = listOfPossibilities[k][1]
            j_hole = listOfPossibilities[k][2]
            action = listOfPossibilities[k][3]

            if action == "left"
                G[i_hole-2, j_hole] = 2
                G[i_hole-1, j_hole] = 2
            elseif action == "right"
                G[i_hole+2, j_hole] = 2
                G[i_hole+1, j_hole] = 2
            elseif action == "up"
                G[i_hole, j_hole-2] = 2
                G[i_hole, j_hole-1] = 2
            elseif action == "down"
                G[i_hole, j_hole+2] = 2
                G[i_hole, j_hole+1] = 2
            end
            G[i_hole, j_hole] = 3

            A = copy(G)

            push!(listSteps, A)
        end
    end

    return listSteps, t

end