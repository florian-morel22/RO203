using JuMP
using CPLEX
using Random

function generateInstance(l::Int, c::Int, k::Int)

    if rem(l, 2) == 1 || rem(c, 2) == 1
        println("Les dimensions doivent être paires.")
        return -1
    end

    if k > l * c
        println("Le nombre de cases à colorier est trop grand.")
        return -1
    end

    # Une couleur de case ne peut pas recouvrir plus de la moitié de la grille
    if k > l * c / 2
        nb_blancs = convert(Int, round(rand(k-l*c/2:l*c/2)))
        nb_noirs = k - nb_blancs
    else
        nb_blancs = convert(Int, round(rand(1:k)))
        nb_noirs = k - nb_blancs
    end



    model = Model(CPLEX.Optimizer)

    @variable(model, x[1:l, 1:c, 1:3], Bin)

    @objective(model, Max, 1)

    # Une unique valeur par case
    @constraint(model, [i in 1:l, j in 1:c], sum(x[i, j, k] for k in 1:3) == 1)

    # Le bon nombre de cases blanches, noires et vides
    @constraint(model, sum(x[i, j, 2] for i in 1:l, j in 1:c) == nb_blancs)
    @constraint(model, sum(x[i, j, 3] for i in 1:l, j in 1:c) == nb_noirs)
    @constraint(model, sum(x[i, j, 1] for i in 1:l, j in 1:c) == l * c - k) # peut être pas utile ?

    @constraint(model, [i in 1:l, j in 1:(c-2)], sum(x[i, j+k, 2] for k in 0:2) <= 2) # Pas plus de 2 cases noires consécutives sur une colonne
    @constraint(model, [i in 1:l, j in 1:(c-2)], sum(x[i, j+k, 3] for k in 0:2) <= 2) # Pas plus de 2 cases blanches consécutives sur une colonne

    @constraint(model, [i in 1:(l-2), j in 1:c], sum(x[i+k, j, 2] for k in 0:2) <= 2) # Pas plus de 2 cases noires consécutives sur une ligne
    @constraint(model, [i in 1:(l-2), j in 1:c], sum(x[i+k, j, 3] for k in 0:2) <= 2) # Pas plus de 2 cases blanches consécutives sur une ligne

    set_silent(model)
    optimize!(model)

    res = fill(-1, l, c)

    if primal_status(model) == MOI.FEASIBLE_POINT
        for i in 1:l
            for j in 1:c
                if value.(x[i, j, 2]) == 1
                    res[i, j] = 0
                elseif value.(x[i, j, 3]) == 1
                    res[i, j] = 1
                end
            end
        end
        return round.(Int, res)
    else
        println("Aucun génération trouvée.")
        return -1
    end
end

function generateDataSet_v1(n::Int, taille_min::Int, taille_max::Int)

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

        x, y = -1, -1
        l, c, color_fixed = 0, 0, -1

        while y == -1
            l = convert(Int, rand(taille_min:taille_max))
            c = convert(Int, rand(taille_min:taille_max))
            color_fixed = convert(Int, rand(1:l*c-1))
            x = generateInstance(l, c, color_fixed)
            if x != -1
                y = cplexSolve(x)
            end
        end

        text = ""

        if x != -1
            for i in 1:l
                for j in 1:c
                    if x[i, j] == 0
                        text = string(text, " 0,")
                    elseif x[i, j] == 1
                        text = string(text, " 1,")
                    else
                        text = string(text, "  ,")
                    end
                end
                text = chop(text, head=0, tail=1)
                if i != l
                    text = string(text, "\n")
                end
            end
        end
        file = open("data/instance_$instance.txt", "w")
        write(file, text)
        close(file)
    end
end

function generateDataSet1(n::Int, size::Int)

    if n < 1
        println("Le nombre de grilles à générer doit être supérieur ou égal à 1.")
        return -1
    end

    for instance in 1:n

        x, y = -1, -1
        l, c, color_fixed = size, size, -1

        while y == -1
            color_fixed = convert(Int, rand(1:l*c*0.2))
            x = generateInstance(l, c, color_fixed)
            if x != -1
                y = cplexSolve(x)
            end
        end

        #Selection of cases to remove (between 1% and 99% of the total number of cases)
        nb_cases_to_remove = convert(Int, floor(instance / n * (l * c - 1)))
        # nb_cases_to_remove = convert(Int, rand(1:l*c-1)) # use for random number of cases to remove
        ind_alea = randperm(l * c)
        ind_cases_to_remove = ind_alea[1:nb_cases_to_remove]


        text = ""

        if x != -1
            for i in 1:l
                for j in 1:c
                    if i * j in ind_cases_to_remove
                        text = string(text, "  ,")
                    elseif y[i, j] == 0
                        text = string(text, " 0,")
                    elseif y[i, j] == 1
                        text = string(text, " 1,")
                    end
                end
                text = chop(text, head=0, tail=1)
                if i != l
                    text = string(text, "\n")
                end
            end
        end
        file = open("data/instance_$instance.txt", "w")
        write(file, text)
        close(file)
    end
end

function generateDataSet2(n::Int, size_min::Int, size_max::Int, perc_filling::Float64)

    if n < 1
        println("Le nombre de grilles à générer doit être supérieur ou égal à 1.")
        return -1
    end

    for instance in 1:n

        x, y = -1, -1
        color_fixed = -1

        l = convert(Int, floor((size_min + (instance - 1) * (size_max - size_min) / (n - 1)) / 2) * 2)
        c = l

        while y == -1
            color_fixed = convert(Int, rand(1:l*c*0.2))
            x = generateInstance(l, c, color_fixed)
            if x != -1
                y = cplexSolve(x)
            end
        end

        #Selection of cases to remove (between 1% and 99% of the total number of cases)
        nb_cases_to_remove = convert(Int, floor((100 - perc_filling) / 100 * (l * c - 1)))
        ind_alea = randperm(l * c)
        ind_cases_to_remove = ind_alea[1:nb_cases_to_remove]


        text = ""

        if x != -1
            for i in 1:l
                for j in 1:c
                    if i * j in ind_cases_to_remove
                        text = string(text, "  ,")
                    elseif y[i, j] == 0
                        text = string(text, " 0,")
                    elseif y[i, j] == 1
                        text = string(text, " 1,")
                    end
                end
                text = chop(text, head=0, tail=1)
                if i != l
                    text = string(text, "\n")
                end
            end
        end
        file = open("data/instance_$instance.txt", "w")
        write(file, text)
        close(file)
    end
end

function solveDataSet(path::String)

    for i in 1:size(readdir(path), 1) # enumerate ne fonctionne pas car ça lit les fichiers dans un ordre aléatoire

        G, filling = readInputFile(joinpath(path, "instance_$i.txt"))
        out = @timed cplexSolve(G)
        x = out.value

        l = size(x, 1)
        c = size(x, 2)
        text = ""

        if x != -1
            for i in 1:l
                for j in 1:c
                    if x[i, j] == 0
                        text = string(text, " 0,")
                    elseif x[i, j] == 1
                        text = string(text, " 1,")
                    else
                        text = string(text, "  ,")
                    end
                end
                text = chop(text, head=0, tail=1)
                if i != l
                    text = string(text, "\n")
                end
            end

            text = string(text, "\n\n")

            for i in 1:l
                for j in 1:c
                    if x[i, j] == 0
                        text = string(text, " ■")
                    elseif x[i, j] == 1
                        text = string(text, " □")
                    end
                end

                if i != l
                    text = string(text, "\n")
                end
            end
        end
        file = open("res/cplex/cplex_$i.txt", "w")
        write(file, "taille instance = ", string(l), " x ", string(c), "\n")
        write(file, "pourcentage de cases initialement remplies = ", string(filling), " %\n")
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
