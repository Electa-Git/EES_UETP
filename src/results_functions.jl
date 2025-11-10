function create_results_dictionary(model,data)
    results = Dict{String, Any}()
    results["status"] = termination_status(model)
    results["objective"] = objective_value(model)
    results["solution"] = Dict{String, Any}()
    results["solution"]["bus"] = Dict{String, Any}()
    results["solution"]["branch"] = Dict{String, Any}()
    results["solution"]["gen"] = Dict{String, Any}()

    if haskey(data,"busdc")
        results["solution"]["busdc"] = Dict{String, Any}()
        results["solution"]["branchdc"] = Dict{String, Any}()
        results["solution"]["convdc"] = Dict{String, Any}()
    end

    for (g_id,g) in data["gen"] 
        results["solution"]["gen"][g_id] = Dict{String, Any}()
        active_power = value(model.ext[:variables][:pg])
        reactive_power = value(model.ext[:variables][:qg])
        results["solution"]["gen"][g_id]["pg"] = active_power[g_id]
        results["solution"]["gen"][g_id]["qg"] = reactive_power[g_id]
    end

    for (b_id,b) in data["bus"] 
        results["solution"]["bus"][b_id] = Dict{String, Any}()
        voltage_magnitudes = value(model.ext[:variables][:vm])
        voltage_angles = value(model.ext[:variables][:va])
        results["solution"]["bus"][b_id]["vm"] = voltage_magnitudes[b_id]
        results["solution"]["bus"][b_id]["va"] = voltage_angles[b_id]
    end

    for (d,e,f) in model.ext[:sets][:B_ac_fr]
        results["solution"]["branch"][d] = Dict{String, Any}()
        active_power = value(model.ext[:variables][:pb])
        results["solution"]["branch"][d]["pf"] = active_power[(d,e,f)]
        reactive_power = value(model.ext[:variables][:qb])
        results["solution"]["branch"][d]["qf"] = reactive_power[(d,e,f)]
    end
    for (d,f,e) in model.ext[:sets][:B_ac_to]
        active_power = value(model.ext[:variables][:pb])
        results["solution"]["branch"][d]["pt"] = active_power[(d,f,e)]
        reactive_power = value(model.ext[:variables][:qb])
        results["solution"]["branch"][d]["qt"] = reactive_power[(d,f,e)]
    end

    if haskey(data,"busdc")
        for (b_id,b) in data["busdc"] 
            results["solution"]["busdc"][b_id] = Dict{String, Any}()
            voltage_magnitudes = value(model.ext[:variables][:busdc_vm])
            results["solution"]["busdc"][b_id]["vm"] = voltage_magnitudes[b_id]
        end
        for (d,e,f) in model.ext[:sets][:BD_dc_fr]
            results["solution"]["branchdc"][d] = Dict{String, Any}()
            active_power = value(model.ext[:variables][:brdc_p])
            results["solution"]["branchdc"][d]["pf"] = active_power[(d,e,f)]
        end
        for (d,f,e) in model.ext[:sets][:BD_dc_to]
            active_power = value(model.ext[:variables][:brdc_p])
            results["solution"]["branchdc"][d]["pt"] = active_power[(d,f,e)]
        end
        for (cv_id,cv) in data["convdc"] 
            results["solution"]["convdc"][cv_id] = Dict{String, Any}()
            res_conv_p_ac = value(model.ext[:variables][:conv_p_ac])
            res_conv_q_ac = value(model.ext[:variables][:conv_q_ac])
            res_conv_p_dc = value(model.ext[:variables][:conv_p_dc])
            res_conv_p_ac_grid = value(model.ext[:variables][:conv_p_ac_grid])
            res_conv_q_ac_grid = value(model.ext[:variables][:conv_q_ac_grid])
            results["solution"]["convdc"][cv_id]["conv_p_ac"] = res_conv_p_ac[cv_id]
            results["solution"]["convdc"][cv_id]["conv_q_ac"] = res_conv_q_ac[cv_id]
            results["solution"]["convdc"][cv_id]["conv_p_dc"] = res_conv_p_dc[cv_id]
            results["solution"]["convdc"][cv_id]["conv_p_ac_grid"] = res_conv_p_ac_grid[cv_id]
            results["solution"]["convdc"][cv_id]["conv_q_ac_grid"] = res_conv_q_ac_grid[cv_id]
        end
        if haskey(data,"convdc_cand")
            results["solution"]["convdc_cand"] = Dict{String, Any}()
            for (cv_id,cv) in data["convdc_cand"] 
                results["solution"]["convdc_cand"][cv_id] = Dict{String, Any}()
                res_conv_p_ac_cand_bin = value(model.ext[:variables][:conv_p_cand_bin])
                res_conv_p_dc_cand = value(model.ext[:variables][:conv_p_dc_cand])
                res_conv_p_ac_cand = value(model.ext[:variables][:conv_p_ac_cand])
                res_conv_q_ac_cand = value(model.ext[:variables][:conv_q_ac_cand])
                results["solution"]["convdc_cand"][cv_id]["built"] = [cv_id]
                results["solution"]["convdc_cand"][cv_id]["built"] = res_conv_p_ac_cand_bin[cv_id]
                results["solution"]["convdc_cand"][cv_id]["conv_p_dc_cand"] = res_conv_p_dc_cand[cv_id]
                results["solution"]["convdc_cand"][cv_id]["conv_p_ac_cand"] = res_conv_p_ac_cand[cv_id]
                results["solution"]["convdc_cand"][cv_id]["conv_q_ac_cand"] = res_conv_q_ac_cand[cv_id]
            end
        end
        if haskey(data,"branchdc_cand")
            results["solution"]["branchdc_cand"] = Dict{String, Any}()
            for (d,e,f) in model.ext[:sets][:BD_dc_cand_fr]
                results["solution"]["branchdc_cand"][d] = Dict{String, Any}()
                res_brdc_p_cand_bin = value(model.ext[:variables][:brdc_p_cand_bin])
                res_brdc_p_cand = value(model.ext[:variables][:brdc_p_cand])
                results["solution"]["branchdc_cand"][d]["built"] = res_brdc_p_cand_bin[(d,e,f)]
                results["solution"]["branchdc_cand"][d]["brdc_p_cand"] = res_brdc_p_cand[(d,e,f)]
            end
        end
    end
    return results
end


function plot_AC_branch_utilization(data, result, label)
    br_utilization = [abs(result["solution"]["branch"]["$br_id"]["pf"])/data["branch"]["$br_id"]["rate_a"]*100 for br_id in 1:length(data["branch"])]
    
    sx = repeat(["$label"], inner = length(data["branch"]))
    number = collect(1:length(data["branch"]))

    groupedbar(number, br_utilization, group = sx, ylabel = "Branch utilization [%]", xlabel = "Branch number", xticks = 1:1:length(data["branch"]), yticks = 0:20:100, ylims = (0,101), xlims = (0.5,length(data["branch"])+0.5),
    title = "", bar_width = 0.7, color = [:grey70], xtickfont = 2)
end

function compare_branch_utilization(data, result_1, result_2, label_1, label_2, n_branches)
    br_utilization_1 = [abs(result_1["solution"]["branch"]["$br_id"]["pf"])/data["branch"]["$br_id"]["rate_a"]*100 for br_id in 1:n_branches]
    br_utilization_2 = [abs(result_2["solution"]["branch"]["$br_id"]["pf"])/data["branch"]["$br_id"]["rate_a"]*100 for br_id in 1:n_branches]
    
    sx = repeat(["$label_1","$label_2"], inner = n_branches)
    number = collect(1:n_branches)
    numbers = vcat(number, number)
    br_utilization = vcat(br_utilization_1, br_utilization_2)

    groupedbar(numbers, br_utilization, group = sx, ylabel = "Branch utilization [%]", xlabel = "AC branch number", xticks = 1:1:n_branches, yticks = 0:20:100, ylims = (0,101), xlims = (0.5,n_branches+0.5),
    title = "", bar_width = 0.7, color = [:grey40 :grey70], xtickfont = 3, grid = :none)
end

function compare_gen_setpoints(data, result_1, result_2, label_1, label_2, n_gens)
    gen_1 = [abs(result_1["solution"]["gen"]["$g_id"]["pg"])*100 for g_id in 1:n_gens]
    gen_2 = [abs(result_2["solution"]["gen"]["$g_id"]["pg"])*100 for g_id in 1:n_gens]
    
    sx = repeat(["$label_1","$label_2"], inner = n_gens)
    number = collect(1:n_gens)
    numbers = vcat(number, number)
    gen = vcat(gen_1, gen_2)

    groupedbar(numbers, gen, group = sx, ylabel = "Generation [MW]", xlabel = "Generator number", xticks = 1:1:n_gens, xlims = (0.5,n_gens+0.5),
    title = "", bar_width = 0.7, color = [:grey40 :grey70], xtickfont = 8, grid = :none)
end


function plot_DC_branch_utilization(data, result, label)
    br_utilization = [abs(result["solution"]["branchdc"]["$br_id"]["pf"])/(data["branchdc"]["$br_id"]["rateA"]/data["baseMVA"])*100 for br_id in 1:length(data["branchdc"])]
    
    sx = repeat(["$label"], inner = length(data["branchdc"]))
    number = collect(1:length(data["branchdc"]))

    groupedbar(number, br_utilization, group = sx, ylabel = "DC branch utilization [%]", xlabel = "DC branch number", xticks = 1:1:length(data["branchdc"]), yticks = 0:20:100, ylims = (0,101), xlims = (0.5,length(data["branchdc"])+0.5),
    title = "", bar_width = 0.7, color = [:grey70], xtickfont = 2, grid = :none)
end

function compare_DC_branch_utilization(data, result_1, result_2, label_1, label_2)
    br_utilization_1 = [abs(result_1["solution"]["branchdc"]["$br_id"]["pf"])/(data["branchdc"]["$br_id"]["rateA"]/data["baseMVA"])*100 for br_id in 1:length(data["branchdc"])]
    br_utilization_2 = [abs(result_2["solution"]["branchdc"]["$br_id"]["pf"])/(data["branchdc"]["$br_id"]["rateA"]/data["baseMVA"])*100 for br_id in 1:length(data["branchdc"])]
    
    sx = repeat(["$label_1","$label_2"], inner = length(data["branchdc"]))
    number = collect(1:length(data["branchdc"]))
    numbers = vcat(number, number)
    br_utilization = vcat(br_utilization_1, br_utilization_2)

    groupedbar(numbers, br_utilization, group = sx, ylabel = "DC branch utilization [%]", xlabel = "DC branch number", xticks = 1:1:length(data["branchdc"]), yticks = 0:20:100, ylims = (0,101), xlims = (0.5,length(data["branchdc"])+0.5),
    title = "", bar_width = 0.7, color = [:grey40 :grey70], xtickfont = 8, grid = :none)
end

function compare_converter_setpoints(data_1, data_2, result_1, result_2, label_1, label_2)
    cv_utilization_1 = [abs(result_1["solution"]["convdc"]["$br_id"]["conv_p_ac_grid"])/(data_1["convdc"]["$br_id"]["Pacmax"]/data_1["baseMVA"])*100 for br_id in 1:length(data_1["convdc"])]
    cv_utilization_2 = [abs(result_2["solution"]["convdc"]["$br_id"]["conv_p_ac_grid"])/(data_2["convdc"]["$br_id"]["Pacmax"]/data_2["baseMVA"])*100 for br_id in 1:length(data_2["convdc"])]
    for (br_id,br) in data_2["convdc_cand"]
        push!(cv_utilization_1, 0.0)
        push!(cv_utilization_2, abs(result_2["solution"]["convdc"]["$br_id"]["conv_p_ac_grid"])/(data_2["convdc_cand"]["$br_id"]["Pacrated"]/data_2["baseMVA"])*100)
    end

    sx = repeat(["$label_1","$label_2"], inner = length(cv_utilization_1))
    number = collect(1:length(cv_utilization_1))
    numbers = vcat(number, number)
    cv_utilization = vcat(cv_utilization_1, cv_utilization_2)

    #println(sum(cv_utilization_1[length(data_1["convdc"])]))
    #println(sum(cv_utilization_2[length(data_1["convdc"])]))


    xlabels = []
    for (cv_id,cv) in data_1["convdc"]
        push!(xlabels, "C$cv_id - Bus $(cv["busac_i"])")
    end
    for (cv_id,cv) in data_2["convdc_cand"]
        push!(xlabels, "Cand$cv_id - Bus $(cv["busac_i"])")
    end
    println(xlabels)

    groupedbar(numbers, cv_utilization, group = sx, ylabel = "Converter utilization [%]", xlabel = "DC converter", xticks = (1:1:length(cv_utilization_1),xlabels), yticks = 0:20:100, ylims = (0,101), xlims = (0.5,length(cv_utilization_1)+0.5),
    title = "", bar_width = 0.7, color = [:grey40 :grey70], xtickfont = 5, grid = :none)
end
