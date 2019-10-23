'''
A script to convert ArcGIS CSV files to a Matlab format TSV file
'''

import sys
import argparse
import csv
import logging
import traceback
import geopy.distance

MGC_PROPS = ['version', 'sound_speed', 'temperature', 'R', 'compressibility_factor', 'gas_molar_mass', 'gas_specific_gravity', 'specific_heat_capacity_ratio', 'standard_density', 'baseP', 'baseQ', 'per_unit']
COMPONENT_NAMES = ['Junction', 'Pipe', 'Compressor', 'Resistor', 'Producer', 'Consumer', 'Generator', 'Storage']

junction_ids = []

def get_class_by_name(name):
    ''' Get class by name '''
    return getattr(sys.modules[__name__], name)

def get_collection_key(name):
    ''' Get collection key associated with a class name '''
    return get_class_by_name(name).collection_key

def distance(src, dst):
    ''' Calculate geospatial distance between src and dst in meters. '''
    assert(src is not None), 'src is undefined'
    assert(dst is not None), 'dst is undefined'
    return geopy.distance.distance(src, dst).km*1000

class Component:
    ''' An abstract MGC component '''
    _id = None # component id
    status = 1 # status of the component (0 = off, 1 = on). Default is 1.

    def __init__(self, attrs={}):
        for k in ['_id', 'status']:
            default = getattr(type(self), k)
            v = attrs.get(k, default)
            setattr(self, k, v)

    def get_component_name(self):
        ''' Get the component name. '''
        component_name = type(self).__name__.lower()
        return component_name

    def get_matlab_column_names(self, is_ext_data=False):
        ''' Get the Matlab column names for this component. '''
        column_names = []
        return column_names

    def get_matlab_record_values(self, is_ext_data=False):
        ''' Get the Matlab record values for this component. '''
        values = []
        return values

    def get_matlab_header(self, is_ext_data=False):
        ''' Create a Matlab component header string. '''
        component_name = self.get_component_name()
        title = f'%% {component_name}'
        column_names = self.get_matlab_column_names(is_ext_data)
        if is_ext_data:
            # extended data header
            title += ' data'
            column_names_str = '%column_names% '+' '.join(column_names)
            list_header_str = f'mgc.{component_name}_data = '+'[' # used to be }; but ]; "should" work the same
        else:
            title += ' data'
            column_names_str = '%column_names% '+' '.join(column_names)
            list_header_str = f'mgc.{component_name} = ['
        header_str = '\n'.join([title, column_names_str, list_header_str])
        return header_str

    def get_matlab_record(self, is_ext_data=False):
        ''' Create a Matlab component record string. '''
        values = self.get_matlab_record_values(is_ext_data)
        record_str = '\t'.join([str(value) for value in values])
        return record_str

    def get_matlab_footer(self, is_ext_data=False):
        ''' Create a Matlab component footer. '''
        if is_ext_data:
            footer_str = '];' # used to be }; but ]; "should" work the same
        else:
            footer_str = '];'
        return footer_str

class Node(Component):
    ''' An abstract MGC node '''
    location = None # position of the junction (optional)

    def __init__(self, attrs={}):
        Component.__init__(self, attrs)
        for k in ['location']:
            default = getattr(type(self), k)
            v = attrs.get(k, default)
            setattr(self, k, v)

class Edge(Component):
    ''' an abstract mgc edge '''
    f_junction = None # the "from" side junction id
    t_junction = None # the "to" side junction id
    directed = 0 # direction of the component (1 = f_junction -> t_junction, 0 = undirected, -1 = t_junction -> f_junction). Default is 0.

    def __init__(self, attrs={}):
        Component.__init__(self, attrs)
        for k in ['f_junction', 't_junction', 'directed']:
            default = getattr(type(self), k)
            v = attrs.get(k, default)
            setattr(self, k, v)

class Dispatchable(Component):
    ''' an abstract dispatchable '''
    dispatchable = 1 # whether or not the unit is dispatchable (0 = producer should produce qg, 1 = producer can produce between qgmin and qgmax).

    def __init__(self, attrs={}):
        Component.__init__(self, attrs)
        for k in ['dispatchable']:
            default = getattr(type(self), k)
            v = attrs.get(k, default)
            setattr(self, k, v)

class Junction(Node):
    ''' A junction component '''
    collection_key = 'junctions'
    pmax = 5515808 # maximum pressure. SI units are pascals
    pmin = 3447380 # minimum pressure. SI units are pascals
    p = pmin # nominal pressure in pascal
    type = 0

    def __init__(self, attrs={}):
        Node.__init__(self, attrs)
        for k in ['pmax', 'pmin', 'p', 'type']:
            default = getattr(type(self), k)
            v = attrs.get(k, default)
            setattr(self, k, v)

    @staticmethod
    def from_csv_record(row, mgc=None):
        ''' create a junction from csv '''
        _id = int(float(row['NODEID']))
        location = (float(row['POINT_X']), float(row['POINT_Y']))
        return Junction({'_id': _id,
                         'location': location})

    def get_matlab_column_names(self, is_ext_data=False):
        ''' Get the Matlab column names for this component. '''
        if is_ext_data:
            column_names = ['latitude', 'longitude']
        else:
            column_names = ['junction_i', 'type', 'pmin', 'pmax', 'status', 'p']
        return column_names

    def get_matlab_record_values(self, is_ext_data=False):
        ''' Get the Matlab record values for this component. '''
        if is_ext_data:
            values = self.location
        else:
            keys = ['_id', 'type', 'pmin', 'pmax', 'status', 'p']
            values = [getattr(self, key, 0) for key in keys]
        return values

class Consumer(Dispatchable):
    ''' a consumer '''
    collection_key = 'consumers'
    ql_junc = None # junction id
    qlmax = 1 # the maximum volumetric gas demand at standard density. SI units are m^3/s.
    qlmin = 0 # the minimum volumetric gas demand gas demand at standard density. SI units are m^3/s.
    ql = qlmin # nominal volumetric gas demand gas demand at standard density. SI units are m^3/s.
    priority = 0 # priority for serving the variable load. High numbers reflect a higher desired to serve this load.

    def __init__(self, attrs={}):
        Dispatchable.__init__(self, attrs)
        for k in ['ql_junc', 'qlmin', 'qlmax', 'ql', 'priority']:
            default = getattr(type(self), k)
            v = attrs.get(k, default)
            setattr(self, k, v)

    @staticmethod
    def from_csv_record(row, mgc):
        ''' create consumer from csv record '''
        if row['RECDEL'] == 'D':
            _id = int(float(row['RDPTID']))
            ql_junc = int(row['NEAR_FID'])
            qlmax = float(row['MAXCAP'])*(10**3)/(35.3147*86400) # kf^3/d to m^3/s
            ql = float(row['SCHEDCAP'])*(10**3)/(35.3147*86400) # kf^3/d to m^3/s
            dispatchable = 0 if qlmax == 0 else 1
            return Consumer({'_id': _id,
                             'ql_junc': ql_junc,
                             'qlmax': qlmax,
                             'ql': ql,
                             'dispatchable': dispatchable})
        return None

    def get_matlab_column_names(self, is_ext_data=False):
        ''' Get the Matlab column names for this component. '''
        if is_ext_data:
            # added to join generators with consumers
            column_names = ['eiaid']
        else:
            column_names = ['consumer_i', 'junction', 'fd', 'status', 'dispatchable']
        return column_names

    def get_matlab_record_values(self, is_ext_data=False):
        ''' Get the Matlab record values for this component. '''
        if is_ext_data:
            # added to join generators with consumers
            keys = ['eiaid']
        else:
            keys = ['_id', 'ql_junc', 'ql', 'status', 'dispatchable']
        values = [getattr(self, key, 0) for key in keys]
        return values

class Producer(Dispatchable):
    ''' a producer '''
    collection_key = 'producers'
    qg_junc = None # junction id
    qgmin = 0 # the minimum volumetric gas production at standard density. SI units are m^3/s.
    qgmax = 1 # the maximum volumetric gas production at standard density. SI units are m^3/s.
    qg = qgmin # nominal volumetric gas production at standard density. SI units are m^3/s.

    def __init__(self, attrs={}):
        Dispatchable.__init__(self, attrs)
        for k in ['qg_junc', 'qgmin', 'qgmax', 'qg']:
            default = getattr(type(self), k)
            v = attrs.get(k, default)
            setattr(self, k, v)

    @staticmethod
    def from_csv_record(row, mgc):
        ''' create producer from csv '''
        if row['RECDEL'] == 'R':
            _id = int(float(row['RDPTID']))
            qg_junc = int(row['NEAR_FID'])
            qgmax = float(row['MAXCAP'])*(10**3)/(35.3147*86400) # kf^3/d to m^3/s
            qg = float(row['SCHEDCAP'])*(10**3)/(35.3147*86400) # kf^3/d to m^3/s
            dispatchable = 0 if qgmax == 0 else 1
            return Producer({'_id': _id, 'qg_junc': qg_junc, 'qgmax': qgmax, 'qg': qg, 'dispatchable': dispatchable})
        return None

    def get_matlab_column_names(self, is_ext_data=False):
        ''' Get the Matlab column names for this component. '''
        if is_ext_data:
            column_names = []
        else:
            column_names = ['producer_i', 'junction', 'fgmin', 'fgmax', 'fg', 'status', 'dispatchable']
        return column_names

    def get_matlab_record_values(self, is_ext_data=False):
        ''' Get the Matlab record values for this component. '''
        if is_ext_data:
            keys = []
        else:
            keys = ['_id', 'qg_junc', 'qgmin', 'qgmax', 'qg', 'status', 'dispatchable']
        values = [getattr(self, key, 0) for key in keys]
        return values

class Pipe(Edge):
    ''' a pipe '''
    collection_key = 'pipes'
    length = 0 # the length of the connection. SI units are m.
    friction_factor = 0.01 # the friction component of the resistance term of the pipe. Non dimensional.
    diameter = 0 # the diameter of the connection. SI units are m.

    def __init__(self, attrs={}):
        Edge.__init__(self, attrs)
        for k in ['diameter', 'length']:
            default = getattr(type(self), k)
            v = attrs.get(k, default)
            setattr(self, k, v)

    @staticmethod
    def from_csv_record(row, mgc):
        ''' create a pipe from csv '''
        pid = int(float(row['LINEID']))
        f_junction = int(row['FRNODE'])
        t_junction = int(row['TONODE'])
        diameter = float(row['DIAMETER'])*.0254
        f_node = (float(row['FRNODE_Y']), float(row['FRNODE_X']))
        t_node = (float(row['TONODE_Y']), float(row['TONODE_X']))
        length = distance(f_node, t_node)
        pipe = Pipe({'_id': pid,
                     'f_junction': f_junction,
                     't_junction': t_junction,
                     'diameter': diameter,
                     'length': length})
        return pipe

    def get_matlab_column_names(self, is_ext_data=False):
        ''' Get the Matlab column names for this component. '''
        if is_ext_data:
            column_names = []
        else:
            column_names = ['pipeline_i', 'f_junction', 't_junction', 'diameter', 'length', 'friction_factor', 'status']
        return column_names

    def get_matlab_record_values(self, is_ext_data=False):
        ''' Get the Matlab record values for this component. '''
        if is_ext_data:
            keys = []
        else:
            keys = ['_id', 'f_junction', 't_junction', 'diameter', 'length', 'friction_factor', 'status']
        values = [getattr(self, key, 0) for key in keys]
        return values

class Compressor(Edge):
    ''' a compressor '''
    collection_key = 'compressors'
    c_ratio_min = 1.0 # minimum multiplicative pressure change (compression or decompressions). Compression only goes from f_junction to t_junction (1 if flow reverses).
    c_ratio_max = 1.4 # maximum multiplicative pressure change (compression or decompressions). Compression only goes from f_junction to t_junction (1 if flow reverses).
    power_max = 0 # max power in watts
    fmin = 0
    fmax = 700

    def __init__(self, attrs={}):
        Edge.__init__(self, attrs)
        for k in ['c_ratio_min', 'c_ratio_max', 'power_max', 'fmin', 'fmax']:
            default = getattr(type(self), k)
            v = attrs.get(k, default)
            setattr(self, k, v)

    @staticmethod
    def from_csv_record(row, mgc):
        ''' create a compressor from csv '''
        _id = len(mgc.compressors)
        power_max = float(row['HP']) * 745.7 # hp to watts
        # insert compressor logically between near pipe and near node
        pid = int(row['NEARLINEID'])
        nid = int(row['NEARNODEID'])
        # create new compressor junction
        for junction in mgc.junctions:
            if junction._id == nid:
                nearnode = junction
                break
        new_id = max([junction._id for junction in mgc.junctions]) + 1 + len(mgc.compressors)
        compressor_junction = Junction({'_id': new_id, 'location': nearnode.location}) # use same location as nid
        mgc.junctions.append(compressor_junction)
        for pipe in mgc.pipes:
            if pipe._id == pid:
                if pipe.f_junction == nid:
                    # compressor is between pipe and its f_junction
                    f_junction = nid
                    t_junction = compressor_junction._id
                    pipe.f_junction = compressor_junction._id # new compressor node
                elif pipe.t_junction == nid:
                    t_junction = nid
                    f_junction = compressor_junction._id
                    pipe.t_junction = compressor_junction._id # new compressor node
                break
        return Compressor({'_id': _id,
                           'f_junction': f_junction,
                           't_junction': t_junction,
                           'power_max': power_max})

    def get_matlab_column_names(self, is_ext_data=False):
        ''' Get the Matlab column names for this component. '''
        if is_ext_data:
            column_names = []
        else:
            column_names = ['compressor_i', 'f_junction', 't_junction', 'cmin', 'cmax', 'power_max', 'fmin', 'fmax', 'status']
        return column_names

    def get_matlab_record_values(self, is_ext_data=False):
        ''' Get the Matlab record values for this component. '''
        if is_ext_data:
            keys = []
        else:
            keys = ['_id', 'f_junction', 't_junction', 'c_ratio_min', 'c_ratio_max', 'power_max', 'fmin', 'fmax', 'status']
        values = [getattr(self, key, 0) for key in keys]
        return values

class Short_Pipe(Edge):
    ''' a short pipe '''
    collection_key = 'short_pipes'

    def __init__(self, attrs={}):
        Edge.__init__(self, attrs)

class Valve(Edge):
    ''' a valve '''
    collection_key = 'valves'

    def __init__(self, attrs={}):
        Edge.__init__(self, attrs)

class Control_Valve(Compressor):
    ''' a control valve '''
    collection_key = 'control_valves'

    def __init__(self, attrs={}):
        Compressor.__init__(self, attrs)

class Resistor(Edge):
    ''' a resistor '''
    collection_key = 'resistors'
    drag = 1.0 # the drag factor of resistors. Non dimensional.

    def __init__(self, attrs={}):
        Edge.__init__(self, attrs)
        for k in ['drag']:
            default = getattr(type(self), k)
            v = attrs.get(k, default)
            setattr(self, k, v)

class Generator(Consumer):
    ''' a generator '''
    collection_key = 'generators'
    eiaid = 0

    def __init__(self, attrs={}):
        Consumer.__init__(self, attrs)
        for k in ['eiaid']:
            default = getattr(type(self), k)
            v = attrs.get(k, default)
            setattr(self, k, v)

    @staticmethod
    def from_csv_record(row, mgc):
        # HACK: generate ids higher than consumers
        _id = max([consumer._id for consumer in mgc.consumers]) + 1 + len(mgc.generators)
        ql_junc = int(row['NEAR_FID'])
        qlmax = float(row['W_CAP_MW'])*94.28/3600 # MWh to m^3/s
        ql = float(row['S_CAP_MW'])*94.28/3600 # MWh to m^3/s
        dispatchable = 0 if qlmax == 0 else 1
        eiaid = row['EIACODE'] or 0
        return Generator({'_id': _id,
                          'ql_junc': ql_junc,
                          'qlmax': qlmax,
                          'ql': ql,
                          'dispatchable': dispatchable,
                          'eiaid': eiaid})

    def get_matlab_column_names(self, is_ext_data=False):
        ''' Get the Matlab column names for this component. '''
        if is_ext_data:
            column_names = ['eiaid']
        else:
            column_names = ['consumer_i', 'junction', 'fg', 'status', 'dispatchable']
        return column_names

    def get_matlab_record_values(self, is_ext_data=False):
        ''' Get the Matlab record values for this component. '''
        if is_ext_data:
            keys = ['eiaid']
        else:
            keys = ['_id', 'ql_junc', 'ql', 'status', 'dispatchable']
        values = [getattr(self, key, 0) for key in keys]
        return values

class Storage(Consumer):
    ''' a storage '''
    collection_key = 'storage'

    def __init__(self, attrs):
        Consumer.__init__(self, attrs)

    @staticmethod
    def from_csv_record(row, mgc):
        _id = int(float(row['STFCID']))
        junction = int(row['NEAR_FID'])
        qlmax = float(row['TOTALCAP'])*(10**3)/(35.3147) # kf^3 to m^3
        ql = float(row['WORKCAP'])*(10**3)/(35.3147) # kf^3 to m^3
        dispatchable = 0 if qlmax == 0 else 1
        return Storage({'_id': _id,
                        'junction': junction,
                        'qlmax': qlmax,
                        'ql': ql,
                        'dispatchable': dispatchable})

    def get_matlab_column_names(self, is_ext_data=False):
        ''' Get the Matlab column names for this component. '''
        if is_ext_data:
            column_names = ['_id', 'eiaid']
        else:
            column_names = ['storage_i', 'junction', 'qlmax', 'ql', 'status']
        return column_names

    def get_matlab_record_values(self, is_ext_data=False):
        ''' Get the Matlab record values for this component. '''
        if is_ext_data:
            keys = []
        else:
            keys = ['_id', 'junction', 'qlmax', 'ql', 'status']
        values = [getattr(self, key, 0) for key in keys]
        return values

class MGC:
    ''' MatGas Case '''
    version = 1
    name = 'unnamed' # a name for the model
    temperature = 273.15 # gas temperature. SI units are kelvin
    multinetwork = 0 # flag for whether or not this is multiple networks
    gas_molar_mass = 0.0185674 # molecular mass of the gas. SI units are kg/mol
    standard_density = 1.0 # Standard (nominal) density of the gas. SI units are kg/m^3
    per_unit = 0 # Whether or not the file is in per unit (non dimensional units) or SI units.  Note that the only quantities that are non-dimensionalized are pressure and flux.
    compressibility_factor = 0.8 # Gas compressability. Non-dimensional.
    baseQ = 604.167 # Base for non-dimensionalizing volumetric flow at standard density. SI units are m^3/s
    baseP = 8101325 # Base for non-dimensionalizing pressure. SI units are pascal.

    # deprecated props
    gas_specific_gravity = 0.6
    specific_heat_capacity_ratio = 1.4
    sound_speed = 312.805 # m/s
    R = 8.314

    junctions = []
    pipes = []
    consumers = []
    producers = []
    compressors = []
    resistors = []
    generators = []
    storage = []

    def __init__(self, components={}, attrs={}):
        for k,v in components.items():
            assert(isinstance(v, list)), f'{v} must be a list'
            setattr(self, k, v)
        for k,v in attrs.items():
            default = getattr(MGC, k)
            setattr(self, k, v)

    def add_component(self, component):
        ''' adds an abstract component to the model '''

        component_name = type(component).__name__
        if component_name not in COMPONENT_NAMES:
            raise Exception(f'Unsupported component {component_name}')
        collection_key = get_collection_key(component_name)
        components = getattr(self, collection_key, [])
        components.append(component)
        setattr(self, collection_key, components)

    @staticmethod
    def from_csv_files(component_files, attrs={}):
        ''' creates MGC object from csv file '''

        mgc = MGC(attrs=attrs)
        for component_name in component_files:
            logging.info(f'Processing {component_name} file')
            count = 0
            invalid = 0
            try:
                component_file_path = component_files[component_name]
                assert(isinstance(component_file_path, str)), f'{component_name} file path is invalid: {component_file_path}'
                with open(component_file_path) as csv_file:
                    # process csv file
                    csv_reader = csv.DictReader(csv_file)
                    # skip header row
                    #next(csv_reader)
                    for row in csv_reader:
                        # increment record count
                        count += 1
                        try:
                            component_class = get_class_by_name(component_name)
                            component = component_class.from_csv_record(row, mgc)
                            if component:
                                mgc.add_component(component)
                        except Exception as e:
                            logging.debug(traceback.print_exc())
                            logging.error(f'Unable to add {component_name} component: {e}')
                            invalid += 1
                    logging.info(f'{invalid}/{count} {component_name} components discarded')
            except Exception as e:
                logging.debug(traceback.print_exc())
                logging.warning(f'Unable to process {component_name} file: {e}')
        mgc.validate()
        return mgc

    def validate(self):
        ''' Validate MGC properties '''
        logging.info('Validating dataset')
        try:
            for component_name in COMPONENT_NAMES:
                collection_key = get_collection_key(component_name)
                ''' Check component IDs are unique '''
                ids = [component._id for component in getattr(self, collection_key)]
                seen = set()
                for _id in ids:
                    assert(_id not in seen), f'{component_name} {_id} is duplicate'
                    seen.add(_id)
                if collection_key == "pipelines":
                    ''' For each pipeline, check endpoints exist and are active '''
                    endpoints = {junction._id: junction.status for junction in self.junctions}
                    for edge in self.pipes+self.compressors+self.resistors:
                        f_junction = edge.f_junction
                        t_junction = edge.t_junction
                        assert(f_junction in endpoints), f'{type(edge).__name__} {edge._id} f_junction {f_junction} nonexistent'
                        assert(endpoints.get(f_junction) == 1), f'edge {edge._id} f_junction {f_junction} inactive'
                        assert(t_junction in endpoints), f'edge {edge._id} t_junction {t_junction} nonexistent'
                        assert(endpoints.get(t_junction) == 1), f'edge {edge._id} t_junction {t_junction} inactive'

        except Exception as e:
            logging.debug(traceback.print_exc())
            logging.info(f'MGC invalid: {e}')

    def to_matlab_document(self):
        ''' creates Matlab output from MGC object '''
        # mgc name
        mgc_str = f'function mgc = {self.name}\n'
        # mgc properties
        mgc_str += '\n'.join([f'mgc.{prop} = {getattr(self, prop)};' for prop in MGC_PROPS])+'\n\n'
        # HACK: replace baseQ with baseF
        mgc_str = mgc_str.replace('baseQ', 'baseF')
        for component_name in COMPONENT_NAMES:
            # HACK: skip generator components
            if component_name == 'Generator':
                continue
            collection_key = get_collection_key(component_name)
            components = getattr(self, collection_key, [])
            # HACK: add generator components to consumer components
            if component_name == 'Consumer':
                collection_key = get_collection_key('Generator')
                components += getattr(self, collection_key, [])
            if components:
                component_header = components[0].get_matlab_header()
                component_records = '\n'.join([component.get_matlab_record() for component in components])
                component_footer = components[0].get_matlab_footer()
                mgc_str += '\n'.join([component_header, component_records, component_footer])
                mgc_str += '\n\n'
                is_ext_data = True
                if components[0].get_matlab_record_values(is_ext_data):
                    # add is_ext_datara data table
                    component_header = components[0].get_matlab_header(is_ext_data)
                    component_records = '\n'.join([component.get_matlab_record(is_ext_data) for component in components])
                    component_footer = components[0].get_matlab_footer(is_ext_data)
                    mgc_str += '\n'.join([component_header, component_records, component_footer])
                    mgc_str += '\n\n'
        mgc_str += "end\n"
        return mgc_str

def csv2mgc(args):
    ''' generate matlab output from csv files '''
    component_files = {}
    for component_name in COMPONENT_NAMES:
        collection_key = get_collection_key(component_name)
        #default = getattr(MGC, collection_key)
        if collection_key in args and getattr(args, collection_key) is not None:
            component_files[component_name] = getattr(args, collection_key)
    mgc_props = {}
    for prop in MGC_PROPS:
        if prop in args and getattr(args, prop) is not None:
            mgc_props[prop] = getattr(args, prop)

    return MGC.from_csv_files(component_files, mgc_props).to_matlab_document()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Convert ArcGIS CSVs to Matlab mgc format')
    parser.add_argument('-j', '--junctions', type=str, help='Junction data file', required=True)
    parser.add_argument('-p', '--pipes', type=str, help='Pipe data file', required=True)
    parser.add_argument('-d', '--producers', type=str, help='Producer data file', required=True)
    parser.add_argument('-r', '--consumers', type=str, help='Consumer data file', required=True)
    parser.add_argument('-c', '--compressors', type=str, help='Compressor data file')
    parser.add_argument('-e', '--resistors', type=str, help='Resistors data file')
    parser.add_argument('-g', '--generators', type=str, help='Generator data file')
    parser.add_argument('-s', '--storage', type=str, help='Generator data file')
    parser.add_argument('-o', '--output', type=str, help='Matlab output file')
    parser.add_argument('--name', type=str, help=f'a name for the model (default: {MGC.name})', default=MGC.name)
    parser.add_argument('--version', type=str, help=f'mgc version (default: {MGC.version})', default=MGC.version)
    parser.add_argument('--temperature', type=float, help=f'gas temperature. SI units are kelvin (default: {MGC.temperature} K)', default=MGC.temperature)
    parser.add_argument('--multinetwork', help=f'flag for whether or not this is multiple networks (default {MGC.multinetwork})', action='store_const', const=1, default=MGC.multinetwork)
    parser.add_argument('--gas_molar_mass', type=float, help=f'molecular mass of the gas. SI units are kg/mol (default: {MGC.gas_molar_mass} kg/mol)', default=MGC.gas_molar_mass)
    parser.add_argument('--standard_density', type=float, help=f'Standard (nominal) density of the gas. SI units are kg/m^3 (default: {MGC.standard_density} kg/m^3)', default=MGC.standard_density)
    parser.add_argument('--per_unit', help=f'Whether or not the file is in per unit (non dimensional units) or SI units.  Note that the only quantities that are non-dimensionalized are pressure and flux. (default: {MGC.per_unit})', action='store_const', const=1, default=MGC.per_unit)
    parser.add_argument('--baseQ', type=float, help=f'Base for non-dimensionalizing volumetric flow at standard density. (default: {MGC.baseQ} m^3/s)', default=MGC.baseQ)
    parser.add_argument('--baseP', type=float, help=f'Base for non-dimensionalizing pressure. (default: {MGC.baseP} Pa)', default=MGC.baseP)
    parser.add_argument('-v', '--verbosity', help='Increase output verbosity', action='count')
    parser.add_argument('-q', '--quiet', help='Suppress all log messages', action='store_const', const=0, dest='verbosity')
    args = parser.parse_args()
    verbosity = args.verbosity
    if verbosity is not None:
        if verbosity > 1:
            log_level = logging.DEBUG
        elif verbosity == 1:
            log_level = logging.INFO
        else:
            log_level = logging.ERROR
        logging.basicConfig(level=log_level)

    results = csv2mgc(args)

    output = args.output
    if output is not None:
        # write result to file
        with open(output, 'w') as fp:
            fp.write(results)
    else:
        # print to stdout
        print(results)
