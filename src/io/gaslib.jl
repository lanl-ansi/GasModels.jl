import LightXML
import ZipFile

function _read_gaslib_topology_xml(gaslib_zip)
    index = findfirst(x -> occursin(".net", x.name), gaslib_zip.files)
    topology_xml = ZipFile.read(gaslib_zip.files[index], String)
    return LightXML.root(LightXML.parse_string(topology_xml))
end

function _read_nodes_from_topology(topology_xml)
    return LightXML.find_element(topology_xml, "nodes")

    #sources = LightXML.get_elements_by_tagname(node_xml, "source")
    #sinks = LightXML.get_elements_by_tagname(node_xml, "sink")
    #innodes = LightXML.get_elements_by_tagname(node_xml, "sink")
    #println(sources)
    #nodes = collect(LightXML.child_nodes(node_xml))
    #println(nodes)
    #data = LightXML.attributes_dict(node_xml)
    #println(data)
    #return 0.0
end

function _read_component_properties(component_xml)
    properties_xml = collect(LightXML.child_nodes(component_xml))
    properties = [(LightXML.name(x), LightXML.value(x)) for x in properties_xml]
    println(properties)
end

function _read_sources_from_nodes(node_xml)
    source_xml = LightXML.get_elements_by_tagname(node_xml, "source")
    properties = [_read_component_properties(x) for x in source_xml]
    println(properties)
    #sources = [LightXML.attributes_dict(source) for source in source_xml]
    #println(sources)
end

function parse_gaslib(zip_path::Union{IO, String})
    gaslib_zip = ZipFile.Reader(zip_path)
    topology_xml = _read_gaslib_topology_xml(gaslib_zip)
    node_xml = _read_nodes_from_topology(topology_xml)
    sources = _read_sources_from_nodes(node_xml)
end
