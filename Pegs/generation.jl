include("resolution.jl")

#generetaion if an square instance 
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

function generateInstance(l::Int64, c::Int64)
    M = fill(1, l, c)
    i0 = rand(1:l)
    j0 = rand(1:c)
    M[i0, j0] = 3
    listPossibilities = [0]
    while length(listPossibilities) > 0
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

            k = rand(1:length(listPossibilities)) #On choisit un mouv au hasard parmi ceux possibles
            move = listPossibilities[k]
            i0, j0 = move[1], move[2]
            i1, j1 = i0 + move[3], j0 + move[4]
            i2, j2 = i0 + 2 * move[3], j0 + 2 * move[4]

            M[i0, j0] = 2
            M[i1, j1] = 3
            M[i2, j2] = 3
        end
    end

    return M
end

function generateDataSet(n::Int, taille_min::Int, taille_max::Int)
    if n < 1
        println("Le nombre de grilles à générer doit être supérieur ou égal à 1.")
        return -1
    end
    if taille_min < 2
        println("La taille minimale doit être supérieure ou égale à 2.")
        return -1
    end
    if taille_min > taille_max
        println("La taille maximale doit être supérieure à la taille minimale.")
        return -1
    end

    for instance in 1:n

        l = convert(Int, rand(taille_min:taille_max))
        c = convert(Int, rand(taille_min:taille_max))
        x = generateInstance(l, c)

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

