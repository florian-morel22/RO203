include("resolution.jl")

#generetaion if a square/cross instance 
function generateInstance1(l::Int64, c::Int64, p::Float64, type::String)
    M = fill(1, l, c)
    index = 0

    if type == "square"
        # while (index == 0) || (cplexSolve(M) == -1)
        index += 1
        M = fill(1, l, c)
        for i in 1:l
            for j in 1:c
                # if rand() < p
                #     M[i, j] = 3
                # else
                #     M[i, j] = 2
                # end
                M[i, j] = 3
            end
        end
        M[convert(Int, floor(l / 2) + 1), convert(Int, floor(c / 2) + 1)] = 2
        #end
    elseif type == "cross"
        if l < 4
            println("La hauteur de la grille doit être supérieure à 3")
            return -1, index
        end
        if c < 4
            println("La largeur de la grille doit être supérieure à 3")
            return -1, index
        end

        el = floor(l / 3)
        ec = floor(c / 3)
        for i in 1:l
            for j in 1:c
                if (i > el && i <= l - el) || (j > ec && j <= c - ec)
                    M[i, j] = 3
                end
            end
        end
        M[convert(Int, floor(l / 2) + 1), convert(Int, floor(c / 2) + 1)] = 2
    end

    return M, index
end

function generateInstance(l::Int64, c::Int64, stepsMax::Int64)
    M = fill(1, l, c)

    i0 = convert(Int, floor(l / 2))
    j0 = convert(Int, floor(c / 2))
    M[i0, j0] = 3
    listPossibilities = []
    s = 0
    while s < stepsMax
        listPossibilities = []
        for i in 1:l
            for j in 1:c
                if M[i, j] == 3
                    if i > 2 && (M[i-1, j] == 1 || M[i-1, j] == 2) && (M[i-2, j] == 1 || M[i-2, j] == 2)
                        push!(listPossibilities, [i, j, -1, 0])
                    elseif i < l - 1 && (M[i+1, j] == 1 || M[i+1, j] == 2) && (M[i+2, j] == 1 || M[i+2, j] == 2)
                        push!(listPossibilities, [i, j, 1, 0])
                    elseif j > 2 && (M[i, j-1] == 1 || M[i, j-1] == 2) && (M[i, j-2] == 1 || M[i, j-2] == 2)
                        push!(listPossibilities, [i, j, 0, -1])
                    elseif j < c - 1 && (M[i, j+1] == 1 || M[i, j+1] == 2) && (M[i, j+2] == 1 || M[i, j+2] == 2)
                        push!(listPossibilities, [i, j, 0, 1])
                    end
                end
            end
        end

        if length(listPossibilities) > 0

            L = []
            for move in listPossibilities

                i1, j1 = move[1], move[2]
                i2, j2 = i1 + move[3], j1 + move[4]
                i3, j3 = i1 + 2 * move[3], j1 + 2 * move[4]

                # Calcul de la distance euclidienne entre la toute première case ajoutée au jeu et les pions qu'on va faire bouger. On choisit ensuite le pion qui est le plus proche du centre pour éviter d'éparpiller le jeu.
                if length(L) == 0
                    L = [[i1, j1, i2, j2, i3, j3]]
                elseif sqrt((i1 - i0)^2 + (j1 - j0)^2) < sqrt((L[1][1] - i0)^2 + (L[1][2] - j0)^2)
                    L = [[i1, j1, i2, j2, i3, j3]]
                elseif sqrt((i1 - i0)^2 + (j1 - j0)^2) == sqrt((L[1][1] - i0)^2 + (L[1][2] - j0)^2)
                    push!(L, [i1, j1, i2, j2, i3, j3])
                end
            end

            # On choisit un pion au hasard parmi ceux les plus proches du centre et sa direction de déploiement
            k = rand(1:length(L))
            L = L[k]

            M[L[1], L[2]] = 2
            M[L[3], L[4]] = 3
            M[L[5], L[6]] = 3

        else
            break
        end
        s = s + 1
    end


    list_i = []
    list_j = []
    for i in 1:l
        for j in 1:c
            if M[i, j] == 3 || M[i, j] == 2
                push!(list_i, i)
                push!(list_j, j)
            end
        end
    end

    i_min = minimum(list_i)
    i_max = maximum(list_i)
    j_min = minimum(list_j)
    j_max = maximum(list_j)

    M = M[i_min:i_max, j_min:j_max]

    return M
end

function generateDataSet(nb_instances::Int, gap::Int)

    for i in 1:length(readdir("data"))
        file = "data/instance_$i.txt"
        rm(file)
    end

    for instance in 1:nb_instances

        x = generateInstance(10 * gap * instance, 10 * gap * instance, 3 + (instance - 1) * gap)

        l, c = size(x)

        text = ""

        for i in 1:l
            for j in 1:c
                if x[i, j] == 1
                    text = string(text, "  ,")
                elseif x[i, j] == 2
                    text = string(text, " 0,")
                elseif x[i, j] == 3
                    text = string(text, " 1,")
                end
            end
            text = chop(text, head=0, tail=1)
            if i != l
                text = string(text, "\n")
            end
        end

        file = open("data/instance_$instance.txt", "w")
        write(file, text)
        close(file)
    end
end



# for i in 1:3
#     G , index  = genreationSquareInstance(5, 4, 0.8)
#     displaySolution(G) 
#     println(index)
# end



#generetaion if an cross instance

# if path != "null"
#     #touch(path)
#     file = open(path, "w")
#     for i in 1:l
#         for j in 1:c
#             if G[1, i, j] == 2
#                 write(file, "□ ")
#             elseif G[1, i, j] == 3
#                 write(file, "■ ")
#             end
#         end
#         write(file, "\n")
#     end
#     close(file)
# end

