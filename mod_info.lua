name = "Equilibrium_Balance_Mod"
uid = "FEATURE2-V63F-2020-D16M-EQBALANCEMOD"
version = 63
copyright = "Ithilis - feel free to use this code, but ask permission first, and credit Equilibrium in your mod."
description = "This mod fixes all balance issues with the game, and improves the gameplay to a higher level."
icon = "/Equilibrium_balance_mod.png"
author = "Ithilis"
selectable = true
enabled = true
exclusive = false
ui_only = false
requires = {}
requiresNames = {}
conflicts = {}
before = {}
after = {}
_faf_modname='equilibrium'
mountpoints = {
    ['animations'] = '/animations',
    ['balance'] = '/balance',
    ['equilibriumhook'] = '/equilibriumhook',
    ['lua'] = '/lua',
    ['modules'] = '/modules',
    ['projectiles'] = '/projectiles',
    ['textures'] = '/textures',
    ['units'] = '/units',
}
hooks = {
    '/schook',
    '/hook',
    '/equilibriumhook',
    '/balance',
    '/EQhook', --special hook folder for mods to hook after eq. this is also great because it doesn't do anything if eqs not loaded.
}