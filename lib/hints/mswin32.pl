#
# Hints for Win32. Shouldn't be required but I can't get MakeMaker to
# pass down CCFLAGS correctly from the parent dir so we have to do it
# this way. Yuk, but it works.
#
use Config;
$self->{CCFLAGS} = $Config{'ccflags'} . " /TP ";
