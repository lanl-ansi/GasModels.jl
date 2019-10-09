# TODO add references to different models docstrings
"MINLP models"
abstract type AbstractMINLPModel <: AbstractGasModel end


"MIP models"
abstract type AbstractMIPModel <: AbstractGasModel end


"MISOCP models"
abstract type AbstractMISOCPModel <: AbstractGasModel end


"NLP models"
abstract type AbstractNLPModel <: AbstractGasModel end


"LP models"
abstract type AbstractLPModel <: AbstractGasModel end


"LP Model Type"
mutable struct LPGasModel <: AbstractLPModel @gm_fields end


"MIP Model Type"
mutable struct MIPGasModel <: AbstractMIPModel @gm_fields end


"NLP Model Type"
mutable struct NLPGasModel <: AbstractNLPModel @gm_fields end


"MISOCP Model Type"
mutable struct MISOCPGasModel <: AbstractMISOCPModel @gm_fields end


"MINLP Model Type"
mutable struct MINLPGasModel <: AbstractMINLPModel @gm_fields end


"Union of MI Models"
AbstractMIModels = Union{AbstractMISOCPModel, AbstractMINLPModel}