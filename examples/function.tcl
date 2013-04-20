# Author: Huang Minghe (h.minghe@gmail.com)
# Date: 2013.4.18
# Description: 
# 	This script is the function for the new.tcl, you can copy, modify and use it freely.

set NO_SERVICE 0
set WIFI_IN_SERVICE 1
set UMTS_IN_SERVICE 2

# function: finish process 
proc finish {} {
    global ns f
    $ns flush-trace
    close $f
    puts " Simulation ended."
    exit 0
}

# function: create UDP Agent for UE
# args
#     ue: ue which need agent
#     agent_name: agent name
#     interface: the network interface which ue is using
proc createUDPAgentForUE {ue agent_name interface} {
    set agent_name [new Agent/UDP]
    $ue attach-agent $agent_name $interface
}

# function: create FullTcp Agent for UE
# args
#     ue: ue which need agent
#     agent_name: agent name
#
proc createTCPAgentForUE {ue agent_name} {
    set agent_name [new Agent/TCP/FullTcp]
    $ue attach-agent $agent_name $interface
}

# function: connect send agent and recieve agent of two UEs 
# args
#     agent_src: source agent
#     agent_des: destination agent
#
proc connectTwoAgents {agent_src agent_des} {
  $ns connect $agent_ue1 $agent_ue2
}

# function: set Node position
# args
#  	node: umts node
#  	pos_x: X_ value
#  	pos_y: Y_ value
#  	pos_z: Z_ value
proc setNodePosition {node pos_x pos_y pos_z} {
	$node set X_ $pos_x
	$node set Y_ $pos_y
	$node set Z_ $pos_z
}

# function: set random position for node
# args
# 	node: node
# 	min: minimum value you want
# 	max: maximum value you want
proc setRandomPositionForNode {node min max} {
	set rand_x [expr rand()]
	set rand_y [expr rand()]
	set pos_x [expr $rand_x * ($max - $min) + $min]
	set pos_y [expr $rand_y * ($max - $min) + $min]
	$node set X_ $pos_x
	$node set Y_ $pos_y
	$node set Z_ 0.0
}

# funcition: make umts ue move by setting the X_ and Y_ value
# args 
# 	umts_ue: umts node
proc moveUmtsNode {umts_ue} {
	set prev_x [$umts_ue set X_]
	set prev_y [$umts_ue set Y_]
	set rand_x [expr rand()]
	set rand_y [expr rand()]
	set mov_x [expr $rand_x * (2 - (-2)) + (-2)]
	set mov_y [expr $rand_y * (2 - (-2)) + (-2)]
	$umts_ue set X_ [expr $prev_x + $mov_x]
	$umts_ue set Y_ [expr $prev_y + $mov_y]
}

# function: move umts node every certain time slot
# args
# 	umts_ue: umts node
# 	time_slot: time slot
# 	from_time: time to start to move
# 	time_length: the length of whole time
proc umtsNodeMove {umts_ue from_time time_slot time_lenght} {
	global ns
	for {set i 0} {$i < [expr $time_lenght/$time_slot]} {incr i 1} {
		$ns at [expr $from_time + $i * $time_slot] "moveUmtsNode $umts_ue"	
	}
}

# function: get node ip address
# args
# 	ue: node to get
proc getNodeIpAddress {ue} {
	$ue set address_
}

# function: make two nodes(interfaces) move together, because actually a mobile phone with
# 	two different network cards but they are at the same position, they are all in the cellphone
# args
# 	wlan_ue: wifi network interface
# 	umts_ue: umts(3G) network interface
proc syncTwoInterfaces {wlan_ue umts_ue} {
	$umts_ue set X_ [$wlan_ue set X_]
	$umts_ue set Y_ [$wlan_ue set Y_]
}

# function: initial network selection, when network topo done, mobile node will chose an network to stay according to RSSI
# args
# 	num: number of multiple nodes
# 	ue: the mutilple interfaces mobile node
# 	wlan_ue: the wifi network card
# 	umts_ue: the umts(3G) network card
# 	ap: the wifi access point
# 	bs: the 3G basetation 
# notice: we select network using the WIFI comes first policy
proc initNetworkSelection {num ue wlan_ue umts_ue ap bs} {
	for {set i 0} {$i < $num} {
		scanNetworks $ue($i) $in_service_network($i) $wlan_ue($i) $umts_ue($i) $ap $bs
	}
}

# function: scan networks
# args
# 	num: number of multiple interfaces mobile node
# 	ue: the multiple interfaces mobile node
# 	in_service_network: the network ue is in
# 	wlan_ue: wifi interface 
# 	umts_ue: umts interface
# 	ap: wifi access point
# 	bs: umts basetation
# return: a list of network attach 1 for WIFI, 2 for UMTS and 0 for no service
proc scanNetworks {num ue in_service_network wlan_ue umts_ue ap bs} {
	upvar $ue UE
	upvar $in_service_network IN_SERVICE_NETWORK
	upvar $wlan_ue WLAN_UE
	upvar $umts_ue UMTS_UE
	
	set ap_cover_radiu 70
	set bs_cover_radiu 1000
	for {set i 0} {$i < $num} {incr i 1} {
		set ap_distance [getDistance $WLAN_UE($i) $ap]
		set bs_distance [getDistance $UMTS_UE($i) $bs]
	
		#puts "ap_distance $ap_distance"
		#puts "bs_distance $bs_distance"
		if {$ap_distance <= $ap_cover_radiu} {
			#select wifi
			puts "scanning WIFI, and it's good"
		#	set IN_SERVICE_NETWORK($i) $WIFI_IN_SERVICE
			set IN_SERVICE_NETWORK($i) 1
		} 
		if {$bs_distance < $bs_cover_radiu && $ap_distance > $ap_cover_radiu} {
			#select umts
			puts "scanning  UMTS, and it's good"
		#	set IN_SERVICE_NETWORK($i) $UMTS_IN_SERVICE
			set IN_SERVICE_NETWORK($i) 2
		} 
		if {$ap_distance > $ap_cover_radiu && $bs_distance > $bs_cover_radiu} {
			puts "No network service"
			#set IN_SERVICE_NETWORK $NO_SERVICE
			set IN_SERVICE_NETWORK($i) 0
		} 
	}
	puts "IN_SERVICE_NETWORK $IN_SERVICE_NETWORK(1)"
	#array get IN_SERVICE_NETWORK
	return [list 0 $IN_SERVICE_NETWORK(0) 1 $IN_SERVICE_NETWORK(1) \
				 2 $IN_SERVICE_NETWORK(2) 3 $IN_SERVICE_NETWORK(3) \
				 4 $IN_SERVICE_NETWORK(4) 5 $IN_SERVICE_NETWORK(5) \
				 6 $IN_SERVICE_NETWORK(6) 7 $IN_SERVICE_NETWORK(7) \
				 8 $IN_SERVICE_NETWORK(8) 9 $IN_SERVICE_NETWORK(9) \
				10 $IN_SERVICE_NETWORK(10) 11 $IN_SERVICE_NETWORK(11) \
				12 $IN_SERVICE_NETWORK(12) 13 $IN_SERVICE_NETWORK(13) \
				14 $IN_SERVICE_NETWORK(14) 15 $IN_SERVICE_NETWORK(15) \
				16 $IN_SERVICE_NETWORK(16) 17 $IN_SERVICE_NETWORK(17) \
				18 $IN_SERVICE_NETWORK(18) 19 $IN_SERVICE_NETWORK(19)]
}

# function: connect send node and recv node
# args
# 	src_ue: send node
# 	dst_ue: recv node
# 	app: application between this two nodes
# 	src_network: the network send node is in
# 	dst_network: the network recv node is in
# 	src_wlan_send_agent: agent on wifi interface for sending data
# 	src_umts_send_agent: agent on umts interface for sending data
# 	dst_wlan_recv_agent: agent on wifi interface for recieving data	
# 	dst_umts_recv_agent: agent on umts interface for recieving data
proc connectSendRecv {src_ue dst_ue app src_network dst_network \
					  src_wlan_ue src_umts_ue \
					  dst_wlan_ue dst_wlan_ue \
					  src_wlan_send_agent src_umts_send_agent \
					  dst_wlan_recv_agent dst_umts_recv_agent} {
	if {$src_network == 1 && $dst_network == 1} {
		$src_ue attach-agent $src_wlan_send_agent $src_wlan_ue
		$src_ue connect-agent $src_wlan_send_agent $dst_wlan_recv_agent $src_wlan_ue
		$app attach-agent $src_wlan_send_agent
		puts [getNodeIpAddress $dst_wlan_recv_agent]
		puts "OK"
	}
	if {$src_network == 2 && $dst_network == 1} {
		$src_ue attach-agent $src_umts_send_agent $src_umts_ue
		$src_ue connect-agent $src_umts_send_agent $dst_wlan_recv_agent $src_umts_ue
		$app attach-agent $src_umts_send_agent
		puts [getNodeIpAddress $dst_wlan_recv_agent]
		puts "OK"
	} 
	if {$src_network == 1 && $dst_network == 2} {
		$src_ue attach-agent $src_wlan_send_agent $src_wlan_ue
		$src_ue connect-agent $src_wlan_send_agent $dst_umts_recv_agent $src_wlan_ue
		$app attach-agent $src_wlan_send_agent
		puts [getNodeIpAddress $dst_umts_recv_agent]
		puts "OK"
	}
	if {$src_network == 2 && $dst_network == 2} {
		$src_ue attach-agent $src_umts_send_agent $src_umts_ue
		$src_ue connect-agent $src_umts_send_agent $dst_umts_recv_agent $src_umts_ue
		$app attach-agent $src_umts_send_agent 
		puts [getNodeIpAddress $dst_umts_recv_agent]
		puts "OK"
	}

	if {$src_network == 0 || $dst_network == 0} {
		puts "no service for src_ue and dst_ue"	
		return "FAILED"
	}
}

# function: attach application to send agent
# args:
# 	app: application to handle
# 	send_agent: agent for application to attach
proc attachSendAgent {app src_network src_umts_send_agent src_wlan_send_agent} {
	if {$src_network == 1} {
		$app attach-agent $src_wlan_send_agent
		return "OK"
	}
	if {$src_network == 2} {
		$app attach-agent $src_umts_send_agent
		return "OK"
	}
	if {$src_network == 0} {
		return "FAILED"
	}
		
}


# function: generate a random destination node
# args
# 	index: the index of source node
# 	min: minimum index of nodes
# 	max: maximum index of nodes
# return
# 	destination node
proc genRandomDstNode {index min max} {
	set rd [expr rand()]	
	set dst_index [expr [expr int($rd)] * ($max - $min) + $min]
	if {$dst_index == $index} {
		puts "cannot connect to itself, increase dst_node_index with 1"
		if {$index == $min} {
			return [expr $dst_index + 1]
		}
		if {$index == $max} {
			return [expr $dst_index - 1]
		}
		return [expr $dst_index + 1]
	}
	return $dst_index
}


# function: access to UMTS
# args
# 	ue: the multiple interfaces mobile node
# 	umts_ue: the umts interface to use
# 	send_agent: agent for sending data
# 	recv_agent: agent for recieving data
proc accessUmts {ue app umts_ue send_agent recv_agent} {
	$app attach-agent $send_agent	
}


# function: access to WIFI
# args
# 	ue: the multiple interface mobile node
# 	wlan_ue: the wifi interface to use
# 	send_agent: agent for sending data
# 	recv_agent: agent for recieving data
proc accessWifi {ue app wlan_ue send_agent recv_agent} {
	$app attach-agent $send_agent
}

# function: get coordinate x of node position
# args
# 	ue: the node we want to get
proc getNodePosition_x {ue} {
	$ue set X_
}

# function: get coordinate y of node position
# args
# 	ue: the node we want to get
proc getNodePosition_y {ue} {
	$ue set Y_
}

# function: get distance between two nodes
# args
# 	src_node: source node
# 	dst_node: destination ndoe
proc getDistance {src_node dst_node} {
	set src_x [$src_node set X_]
	set src_y [$src_node set Y_]
	set dst_x [$dst_node set X_]
	set dst_y [$dst_node set Y_]
	set distance_value_tmp [expr ($dst_x - $src_x)*($dst_x - $src_x) + ($dst_y - $src_y)*($dst_y - $src_y)]
	set distance_value [expr pow($distance_value_tmp, 0.5)]
}

# function: print position of node
# args: 
# 	node: node
proc printNodePosition {node} {
	set tmp_x [$node set X_]
	set tmp_y [$node set Y_]
	puts "X: $tmp_x Y:$tmp_y"	
}

# function: print Node id
# args 
# 	node: node name
proc printNodeID {node node_name} {
	set node_id [$node id]
	puts "$node_name id=$node_id"
}

# function: do handover action
# args
#     ue: the UE which want to handover
#     interface: the network interface which ue want to handover to
#     sent_agent: agent for sending
#     receieve_agent: agent for receiving
proc redirectTraffic {ue interface send_agent recieve_agent} {
	set flag [ checkCurrentDelay 0.05 ]
	if { $flag == 1 } then {
    	puts "handover happening now"
		$ue attach-agent $send_agent $interface 
		$ue connect-agent $send_agent $recieve_agent $interface  
	} else {
		set ns [ Simulator instance ]
		set now [ $ns now ]
		$ns at [expr $now + 0.2 ] "redirectTraffic $ue $interface $send_agent $recieve_agent"
	}
	
}

# function: network selection
# args:
# 	ue: multiple interfaces mobile node
# 	interface: the netwrok interface to use, which means chose the network
# 	send_agent: agent for sending data
# 	recv_agent: agent for recieving data
proc networkSelection {ue interface send_agent recv_agent} {
	$ue attach-agent $send_agent $interface
	$ue connect-agent $send_agent $recv_agent $interface
}

# function: record position of node 
# args
#     ue: the UE we want to record 
proc record {ue} {
   set ns [Simulator instance]
   set time 0.1;# record 0.5 second
   set pos_x [ $ue set X_ ]
   set pos_y [ $ue set Y_ ]
   set now [ $ns now ]

  # puts "$pos_x\t$pos_y"
   $ns at [expr $now + $time] "record $ue"
}

# function: check the current delay, if current delay >= given delay, return 1 else return 0
# args
# 	delay: given delay
proc checkCurrentDelay {delay} {
	set ns [ Simulator instance ]
	set time 0.3 ;#slot time to detect delay
	set realtrace_tmp [ new Agent/RealtimeTrace ]
	set current_delay [ $realtrace_tmp GetCurrentDelay "5.0.0" "3.0.2" "cbr" ]
	if { $current_delay >= $delay } then {
		set flag 1
	} else {
		set now [ $ns now ]
		$ns at [ expr $now + $time ] "checkCurrentDelay $delay"
		set flag 0
	}
}

# function: get mean delay of communcation between two nodes
# args
# 	 src_ue: source node
# 	 dst_ue: source node
# 	 packet_type: trace the packet type
proc getMeanDelay {src_ue dst_ue packet_type realtime_monitor} {
	set src_nodeaddr [getNodeIpAddress $src_ue]	
	set dst_nodeaddr [getNodeIpAddress $dst_ue]
 	#set trace_tmp [new Agent/RealtimeTrace]
  	set mean_delay [$realtime_monitor GetMeanDelay $src_nodeaddr $dst_nodeaddr $packet_type]
  	puts "$src_nodeaddr $dst_nodeaddr -md $mean_delay's"
}

# function: get mean delay of communcation between two nodes
# args
# 	 src_ue: source node
# 	 dst_ue: source node
# 	 packet_type: trace the packet type
proc getCurrentDelay {src_ue dst_ue packet_type realtime_monitor} {
	set src_nodeaddr [getNodeIpAddress $src_ue]
	set dst_nodeaddr [getNodeIpAddress $dst_ue]
	#set trace_tmp [new Agent/RealtimeTrace]
  	set current_delay [$realtime_monitor GetCurrentDelay $src_nodeaddr $dst_nodeaddr $packet_type]
  	puts "$src_nodeaddr $dst_nodeaddr -cd $current_delay's"
}

# function: get mean delay of communcation between two nodes
# args
# 	 ue: node to calculate
# 	 packet_type: trace the packet type
proc getMeanThroughput {ue packet_type realtime_monitor} {
	set nodeaddr [getNodeIpAddress $ue]
	#set trace_tmp [new Agent/RealtimeTrace]
 	set mean_throughput [$realtime_monitor GetMeanThroughput $nodeaddr $packet_type "1"]
  	puts "$nodeaddr -mt $mean_throughput Mb"
}
