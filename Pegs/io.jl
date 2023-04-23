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

function solveDataSet(path::String)

    for i in 1:size(readdir(path), 1) # enumerate ne fonctionne pas car ça lit les fichiers dans un ordre aléatoire

        G = readInputFile(joinpath(path, "instance_$i.txt"))
        out = @timed cplexSolve(G)
        x = out.value[1]
        nb_steps = out.value[2]

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

"""
generateDataSet(10, 30, 30)
println("generation done")
solveDataSet("data")
"""