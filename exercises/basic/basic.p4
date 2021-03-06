/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 2048;
const bit<16> PORT_NC = 1234;
const bit<8> TYPE_TCP = 6;
const bit<8> TYPE_UDP = 17;

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
   
}
/*
header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<6>  ctrl;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}*/

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> length_;
    bit<16> checksum;
}

header kv_t{
    bit<16> op;
     int<32> key;
     int<32> data;

}

struct metadata {
    /* empty */
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    udp_t	 udp;
    kv_t	 kv;
    
}

register<int<32>>(5) kv_store;

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        /* TODO: add parser logic */
        transition parse_ethernet;
    }
	state parse_ethernet {
	packet.extract(hdr.ethernet);
	transition select(hdr.ethernet.etherType){
	TYPE_IPV4 : parse_ipv4;
	default: accept;
	}
	}

	state parse_ipv4 { 
	packet.extract(hdr.ipv4);
	transition select(hdr.ipv4.protocol){
		TYPE_UDP: parse_udp;
		default: accept;
	}
	}

	state parse_udp { 
	packet.extract(hdr.udp);
	transition select(hdr.udp.dstPort){
		PORT_NC: parse_kv;
		default: accept;
	}
	}

	state parse_kv { 
	packet.extract(hdr.kv);
	transition accept;
	
	}
	

}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    
    
    action kv_read(bit<32> index,egressSpec_t port){
	standard_metadata.egress_spec = port;
	macAddr_t temp = hdr.ethernet.srcAddr;
	hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
	hdr.ethernet.dstAddr = temp;
	hdr.ipv4.ttl = hdr.ipv4.ttl -1;
	kv_store.read(hdr.kv.data,index);

    }

    action kv_write(bit<32> index,egressSpec_t port){
	standard_metadata.egress_spec = port;
	macAddr_t temp = hdr.ethernet.srcAddr;
	hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
	hdr.ethernet.dstAddr = temp;
	hdr.ipv4.ttl = hdr.ipv4.ttl -1;
	kv_store.write(index,hdr.kv.data);
	
    }

    table kv_exact {
	key = {hdr.kv.op:exact;hdr.kv.key:exact;}
	actions = {kv_read;kv_write;NoAction;}
	size = 10;
	default_action = NoAction();
        
   }
    
    apply {
       
	if(hdr.kv.isValid()){kv_exact.apply();}
	/*else 
	ipv4_lpm.apply();*/
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
	update_checksum(
	    hdr.ipv4.isValid(),
            { hdr.ipv4.version,
	      hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        /* TODO: add deparser logic */
	packet.emit(hdr.ethernet);
	packet.emit(hdr.ipv4);
	packet.emit(hdr.udp);
	packet.emit(hdr.kv);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
