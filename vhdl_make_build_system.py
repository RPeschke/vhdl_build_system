import argparse
import xml.etree.ElementTree as ET
import os
import xml.dom.minidom as minidom
from os.path import relpath

def prettify(elem):
    """Return a pretty-printed XML string for the Element.
    """
    rough_string = ET.tostring(elem, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    return reparsed.toprettyxml(indent="\t")


parser = argparse.ArgumentParser(description='Make build scripts for vhdl_build_system')
parser.add_argument('--path', help='Path to where the build system should be located',default="build")
parser.add_argument('--ssh', help='ssh configuration used for running the Xilinx programs remotly',default="xilinx")
parser.add_argument('--remotePath', help='Path on the remote machine that has the Xilinx programs', default="path_to_project")
args = parser.parse_args()



setup = ET.Element('setup')
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
protoBuild_ ='protoBuild/'
protoBuild.text = protoBuild_
#print(prettify(setup))

#ET.write(args.path+"/vhdl_build_setup.xml",setup)
with open(args.path+"/vhdl_build_setup.xml","w",newline="") as f:
    f.write(prettify(setup))



with open("make_simulation.sh","w",newline="") as f:
    f.write('echo "make ISIM build system for \'$1\'"\n\n')
    f.write('# $1 : Test Bench Name\n\n')
    f.write('python '+vhdl_build_system+'/vhdl_make_simulation.py  "$1"\n')

with open("make_implementation.sh","w",newline="") as f:
    f.write('echo "make ISE build system for $1"\n\n')
    f.write("python "+vhdl_build_system+"/vhdl_make_implementation.py $1 $2\n\n")
    f.write('cp "'+protoBuild_+'/simpleTemplate.xise.in"   "./' + args.path +'/$1/"\n\n')
    f.write('mv "./' + args.path +'/$1/simpleTemplate.xise.in"  "./' + args.path +'/$1/$1_simpleTemplate.xise.in"\n\n')
    f.write('python '+ makeise_ +'/makeise.py "' + args.path +'/$1/$1.in" "' + args.path +'/$1/$1.xise"\n')


with open("run_simulation.sh","w",newline="") as f:
    f.write('echo "running $1"\n\n')
    f.write('# $1 : Test Bench Name\n# $2 : Input csv File name\n# $3 : output csv File Name\n')
    f.write('ssh ' + args.ssh +' "cd ' + args.remotePath +' && ./'+ args.path + '/$1/run.sh $2 $3"\n')


        
with open("run_test_cases.sh","w",newline="") as f:
    f.write('echo "Runing test case  \'$1\'"\n\n')
    f.write('# $1 : Test Case File\n')
    f.write('python ' + vhdl_build_system +'/vhdl_run_test_case.py $1\n')


