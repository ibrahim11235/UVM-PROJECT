#!/bin/csh

clear
clear

source /CMC/scripts/mentor.questasim.2020.1_1.csh

set rootdir = `dirname $0`
set rootdir = `cd $rootdir && pwd`
chmod u+x $rootdir/run_regression.csh
set f_file = $rootdir/UVM.f

set script_name = $0:t

setenv QUESTA_HOME $CMC_MNT_QSIM_HOME
setenv UVM_HOME $QUESTA_HOME/verilog_src/uvm-1.2


set workdir = "$rootdir/../verification"
if (! -d $workdir ) then
  echo "ERROR: $workdir doesn't exist!"
  exit 0
else
  echo "Working directory: $workdir"
endif

set testcase_list = `cat $workdir/lab4_pkg.sv | grep "^[ ]*class.*extends test;" | sed -e 's/ *extends *[test]*//' -e 's/class *//g' -e 's/;//g'`

     
if ($#argv == 0 || $#argv > 3 ) then
 if ($#argv > 1) then
    exit 0
  else
  cd $rootdir/..
    if (! -e lab4_fcov_ucdb) then
    echo CME435\: Creating work library...
    mkdir lab4_fcov_ucdb
    endif

    if (! -e ./lab4_fcov_ucdb/lab4_fcov_rpt) then
    echo CME435\: Creating work library...
    mkdir ./lab4_fcov_ucdb/lab4_fcov_rpt
    endif

    if (! -e ./lab4_fcov_ucdb/lab4_fcov_html) then
    echo CME435\: Creating work library...
    mkdir ./lab4_fcov_ucdb/lab4_fcov_html
    endif

    vlog -f $f_file
    foreach testcase ($testcase_list)
    vsim -c tbench_top -L $QUESTA_HOME/uvm-1.2 +UVM_TESTNAME="$testcase" -do "coverage save -onexit ./lab4_fcov_ucdb/${testcase}.ucdb; run -all; exit"
    vcover report -summary ./lab4_fcov_ucdb/${testcase}.ucdb -output ./lab4_fcov_ucdb/lab4_fcov_rpt/$testcase.rpt
    vcover report -details ./lab4_fcov_ucdb/${testcase}.ucdb -output ./lab4_fcov_ucdb/lab4_fcov_html/$testcase.html     

    end


    set merged_cmd = "merge ./lab4_fcov_ucdb/merged_db.ucdb"
    foreach testcase ($testcase_list)
      set merged_cmd = "$merged_cmd ./lab4_fcov_ucdb/${testcase}.ucdb"
    end
    vcover $merged_cmd
    
    vcover report -summary ./lab4_fcov_ucdb/merged_db.ucdb -output ./lab4_fcov_ucdb/lab4_fcov_rpt/final.rpt
    vcover report -details ./lab4_fcov_ucdb/merged_db.ucdb -output ./lab4_fcov_ucdb/lab4_fcov_html/final.html     
    vcover report -details ./lab4_fcov_ucdb/merged_db.ucdb 
    exit 0
  endif
endif




switch ($argv[1])
# ////////////////////////////////////////////////////////////
case "-l":
  if ($#argv > 1) then
      echo "ERROR: Too many arguments"
      echo asdasdasdasd
      exit 0
  else
    echo "List of test cases:"
    @ testcase_no = 0
    foreach testcase ($testcase_list)
      @ testcase_no++
      echo "  $testcase_no : $testcase"
    end
  endif
breaksw


# ////////////////////////////////////////////////////////////

  

foreach line ("`cat $workdir/testcase_list`")
  set testcase_list = "$testcase_list $line"
end

case "-t":
  # NOTE: $#argv > 2 is already checked at the beginning
  if ($#argv != 2) then 
    echo "ERROR: Too few arguments"
    exit 0
  else
    set test_specified = "$argv[2]"
    set test_exist = `echo $testcase_list | grep "$test_specified"`
    if ("$test_exist" != "") then
      echo "Running testcase $test_specified in $workdir"
      #echo vlog $test_specified
      echo vsim +UVM_TEST=$test_specified
        cd $rootdir/..
    if (! -e lab4_fcov_ucdb) then
    echo CME435\: Creating work library...
    mkdir lab4_fcov_ucdb
    endif

    if (! -e ./lab4_fcov_ucdb/lab4_fcov_rpt) then
    echo CME435\: Creating work library...
    mkdir ./lab4_fcov_ucdb/lab4_fcov_rpt
    endif

    if (! -e ./lab4_fcov_ucdb/lab4_fcov_html) then
    echo CME435\: Creating work library...
    mkdir ./lab4_fcov_ucdb/lab4_fcov_html
    endif


        vlog -f $f_file

        vsim -c tbench_top -L $QUESTA_HOME/uvm-1.2 +UVM_TESTNAME="$test_specified" -do "coverage save -onexit ./lab4_fcov_ucdb/${test_specified}.ucdb; run -all; exit"
      
        vcover report -summary ./lab4_fcov_ucdb/${test_specified}.ucdb -output ./lab4_fcov_ucdb/lab4_fcov_rpt/$test_specified.rpt
        vcover report -details ./lab4_fcov_ucdb/${test_specified}.ucdb -output ./lab4_fcov_ucdb/lab4_fcov_html/$test_specified.html  
        
    else
      echo "ERROR: Testcase $test_specified doesn't exist!"
      exit 0
    endif
  endif
  breaksw
default:    
  echo "ERROR: invalid arguments"
  exit 0
endsw

