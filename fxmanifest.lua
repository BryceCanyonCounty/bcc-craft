fx_version 'adamant'
games { 'rdr3' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

author 'BCC Team'

description 'Advanced Craft Script using FeatherMenu.'

shared_scripts {
    'configs/*.lua',
    'locale.lua',
    'languages/*.lua'
}

client_scripts {
    'client/functions.lua',
    'client/client.lua',
    'client/MenuSetup.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/functions.lua',
    'server/dbUpdater.lua',
    'server/server.lua'
}

dependency {
    'vorp_core',
    'vorp_inventory',
    'vorp_character',
    'bcc-utils',
    'feather-menu',
    'feather-progressbar',
}

version '0.2.0'
