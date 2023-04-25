include("resolution.jl")
include("generation.jl")

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

    # Le taux de remplissage initial de la grille
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

    y = cplexSolve(x)

    if y == -1
        println("Pas de solution")
        return
    end

    for i in 1:l
        for j in 1:c
            if y[i, j] == 1
                print("□ ")
            else
                print("■ ")
            end
        end
        println()
    end

end

function resultsArray(path_read::String, path_write::String)

    """
        Cette fonction effectue une simulation complète en générant plusieurs datasets et en les résolvant.
        Elle écrit ensuite les résultats dans les fichiers text : tab1.txt (pour la phase 1) et tab2.txt (pour la phase 2).

        Cette fonction peut mettre beaucoup de temps à s'exécuter.
    """

    #### PHASE 1 : On fixe la taille de la grille et on fait varier le taux de remplissage

    file_w = open(joinpath(path_write, "tab1.txt"), "w")
    write(file_w, "Dans ce fichier, on fixe la taille de la grille et on varie le taux de remplissage dans chaque tableau\n\n\n")
    close(file_w)

    sizes = [10, 50, 90]
    nb_samples = 15

    for size in sizes

        generateDataSet1(nb_samples, size)
        solveDataSet("data")

        file_w = open(joinpath(path_write, "tab1.txt"), "a")
        write(file_w, "-------------------------------------------------------------------------------\n")
        write(file_w, "Taille de la grille : $size x $size\n\n")
        write(file_w, "Taux de remplissage initial     ")
        write(file_w, "Temps d'execution du cplex      ")
        write(file_w, "Solution trouvée                \n")

        for k in 1:nb_samples

            file_r = open(joinpath(path_read, "cplex_$k.txt"))
            lines = readlines(file_r)[1:4]
            close(file_r)

            write(file_w, lpad(lines[2][45:end], 27))
            write(file_w, lpad(lines[3][13:end], 31))
            write(file_w, lpad(lines[4][13:end], 22))
            write(file_w, "\n")
        end

        write(file_w, "\n\n")
        close(file_w)
    end



    #### PHASE 2 : On fixe le taux de remplissage et fait on varier la taille de la grille

    file_w = open(joinpath(path_write, "tab2.txt"), "w")
    write(file_w, "Dans ce fichier, on fixe le taux de remplissage et on fait varier la taille de la grille dans chaque tableau\n\n\n")
    close(file_w)

    fillings = [20.0, 50.0, 70.0]
    nb_samples = 15

    for filling in fillings
        println("filling : ", filling)

        generateDataSet2(nb_samples, 10, 150, filling)
        solveDataSet("data")

        file_w = open(joinpath(path_write, "tab2.txt"), "a")
        write(file_w, "-------------------------------------------------------------------------------\n")
        write(file_w, "Taux de remplissage initial : $filling %\n\n")
        write(file_w, "Taille de la grille     ")
        write(file_w, "Temps d'execution du cplex     ")
        write(file_w, "Solution trouvée\n")

        for k in 1:nb_samples

            file_r = open(joinpath(path_read, "cplex_$k.txt"))
            lines = readlines(file_r)[1:4]
            close(file_r)

            write(file_w, lpad(lines[1][18:end], 19))
            write(file_w, lpad(lines[3][13:end], 31))
            write(file_w, lpad(lines[4][13:end], 21))
            write(file_w, "\n")
        end

        write(file_w, "\n\n")
        close(file_w)

    end

    println("done")
end


###### MAIN ######


# generateDataSet1(5, 10)
# generateDataSet2(5, 10, 200, 10.0)
# solveDataSet("data")

resultsArray("res/cplex", "res/tableaux")