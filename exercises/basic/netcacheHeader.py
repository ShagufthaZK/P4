from scapy.all import *
import sys, os

PORT_NC = 1234
TYPE_IPV4 = 0x0800

class NetCache(Packet):
    name = "NetCache"
    fields_desc = [
        ShortField("op", 0),
	IntField("key", 0),
	IntField("data", 0)
    ]
    def mysummary(self):
        return self.sprintf("key=%key%, op=%op%")


bind_layers(TCP, NetCache, dport=PORT_NC)

