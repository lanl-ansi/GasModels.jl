nw_ids(gm::_IM.AbstractInfrastructureModel) = _IM.nw_ids(gm, gm_it_sym)
nws(gm::_IM.AbstractInfrastructureModel) = _IM.nws(gm, gm_it_sym)

ids(gm::_IM.AbstractInfrastructureModel, nw::Int, key::Symbol) = _IM.ids(gm, gm_it_sym, nw, key)
ids(gm::_IM.AbstractInfrastructureModel, key::Symbol; nw::Int=gm.cnw) = _IM.ids(gm, gm_it_sym, key; nw = nw)

ref(gm::_IM.AbstractInfrastructureModel, nw::Int = gm.cnw) = _IM.ref(gm, gm_it_sym, nw)
ref(gm::_IM.AbstractInfrastructureModel, nw::Int, key::Symbol) = _IM.ref(gm, gm_it_sym, nw, key)
ref(gm::_IM.AbstractInfrastructureModel, nw::Int, key::Symbol, idx) = _IM.ref(gm, gm_it_sym, nw, key, idx)
ref(gm::_IM.AbstractInfrastructureModel, nw::Int, key::Symbol, idx, param::String) = _IM.ref(gm, gm_it_sym, nw, key, idx, param)
ref(gm::_IM.AbstractInfrastructureModel, key::Symbol; nw::Int = gm.cnw) = _IM.ref(gm, gm_it_sym, key; nw = nw)
ref(gm::_IM.AbstractInfrastructureModel, key::Symbol, idx; nw::Int = gm.cnw) = _IM.ref(gm, gm_it_sym, key, idx; nw = nw)
ref(gm::_IM.AbstractInfrastructureModel, key::Symbol, idx, param::String; nw::Int = gm.cnw) = _IM.ref(gm, gm_it_sym, key, idx, param; nw = nw)

var(gm::_IM.AbstractInfrastructureModel, nw::Int = gm.cnw) = _IM.var(gm, gm_it_sym, nw)
var(gm::_IM.AbstractInfrastructureModel, nw::Int, key::Symbol) = _IM.var(gm, gm_it_sym, nw, key)
var(gm::_IM.AbstractInfrastructureModel, nw::Int, key::Symbol, idx) = _IM.var(gm, gm_it_sym, nw, key, idx)
var(gm::_IM.AbstractInfrastructureModel, key::Symbol; nw::Int = gm.cnw) = _IM.var(gm, gm_it_sym, key; nw = nw)
var(gm::_IM.AbstractInfrastructureModel, key::Symbol, idx; nw::Int = gm.cnw) = _IM.var(gm, gm_it_sym, key, idx; nw = nw)

con(gm::_IM.AbstractInfrastructureModel, nw::Int = gm.cnw) = _IM.con(gm, gm_it_sym; nw = nw)
con(gm::_IM.AbstractInfrastructureModel, nw::Int, key::Symbol) = _IM.con(gm, gm_it_sym, nw, key)
con(gm::_IM.AbstractInfrastructureModel, nw::Int, key::Symbol, idx) = _IM.con(gm, gm_it_sym, nw, key, idx)
con(gm::_IM.AbstractInfrastructureModel, key::Symbol; nw::Int = gm.cnw) = _IM.con(gm, gm_it_sym, key; nw = nw)
con(gm::_IM.AbstractInfrastructureModel, key::Symbol, idx; nw::Int = gm.cnw) = _IM.con(gm, gm_it_sym, key, idx; nw = nw)

sol(gm::_IM.AbstractInfrastructureModel, nw::Int, args...) = _IM.sol(gm, gm_it_sym, nw)
sol(gm::_IM.AbstractInfrastructureModel, args...; nw::Int = gm.cnw) = _IM.sol(gm, gm_it_sym; nw = nw)

ismultinetwork(gm::_IM.AbstractInfrastructureModel) = _IM.ismultinetwork(gm, gm_it_sym)
