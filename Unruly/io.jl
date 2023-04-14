using Plots
include("resolution.jl")

function readInputFile(path::String)

    fichier = open(path)
    lines = readlines(fichier)
    close(fichier)

    l = size(lines, 1)
    c = ceil(Int, length(lines[1]) / 3) # On divise par 3 car chaque nombre est séparé par une virgule et un espace

    x = fill(-1, l, c) # On initialise la matrice à -1 (cases vides)

    filled_cases = 0

    for i in 1:l
        for j in 1:c
            if lines[i][3*j-1] != ' '
                number = parse(Int, lines[i][3*j-1])
                x[i, j] = number
                filled_cases += 1
            end
        end
    end

    filling = round(filled_cases / (l * c) * 100, digits=1)

    return x, filling
end

function displayGrid(x::Matrix{Int})

    l = size(x, 1)
    c = size(x, 2)

    for i in 1:l
        for j in 1:c
            if x[i, j] == 1
                print("□ ")
            elseif x[i, j] == 0
                print("■ ")
            else
                print(". ")
            end
        end
        println()
    end
end

function displaySolution(x::Matrix{Int})

    l = size(x, 1)
    c = size(x, 2)

    for i in 1:l
        for j in 1:c
            if x[i, j] == 1
                print("□ ")
            else
                print("■ ")
            end
        end
        println()
    end

end