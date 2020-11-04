nw_ids(gm::AbstractGasModel) = _IM.nw_ids(gm, :ng)
nws(gm::AbstractGasModel) = _IM.nws(gm, :ng)

ids(gm::AbstractGasModel, nw::Int, key::Symbol) = _IM.ids(gm, :ng, nw, key)
ids(gm::AbstractGasModel, key::Symbol; nw::Int=gm.cnw) = _IM.ids(gm, :ng, key; nw = nw)

ref(gm::AbstractGasModel, nw::Int = gm.cnw) = _IM.ref(gm, :ng, nw)
ref(gm::AbstractGasModel, nw::Int, key::Symbol) = _IM.ref(gm, :ng, nw, key)
ref(gm::AbstractGasModel, nw::Int, key::Symbol, idx) = _IM.ref(gm, :ng, nw, key, idx)
ref(gm::AbstractGasModel, nw::Int, key::Symbol, idx, param::String) = _IM.ref(gm, :ng, nw, key, idx, param)
ref(gm::AbstractGasModel, key::Symbol; nw::Int = gm.cnw) = _IM.ref(gm, :ng, key; nw = nw)
ref(gm::AbstractGasModel, key::Symbol, idx; nw::Int = gm.cnw) = _IM.ref(gm, :ng, key, idx; nw = nw)
ref(gm::AbstractGasModel, key::Symbol, idx, param::String; nw::Int = gm.cnw) = _IM.ref(gm, :ng, key, idx, param; nw = nw)

var(gm::AbstractGasModel, nw::Int = gm.cnw) = _IM.var(gm, :ng, nw)
var(gm::AbstractGasModel, nw::Int, key::Symbol) = _IM.var(gm, :ng, nw, key)
var(gm::AbstractGasModel, nw::Int, key::Symbol, idx) = _IM.var(gm, :ng, nw, key, idx)
var(gm::AbstractGasModel, key::Symbol; nw::Int = gm.cnw) = _IM.var(gm, :ng, key; nw = nw)
var(gm::AbstractGasModel, key::Symbol, idx; nw::Int = gm.cnw) = _IM.var(gm, :ng, key, idx; nw = nw)

con(gm::AbstractGasModel, nw::Int = gm.cnw) = _IM.con(gm, :ng; nw = nw)
con(gm::AbstractGasModel, nw::Int, key::Symbol) = _IM.con(gm, :ng, nw, key)
con(gm::AbstractGasModel, nw::Int, key::Symbol, idx) = _IM.con(gm, :ng, nw, key, idx)
con(gm::AbstractGasModel, key::Symbol; nw::Int = gm.cnw) = _IM.con(gm, :ng, key; nw = nw)
con(gm::AbstractGasModel, key::Symbol, idx; nw::Int = gm.cnw) = _IM.con(gm, :ng, key, idx; nw = nw)

sol(gm::AbstractGasModel, nw::Int, args...) = _IM.sol(gm, :ng, nw)
sol(gm::AbstractGasModel, args...; nw::Int = gm.cnw) = _IM.sol(gm, :ng; nw = nw)

ismultinetwork(gm::AbstractGasModel) = _IM.ismultinetwork(gm, :ng)
