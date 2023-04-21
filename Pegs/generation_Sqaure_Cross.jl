include("resolution.jl")

function displaySolution(A::Array{Int64,3})

    n = size(A, 1)
    l = size(A, 2)
    c = size(A, 3)

    for s in 1:n
        println("Etape ", s, " :")
        for i in 1:l
            for j in 1:c
                if A[s, i, j] == 1
                    print("  ")
                elseif A[s, i, j] == 2
                    print("□ ")
                elseif A[s, i, j] == 3
                    print("■ ")
                end
            end
            println()
        end
        println()
    end
end

#generetaion if an square instance 
function genreationSquareInstance(l::Int64, c::Int64, p::Float64, path::String = "null")
    G = fill(1, 1, l, c)
    index = 0
    while (index==0) || (cplexSolve(Matrix{Int}(G[1,:,:]))==-1)
        index += 1
        G = fill(1, 1, l, c)
        for i in 1:l
            for j in 1:c
                if rand() < p
                    G[1, i, j] = 3
                else
                    G[1, i, j] = 2
                end
            end
        end
    end

    if path != "null"
        touch(path)
        file = open(path, "w")
        for i in 1:l
            for j in 1:c
                if G[1, i, j] == 2
                    write(file, "  ")
                elseif G[1, i, j] == 3
                    write(file, "■ ")
                end
            end
            write(file, "\n")
        end
        close(file)
    end
    return G , index
end

for i in 1:3
    G , index  = genreationSquareInstance(5, 4, 0.8)
    displaySolution(G) 
    println(index)
end

G , index  = genreationSquareInstance(5, 4, 0.8, "/data/TEST.txt")

#generetaion if an cross instance