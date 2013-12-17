request = require 'request-json'
path = require 'path'
fs = require 'fs'

{docopt} = require 'docopt'
log = require('printit')(date: false, prefix: null)

version = require('./package.json').version

# Init doc
doc = """
Usage:
"""

getModulePath = ->
    path.join(path.dirname(fs.realpathSync(__filename)), 'clis')

isCoffeeFile = (fileName) ->
    extension = fileName.split('.')[1]
    firstChar = fileName[0]
    firstChar isnt '.' and extension is 'coffee'

loadModules = ->
    moduleFiles = fs.readdirSync getModulePath()
    modules = {}
    for moduleFile in moduleFiles
        if isCoffeeFile moduleFile
            name = moduleFile.split('.')[0]
            modulePath = "./clis/#{name}"
            modules[name] = require modulePath
            doc += "\n" + modules[name].doc
    modules

getUserHome = ->
    process.env[if process.platform is 'win32' then 'USERPROFILE' else 'HOME']

getCredentials = ->
    configFile = path.join getUserHome(), '.cozy-config.json'
    try
        require configFile
    catch exception
        log.error """
No configuration file found. expected location : ~/.cozy-config.json
The file is maybe corrupted.
"""
        process.exit 1


# Load modules from clis directory
modules = loadModules doc

# Add docopt options
doc += "\n
cozy-cli -h | --help | --version
"

# Get url
credentials = getCredentials()
url = credentials.url
password = credentials.password

opts = docopt doc, version: version

# Check if action match a given module
# If yes, match args with available commands.
moduleName = process.argv[2]
if modules[moduleName]?
    client = request.newClient url
    client.post 'login', password: password, (err) ->
        if err
            log.error "Can't log to your Cozy"
            process.exit 1
        modules[moduleName].action opts, client
