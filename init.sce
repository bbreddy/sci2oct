// This is initialization program which links sci2oct.c program to Scilab
ilib_for_link('sci2oct','sci2oct.c',[],"c")
exec loader.sce
exec sci2oct.sce // executes sci2oct.sce file. Which is the main program in this interface
