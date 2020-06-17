#Create a simulator object
set ns [new Simulator]

#Define different colors for data flows (for NAM)
$ns color 1 Green
$ns color 2 Red

#Open the NAM trace file
set nf [open out.nam w]
$ns namtrace-all $nf

#Define a 'finish' procedure
proc finish {} {
        global ns nf
        $ns flush-trace
        #Close the NAM trace file
        close $nf
        #Execute NAM on the trace file
        exec nam out.nam &
        exit 0
}

#$defaultRNG seed 999

#Create four nodes
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]

set linkDelay23_ [new RandomVariable/Uniform];
$linkDelay23_ set min_ 5 
$linkDelay23_ set max_ 25

set linkDelay56_ [new RandomVariable/Uniform];
$linkDelay56_ set min_ 5 
$linkDelay56_ set max_ 25

$ns duplex-link $n1 $n3 100Mb 5ms DropTail
$ns duplex-link $n2 $n3 100Mb [expr [$linkDelay23_ value]]ms DropTail

$ns duplex-link $n3 $n4 100Kb 1ms DropTail
$ns duplex-link $n4 $n5 100Mb 5ms DropTail
$ns duplex-link $n4 $n6 100Mb [expr [$linkDelay56_ value]]ms DropTail

$ns queue-limit $n3 $n4 10
$ns queue-limit $n4 $n5 10
$ns queue-limit $n4 $n6 10

#Give node position (for NAM)
$ns duplex-link-op $n1 $n3 orient left-up
$ns duplex-link-op $n2 $n3 orient left-down
#$ns duplex-link-op $n3 $n4 orient center
$ns duplex-link-op $n4 $n5 orient right-up
$ns duplex-link-op $n4 $n6 orient right-down
#$ns duplex-link-op $n3 $n4 orient center

#Monitor the queue for link (n2-n3). (for NAM)
$ns duplex-link-op $n3 $n4 queuePos 0.5


#Setup a TCP connection
set tcp [new Agent/TCP]
$tcp set class_ 2
$ns attach-agent $n1 $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $n5 $sink
$ns connect $tcp $sink
$tcp set fid_ 1

#Setup a FTP over TCP connection
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP

#Schedule events for the CBR and FTP agents
$ns at 0.1 "$ftp start"
$ns at 1.0 "$ftp start"
$ns at 4.0 "$ftp stop"
$ns at 4.5 "$ftp stop"

#Detach tcp and sink agents (not really necessary)
$ns at 4.5 "$ns detach-agent $n1 $tcp ; $ns detach-agent $n5 $sink"

#Call the finish procedure after 5 seconds of simulation time
$ns at 5.0 "finish"

#Run the simulation
$ns run