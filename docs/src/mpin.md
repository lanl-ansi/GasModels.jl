# Explaining Solutions

GasModels contains a `MathProgIncidence` extension to help explain
solutions of optimal gas flow problems. This documentation page
provides an example demonstrating how this tool can be used.

## Step 0: Imports
This tutorial depends on GasModels, MathProgIncidence, JuMP, and Ipopt.
```julia
import GasModels, MathProgIncidence as MPIN, JuMP, Ipopt
```

## Step 1: Load a test model
This tutorial uses an optimal gas flow problem derived from the
GasLib-11 network.

Here is the matgas file for the network:
```matlab
function mgc = gaslib11

%% required global data
mgc.gas_specific_gravity         = 0.6     ; % dimensionless
mgc.specific_heat_capacity_ratio = 1.4     ; % dimensionless
mgc.temperature                  = 288.706 ; % K
mgc.compressibility_factor       = 1       ; % dimensionless
mgc.units                        = 'si'    ;
%% optional global data
mgc.is_per_unit        = 0     ;
mgc.base_length        = 1000  ; % m
mgc.base_pressure      = 1.0e6 ; % Pa
mgc.base_flow          = 100   ; % kg/s
mgc.economic_weighting = 1     ; % dimensionless

%% junction data
% id p_min p_max p_nominal junction_type status pipeline_name edi_id lat lon
mgc.junction = [
4  3.0e6 8.0e6 5.5e6 0 1 '4.0'  '4.0'  0.0     0.4   
1  3.0e6 8.0e6 5.5e6 0 1 '1.0'  '1.0'  0.0     0.2   
2  3.0e6 8.0e6 5.5e6 0 1 '2.0'  '2.0'  0.05    0.3   
6  3.0e6 8.0e6 8.0e6 1 1 '6.0'  '6.0'  0.0     0.0   
11 3.0e6 8.0e6 5.5e6 0 1 '11.0' '11.0' -0.0705 0.5705
5  3.0e6 8.0e6 5.5e6 0 1 '5.0'  '5.0'  0.0     0.5   
7  3.0e6 8.0e6 5.5e6 0 1 '7.0'  '7.0'  -0.15   0.3   
8  3.0e6 8.0e6 5.5e6 0 1 '8.0'  '8.0'  0.0     0.1   
10 3.0e6 8.0e6 5.5e6 0 1 '10.0' '10.0' 0.0705  0.5705
9  3.0e6 8.0e6 5.5e6 0 1 '9.0'  '9.0'  0.15    0.3   
3  3.0e6 8.0e6 5.5e6 0 1 '3.0'  '3.0'  -0.05   0.3   
];

%% pipe data
% id fr_junction to_junction diameter length friction_factor p_min p_max status
mgc.pipe = [
3 7 3  0.5 55000 0.002589574 0 1.0e8 1
4 2 9  0.5 55000 0.002589574 0 1.0e8 1
1 6 8  0.5 55000 0.002589574 0 1.0e8 1
5 2 4  0.5 55000 0.002589574 0 1.0e8 1
2 1 2  0.5 55000 0.002589574 0 1.0e8 1
6 3 4  0.5 55000 0.002589574 0 1.0e8 1
7 5 10 0.5 55000 0.002589574 0 1.0e8 1
8 5 11 0.5 55000 0.002589574 0 1.0e8 1
9 1 3  1.0 1000  0.01        0 1.0e8 1
];

%% compressor data
% id fr_junction to_junction c_ratio_min c_ratio_max power_max flow_min flow_max inlet_p_min inlet_p_max outlet_p_min outlet_p_max status operating_cost directionality
mgc.compressor = [
1 8 1 1 1.6 100000 0 2000 0 1.0e8 0 1.0e8 1 1 1
2 4 5 1 1.6 100000 0 2000 0 1.0e8 0 1.0e8 1 1 1
];

%% receipt data
% id junction_id injection_min injection_max injection_nominal is_dispatchable status offer_price
mgc.receipt = [
1 10 0 100 0 1 1 2   
2 7  0 0   0 1 1 2   
3 11 0 100 0 1 1 1.25
4 9  0 0   0 1 1 1   
5 6  0 300 0 1 1 1.25
];

%% delivery data
% id junction_id withdrawal_min withdrawal_max withdrawal_nominal is_dispatchable status bid_price
mgc.delivery = [
1 10 0 50  0 1 1 3
2 7  0 100 0 1 1 3
3 11 0 100 0 1 1 5
4 9  0 150 0 1 1 3
5 6  0 0   0 1 1 0
];

end
```

This network is also distributed with the GasModels source code. This is how we will access
it for this tutorial:
```julia
file = joinpath(dirname(dirname(pathof(GasModels))), "examples", "data", "matgas", "gaslib11.m")
data = GasModels.parse_file(file)
```

## Step 2: Data checks
This tutorial will explain why a delivery is satisfied at less than its upper bound.
To do this, we need to make sure this delivery is dispatchable.
```julia
for delivery in values(data["delivery"])
    delivery["is_dispatchable"] = 1
end
```

Later in this tutorial, we will generate a "reduced-space" explanation.
The reduced-space projection we will is is only defined for models with fixed
compressor directionality (i.e., directionality = 1). We hope to relax
this requirement in future versions of GasModels.
```julia
for compressor in values(data["compressor"])
    compressor["directionality"] = 1
end
```

## Step 3: Solve the initial model
Now we instantiate and solve the model. We use `intantiate_model` instead of
`solve_ogf` because we will need to access the underlying JuMP model
(i.e., `gm.model`) to compute an explanation.
```julia
gm = GasModels.instantiate_model(data, GasModels.WPGasModel, GasModels.build_ogf)
JuMP.set_optimizer(gm.model, Ipopt.Optimizer)
JuMP.optimize!(gm.model)
@assert JuMP.is_solved_and_feasible(gm.model)
```

Suppose we care about delivery 4. Let's check its value.
```julia
delivery4 = GasModels.var(gm, :fl, 4)
println("delivery[4] = $(JuMP.value(delivery4)); UB = $(JuMP.upper_bound(delivery4))")
```

Delivery 4 has a gap of about 0.5 units to its upper bound. We'd like to know why.

## Step 4: A basic explanation
One possible explanation of a variable's value involves the gradient of the Lagrangian.

For an optimization problem:
```math
\min_x f(x);~ g(x) \leq 0,
```
the gradient of the Lagrangian is:
```math
\nabla \mathcal{L} = - \nabla f - \nabla g^T \lambda
```
where $\lambda$ is the vector of Lagrange multipliers.
We have chosen a negative sign for these two terms so that
the objective gradient term is a "direction of improvement"
and the constraint Jacobian term is an "interior direction".

Informally, each coordinate of this gradient may be interpreted as a
set of forces acting on each variable. The forces are due to (a)
the objective function and (b) each constraint. At optimality,
the forces are "balanced."
A *possible* explanation for a variable's value at the solution
is the set of "forces" acting on it. This is what the
`MathProgIncidence.explain` method returns: The terms in the
gradient of the Lagrangian corresponding to a specified variable.

To keep explanations concise, we usually want to filter out terms with
magnitudes below some threshold or keep only the top $k$ terms (in magnitude).
```julia
options = MPIN.ExplanationOptions(atol = 1e-2)
explanation = MPIN.explain(delivery4; options)
display(explanation)
```

This explanation indicates that the variable has a "force" of 300 pushing
the value up and another force of 300 pushing the value down.

The first constraint, pushing the value up, is the epigraph constraint used
to keep the objective linear. This may be interpreted as the objective function
pushing the pushing the value up. This makes sense because we improve the objective
function by satisfying more demand.

The constraint pushing the value down is more difficult to interpret. This is the
balance equation at this demand's junction. Ideally, we could "project out"
equality constraints such as this balance equation and the Weymouth equations
and explain this variable's value in terms of active inequalities.

## Step 5: A reduced-space explanation
When we provide the `GasModels.AbstractGasModel` struct, `gm`, to the `explain`
function, the nodal pressures, pipeline and compressor flow rates, and
associated equations are projected out of the explanation.
```julia
explanation = MPIN.explain(gm, :fl, 4; options)
# This also works: MPIN.explain(gm, delivery4; options)
display(explanation)
```

We now see a different pattern of constraints influencing the variable:
- Again, the first constraint, pushing the variable up with a "force" of 300 units,
  is the epigraph constraint.
- The constraint with the highest magnitude pushing the variable down is the lower bound
  on pressure at junction 9.
- The equality constraint still present in this explanation is the mass balance on
  the slack/reference junction.

## Step 6: Relaxing constraints to satisfy demand
At this point we might be satisfied with our explanation. We know what
constraints are preventing us from making a marginal improvement
in this delivery. However, we can also use this knowledge to relax constraints
to improve demand satisfaction.
Let's relax the constraint with the most significant negative coefficient
(i.e., the constraint pushing the variable down "the hardest").
```julia
p9 = GasModels.var(gm, :p_sqr, 9)
JuMP.set_lower_bound(p9, 1.5)
```

Admittedly, the amount by which we relax this bound is somewhat arbitrary.
Some trial-and-error will be necessary here.

We now solve the problem and check whether we can deliver more gas:
```julia
JuMP.optimize!(gm.model)
println("delivery[4] = $(JuMP.value(delivery4)); UB = $(JuMP.upper_bound(delivery4))")
```

We can now satisfy more of delivery 4, but we still have a shortfall
of 0.4 units.
```julia
explanation = MPIN.explain(gm, :fl, 4; options)
display(explanation)
```

The lower bound on $p_9$ no longer has the strongest negative
impact on our target delivery. Instead, the slack balance equation
does. To interpret the slack balance equation, we can explain
the variables it contains. We'll explain the flow rate through
pipe 1.
```julia
explanation = MPIN.explain(gm, :f_pipe, 1; options)
display(explanation)
```

To increase the flow _leaving_ the slack node, we would like to
increase the flow through pipe 1. Therefore, we will look for
constraints with negative coefficients (forcing this flow rate down)
that we can potentially relax.

Upper bounds on receipts seem like an obvious candidate.
Let's relax the upper bound on receipt 2.
(This is not the receipt bound with the most negative coefficient,
but receipt 4 is on the same junction as delivery 4. This is a bit
too obvious, so let's suppose it's not practical.)
```julia
receipt2 = GasModels.var(gm, :fg, 2)
JuMP.set_upper_bound(receipt2, 0.1)
JuMP.optimize!(gm.model)
println("delivery[4] = $(JuMP.value(delivery4)); UB = $(JuMP.upper_bound(delivery4))")
explanation = MPIN.explain(gm, :fl, 4; options)
display(explanation)
```

We have now satisfied another 0.06 units of delivery 4.
We can continue in this manner until we have either
satisfied this demand or are satisfied with our explanation.
