include("resolution.jl")
include("generation.jl")

function readInputFile(path::String)

    fichier = open(path)
    lines = readlines(fichier)
    close(fichier)

    l = size(lines, 1)
    c = ceil(Int, length(lines[1]) / 3)

    x = fill(1, l, c)


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


function displaySolution(A::Array{Int64,3})

    l = size(A, 1)
    c = size(A, 2)
    n = size(A, 3)

    for s in 1:n
        println("Etape ", s, " :")
        for i in 1:l
            for j in 1:c
                if A[i, j, s] == 1
                    print("  ")
                elseif A[i, j, s] == 2
                    print("□ ")
                elseif A[i, j, s] == 3
                    print("■ ")
                end
            end
            println()
        end
        println()
    end
end

solveDataSet("data")