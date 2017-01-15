name = "Equilibrium_Balance_Mod"
uid = "RELEASE1-V40R-L28D-93JF-EQBALANCEMOD"
version = 40
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
    ['balance'] = '/balance',
    ['equilibriumhook'] = '/equilibriumhook',
    ['animations'] = '/animations',
    ['modules'] = '/modules',
    ['projectiles'] = '/projectiles',
    ['textures'] = '/textures',
}
hooks = {
    '/equilibriumhook',
    '/balance',
}