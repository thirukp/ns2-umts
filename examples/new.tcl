# Check input
if {$argc != 0} {
	puts ""
	puts "Wrong Number of Arguments! No arguments in this topology"
	puts ""
	exit (1)
}
global ns

source ./function.tcl

# set output directory
set output_dir .

#create a simulation instance
set ns [new Simulator]
#$ns use-newtrace

$ns color 1 Blue
$ns color 2 Red

#set trace output file and directory
set f [open out.tr w]
$ns trace-all $f
set namfile [open out.nam w]
$ns namtrace-all-wireless $namfile 1000 1000

# configure UMTS 
$ns set hsdschEnabled_ 1addr
$ns set hsdsch_rlc_set_ 0
$ns set hsdsch_rlc_nif_ 0

# configure address model (domain:cluster:ip number) (needed for routing over a basestation)
$ns node-config -addressType hierarchical
AddrParams set domain_num_  25           	           												;# domain number
AddrParams set cluster_num_ {1  1 1 1  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1}            		;# cluster number
AddrParams set nodes_num_   {22 1 1 21 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1}	      			;# nodes number             

#configure RNC 
puts ""
puts "Creating RNC"
$ns node-config -UmtsNodeType rnc 
set RNC [$ns create-Umtsnode 0.0.0] ;# node id is 0.
setNodePosition $RNC 800 800 0 
$RNC color "yellow"
$ns initial_node_pos $RNC 20
printNodeID $RNC "RNC"
puts "Done RNC configuration"

# UMTS Bastation
puts ""
puts "Creating BS"
$ns node-config -UmtsNodeType bs \
		-downlinkBW 384kbs \
		-downlinkTTI 10ms \
		-uplinkBW 384kbs \
		-uplinkTTI 10ms \
     	-hs_downlinkTTI 2ms \
      	-hs_downlinkBW 384kbs 

set BS [$ns create-Umtsnode 0.0.1] ;# node id is 1, BS and RNC is in the same domain
setNodePosition $BS 1000 1000 0
$BS color "blue"
$ns initial_node_pos $BS 10
printNodeID $BS "BS"
puts "Done BS configuration"

# Link BS and RNC 
$ns setup-Iub $BS $RNC 622Mbit 622Mbit 15ms 15ms DummyDropTail 2000

#create UMTS nodes
puts ""
puts "Creating UMTS nodes"
$ns node-config -UmtsNodeType ue \
		-baseStation $BS \
		-radioNetworkController $RNC

for {set i 0} {$i < 20} {incr i 1} {
	set umts_ue($i) [$ns create-Umtsnode 0.0.[expr $i+2]]
	setRandomPositionForNode $umts_ue($i) 500 600
#	printNodeID $umts_ue($i) "umts_ue($i)"
#	printNodePosition $umts_ue($i)
	$umts_ue($i) color "red"
	$ns initial_node_pos $umts_ue(0) 5
	#umtsNodeMove $umts_ue($i) 1.0 0.2 5.0
}

# create a dummy node for simulation run normally, but
# it seems no need anymore

#set dummy_node [$ns create-Umtsnode 0.0.3] ;# node id is 3
#$dummy_node set Y_ 150
#$dummy_node set X_ 100 
#$dummy_node set Z_ 0
#$dummy_node color "brown"

# Create SGSN and GGSN, they are in different domain and id for SGSN0 and GGSN0 are 4 and 5, respectively.

puts ""
puts "Creating SGSN and GGSN"

set SGSN [$ns node 1.0.0]
setNodePosition $SGSN 850 800 0 
printNodeID $SGSN "SGSN"
$SGSN color "blue"
$ns initial_node_pos $SGSN 10

set GGSN [$ns node 2.0.0]
setNodePosition $GGSN 870 800 0
printNodeID $GGSN "GGSN"
$GGSN color "blue"
$ns initial_node_pos $GGSN 10

puts "Done SGSN and GGSN creation"


# Create core-network node

puts ""
puts "Creating core-network node"

set CN_host0 [$ns node 4.0.0]
setNodePosition $CN_host0 600 1000 0 
printNodeID $CN_host0 "CN_host0"
$CN_host0 color "black"
$ns initial_node_pos $CN_host0 5

puts "Done core-network node creation"

# do the connections in the UMTS part
puts ""
puts "Connecting RNC SGSN GGSN CN_host0"

$ns duplex-link $RNC $SGSN 622Mbit 0.4ms DropTail 1000
$ns duplex-link $SGSN $GGSN 622MBit 10ms DropTail 1000
$ns duplex-link $GGSN $CN_host0 10MBit 15ms DropTail 1000

puts "Done connection of RNC, SGSN GGSN CN_host0"

puts ""
puts "Add Gateway"
$RNC add-gateway $SGSN                                  		;#这一句应该放在链路搭建完成之后，一般情况放在这个位置
puts "Done adding gateway"

# add WLAN network 

puts ""
puts "Creating WLAN"
# parameter for wireless nodes
set opt(chan)           Channel/WirelessChannel   			;# channel type for 802.11
set opt(prop)           Propagation/TwoRayGround   			;# radio-propagation model 802.11
set opt(netif)          Phy/WirelessPhy            			;# network interface type 802.11
set opt(mac)            Mac/802_11                 			;# MAC type 802.11
set opt(ifq)            Queue/DropTail/PriQueue    			;# interface queue type 802.11
set opt(ll)             LL                         			;# link layer type 802.11
set opt(ant)            Antenna/OmniAntenna        			;# antenna model 802.11
set opt(ifqlen)         50              	   			    ;# max packet in ifq 802.11
set opt(adhocRouting)   DSDV                       			;# routing protocol 802.11
set opt(umtsRouting)    ""                         			;# routing for UMTS (to reset node config)
set opt(x) 				1000   			                    ;# X dimension of the topography
set opt(y) 				1000		                        ;# Y dimension of the topography

Mac/802_11 set basicRate_ 11Mb
Mac/802_11 set dataRate_ 11Mb
Mac/802_11 set bandwidth_ 11Mb
Mac/802_11 set client_lifetime_ 10 					            ;#increase since iface 2 is not sending traffic for some time

puts "Creating topology"
set topo [new Topography]
$topo load_flatgrid $opt(x) $opt(y)
puts "Topology created"

# create God
set god [create-god 66]				                		     ;# give the number of nodes 

# Create multiple interfaces nodes
puts ""
puts "Creating multiple interfaces ue"
$ns node-config  -multiIf ON                            		;#to create MultiFaceNode
for {set i 0} {$i < 20} {incr i 1} {
	set ue($i) [$ns node [expr 5+$i].0.0]						;# multiIf has not X_ and Y_
}
$ns node-config  -multiIf OFF                           		;#reset attribute
puts "Done multiIf node creation"

# set number of hop between nodes, minimize the calculation time
#$god set-dist 1 2 1 
#$god set-dist 0 2 2 
#$god set-dist 0 1 1 
set god [God instance]

#配置接入点AP 
puts "Creating AP"
puts ""
puts "coverge:70m"

Phy/WirelessPhy set Pt_ 0.025
Phy/WirelessPhy set RXThresh_ 3.92405e-08
Phy/WirelessPhy set CSThresh_ [expr 0.9*[Phy/WirelessPhy set RXThresh_]]

$ns node-config  -adhocRouting $opt(adhocRouting) \
                 -llType $opt(ll) \
                 -macType $opt(mac) \
                 -channel [new $opt(chan)] \
                 -ifqType $opt(ifq) \
                 -ifqLen $opt(ifqlen) \
                 -antType $opt(ant) \
                 -propType $opt(prop)    \
                 -phyType $opt(netif) \
                 -topoInstance $topo \
                 -wiredRouting ON \
                 -agentTrace OFF\
                 -routerTrace OFF \
                 -macTrace ON  \
                 -movementTrace OFF	

# configure Base station 802.11
set AP0 [$ns node 3.0.0]
setNodePosition $AP0 200 50 0 
printNodeID $AP0 "AP0"
$AP0 color "red"
$ns initial_node_pos $AP0 10

[$AP0 set mac_(0)] bss_id [[$AP0 set mac_(0)] id]
[$AP0 set mac_(0)] enable-beacon
[$AP0 set mac_(0)] set-channel 1

puts "Done AP creation"

# creation of the wireless interface 802.11
puts ""
puts "Creating WLAN UEs"
$ns node-config -wiredRouting OFF \
                -macTrace ON 				
for {set i 0} {$i < 20} {incr i 1} {
	set wlan_ue($i) [$ns node 3.0.[expr $i+1]]
	$wlan_ue($i) random-motion 1
	$wlan_ue($i) base-station [AddrParams addr2id [$AP0 node-addr]]
#	setRandomPositionForNode $wlan_ue($i) 100 300 
	syncTwoInterfaces $umts_ue($i) $wlan_ue($i)
	printNodeID $wlan_ue($i) "wlan_ue($i)"
#	printNodePosition $wlan_ue($i)
	$ns initial_node_pos $wlan_ue($i) 5
}
puts "Done creation of WLAN UEs"
# add link to backbone
puts ""
puts "Connecting AP0 to GGSN"
$ns duplex-link $AP0 $GGSN 10MBit 15ms DropTail 1000
puts "Done connection of AP0 and GGSN"

# add interfaces to MultiFaceNode
puts ""
puts "adding interfaces to multiface ue"
for {set i 0} {$i < 20} {incr i 1} {
	$ue($i) add-interface-node $wlan_ue($i)
	$ue($i) add-interface-node $umts_ue($i)
}
puts "Done adding interfaces to multiface ue"

puts "***********************Completed successfully*****************"
puts "##############################################################"
puts ""

# create a TCP agent and attach it to multi-interface node
puts "##############################################################"
puts "***************Generating traffic: using UDP***************"
puts ""

puts "creating a real time monitor agent"
set realtime_monitor [new Agent/RealtimeTrace]

for {set i 0} {$i < 20} {incr i 1} {
	set src_umts($i)  [new Agent/UDP]
	$ue($i) attach-agent $src_umts($i) $umts_ue($i)
	set sink_umts($i) [new Agent/Null]
	#$ue(0) attach-agent $sink(0) $umts_ue(0) 
    $ns attach-agent $umts_ue($i) $sink_umts($i)
    $src_umts($i) set fid_ $i
    $sink_umts($i) set fid_ $i

    set src_wlan($i)  [new Agent/UDP]
    $ue($i) attach-agent $src_wlan($i) $wlan_ue($i)
    set sink_wlan($i) [new Agent/Null]
    #$ue(0) attach-agent $sink(0) $umts_ue(0) 
    $ns attach-agent $wlan_ue($i) $sink_wlan($i)
    $src_wlan($i) set fid_ [expr $i+20]
    $sink_wlan($i) set fid_ [expr $i+20]
}

for {set i 0} {$i < 20} {incr i 1} {
	set app($i) [new Application/Traffic/CBR]
}

#$ns connect $src_umts(0) $sink_wlan(1)
#puts [getNodeIpAddress $umts_ue(0)]
#puts [getNodeIpAddress $wlan_ue(1)]
#puts "----"
#set e_app(0) [new Application/Traffic/CBR]
#$e_app(0) attach-agent $src_umts(0)
#$e_app(0) set packet_size_ 666
#$e_app(0) set type_ CBR

#$ns connect $src_wlan(1) $sink_umts(2)
#puts [getNodeIpAddress $wlan_ue(1)]
#puts [getNodeIpAddress $umts_ue(2)]
#puts "----"

#set e_app(1) [new Application/Traffic/CBR]
#$e_app(1) attach-agent $src_wlan(1)
#$e_app(1) set packet_size_ 777
#$e_app(1) set type_ CBR

#$ns connect $src_umts(2) $sink_umts(0)
#puts [getNodeIpAddress $umts_ue(2)]
#puts [getNodeIpAddress $umts_ue(0)]
#puts "BS ipaddress is"
#puts [getNodeIpAddress $BS]
#puts "UE0 is [getNodeIpAddress $ue(0)]"
#puts "----"
#set e_app(2) [new Application/Traffic/CBR]
#$e_app(2) attach-agent $src_umts(2)
#$e_app(2) set packet_size_ 888
#$e_app(2) set type_ CBR

#$ns at 1.0 "$e_app(1) start"
#$ns at 1.0 "$e_app(2) start"

for {set i 0} {$i < 18} {incr i 1} {
	set dst_node_index [expr $i+2]
	$ns connect $src_umts($i) $sink_wlan($dst_node_index)
	puts [getNodeIpAddress $umts_ue($i)]
	puts [getNodeIpAddress $wlan_ue($dst_node_index)]
	puts "----"
	$app($i) attach-agent $src_umts($i)
	$app($i) set packet_size_ 666
	$app($i) set type_ CBR
	$ns at 1.0 "$app($i) start"
	$ns at 10.0 "getCurrentDelay  $ue($i) $wlan_ue($dst_node_index) \"cbr\" $realtime_monitor"
}


puts "finished"
puts ""

# do some kind of registration in UMTS
puts "****************************************************************"
puts "do some kind of registration in UMTS......"
$ns node-config -llType UMTS/RLC/AM \
		-downlinkBW 384kbs \
		-uplinkBW 384kbs \
		-downlinkTTI 20ms \
		-uplinkTTI 20ms \
   		-hs_downlinkTTI 2ms \
    	-hs_downlinkBW 384kbs

# for the first HS-DSCH, we must create. If any other, then use attach-hsdsch

$ns create-hsdsch $umts_ue(0) $src_umts(0)
for {set i 1} {$i < 19} {incr i 1} {
	#$ns attach-hsdsch $umts_ue(1) $src_umts(1)
	#$ns attach-hsdsch $umts_ue(1) $sink_umts(1)
	$ns attach-hsdsch $umts_ue($i) $src_umts($i)
	$ns attach-hsdsch $umts_ue($i) $sink_umts($i)
}

#puts "create hsdsch umts_ue(1) sink(1)"

#for {set i 2} {$i < 20} {incr i 2} {
#	$ns attach-hsdsch $umts_ue($i) $src($i)
 # puts "attach hsdsch to umts_ue($i) src($i)"
	#$ns attach-hsdsch $umts_ue([expr $i+1]) $sink([expr $i+1])
  #puts "attach hsdsch umts_ue([expr $i+1]) sink([expr $i+1])"
#}
# we must set the trace for the environment. If not, then bandwidth is reduced and
# packets are not sent the same way (it looks like they are queued, but TBC)
puts "set trace for the environment......"

$BS setErrorTrace 0 "idealtrace"

# load the CQI (Channel Quality Indication)
puts "loading Channel Quality Indication......"

$BS loadSnrBlerMatrix "SNRBLERMatrix"

$BS trace-outlink $f 2

#for {set i 0} {$i < 20} {incr i 1} {
#  $umts_ue($i) trace-inlink $f $i
#  $umts_ue($i) trace-outlink $f $i
#  $wlan_ue($i) trace-outlink $f [expr $i + 20]
#  $wlan_ue($i) trace-inlink $f [expr $i + 20]
#}


puts "finished"
puts "****************************************************************"
puts "################################################################"

#$ns at  2.3 "getMeanDelay  $ue(1) $umts_ue(2) \"cbr\" $realtime_monitor "
#$ns at 12.3 "getMeanDelay  $ue(0) $wlan_ue(1) \"cbr\" $realtime_monitor "
#$ns at 12.0 "getMeanDelay  $ue(2) $umts_ue(0) \"cbr\" $realtime_monitor"
#$ns at 12.1 "getMeanThroughput $ue(0) \"cbr\" $realtime_monitor"
$ns at 3.0 "getDistance $wlan_ue(1) $wlan_ue(4)"
$ns at 0.1 "record $wlan_ue(1)"

# call to redirect traffic
#$ns at 2 "redirectTraffic $ue(0) $wlan_ue(0) $src_wlan(0) $sink_wlan(1)"
#$ns at 2 "$ns trace-annotate \"Redirecting traffic\""

$ns at 15 "finish"

puts " Simulation is running ... please wait ..."
$ns run
