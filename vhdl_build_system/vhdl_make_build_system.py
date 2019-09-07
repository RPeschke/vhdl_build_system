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

line = ""
if args.ssh == sshNotSet:
    line = './'+ args.path + '/$1/run.sh $2 $3\n'
else :
    line = 'ssh ' + args.ssh +' "cd ' + args.remotePath +' && ./'+ args.path + '/$1/run.sh $2 $3"\n'

run_simulation='''#/bin/bash
echo "running $1"

# $1 : Test Bench Name
# $2 : Input csv File name
# $3 : output csv File Name
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

if [ "$3" != "" ]; then
    rm -f  $3
fi

if [ "$2" != "" ]; then
    cp -f  $2 {buildpath}/$1/$1.csv
fi

scp firmware-ethernet/scripts/udp_run.py {RunPcSsh}:{RunPcRemote}/

scp {buildpath}/$1/$1.csv {RunPcSsh}:{RunPcRemote}/

ssh {RunPcSsh} "cd {RunPcRemote}/ && ./udp_run.py $1.csv $1_out.csv"

scp  {RunPcSsh}:{RunPcRemote}/$1_out.csv  {buildpath}/$1/

if [ "$3" != "" ]; then
    cp -f {buildpath}/$1/$1_out.csv $3
fi
    '''.format(
        buildpath=args.path,
        RunPcRemote=args.RunPcRemote,
        RunPcSsh=args.RunPcSsh
    
        )

make_bash_file("run_on_hardware.sh",run_on_hardware)