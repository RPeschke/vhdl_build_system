# Getting Started


The Framework runs on python3 and requires the user to have the following packages installed:

pandas, six, tabulate





The VHDL Test Framework is not part of the main repository. It is only at the following repository:


[vhdl_build_system](https://github.com/RPeschke/vhdl_build_system.git)




After this install the framwork by running the following command from within the project directory:

```bash
python ./vhdl_build_system/vhdl_make_build_system.py --remotePath /home/ise/xilinx_share2/GitHub/klm_scrod_vas --ssh xilinx
```


with:
```
--remotePath... is the path on the Xilinx VM to the project (it assumes that the VM has mounted the project as a network share).
--ssh... is the ssh configuration which allows to connect to the VM. It is important that the Public/Private keys are exchanged so that this configuration can be called without entering a password. 
```


this will create a bunch of scripts in the current directory as well as a xml config file in the build folder.

after this the first test should be to run the test cases for this one can use the following script:


./run_test_cases.sh 


if no argument is given the script will run through all Test cases. If a specific test case file was given as argument it will only run this one file. 

the result can be found in the build folder 


build/tests.md



# Running Test Benches


After the build system is installed one can directly make Simulations with Isim. For this one has to execute:



./make_simulation.sh Test_bench_name




the simulation can then be run by executing:

./run_simulation.sh TEST_BENCH_NAME




this will compile and execute the simulation.




