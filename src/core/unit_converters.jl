psi_to_pascal(psi) = psi * 6894.75729
pascal_to_psi(pascal) = pascal / 6894.75729
km_to_m(km) = km * 1000.0 
m_to_km(m) = m / 1000.0 
get_universal_R() = 8.314
get_universal_R(data::Dict{String, Any}) = get(data, "R", get_universal_R())
get_gas_specific_gravity(data::Dict{String, Any}) = get(data, "gas_specific_gravity", 0.6)
get_temperature(data::Dict{String, Any}) = get(data, "temperature", 288.7060)
get_sound_speed(data::Dict{String, Any}) = get(data, "sound_speed", 371.6643)
get_molecular_mass_of_air() = 0.02896
get_one_atm_in_pascal() = 101.325 
get_one_atm_in_psi() = pascal_to_psi(101.325)

function get_mmscfd_to_kgps_conversion_factor(data::Dict{String, Any})::Number 
    atm = get_one_atm_in_pascal()
    R = get_universal_R(data)
    T = get_temperature(data)
    return 1000.0 * 0.02832 / 86400.0 * (atm / (R * T) * 1e6) * get_gas_specific_gravity() * get_molecular_mass_of_air()
end 

get_kgps_to_mmscfd_conversion_factor(data::Dict{String, Any})::Number = 1/get_mmscfd_to_kgps_conversion_factor(data)

hp_to_watts(hp) = hp * 745.7 
watts_to_hp(watts) = watts / 745.7
miles_to_m(miles) = miles * 1609.64
m_to_miles(m) = m / 1609.64
inches_to_m(inches) = inches * 0.0254
m_to_inches(m) = m / 0.0254
