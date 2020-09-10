# TODO add references to different models docstrings
"DWP models"
abstract type AbstractDWPModel <: AbstractGasModel end


"LRDWP models"
abstract type AbstractLRDWPModel <: AbstractGasModel end


"CRDWP models"
abstract type AbstractCRDWPModel <: AbstractGasModel end


"WP models"
abstract type AbstractWPModel <: AbstractGasModel end


"LRWP models"
abstract type AbstractLRWPModel <: AbstractGasModel end


"LRWP Model Type"
mutable struct LRWPGasModel <: AbstractLRWPModel @gm_fields end


"LRDWP Model Type"
mutable struct LRDWPGasModel <: AbstractLRDWPModel @gm_fields end


"WP Model Type"
mutable struct WPGasModel <: AbstractWPModel @gm_fields end


"CRDWP Model Type"
mutable struct CRDWPGasModel <: AbstractCRDWPModel @gm_fields end


"DWP Model Type"
mutable struct DWPGasModel <: AbstractDWPModel @gm_fields end


"Union of MI Models"
AbstractMIModels = Union{AbstractCRDWPModel,AbstractDWPModel,AbstractLRDWPModel}
