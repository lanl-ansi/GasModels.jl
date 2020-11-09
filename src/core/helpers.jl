nw_ids(gm::AbstractGasModel) = _IM.nw_ids(gm, _gm_it_sym)
nws(gm::AbstractGasModel) = _IM.nws(gm, _gm_it_sym)

ids(gm::AbstractGasModel, nw::Int, key::Symbol) = _IM.ids(gm, _gm_it_sym, nw, key)
ids(gm::AbstractGasModel, key::Symbol; nw::Int=gm.cnw) = _IM.ids(gm, _gm_it_sym, key; nw = nw)

ref(gm::AbstractGasModel, nw::Int = gm.cnw) = _IM.ref(gm, _gm_it_sym, nw)
ref(gm::AbstractGasModel, nw::Int, key::Symbol) = _IM.ref(gm, _gm_it_sym, nw, key)
ref(gm::AbstractGasModel, nw::Int, key::Symbol, idx) = _IM.ref(gm, _gm_it_sym, nw, key, idx)
ref(gm::AbstractGasModel, nw::Int, key::Symbol, idx, param::String) = _IM.ref(gm, _gm_it_sym, nw, key, idx, param)
ref(gm::AbstractGasModel, key::Symbol; nw::Int = gm.cnw) = _IM.ref(gm, _gm_it_sym, key; nw = nw)
ref(gm::AbstractGasModel, key::Symbol, idx; nw::Int = gm.cnw) = _IM.ref(gm, _gm_it_sym, key, idx; nw = nw)
ref(gm::AbstractGasModel, key::Symbol, idx, param::String; nw::Int = gm.cnw) = _IM.ref(gm, _gm_it_sym, key, idx, param; nw = nw)

var(gm::AbstractGasModel, nw::Int = gm.cnw) = _IM.var(gm, _gm_it_sym, nw)
var(gm::AbstractGasModel, nw::Int, key::Symbol) = _IM.var(gm, _gm_it_sym, nw, key)
var(gm::AbstractGasModel, nw::Int, key::Symbol, idx) = _IM.var(gm, _gm_it_sym, nw, key, idx)
var(gm::AbstractGasModel, key::Symbol; nw::Int = gm.cnw) = _IM.var(gm, _gm_it_sym, key; nw = nw)
var(gm::AbstractGasModel, key::Symbol, idx; nw::Int = gm.cnw) = _IM.var(gm, _gm_it_sym, key, idx; nw = nw)

con(gm::AbstractGasModel, nw::Int = gm.cnw) = _IM.con(gm, _gm_it_sym; nw = nw)
con(gm::AbstractGasModel, nw::Int, key::Symbol) = _IM.con(gm, _gm_it_sym, nw, key)
con(gm::AbstractGasModel, nw::Int, key::Symbol, idx) = _IM.con(gm, _gm_it_sym, nw, key, idx)
con(gm::AbstractGasModel, key::Symbol; nw::Int = gm.cnw) = _IM.con(gm, _gm_it_sym, key; nw = nw)
con(gm::AbstractGasModel, key::Symbol, idx; nw::Int = gm.cnw) = _IM.con(gm, _gm_it_sym, key, idx; nw = nw)

sol(gm::AbstractGasModel, nw::Int, args...) = _IM.sol(gm, _gm_it_sym, nw)
sol(gm::AbstractGasModel, args...; nw::Int = gm.cnw) = _IM.sol(gm, _gm_it_sym; nw = nw)

ismultinetwork(gm::AbstractGasModel) = _IM.ismultinetwork(gm, _gm_it_sym)
