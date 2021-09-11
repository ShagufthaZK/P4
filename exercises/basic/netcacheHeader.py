from scapy.all import *
import sys, os

TYPE_NC = 0x1212
TYPE_IPV4 = 0x0800

class NetCache(Packet):
    name = "NetCache"
    fields_desc = [
        ShortField("op", 0),
	IntField("key", 0),
	#FieldLenField("len", None, length_of="data"),
	#StrLenField("data", "", length_from=lambda pkt:pkt.len)
	IntField("data", 0)
    ]
    def mysummary(self):
        return self.sprintf("key=%key%, op=%op%")


bind_layers(TCP, NetCache, type=TYPE_NC)
#bind_layers(MyTunnel, IP, pid=TYPE_IPV4)
