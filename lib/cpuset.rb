#
# Class that we can include when want to write an application 
# that cares about cpu isolation and cpusets. 
#
# usage is as follows:
# require 'cpuset'
#
# # list cpusets:
# Cpuset.list_cpusets
#
# # create a cpuset:
# Cpuset.create_cpuset( "cpuset_name" ) 
#
# # delete a cpuset:
# Cpuset.delete_cpuset( "cpuset_name" )
#
# # list all tasks in a cpuset
# Cpuset.get_tasks( "cpuset" )
#
# # change the value of a vairable in cpuset:
# # the below will set the cpuset called cpuset2 
# # to use 5 cpus: 0,1,2,3,4,5
# Cpuset.set_variable( "cpuset2", "cpus", "0-4" )
#
# # migrate a tasks PID to a cpuset:
# Cpuset.migrate_tasks( 35425, "cpuset_name" )
#

require "cpuset/cpuset_fs"

class Cpuset
    extend Cpuset_fs
end
