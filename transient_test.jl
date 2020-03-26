using JuMP, Ipopt, GasModels
ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer)

function main()
    mn_data = GasModels.parse_files("test/data/matgas/case-6.m", "test/data/transient/case6-data/time_series_new.csv", 
        spatial_discretization=1e6, time_step=43200.0, additional_time=0.0);

    return mn_data
end
