#!/usr/bin/env python
import argparse
import sys
import socket
import random
import struct

from scapy.all import *#sendp, send, get_if_list, get_if_hwaddr
from scapy.all import Packet
from scapy.all import Ether, IP, UDP, TCP
from netcacheHeader import NetCache

def get_if():
    ifs=get_if_list()
    iface=None # "h1-eth0"
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break;
    if not iface:
        print "Cannot find eth0 interface"
        exit(1)
    return iface

def main():

    if len(sys.argv)<4:
		print "requires minimum 3 parameters: <destination> <op(read/write)> <key> <(if write)value>"
		exit(1)
    if sys.argv[2] == "write" and len(sys.argv)<5:
		print "write operation requires a value to write"
		exit(1)
    if sys.argv[2] not in ["read","write"]:
		print "invalid operation: valid operations are 'read' and 'write'"
		exit(1)
    if (len(sys.argv)>4 and sys.argv[2] == "read") or len(sys.argv)>5:
		print "Too many arguments \n requires minimum 3 parameters: <destination> <op(read/write)> <key> <(if write)value>"

    addr = socket.gethostbyname(sys.argv[1])
    iface = get_if()

    print "sending on interface %s to %s" % (iface, str(addr))
    pkt =  Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff')
    pkt = pkt /IP(dst=addr) / TCP(sport=random.randint(49152,65535)) 
    

    if sys.argv[2] == "read":
	pkt = pkt/NetCache(op=0,key=int(sys.argv[3]))
    else:
	pkt = pkt/NetCache(op=1, key=int(sys.argv[3]),data=int(sys.argv[4]))
 
    #pkt.show2()
    ls(pkt)
    sendp(pkt, iface=iface, verbose=False)

if __name__ == '__main__':
    main()
