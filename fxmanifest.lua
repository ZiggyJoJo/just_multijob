fx_version   'cerulean'
use_experimental_fxv2_oal 'yes'
lua54        'yes'
game         'gta5'

shared_scripts {
  '@ox_lib/init.lua',
  'config.lua',
}

server_scripts {
  '@mysql-async/lib/MySQL.lua',
  'server.lua',
}

client_scripts {
  'client.lua',
}