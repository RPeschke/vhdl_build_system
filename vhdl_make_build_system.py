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

sshNotSet = "NotSet"
parser = argparse.ArgumentParser(description='Make build scripts for vhdl_build_system')
parser.add_argument('--path', help='Path to where the build system should be located',default="build")
parser.add_argument('--ssh', help='ssh configuration used for running the Xilinx programs remotly',default=sshNotSet)
parser.add_argument('--remotePath', help='Path on the remote machine that has the Xilinx programs', default="path_to_project")
parser.add_argument('--protoBuild', help='Path to the proto build files', default="protoBuild/")


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

#ET.write(args.path+"/vhdl_build_setup.xml",setup)
with open(args.path+"/vhdl_build_setup.xml","w",newline="") as f:
    f.write(prettify(setup))



with open("make_simulation.sh","w",newline="") as f:
    f.write('#/bin/bash\n')
    f.write('echo "make ISIM build system for \'$1\'"\n\n')
    f.write('# $1 : Test Bench Name\n\n')
    f.write('python3 '+vhdl_build_system+'/vhdl_make_simulation.py  "$1"\n')

os.system("chmod +x ./make_simulation.sh") 

with open("make_implementation.sh","w",newline="") as f:
    cp = '''#/bin/bash
#$1 ... Entity name
#$2 ... UCF File
#$3 ... coregen folder (optional)

echo "make ISE build system for $1"
mkdir ./{protoBuild}/$1/
cp "{protoBuild}/proto_Project.in"   "./{buildpath}/$1/"
mv "./{buildpath}/$1/proto_Project.in"  "./{buildpath}/$1/$1_proto_Project.in"
python3 {vhdl_build_system}/vhdl_make_implementation.py $1 $2
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
    f.write(cp)
    

os.system("chmod +x ./make_implementation.sh") 


with open("run_simulation.sh","w",newline="") as f:
    f.write('#/bin/bash\n')
    f.write('echo "running $1"\n\n')
    f.write('# $1 : Test Bench Name\n# $2 : Input csv File name\n# $3 : output csv File Name\n')
    if args.ssh == sshNotSet:
        f.write('./'+ args.path + '/$1/run.sh $2 $3\n')
    else :
        f.write('ssh ' + args.ssh +' "cd ' + args.remotePath +' && ./'+ args.path + '/$1/run.sh $2 $3"\n')

os.system("chmod +x ./run_simulation.sh") 

        
with open("run_test_cases.sh","w",newline="") as f:
    f.write('#/bin/bash\n')
    f.write('echo "Runing test case  \'$1\'"\n\n')
    f.write('# $1 : Test Case File\n')
    f.write('if [ "$1" != "" ]; then \n')
    f.write("  python3 "+ vhdl_build_system + "/vhdl_run_test_case.py --test $1 \n")
    f.write('else \n')
    f.write('  python3 ' + vhdl_build_system +'/vhdl_run_test_case.py \n')
    f.write('fi \n')

os.system("chmod +x ./run_test_cases.sh") 

with open("update_test_cases.sh","w",newline="") as f:
    f.write('#/bin/bash\n')
    f.write('echo "Runing test case  \'$1\'"\n\n')
    f.write('# $1 : Test Case File\n')
    f.write('if [ "$1" != "" ]; then \n')
    f.write("  python3 "+ vhdl_build_system + "/vhdl_run_test_case.py --test $1 --update True \n")
    f.write('else \n')
    f.write('  python3 ' + vhdl_build_system +'/vhdl_run_test_case.py --update True \n')
    f.write('fi \n')

os.system("chmod +x ./update_test_cases.sh") 


with open("make_test_bench.sh","w",newline="") as f:
    f.write('#/bin/bash\n')
    f.write('echo "make test bench for \'$1\' in Folder \'$2\' " \n\n')
    f.write('python3 vhdl_build_system//vhdl_make_test_bench.py  --EntityName $1 --OutputPath $2\n')

os.system("chmod +x ./make_test_bench.sh") 

with open("build_implementation.sh","w",newline="") as f:
    line = ""
    if args.ssh == sshNotSet:
        line = 'cd ./'+ args.path + '/$1/ && ./build_implementation.sh \ncd -\n'
    else :
        line = 'ssh ' + args.ssh +' "cd ' + args.remotePath +'/' + args.path +'/$1/ && ./build_implementation.sh "'

    fileContent = '''#/bin/bash
echo "build_implementation $1"
# $1 : Test Bench Name
{line}
    '''.format(
    line=line
        )
    f.write(fileContent)
os.system("chmod +x ./build_implementation.sh") 

with open("build_synt.sh","w",newline="") as f:
    line = ""
    if args.ssh == sshNotSet:
        line = 'cd ./'+ args.path + '/$1/ && ./build_syntesize.sh \ncd -\n'
    else :
        line = 'ssh ' + args.ssh +' "cd ' + args.remotePath +'/' + args.path +'/$1/ && ./build_syntesize.sh "'

    fileContent = '''#/bin/bash
echo "build_syntesize $1"
# $1 : Test Bench Name
{line}
    '''.format(
    line=line
        )
    f.write(fileContent)

os.system("chmod +x ./build_synt.sh") 