#
# Hints for Windows. Tested on Win2K
#
use Config;

$self->{CCFLAGS} = $Config{'ccflags'} . " /TP ";
$self->{DEFINE} .= " -DOS_NT ";
