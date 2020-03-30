using JuMP, Ipopt, GasModels
ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer)

function main()
    mn_data = GasModels.parse_files("test/data/matgas/case-6.m", "test/data/transient/time-series-case-6b.csv", 
        spatial_discretization=1e4, additional_time=0.0);

    return mn_data
end
