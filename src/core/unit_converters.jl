@inline psi_to_pascal(psi) = psi * 6894.75729
@inline pascal_to_psi(pascal) = pascal / 6894.75729
@inline km_to_m(km) = km * 1000.0 
@inline m_to_km(m) = m / 1000.0 
@inline hp_to_watts(hp) = hp * 745.7 
@inline watts_to_hp(watts) = watts / 745.7
@inline miles_to_m(miles) = miles * 1609.64
@inline m_to_miles(m) = m / 1609.64
@inline inches_to_m(inches) = inches * 0.0254
@inline m_to_inches(m) = m / 0.0254
@inline get_universal_R() = 8.314
@inline get_universal_R(data::Dict{String, Any}) = get(data, "R", get_universal_R())
@inline get_gas_specific_gravity(data::Dict{String, Any}) = get(data, "gas_specific_gravity", 0.6)
@inline get_temperature(data::Dict{String, Any}) = get(data, "temperature", 288.7060)
@inline get_sound_speed(data::Dict{String, Any}) = get(data, "sound_speed", 371.6643)
@inline get_molecular_mass_of_air() = 0.02896
@inline get_one_atm_in_pascal() = 101325.0
@inline get_one_atm_in_psi() = pascal_to_psi(101325)

"""
Convering mmsfcd to kgps (standard volumetric flow rate to mass flow rate)
"""

function get_mmscfd_to_kgps_conversion_factor(data::Dict{String, Any})::Number 
    standard_pressure = get_one_atm_in_pascal()
    R = get_universal_R(data)
    standard_temperature = get_temperature(data)
    cubic_ft_to_cubic_m = 0.02832
    volumetric_flow_rate_in_si = cubic_ft_to_cubic_m * 1e6 / 86400.0
    molecular_mass_of_gas = get_gas_specific_gravity(data) * get_molecular_mass_of_air()
    density_at_standard_conditions = standard_pressure * molecular_mass_of_gas / standard_temperature / R 
    return density_at_standard_conditions * volumetric_flow_rate_in_si 
end 

get_kgps_to_mmscfd_conversion_factor(data::Dict{String, Any})::Number = 1/get_mmscfd_to_kgps_conversion_factor(data)
