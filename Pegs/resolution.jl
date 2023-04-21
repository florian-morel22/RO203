using JuMP
using CPLEX



function cplexSolve(G::Matrix{Int})

    l = size(G, 1) + 4
    c = size(G, 2) + 4
    n = 32 #32 étapes pour tout enlever, mais ça marche pas
    model = Model(CPLEX.Optimizer)

    @variable(model, x[1:n, 1:l, 1:c, 1:5], Bin)

    """
        x[s, i, k, p, h] in 

            si h=2
                {0: la case (i,j) est hors jeu pour toutes les étapes}
            si h=1
                si p=5
                    {0: la case (i,j) est un trou à l'étape s, 1: la case (i, j) est un pion pour l'étape s}
                si p=1
                    {0: la case (i,j) ne peut pas se déplacer vers la gauche à l'étape s, 1: la case (i, j) peut se déplacer vers la gauche à l'étape s}
                si p=2
                    {0: la case (i,j) ne peut pas se déplacer vers la droite à l'étape s, 1: la case (i, j) peut se déplacer vers la droite à l'étape s}
            
                ...
          

        s in [1, n] : étapes du jeu
        (i,j) in [1,l]x[1,c] : position sur la grille
        p in {1:left, 2:right, 3:up, 4:down, 5:position} : 1,2,3,4 pour la direction de son mouvement ET 5 pour la position du pion
        h in {1:case dans le jeu, 2:case hors jeu} : détermine si la case est dans le jeu ou non
    """

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


    #On fait pareil pour les cases hors jeu dans G directement
    @constraint(model, [s in 1:n, i in 3:(l-2), j in 3:(c-2), p in 1:4; G[i-2, j-2] == 1], x[s, i, j, p] == 0) # Les cases hors du jeu restent hors du jeu 
    @constraint(model, [s in 1:n, i in 3:(l-2), j in 3:(c-2); G[i-2, j-2] == 1], x[s, i, j, 5] == 1) # Les cases hors du jeu restent hors du jeu 


    @constraint(model, [s in 1:n, i in 3:(l-2), j in 3:(c-2); G[i-2, j-2] == 2], x[1, i, j, 5] == 0) # Les trous de G sont reportés sur la grille de l'étape 1
    @constraint(model, [s in 1:n, i in 3:(l-2), j in 3:(c-2); G[i-2, j-2] == 3], x[1, i, j, 5] == 1) # Les pions de G sont reportés sur la grille de l'étape 1


    ### Contrainets de mouvement ###

    @constraint(model, [s in 1:n, i in 1:l, j in 1:c, p in 1:4], x[s, i, j, p] <= x[s, i, j, 5]) # Si une case est un pion, le mouvement dans la direction p est faisable

    @constraint(model, [s in 1:n, i in 2:l, j in 1:c], x[s, i, j, 1] <= x[s, i-1, j, 5]) # 1 left
    @constraint(model, [s in 1:n, i in 1:(l-1), j in 1:c], x[s, i, j, 2] <= x[s, i, j, 5]) # 1 right
    @constraint(model, [s in 1:n, i in 1:l, j in 2:c], x[s, i, j, 3] <= x[s, i, j-1, 5]) # 1 up
    @constraint(model, [s in 1:n, i in 1:l, j in 1:(c-1)], x[s, i, j, 4] <= x[s, i, j, 5]) # 1 down

    @constraint(model, [s in 1:n, i in 3:l, j in 1:c], x[s, i, j, 1] <= 1 - x[s, i-2, j, 5]) # 2 left
    @constraint(model, [s in 1:n, i in 1:(l-2), j in 1:c], x[s, i, j, 2] <= 1 - x[s, i+2, j, 5]) # 2 right
    @constraint(model, [s in 1:n, i in 1:l, j in 3:c], x[s, i, j, 3] <= 1 - x[s, i, j-2, 5]) # 2 up
    @constraint(model, [s in 1:n, i in 1:l, j in 1:(c-2)], x[s, i, j, 4] <= 1 - x[s, i, j+2, 5]) # 2 down

    @constraint(model, [s in 1:n], sum(x[s, i, j, p] for i in 1:l, j in 1:c, p in 1:4) == 1) # Un seul mouvement par étape est autorisé, tous pions confondus # <= 1 si le jeu n'est pas forcément résolvable

    ## Contrainte de mise à jour de la grille entre l'étape s et s+1 ##

    @constraint(model, [s in 1:(n-1), i in 3:(l-2), j in 3:(c-2)], x[s, i, j, 5] - x[s+1, i, j, 5] <= sum(x[s, i, j, p] for p in 1:4) + x[s, i-1, j, 2] - x[s, i-2, j, 2] + x[s, i+1, j, 1] - x[s, i+2, j, 1] + x[s, i, j-1, 4] - x[s, i, j-2, 4] + x[s, i, j+1, 3] - x[s, i, j+2, 3]) # Si un pion se déplace, il n'est plus sur la case (i, j) à l'étape s+1


    set_optimizer_attribute(model, "CPXPARAM_TimeLimit", 60)
    set_silent(model)
    optimize!(model)



    res = fill(-1, n, l - 4, c - 4)

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

function heuristicSolve(G::Matrix{Int})

    l = size(G, 1)
    c = size(G, 2)
    listSteps = [G]
    listOfPossibilities = []

    while true
        listOfPossibilities = []
        #Pour chaque trou, si on a deux pions alignés à côté, on marque la possibilité dans listOfPossibilities
        for i in 1:l
            for j in 1:c
                if G[i, j] == 2 #trou
                    if i >= 3 && G[i-1, j] == 3 && G[i-2, j] == 3
                        append!(listOfPossibilities, [i, j, "left"])
                    end
                    if i <= l - 2 && G[i+1, j] == 3 && G[i+2, j] == 3
                        append!(listOfPossibilities, [i, j, "right"])
                    end
                    if j >= 3 && G[i, j-1] == 3 && G[i, j-2] == 3
                        append!(listOfPossibilities, [i, j, "up"])
                    end
                    if j <= c - 2 && G[i, j+1] == 3 && G[i, j+2] == 3
                        append!(listOfPossibilities, [i, j, "down"])
                    end
                end
            end
        end

        if length(listOfPossibilities) == 0
            break
        else
            k = 1 # choose random
            i_hole = listOfPossibilities[1]
            j_hole = listOfPossibilities[2]
            action = listOfPossibilities[3]

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

            append!(listSteps, G)
        end
    end

    return listSteps

end

