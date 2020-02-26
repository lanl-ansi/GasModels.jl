# old tools for working with GasModels internal data format
"A very simple model of computing resistance for resistors that is based on the Thorley model.  The are other more realistic models that could
be used.  See Physical and technical fundamentals of gas networks by Fugenschu et al. for an example"
function _calc_resistor_resistance_simple(ref::Dict{Symbol,Any}, pipe::Dict{String,Any})
    R          = ref[:R] #8.314 # universal gas constant
    z          = ref[:compressibility_factor]
    T          = ref[:temperature]
    m          = ref[:gas_molar_mass]
    lambda     = pipe["drag"]
    D          = pipe["diameter"]
    L          = pipe["length"]

    a_sqr = z * (R/m) * T
    A     = (pi*D^2) / 4 # cross sectional area

    resistance = ( (D * A^2) / (lambda * L * a_sqr)) * (ref[:baseP]^2 / ref[:baseQ]^2) # second half is the non-dimensionalization
    return resistance
end


"Calculate the pipe resistance using the method described in De Wolf and Smeers. The Gas Transmission Problem Solved by an Extension of the Simplex Algorithm. Management Science. 46 (11) 1454-1465, 2000
 This function assumes that diameters are in mm, lengths are in km, volumetric flow is in 10^6 m^3/day, and pressure is in bars"
function _calc_pipe_resistance_smeers(ref::Dict{Symbol,Any},pipe::Dict{String,Any})
    c          = 96.074830e-15    # Gas relative constant
    L          = pipe["length"] / 1000.0  # length of the pipe [km]
    D          = pipe["diameter"] * 1000.0 # interior diameter of the pipe [mm]
    T          = 281.15           # gas temperature [K]
    epsilon    = 0.05       # absolute rugosity of pipe [mm]
    delta      = 0.6106       # density of the gas relative to air [-]
    z          = 0.8                      # gas compressibility factor [-]
    B          = 3.6*D/epsilon
    lambda     = 1/((2*log10(B))^2)
    resistance = c*(D^5/(lambda*z*T*L*delta));

    return resistance
end


"checks pipe diameters and friction factors"
function check_pipe_parameters(data::Dict{String,<:Any})
    for (i, pipe) in get(data, "pipe", Dict())
        if get(data, "is_si_units", false) == true
            if pipe["diameter"] < 0.1 || pipe["diameter"] > 1.6
                if pipe["diameter"] < 0.0
                    Memento.error(_LOGGER, "diameter of pipe $i is < 0 m")
                else
                    Memento.warn(_LOGGER, "diameter $(pipe["diameter"]) m of pipe $i is unrealistic")
                end
            end
        end

        if get(data, "is_english_units", false) == true
            if inches_to_m(pipe["diameter"]) < 0.1 || inches_to_m(pipe["diameter"]) > 1.6
                if inches_to_m(pipe["diameter"]) < 0.0
                    Memento.error(_LOGGER, "diameter of pipe $i is < 0.0 m")
                else
                    Memento.warn(_LOGGER, "diameter $(inches_to_m(pipe["diameter"])) m of pipe $i is unrealistic")
                end
            end
        end

        if pipe["friction_factor"] < 0.0005 || pipe["friction_factor"] > 0.1
            if pipe["friction_factor"] < 0
                Memento.error(_LOGGER, "friction factor of pipe $i is < 0")
            else
                Memento.warn(_LOGGER, "friction factor $(pipe["friction_factor"]) of pipe $i is unrealistic")
            end
        end
    end
end
