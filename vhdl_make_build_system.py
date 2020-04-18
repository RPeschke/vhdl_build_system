import argparse
import xml.etree.ElementTree as ET
import os
import xml.dom.minidom as minidom
from os.path import relpath

def make_bash_file(FileName,Content):
    with open(FileName,"w",newline="") as f:
        f.write(Content)
    
    os.system("chmod +x ./"+FileName) 


def prettify(elem):
    """Return a pretty-printed XML string for the Element.
    """
    rough_string = ET.tostring(elem, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="\t")

sshNotSet = "NotSet"
parser = argparse.ArgumentParser(description='Make build scripts for vhdl_build_system')
parser.add_argument('--path', help='Path to where the build system should be located',default="build")
parser.add_argument('--ssh', help='ssh configuration used for running the Xilinx programs remotly',default=sshNotSet)
parser.add_argument('--remotePath', help='Path on the remote machine that has the Xilinx programs', default="path_to_project")
parser.add_argument('--protoBuild', help='Path to the proto build files', default="protoBuild/")
parser.add_argument('--RunPcSsh', help='ssh configuration used for running the firmware on actual Hardware', default="labpc")
parser.add_argument('--RunPcRemote', help='Path on the remote running PC', default="/home/belle2/Documents/tmp/")
parser.add_argument('--jtag_PC', help='Path on the remote jtag PC', default="lab_xilinx")
parser.add_argument('--sym', help='Which simulator to use  (ISE/vivado)', default="ISE")

args = parser.parse_args()



setup = ET.Element('setup')

if not args.ssh == sshNotSet:
    remote = ET.SubElement(setup, 'remote')
    ssh_config = ET.SubElement(remote, 'ssh_config')
    ssh_config.text=args.ssh
    path =  ET.SubElement(remote, 'path')
    path.text = args.remotePath


local = ET.SubElement(setup, 'local')
build_system_path = ET.SubElement(local, 'build_system_path')
vhdl_build_system= "vhdl_build_system/"
build_system_path.text = vhdl_build_system
build_local = ET.SubElement(local, 'path')
build_local.text = os.getcwd()
makeise = ET.SubElement(local, 'makeise')
makeise_ = "makeise/"
makeise.text = makeise_



protoBuild = ET.SubElement(local, 'protoBuild')
protoBuild_ =args.protoBuild
protoBuild.text = protoBuild_
#print(prettify(setup))

########################################################################
#   vhdl_build_setup
with open(args.path+"/vhdl_build_setup.xml","w",newline="") as f:
    f.write(prettify(setup))


########################################################################
#   make_simulation

make_simulation='''#/bin/bash
echo "make ISIM build system for \'$1\'"


# $1 : Test Bench Name
python3 {vhdl_build_system}/bin_make_simulation.py  "$1"
'''.format(
    vhdl_build_system=vhdl_build_system
    )
make_bash_file("make_simulation.sh",make_simulation)


########################################################################
#   make_implementation
make_implementation = '''#/bin/bash
#$1 ... Entity name
#$2 ... UCF File
#$3 ... coregen folder (optional)

echo "make ISE build system for $1"
mkdir ./{protoBuild}/$1/
cp "{protoBuild}/proto_Project.in"   "./{buildpath}/$1/"
mv "./{buildpath}/$1/proto_Project.in"  "./{buildpath}/$1/$1_proto_Project.in"
python3 {vhdl_build_system}/bin_make_implementation.py $1 $2
cp "{protoBuild}/simpleTemplate.xise.in"   "./{buildpath}/$1/"
mv "./{buildpath}/$1/simpleTemplate.xise.in"  "./{buildpath}/$1/$1_simpleTemplate.xise.in"
python3  {makeisePath}/makeise.py "{buildpath}/$1/$1.in" "{buildpath}/$1/$1.xise"
if [ "$3" != "" ]; then
  cp -rf $3 ./{buildpath}/$1/coregen/
fi
    '''.format(
        makeisePath=makeise_,
        buildpath=args.path,
        protoBuild=protoBuild_,
        vhdl_build_system=vhdl_build_system
        )
make_bash_file("make_implementation.sh",make_implementation)

########################################################################
#   run_simulation

run_command = "run.sh"
if args.sym == "vivado":
    run_command = "vivado_run.sh"
line = ""
if args.ssh == sshNotSet:
    line = './'+ args.path + '/$1/'+run_command+' $2.csv $3\n'
else :
    line = 'ssh ' + args.ssh +' "cd ' + args.remotePath +' && ./'+ args.path + '/$1/'+run_command+' $2.csv $3"\n'

run_simulation='''#/bin/bash
echo "running $1"

# $1 : Test Bench Name
# $2 : Input csv File name
# $3 : output csv File Name

if [ "$3" != "" ]; then
    rm -f  $3
fi

python3 vhdl_build_system/excel_to_csv.py --OutputCSV  "$2.csv"  --InputXLS $2 

{line}
'''.format(
    line=line
)

make_bash_file("run_simulation.sh",run_simulation)
        
########################################################################
#   run_test_cases
run_test_cases= '''#/bin/bash
echo "Runing test case  \'$1\'"


# $1 : Test Case File
if [ "$1" != "" ]; then 
  python3 {vhdl_build_system}/bin_run_test_case.py --test $1 
else 
  python3 {vhdl_build_system}/bin_run_test_case.py
fi 
'''.format(
    vhdl_build_system=vhdl_build_system
    )
make_bash_file("run_test_cases.sh",run_test_cases)


#########################################################################
#   update_test_cases
update_test_cases='''#/bin/bash
echo "Runing test case  \'$1\'"
# $1 : Test Case File
if [ "$1" != "" ]; then
  python3 {vhdl_build_system}/bin_run_test_case.py --test $1 --update True 
else
  python3 {vhdl_build_system}/bin_run_test_case.py --update True 
fi
'''.format(
    vhdl_build_system=vhdl_build_system
        )
make_bash_file("update_test_cases.sh",update_test_cases)


#########################################################################
#   make_test_bench
make_test_bench = '''#/bin/bash
echo "make test bench for \'$1\' in Folder \'$2\' "

mkdir $2

python3 {vhdl_build_system}/bin_make_test_bench.py  --EntityName $1 --OutputPath $2
'''.format(
    vhdl_build_system=vhdl_build_system
        )
make_bash_file("make_test_bench.sh",make_test_bench)

#########################################################################
#   build_implementation

line = ""
if args.ssh == sshNotSet:
    line = 'cd ./'+ args.path + '/$1/ && ./build_implementation.sh \ncd -\n'
else :
    line = 'ssh ' + args.ssh +' "cd ' + args.remotePath +'/' + args.path +'/$1/ && ./build_implementation.sh "'

build_implementation = '''#/bin/bash
echo "build_implementation $1"
# $1 : Test Bench Name
{line}
    '''.format(
    line=line
        )
make_bash_file("build_implementation.sh",build_implementation)

#########################################################################
#   build_synt
line = ""
if args.ssh == sshNotSet:
    line = 'cd ./'+ args.path + '/$1/ && ./build_syntesize.sh \ncd -\n'
else :
    line = 'ssh ' + args.ssh +' "cd ' + args.remotePath +'/' + args.path +'/$1/ && ./build_syntesize.sh "'

build_synt = '''#/bin/bash
echo "build_syntesize $1"
# $1 : Test Bench Name
{line}
    '''.format(
    line=line
        )

make_bash_file("build_synt.sh",build_synt)



#########################################################################
#   run_on_hardware
run_on_hardware = '''#/bin/bash
#$1 entity Name
#$2 Input File Name
#$3 Ouput File name
#$4 IP Address
#$5 Port



if [ "$3" != "" ]; then
    rm -f  $3
fi

if [ "$2" != "" ]; then
    python3 vhdl_build_system/excel_to_csv.py --OutputCSV  {buildpath}/$1/$1.csv  --InputXLS $2 
fi

IpAddress="192.168.1.20"
if [ "$4" != "" ]; then
    IpAddress="$4"
fi

port="2000"
if [ "$5" != "" ]; then
    port="$5"
fi

dos2unix firmware-ethernet/scripts/udp_run.py
scp firmware-ethernet/scripts/udp_run.py {RunPcSsh}:{RunPcRemote}/

scp {buildpath}/$1/$1.csv {RunPcSsh}:{RunPcRemote}/



echo  "cd {RunPcRemote}/ && ./udp_run.py --InputFile $1.csv --OutputFile $1_out_HW.csv --IpAddress $IpAddress --port $port --OutputHeader $1_header.txt"
ssh {RunPcSsh} "cd {RunPcRemote}/ && ./udp_run.py --InputFile $1.csv --OutputFile $1_out_HW.csv --IpAddress $IpAddress --port $port --OutputHeader $1_header.txt"


scp  {RunPcSsh}:{RunPcRemote}/$1_out_HW.csv  {buildpath}/$1/





if [ "$3" != "" ]; then
    cp -f {buildpath}/$1/$1_out_HW.csv $3
fi


FolderName=$(cat "currentFolder.txt")
echo $FolderName
ssh {RunPcSsh} "cd  {RunPcRemote}/ && cp  $1.csv  $FolderName/$(date '+%Y-%m-{ampersand}d-%H-%M')_$1.csv  && cp  $1_out_HW.csv $FolderName/$(date '+%Y-%m-{ampersand}d-%H-%M')_$1_out_HW.csv"

    '''.format(
        buildpath=args.path,
        RunPcRemote=args.RunPcRemote,
        RunPcSsh=args.RunPcSsh,
        ampersand="%"
        )

make_bash_file("run_on_hardware.sh",run_on_hardware)

jtag= """#/bin/bash
#$1 entity Name

echo " {buildpath}/$1/$1.bit"
ls  {buildpath}/$1/$1.bit
scp  {buildpath}/$1/$1.bit lab_xilinx:/home/ise//

echo "setMode -bscan" > commad.cmd
echo "setCable -port auto" >> commad.cmd
echo "Identify -inferir"  >> commad.cmd
echo "identifyMPM"  >> commad.cmd
echo "assignFile -p 1 -file \"$1.bit\""  >> commad.cmd
echo "Program -p 1" >> commad.cmd
echo "quit"  >> commad.cmd

scp commad.cmd {jtag_PC}:/home/ise//
ssh {jtag_PC} "impact -batch commad.cmd"
rm commad.cmd

FolderName=$(cat "nextRunFolder.txt")
newFolder="{RunPcRemote}/$FolderName"

ssh {RunPcSsh} "mkdir $newFolder"
ssh {RunPcSsh} "echo start > $newFolder/$(date '+%Y-%m-{ampersand}d-%H-%M')_start.txt"
scp {buildpath}/$1/$1.bit "{RunPcSsh}:$newFolder"
ssh {RunPcSsh} "mv $newFolder/$1.bit $newFolder/$(date '+%Y-%m-{ampersand}d-%H-%M')_$1.bit"
scp "{buildpath}/$1/$1_header.txt" "{RunPcSsh}:{RunPcRemote}/"
echo  $FolderName > currentFolder.txt
""".format(
        buildpath=args.path,
        RunPcRemote=args.RunPcRemote,
        RunPcSsh=args.RunPcSsh,
        ampersand="%",
        jtag_PC=args.jtag_PC
        )

make_bash_file("jtag.sh",jtag)


startNewRun='''runNr="RUN_$(date '+%Y-%m-{ampersand}d-%H-%M')"
echo $runNr > nextRunFolder.txt
git add *
git commit -m "$runNr"
'''.format(ampersand="%")


make_bash_file("startNewRun.sh",startNewRun)