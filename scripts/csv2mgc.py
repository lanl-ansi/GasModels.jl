'''
A script to convert ArcGIS CSV files to a Matlab format TSV file
'''

import sys
import argparse
import csv
import logging
import traceback
from uuid import uuid4
import geopy.distance

COMPONENT_TYPES = ['junctions', 'pipes', 'compressors', 'regulators', 'producers', 'consumers', 'generators', 'storage']

class Component:
    ''' An abstract MGC component '''

    def __init__(self, _id):
        self.id = _id or int(str(uuid4().int)[:8])
        self.status = 1

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
            column_names_str = '%column_names%'+' '.join(column_names)
            list_header_str = f'mgc.{component_name}_data = '+'[' # used to be }; but ]; "should" work the same
        else:
            column_names_str = '%'+' '.join(column_names)
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

    def __init__(self, _id, location):
        Component.__init__(self, _id)
        self.location = location # (lat, lng)

class Edge(Component):
    ''' an abstract mgc edge '''

    def __init__(self, _id, f_junction, t_junction):
        Component.__init__(self, _id)
        self.f_junction = f_junction
        self.t_junction = t_junction

class Dispatchable(Component):
    ''' an abstract dispatchable '''

    def __init__(self, _id):
        Component.__init__(self, _id)
        self.dispatchable = 1

class Junction(Node):
    ''' A junction component '''

    def __init__(self, _id, location):
        Node.__init__(self, _id, location)
        self.type = 0
        self.pmin = 3447380 # min pressure in pascal
        self.pmax = 5515808 # max pressure in pascal
        self.p = 3447380 # current pressure in pascal

    @staticmethod
    def from_csv_record(row, mgc):
        ''' create a junction from csv '''
        _id = int(float(row['NODEID']))
        location = (float(row['POINT_X']), float(row['POINT_Y']))
        return Junction(_id, location)

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
            keys = ['id', 'type', 'pmin', 'pmax', 'status', 'p']
            values = [getattr(self, key) for key in keys]
        return values

def distance(src, dst):
    ''' Calculate geospatial distance between src and dst in meters. '''
    assert(src is not None), 'src is undefined'
    assert(dst is not None), 'dst is undefined'
    return geopy.distance.distance(src, dst).km*1000

class Pipe(Edge):
    ''' a pipe '''
    friction_factor = 0.01 # friction factor (unitless)

    def __init__(self, _id, f_junction, t_junction, diameter, length):
        Edge.__init__(self, _id, f_junction, t_junction)
        self.diameter = diameter # pipe diameter in meters
        self.length = length # length of pipe in km

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
        return Pipe(pid, f_junction, t_junction, diameter, length)

    def get_matlab_column_names(self, is_ext_data=False):
        ''' Get the Matlab column names for this component. '''
        if is_ext_data:
            column_names = []
        else:
            column_names = ['pipe_i', 'f_junction', 't_junction', 'diameter', 'length', 'friction_factor', 'status']
        return column_names

    def get_matlab_record_values(self, is_ext_data=False):
        ''' Get the Matlab record values for this component. '''
        if is_ext_data:
            keys = []
        else:
            keys = ['id', 'f_junction', 't_junction', 'diameter', 'length', 'friction_factor', 'status']
        values = [getattr(self, key) for key in keys]
        return values

class Compressor(Edge):
    ''' a compressor '''

    def __init__(self, _id, f_junction, t_junction, power_max):
        Edge.__init__(self, _id, f_junction, t_junction)
        self.cmin = 1.0 # min compression ratio
        self.cmax = 1.4 # max compression ratio
        self.fmin = 0 # mine flow m^3/s
        self.fmax = 700 # max flow in m^3/s
        self.power_max = power_max # max power in watts

    @staticmethod
    def from_csv_record(row, mgc):
        ''' create a compressor from csv '''
        _id = int(str(uuid4().int)[:8])
        power_max = float(row['HP']) * 745.7 # hp to watts
        # insert compressor logically between near pipe and near node
        pid = int(row['NEARLINEID'])
        nid = int(row['NEARNODEID'])
        for pipe in mgc.pipes:
            if pipe.id == pid:
                if pipe.f_junction == nid:
                    # compressor is between pipe and its f_junction
                    f_junction = nid
                    t_junction = pid
                    pipe.f_junction = _id
                elif pipe.t_junction == nid:
                    # compressor is between pipe and its t_junction
                    t_junction = nid
                    f_junction = pid
                    pipe.t_junction = _id
                break
        return Compressor(_id, f_junction, t_junction, power_max)

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
            keys = ['id', 'f_junction', 't_junction', 'cmin', 'cmax', 'power_max', 'fmin', 'fmax', 'status']
        values = [getattr(self, key) for key in keys]
        return values

class Regulator(Edge):
    ''' a regulator '''

    def __init__(self, _id, f_junction, t_junction, power_max):
        Edge.__init__(self, _id, f_junction, t_junction)
        self.cmin = 0.9 # min compression ratio
        self.cmax = 1.0 # max compression ratio
        self.fmin = 0 # min flow m^3/s
        self.fmax = 700 # max flow in m^3/s
        self.power_max = power_max # max power in watts

    @staticmethod
    def from_csv_record(row, mgc):
        ''' create a regulator from csv '''
        _id = int(str(uuid4().int)[:8])
        power_max = float(row['HP']) * 745.7 # hp to watts
        # insert compressor logically between near pipe and near node
        pid = int(row['NEARLINEID'])
        nid = int(row['NEARNODEID'])
        for pipe in mgc.pipes:
            if pipe.id == pid:
                if pipe.f_junction == nid:
                    # compressor is between pipe and its f_junction
                    f_junction = nid
                    t_junction = pid
                    pipe.f_junction = _id
                elif pipe.t_junction == nid:
                    # compressor is between pipe and its t_junction
                    t_junction = nid
                    f_junction = pid
                    pipe.t_junction = _id
                break
        return Regulator(_id, f_junction, t_junction, power_max)

    def get_matlab_column_names(self, is_ext_data=False):
        ''' Get the Matlab column names for this component. '''
        if is_ext_data:
            column_names = []
        else:
            column_names = ['regulator_i', 'f_junction', 't_junction', 'cmin', 'cmax', 'power_max', 'fmin', 'fmax', 'status']
        return column_names

    def get_matlab_record_values(self, is_ext_data=False):
        ''' Get the Matlab record values for this component. '''
        if is_ext_data:
            keys = []
        else:
            keys = ['id', 'f_junction', 't_junction', 'cmin', 'cmax', 'power_max', 'fmin', 'fmax', 'status']
        values = [getattr(self, key) for key in keys]
        return values

class Producer(Dispatchable):
    ''' a producer '''

    def __init__(self, _id, junction, fgmax, fg):
        Dispatchable.__init__(self, _id)
        self.junction = junction
        self.fgmin = 0 # kf^3/d to m^3/s
        self.fgmax = fgmax # kf^3/d to m^3/s
        self.fg = fg # kf^3/d to m^3/s

    @staticmethod
    def from_csv_record(row, mgc):
        ''' create producer from csv '''
        if row['RECDEL'] == 'R':
            _id = int(float(row['RDPTID']))
            junction = int(row['NEAR_FID'])
            fgmax = float(row['MAXCAP'])/((10**3)*35.3147*86400) # kf^3/d to m^3/s
            fg = float(row['SCHEDCAP'])/((10**3)*35.3147*86400) # kf^3/d to m^3/s
            return Producer(_id, junction, fgmax, fg)
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
            keys = ['id', 'junction', 'fgmin', 'fgmax', 'fg', 'status', 'dispatchable']
        values = [getattr(self, key) for key in keys]
        return values

class Consumer(Dispatchable):
    ''' a consumer '''

    def __init__(self, _id, junction, fdmax, fd):
        Dispatchable.__init__(self, _id)
        self.junction = junction
        self.fdmin = 0 # kf^3/d to m^3/s
        self.fdmax = fdmax # kf^3/d to m^3/s
        self.fd = fd # kf^3/d to m^3/s

    @staticmethod
    def from_csv_record(row, mgc):
        ''' create consumer from csv record '''
        if row['RECDEL'] == 'D':
            _id = int(float(row['RDPTID']))
            junction = int(row['NEAR_FID'])
            fdmax = float(row['MAXCAP'])/((10**3)*35.3147*86400) # kf^3/d to m^3/s
            fd = float(row['SCHEDCAP'])/((10**3)*35.3147*86400) # kf^3/d to m^3/s
            return Consumer(_id, junction, fdmax, fd)
        return None

    def get_matlab_column_names(self, is_ext_data=False):
        ''' Get the Matlab column names for this component. '''
        if is_ext_data:
            column_names = []
        else:
            column_names = ['consumer_i', 'junction', 'fd', 'status', 'dispatchable']
        return column_names

    def get_matlab_record_values(self, is_ext_data=False):
        ''' Get the Matlab record values for this component. '''
        if is_ext_data:
            keys = []
        else:
            keys = ['id', 'junction', 'fd', 'status', 'dispatchable']
        values = [getattr(self, key) for key in keys]
        return values

class Generator(Consumer):
    ''' a generator '''

    def __init__(self, _id, junction, fdmax, fd, eiaid):
        Consumer.__init__(self, _id, junction, fdmax, fd)
        self.eiaid = eiaid

    @staticmethod
    def from_csv_record(row, mgc):
        junction = int(row['NEAR_FID'])
        fdmax = float(row['W_CAP_MW'])*94.28/3600 # MW to m^3/s
        fd = float(row['S_CAP_MW'])*94.28/3600 # MW to m^3/s
        eiaid = row['EIACODE']
        return Generator(None, junction, fdmax, fd, eiaid)

    def get_matlab_column_names(self, is_ext_data=False):
        ''' Get the Matlab column names for this component. '''
        if is_ext_data:
            column_names = ['eiaid']
        else:
            column_names = ['generator_i', 'junction', 'fdmin', 'fdmax', 'fd', 'status', 'dispatchable']
        return column_names

    def get_matlab_record_values(self, is_ext_data=False):
        ''' Get the Matlab record values for this component. '''
        if is_ext_data:
            keys = ['eiaid']
        else:
            keys = ['id', 'junction', 'fdmin', 'fdmax', 'fd', 'status', 'dispatchable']
        values = [getattr(self, key) for key in keys]
        return values

class Storage(Consumer):
    ''' a storage '''

    def __init__(self, _id, junction, fdmax, fd):
        Consumer.__init__(self, _id, junction, fdmax, fd)

    @staticmethod
    def from_csv_record(row, mgc):
        _id = int(float(row['STFCID']))
        junction = int(row['NEAR_FID'])
        fdmax = float(row['TOTALCAP'])/((10**3)*35.3147) # kf^3 to m^3
        fd = float(row['WORKCAP'])/((10**3)*35.3147) # kf^3 to m^3
        return Storage(_id, junction, fdmax, fd)

    def get_matlab_column_names(self, is_ext_data=False):
        ''' Get the Matlab column names for this component. '''
        if is_ext_data:
            column_names = []
        else:
            column_names = ['storage_i', 'junction', 'fdmax', 'fd', 'status']
        return column_names

    def get_matlab_record_values(self, is_ext_data=False):
        ''' Get the Matlab record values for this component. '''
        if is_ext_data:
            keys = []
        else:
            keys = ['id', 'junction', 'fdmax', 'fd', 'status']
        values = [getattr(self, key) for key in keys]
        return values

class MGC:
    ''' MatGas Case '''
    sound_speed = 312.805 # m/s
    temperature = 273.15 # K
    R = 8.314
    compressibility_factor = 0.8
    gas_molar_mass = 0.0185674
    gas_specific_gravity = 0.6
    specific_heat_capacity_ratio = 1.4
    standard_density = 1.0

    def __init__(self, name, components={}):
        self.id = int(str(uuid4().int)[:8])
        self.baseP = 8101325
        self.baseF = 604.167
        self.per_unit = 1
        assert(name is None or isinstance(name, str)), 'name must be a string'
        self.name = name
        for component in components:
            assert(isinstance(components[component], list)), f'{component} must be a list'
            setattr(self, component, components[component])

    def add_component(self, component):
        ''' adds an abstract component to the model '''
        key = (type(component).__name__).lower()
        if key not in COMPONENT_TYPES:
            key = key+'s'
        if key not in COMPONENT_TYPES:
            raise Exception(f'Unsupported component type {key}')
        components = getattr(self, key, [])
        components.append(component)
        setattr(self, key, components)

    @staticmethod
    def from_csv_files(component_files, name):
        ''' creates MGC object from csv file '''

        mgc = MGC(name)
        for component_type in component_files:
            if component_files[component_type] is None:
                logging.info(f'No {component_type} data supplied')
                continue
            logging.info(f'Processing {component_type} data')
            count = 1
            invalid = 0
            try:
                with open(component_files[component_type]) as csv_file:
                    # process csv file
                    csv_reader = csv.DictReader(csv_file)
                    # skip header row
                    next(csv_reader)
                    for row in csv_reader:
                        # increment record count
                        count += 1
                        try:
                            cls = getattr(sys.modules[__name__], component_type)
                            component = cls.from_csv_record(row, mgc)
                            if component:
                                mgc.add_component(component)
                        except Exception as e:
                            logging.debug(traceback.print_exc())
                            logging.error(f'Unable to add {component_type} component: {e}')
                            invalid += 1
                    logging.info(f'{invalid}/{count} {component_type} components discarded')
            except Exception as e:
                logging.debug(traceback.print_exc())
                logging.warning(f'Unable to process {component_type} file: {e}')
        return mgc

    def to_matlab_document(self):
        ''' creates Matlab output from MGC object '''
        # mgc name
        mgc_str = f'function mgc = {self.name}\n\n'
        # mgc constants
        constants = ['sound_speed', 'temperature', 'R', 'compressibility_factor', 'gas_molar_mass', 'gas_specific_gravity', 'specific_heat_capacity_ratio', 'standard_density', 'baseP', 'baseF', 'per_unit']
        mgc_str += '\n'.join([f'mgc.{constant} = {getattr(self, constant)};' for constant in constants])+'\n\n'
        for component_type in COMPONENT_TYPES:
            components = getattr(self, component_type, [])
            if components:
                component_header = components[0].get_matlab_header()
                component_records = '\n'.join([component.get_matlab_record() for component in components])
                component_footer = components[0].get_matlab_footer()
                mgc_str += '\n'.join([component_header, component_records, component_footer])
                mgc_str += '\n\n'
                ext = True
                if components[0].get_matlab_record_values(ext):
                    # add extra data table
                    component_header = components[0].get_matlab_header(ext)
                    component_records = '\n'.join([component.get_matlab_record(ext) for component in components])
                    component_footer = components[0].get_matlab_footer(ext)
                    mgc_str += '\n'.join([component_header, component_records, component_footer])
                    mgc_str += '\n\n'
        mgc_str += "end\n"
        return mgc_str

def csv2mgc(components):
    ''' generate matlab output from csv files '''
    component_files = {
        'Junction': components.junctions,
        'Pipe': components.pipes,
        'Compressor': components.compressors,
        'Regulator': components.regulators,
        'Producer': components.producers,
        'Consumer': components.consumers,
        'Generator': components.generators,
        'Storage': components.storage
    }

    return MGC.from_csv_files(component_files, name=args.name).to_matlab_document()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Convert ArcGIS CSVs to Matlab mgc format')
    parser.add_argument('-n', '--name', type=str, help='Model name', metavar='MODEL_NAME')
    parser.add_argument('-j', '--junctions', type=str, help='Junction data file', metavar='JUNCTION_FILE')
    parser.add_argument('-p', '--pipes', type=str, help='Pipe data file', metavar='PIPE_FILE')
    parser.add_argument('-c', '--compressors', type=str, help='Compressor data file', metavar='COMPRESSOR_FILE')
    parser.add_argument('-e', '--regulators', type=str, help='Regulators data file', metavar='REGULATOR_FILE')
    parser.add_argument('-d', '--producers', type=str, help='Producer data file', metavar='PRODUCER_FILE')
    parser.add_argument('-r', '--consumers', type=str, help='Consumer data file', metavar='CONSUMER_FILE')
    parser.add_argument('-g', '--generators', type=str, help='Generator data file', metavar='GENERATOR_FILE')
    parser.add_argument('-s', '--storage', type=str, help='Generator data file', metavar='STORAGE_FILE')
    parser.add_argument('-o', '--output', type=str, help='Matlab output file')
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
    output = args.output

    results = csv2mgc(args)

    if output is not None:
        # write result to file
        with open(output, 'w') as fp:
            fp.write(results)
    else:
        # print to stdout
        print(results)
