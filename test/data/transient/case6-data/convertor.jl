using Dates 
using DelimitedFiles

start_dt = DateTime(2020, 1, 1, 0, 0, 0)
time_pts = readdlm("input_ts_tpts.csv")

dt = start_dt .+ Millisecond.(round.(time_pts * 3600.0 * 1E3, digits=2))

@info "writing tpts into dates file"
open("time_series.csv", "w") do io 
    writedlm(io, dt)
end 

