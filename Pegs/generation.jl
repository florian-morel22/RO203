function solveDataSet(path::String)

    for i in 1:size(readdir(path), 1) # enumerate ne fonctionne pas car ça lit les fichiers dans un ordre aléatoire

        G = readInputFile(joinpath(path, "instance_$i.txt"))
        out = @timed cplexSolve(G)
        x = out.value

        l = size(x, 1)
        c = size(x, 2)
        n = size(x, 3)
        text = ""

        if x != -1
            for s in 1:n
                text = string(text, "Etape ", string(s), " : \n")
                for i in 1:l
                    for j in 1:c
                        if x[i, j, s] == 1
                            text = string(text, "  ")
                        elseif x[i, j, s] == 2
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