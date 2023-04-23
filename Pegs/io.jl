include("resolution.jl")
include("generation.jl")

function readInputFile(path::String)

    fichier = open(path)
    lines = readlines(fichier)
    close(fichier)

    l = size(lines, 1)
    c = ceil(Int, length(lines[1]) / 3)

    x = Matrix{Int}(fill(1, l, c))


    for i in 1:l
        for j in 1:c
            if lines[i][3*j-1] != ' '
                number = parse(Int, lines[i][3*j-1])
                x[i, j] = number + 2
            end
        end
    end
    return x
end

function displayGrid(X::Matrix{Int64})

    l = size(X, 1)
    c = size(X, 2)

    for i in 1:l
        for j in 1:c
            if X[i, j] == 1
                print("  ")
            elseif X[i, j] == 2
                print("□ ")
            elseif X[i, j] == 3
                print("■ ")
            end
        end
        println()
    end
    println()
end

function displaySolution(X::Matrix{Int64})

    Y = cplexSolve(X)

    if Y == -1
        println("No solution found")
        return
    end

    n = size(Y, 1)
    l = size(Y, 2)
    c = size(Y, 3)

    for s in 1:n
        println("Etape ", s, " :")
        for i in 1:l
            for j in 1:c
                if Y[s, i, j] == 1
                    print("  ")
                elseif Y[s, i, j] == 2
                    print("□ ")
                elseif Y[s, i, j] == 3
                    print("■ ")
                end
            end
            println()
        end
        println()
    end
end

function resultsArray(path_read::String, path_write::String, nb_samples::Int64, gap::Int64)

    generateDataSet(nb_samples, gap)
    solveDataSet("data")

    file_w = open(joinpath(path_write, "tab.txt"), "w")
    write(file_w, "Nombre d'étapes nécessaires à la résolution     ")
    write(file_w, "Temps d'execution du cplex      ")
    write(file_w, "Solution trouvée                \n")

    for sample in 1:nb_samples

        file_r = open(joinpath(path_read, "cplex_$sample.txt"))
        lines = readlines(file_r)[1:4]
        close(file_r)

        write(file_w, lpad(lines[3][48:end], 43))
        write(file_w, lpad(lines[2][13:end], 31))
        write(file_w, lpad(lines[4][13:end], 22))
        write(file_w, "\n")
    end

    write(file_w, "\n\n")
    close(file_w)


    println("done")
end

resultsArray("res/cplex", "res/tableau", 17, 2)



#solveDataSet("data")

# displayGrid(readInputFile("./data/instance_1.txt"))

#G, index = generateInstance(6, 6, 0.5, "cross")
# G = [1 1 1 1 3 1 1; 1 1 1 3 3 3 1; 3 1 3 3 2 3 1; 3 3 3 3 3 3 3; 3 3 2 3 3 3 1; 3 3 3 3 3 1 1; 1 1 1 3 1 1 1] # 7x7 OK
# G = [1 3 3 3 1; 1 3 3 3 1; 3 3 3 3 3; 3 3 2 3 3; 3 3 3 3 3; 1 3 3 3 1; 1 3 3 3 1] # 7x5 OK
# G, index = generateInstance(7, 5, 0.5, "cross") # OK
# G = [1 3 3 3 3 1 1; 1 1 3 3 3 3 1; 1 1 1 3 3 3 3; 1 3 3 3 3 3 1; 3 3 3 3 2 3 1; 3 3 3 3 3 3 1; 1 1 3 1 1 1 1] # 7x7 OK, 29 steps
#G = [1 1 3 3 1 1 1 1 1; 3 3 3 3 1 3 1 1 1; 1 3 3 3 3 2 3 3 1; 1 3 3 2 3 3 3 1 1; 1 3 3 3 3 3 3 3 3; 3 3 3 3 3 3 3 3 1; 1 3 3 2 3 3 1 3 1; 1 1 3 3 1 1 1 3 1; 1 1 3 1 1 1 1 1 1]

# G = generateInstance(20, 20)

# if G != -1
#     displayGrid(G)
# end


# generateDataSet(10, 30, 30)
# println("generation done")
# solveDataSet("data")


