## Step 0: Activate environment
using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()
Pkg.update()
Pkg.add("Ipopt")
Pkg.add("HiGHS")
Pkg.add("Juniper")
Pkg.add("PowerModels")
Pkg.add("PowerModelsACDC")
Pkg.add("JuMP")
Pkg.add("StatsPlots")
Pkg.add("Plots") # if Plots package not added yet, for plotting results

using PowerModels, PowerModelsACDC, Ipopt, JuMP, HiGHS, Juniper
using StatsPlots, Plots

# Define solver
ipopt = optimizer_with_attributes(Ipopt.Optimizer)
highs = optimizer_with_attributes(HiGHS.Optimizer)
juniper = optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => ipopt, "mip_solver" => highs)

########################
##### Step 1: Import the grid data and initialize the JuMP model
# Select the MATPOWER case file
path = pwd()
case_file_ac = joinpath(path, "opf_ac", "test_cases", "case67_investment_ac.m")
case_file_acdc = joinpath(path, "opf_acdc", "test_cases", "case67_investment_dc.m")
#case_file_acdc_tnep = joinpath(path, "tnep_acdc", "test_cases", "case67_investment_dc.m")

# For convenience, use the parser of Powermodels to convert the MATPOWER format file to a Julia dictionary
data_ac = PowerModels.parse_file(case_file_ac)
data_acdc = PowerModels.parse_file(case_file_acdc)
#data_acdc_tnep = PowerModels.parse_file(case_file_acdc_tnep)

# Initialize the JuMP model (an empty JuMP model) with defined solver
m_ac = Model(ipopt)
m_acdc = Model(ipopt)
#m_acdc_tnep = Model(juniper)
#m_acdc_tnep_exercise = Model(juniper)

########################
##### Step 2: create the JuMP model & pass data to model
include(joinpath(path, "opf_ac", "init_model.jl")) # Define functions define_sets! and process_parameters!
define_sets!(m_ac, data_ac) # Pass the sets to the JuMP model
process_parameters!(m_ac, data_ac) # Pass the parameters to the JuMP model

include(joinpath(path, "opf_acdc", "init_model.jl"))# Define functions define_sets! and process_parameters!
define_sets!(m_acdc, data_acdc) # Pass the sets to the JuMP model
process_parameters!(m_acdc, data_acdc) # Pass the parameters to the JuMP model

# Exercise: Adding candidates for TNEP problem #
#=
data_acdc_tnep["branchdc_cand"] = Dict{String, Any}() # Initialize the dictionary for DC branch candidates
data_acdc_tnep["convdc_cand"] = Dict{String, Any}() # Initialize the dictionary for DC converter candidates

include(joinpath(path, "tnep_acdc", "add_candidates.jl")) # Define functions add_dc_branch_cand! and add_dc_converter_cand! to add candidates to the grid
add_converter_candidate!(data_acdc_tnep, 3, 3, 1000.0, 1.0; zone = nothing, islcc = 0, conv_id = 1, status = 1)
add_converter_candidate!(data_acdc_tnep, 8, 8, 1000.0, 1.0; zone = nothing, islcc = 0, conv_id = 2, status = 1)
add_dc_branch_cand!(data_acdc_tnep, 3, 8, 1000.0, 1.0; status = 1, r = 0.1, branch_id = 1)

# Including functions for the exercise
include(joinpath(path, "tnep_acdc", "init_model.jl"))# Define functions define_sets! and process_parameters!
define_sets!(m_acdc_tnep_exercise, data_acdc_tnep) # Pass the sets to the JuMP model
process_parameters!(m_acdc_tnep_exercise, data_acdc_tnep) # Pass the parameters to the JuMP model

include(joinpath(path, "tnep_acdc", "init_model.jl"))# Define functions define_sets! and process_parameters!
define_sets!(m_acdc_tnep, data_acdc_tnep) # Pass the sets to the JuMP model
process_parameters!(m_acdc_tnep, data_acdc_tnep) # Pass the parameters to the JuMP model
=#

########################
##### Step 3: Build the model
include(joinpath(path, "opf_ac", "build_ac_opf.jl")) # Define build_ac_opf_acdc! function
build_ac_opf!(m_ac) # Pass the model to the build_ac_opf_acdc! function
include(joinpath(path, "opf_acdc","build_ac_opf_acdc.jl")) # Define build_ac_opf_acdc! function
build_ac_opf_acdc!(m_acdc) # Pass the model to the build_ac_opf_acdc! function

# Exercise: Build the TNEP model 
# You can find the exercise in include(joinpath(path, "tnep_acdc","build_ac_tnep_acdc_exercise.jl"))
# The solutions are in include(joinpath(path, "tnep_acdc","build_ac_tnep_acdc.jl")) # Define build_ac_opf_acdc! function

#build_ac_tnep_acdc_exercise!(m_acdc_tnep) # Build the AC TNEP part in the ACDC model from the exercise
#build_ac_tnep_acdc!(m_acdc_tnep) # Build the AC TNEP part in the ACDC model

########################
##### Step 4: Solve the model
optimize!(m_ac) # Solve the model
result_pm = PowerModels.solve_opf(data_ac, ACPPowerModel, ipopt) # Solve using PowerModels for verification

optimize!(m_acdc) # Solve the model

#optimize!(m_acdc_tnep_exercise) # Solve the model
#optimize!(m_acdc_tnep) # Solve the model

########################
##### Step 5: Analyze the results
# Compare the objective functions of AC and AC/DC OPF
println("objective ac grid" => objective_value(m_ac))
println("objective acdc grid" => objective_value(m_acdc)) 
println("ΔCost ac - acdc grid" => (objective_value(m_ac) - objective_value(m_acdc))) # Compare the objective values

#=
println("objective ac grid" => objective_value(m_ac))
println("objective acdc grid" => objective_value(m_acdc)) 
println("ΔCost ac - acdc grid" => (objective_value(m_ac) - objective_value(m_acdc))) # Compare the objective values
println("objective tnep acdc grid" => objective_value(m_acdc_tnep)) 
println("ΔCost acdc grid - tnep acdc grid" => (objective_value(m_acdc) - objective_value(m_acdc_tnep))) # Compare the objective values")

println("objective tnep acdc grid" => objective_value(m_acdc_tnep_exercise)) 
println("ΔCost acdc grid - tnep acdc grid" => (objective_value(m_acdc) - objective_value(m_acdc_tnep_exercise))) # Compare the objective values")
=#

# Creating a dictionary to analyze the results
include(joinpath(path, "src", "results_functions.jl"))# Define functions to plot results

result_ac_dict = create_results_dictionary(m_ac,data_ac)
result_ac_dc_dict = create_results_dictionary(m_acdc,data_acdc)
#result_ac_dc_tnep_dict = create_results_dictionary(m_acdc_tnep,data_acdc_tnep)
#result_ac_dc_tnep_dict = create_results_dictionary(m_acdc_tnep_exercise,data_acdc_tnep)

# Plotting results
ac_branches_plot = compare_branch_utilization(data_acdc, result_ac_dict, result_ac_dc_dict, "AC OPF", "ACDC OPF",length(data_acdc["branch"]))
gen_plot = compare_gen_setpoints(data_acdc, result_ac_dict, result_ac_dc_dict, "AC OPF", "ACDC OPF",length(data_acdc["gen"]))

for (g_id,g) in data_ac["gen"]
    println("Gen $(g_id), connected to bus $(g["gen_bus"]): generation cost = $(data_ac["gen"][g_id]["cost"][1]/100) €/MWh")
end

#dc_branches_plot = compare_DC_branch_utilization(data_acdc, result_ac_dc_dict, result_ac_dc_tnep_dict, "ACDC OPF", "ACDC TNEP")
#ac_dc_converters_plot = compare_converter_setpoints(data_acdc, data_acdc_tnep, result_ac_dc_dict, result_ac_dc_tnep_dict, "ACDC OPF", "ACDC TNEP")


#Saving figures
savefig(ac_branches_plot,joinpath(path, "results", "compare_ac_branch_utilization_ac_acdc.png"))
#savefig(dc_branches_plot,joinpath(path, "results", "compare_branch_utilization_ac_acdc.png"))
