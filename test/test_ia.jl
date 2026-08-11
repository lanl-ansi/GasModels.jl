#!/usr/bin/env julia
"""
Standalone test runner for Inner Approximation tests.
Run with: julia --project=. test/test_ia.jl
"""

using GasModels
using Test
using JSON
using Printf
using SparseArrays
using LinearAlgebra

# Include common test utilities if needed
include("common.jl")

println("=" ^ 60)
println("Running Inner Approximation Tests")
println("=" ^ 60)

# Set verbose mode to see test details
ENV["JULIA_TEST_VERBOSE"] = "true"

# Run IA tests
include("ia.jl")

println("\n" * "=" ^ 60)
println("✅ All IA tests completed!")
println("=" ^ 60)
