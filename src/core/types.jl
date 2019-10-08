
abstract type AbstractMINLPModel <: AbstractGasModel end

abstract type AbstractMIPModel <: AbstractGasModel end

abstract type AbstractMISOCPModel <: AbstractGasModel end

abstract type AbstractNLPModel <: AbstractGasModel end

abstract type AbstractLPModel <: AbstractGasModel end

mutable struct LPGasModel <: AbstractLPModel @gm_fields end

mutable struct MIPGasModel <: AbstractMIPModel @gm_fields end

mutable struct NLPGasModel <: AbstractNLPModel @gm_fields end

mutable struct MISOCPGasModel <: AbstractMISOCPModel @gm_fields end

mutable struct MINLPGasModel <: AbstractMINLPModel @gm_fields end

AbstractMIModels = Union{AbstractMISOCPModel, AbstractMINLPModel}