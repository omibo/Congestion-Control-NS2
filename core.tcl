set method $env(METHOD)
puts -nonewline "▇"
set ns [new Simulator]

set timeIncr $env(TIMEINCR)

$ns color 1 Green
$ns color 2 Red

set nf [open out.nam w]
$ns namtrace-all $nf
set tf [open out.tr w]
$ns trace-all $tf

proc finish {} {
   global ns nf tf
   $ns flush-trace
   close $nf
   close $tf
   # exec nam out.nam &
   exit 0
}

set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]
set n6 [$ns node]

$defaultRNG seed 0
set randNum [new RandomVariable/Uniform];
$randNum set min_ 5
$randNum set max_ 25

set delay23 [expr [$randNum value]]
set delay56 [expr [$randNum value]]


# puts "delay23: $delay23\ndelay56: $delay56"
$ns duplex-link $n1 $n3 100Mb 5ms DropTail
$ns duplex-link $n2 $n3 100Mb [expr $delay23]ms DropTail
$ns duplex-link $n3 $n4 100Kb 1ms DropTail
$ns duplex-link $n4 $n5 100Mb 5ms DropTail
$ns duplex-link $n4 $n6 100Mb [expr $delay56]ms DropTail

$ns queue-limit $n3 $n4 10
$ns queue-limit $n4 $n3 10
$ns queue-limit $n3 $n1 10
$ns queue-limit $n3 $n2 10
$ns queue-limit $n4 $n5 10
$ns queue-limit $n4 $n6 10

$ns duplex-link-op $n1 $n3 orient left-up
$ns duplex-link-op $n2 $n3 orient left-down
$ns duplex-link-op $n3 $n4 orient center
$ns duplex-link-op $n4 $n5 orient right-up
$ns duplex-link-op $n4 $n6 orient right-down

$ns duplex-link-op $n3 $n4 queuePos 0.5

if {$method == "newreno"} {
   set tcp1 [new Agent/TCP/Newreno]
   set tcp2 [new Agent/TCP/Newreno]
}

if {$method == "tahoe"} {
   set tcp1 [new Agent/TCP]
   set tcp2 [new Agent/TCP]
}

if {$method == "vegas"} {
   set tcp1 [new Agent/TCP/Vegas]
   set tcp2 [new Agent/TCP/Vegas]
}

$tcp1 set ttl_ 64
$tcp1 set fid_ 1
$tcp2 set ttl_ 64
$tcp2 set fid_ 2

$ns attach-agent $n1 $tcp1
set sink1 [new Agent/TCPSink]
$ns attach-agent $n5 $sink1
$ns connect $tcp1 $sink1

set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ftp1 set type_ FTP

$ns attach-agent $n2 $tcp2
set sink2 [new Agent/TCPSink]
$ns attach-agent $n6 $sink2
$ns connect $tcp2 $sink2

set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2
$ftp2 set type_ FTP

$ns at 0.0   "$ftp1 start"
$ns at 0.0   "$ftp2 start"
$ns at 1000.0 "$ftp1 stop"
$ns at 1000.0 "$ftp2 stop"

$ns at 1001.0 "finish"

set cwndfile1 [open  "cwnd1.txt"  w]
set cwndfile2 [open  "cwnd2.txt"  w]
proc plotWindow {tcpSource outfile} {
   global ns
   global timeIncr
   set now [$ns now]
   set cwnd [$tcpSource set cwnd_]

   puts  $outfile  "$now $cwnd"
   $ns at [expr $now+$timeIncr] "plotWindow $tcpSource  $outfile"
}
$ns  at  0.0  "plotWindow $tcp1  $cwndfile1"
$ns  at  0.0  "plotWindow $tcp2  $cwndfile2"

set RTTfile1 [open  "rtt1.txt"  w]
set RTTfile2 [open  "rtt2.txt"  w]
proc plotRTT {tcpSource outfile} {
   global ns
   global timeIncr

   set now [$ns now]
   set rtt [$tcpSource set rtt_]

   puts $outfile  "$now $rtt"
   $ns at [expr $now+$timeIncr] "plotRTT $tcpSource $outfile"
}
$ns  at  0.0  "plotRTT $tcp1 $RTTfile1"
$ns  at  0.0  "plotRTT $tcp2 $RTTfile2"

proc plotGoodput {tcpSink outfile} {
   global ns
   global timeIncr

   set now [$ns now]
   set nbytes [$tcpSink set bytes_]
   $tcpSink set bytes_ 0

   set goodput [expr ($nbytes * 8.0 / 1000000) / $timeIncr]

   puts  $outfile  "$now $goodput"

   $ns at [expr $now+$timeIncr] "plotGoodput $tcpSink  $outfile"
}
set goodputfile1 [open  "goodput1.txt"  w]
set goodputfile2 [open  "goodput2.txt"  w]

source TraceApp.ns

set traceapp1 [new TraceApp]
$traceapp1 attach-agent $sink1
$ns  at  0.0  "$traceapp1  start"

set traceapp2 [new TraceApp]
$traceapp2 attach-agent $sink2
$ns  at  0.0  "$traceapp2  start"

$ns  at  0.0  "plotGoodput $traceapp1  $goodputfile1"
$ns  at  0.0  "plotGoodput $traceapp2  $goodputfile2"


$ns run