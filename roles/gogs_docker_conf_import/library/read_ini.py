#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) Copyright 2016 Sean "Shaleh" Perry

DOCUMENTATION = '''
---
module: read_ini
short_description: Read settings in INI files
description:
     - Read individual settings in an INI-style file
version_added: "0.9"
options:
  path:
    description:
      - Path to the INI-style file
    required: true
    default: null
  section:
    description:
      - Section name in INI file.
    required: true
    default: null
  option:
    description:
      - Name of the option to read.
    required: true
    default: null
requirements: [ ConfigParser ]
author: Sean "Shaleh" Perry
'''

EXAMPLES = '''
# Read "fav" from section "[drinks]" in specified file.
- read_ini: path=/etc/conf section=drinks option=fav
'''

try:
    import configparser
except ImportError:
    import ConfigParser as configparser

try:
    from StringIO import StringIO
except ImportError:
    from io import StringIO

import sys

from ansible.module_utils.basic import *


class ReadIniException(Exception):
    pass


def do_read_ini(module, filename, section=None, option=None):
    cp = configparser.ConfigParser()
    cp.optionxform = lambda x: x  # identity function to prevent casting

    try:
        ini_str = '[root]\n' + open(filename, 'r').read()
        ini_fp = StringIO(ini_str)
        cp = configparser.RawConfigParser()
        cp.readfp(ini_fp)
    except IOError as e:
        raise ReadIniException("failed to read {}: {}".format(filename, e))

    try:
        return cp.get(section, option)
    except configparser.NoSectionError:
        raise ReadIniException("section does not exist: " + section)
    except configparser.NoOptionError:
        raise ReadIniException("option does not exist: " + option)


def main():
    spec = {
        'path': {'required': True},
        'section': {'required': True},
        'option': {'required': True},
        'raise_error': {'required': False, 'type': 'bool', 'default': True},
    }
    module = AnsibleModule(argument_spec=spec)

    path = os.path.expanduser(module.params['path'])
    section = module.params['section']
    option = module.params['option']
    raise_error = module.params['raise_error']

    try:
        value = do_read_ini(module, path, section, option)
        module.exit_json(path=path, changed=True, value=value)
    except ReadIniException as e:
        if raise_error:
            module.fail_json(msg=str(e))
        else:
            module.exit_json(path=path, changed=False, value=None)


if __name__ == '__main__':
    main()
