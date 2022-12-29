#!/usr/bin/env python
# -*- coding: utf-8 -*-
# ==============================================================================
# Compat:       3.5+


# ==============================================================================


# pip install miniupnpc

import miniupnpc

u = miniupnpc.UPnP()
u.discoverdelay = 200
u.discover()
u.selectigd()
print('external ip address: {}'.format(u.externalipaddress()))
