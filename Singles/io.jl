include("resolution.jl")

function readInputFile(path::String)

    fichier = open(path)
    lines = readlines(fichier)
    close(fichier)

    l = size(lines, 1)
    c = ceil(Int, length(lines[1]) / 3) # On divise par 3 car chaque nombre est séparé par une virgule et un espace

    x = fill(0, l, c) # On initialise la matrice à 0 (cases vides)

    for i in 1:l
        for j in 1:c
            number = parse(Int, lines[i][3*j-1])
            x[i, j] = number
        end
    end

    return x

end

function displayGrid(G::Matrix{Int})

    l = size(G, 1)
    c = size(G, 2)

    for i in 1:l
        for j in 1:c
            print(G[i, j], " ")
        end
        println()
    end
    println()
end

function displaySolution(G::Matrix{Int})
    l = size(G, 1)
    c = size(G, 2)

    for i in 1:l
        for j in 1:c
            if G[i, j] == 0
                print("■ ")
            else
                print(string(G[i, j], " "))
            end
        end
        println()
    end
end

#cplexSolve(readInputFile("./data/instanceTest.txt"))

displayGrid(readInputFile("./data/instanceTest.txt"))
displaySolution(cplexSolve(readInputFile("./data/instanceTest.txt")))