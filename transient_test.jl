using JuMP, Ipopt, GasModels
ipopt_solver = JuMP.optimizer_with_attributes(Ipopt.Optimizer, "acceptable_tol" => 1e-3)

function main()
 #   mn_data = GasModels.parse_files("test/data/matgas/case-6.m", "test/data/transient/time-series-case-6b.csv", 
 #       spatial_discretization=10000.0, additional_time=0.0);
 mn_data = GasModels.parse_files("/Users/kaarthik/Downloads/WebDownloads/KernRiver_mod/KernRiver.m", "/Users/kaarthik/Downloads/WebDownloads/KernRiver_mod/Kern_TransientTimeSeries_cubicsplineinterpolation.csv", spatial_discretization=1e4);

    return mn_data
end
