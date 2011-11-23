# #!/usr/bin/env ruby 

# Module that can interface between the cpuset file system. 
# Currently there is no real API to deal with these filesystems
# So the best way to interface between the cgroups and cpusets
# is use simple filesystem calls (mkdir move echo, etc)
#

require 'fileutils'
require 'find' 

module Cpuset_fs

    def list_cpusets
        ret = []
        base = find_base_path
        begin
            Dir.glob("#{base}**/*").each do |d|
                ret << d.gsub(base, "")  if File.directory? d 
            end
        rescue Exception => err
            puts "Could not list all cpusets, exiting with error #{err}"
            exit
        end
        return ret 
    end

    # here we are assuming that the procfs is working... 
    # we trawl through the mounted filesystems and get the cgroup 
    # mounted location
    def find_base_path
        path = ""
        begin 
            File.open( "/proc/mounts", "r").each do |line|
            return path = $1 + "/" if line =~ /^\S+\s+(\S+)\scgroup\s.*?cpuset/
        end
        rescue Exception => e
            puts "Could not read /proc/mounts, I am going to die now."
            puts "For the record the exception is #{e}"
            exit
        end
        raise Exception, "CGROUPS are not mounted, please mount then try again"
    end

    def create_cpuset( name )
        raise ArgumentError, "Cpuset is already taken" if list_cpusets.include? name

        base = find_base_path
        begin
            FileUtils.mkdir "#{base}#{name}" unless File.directory? "#{base}#{name}"
        rescue Exception => err
            puts "Error creating the cpuset #{base}#{name}"
            puts "I am going to quit now. The actual exception was (#{err})"
            exit
        end

        # cpuset created, but we now need to fill in cpus and mem with parent values. 
        parent = find_parent( name ) 
        cpus = get_values( parent, "cpus" )
        mems = get_values( parent, "mems" )
        set_variable( name, "cpus",  cpus)
        set_variable( name, "mems",  mems)
    end

    # recursively remove all cpusets ... 
    def delete_cpuset( cpuset )
        raise ArgumentError, "Cpuset does not exist" unless list_cpusets.include? cpuset
        
        base = find_base_path

        get_tasks( cpuset ).each do |t|
            migrate_tasks( t, "" )
        end
        
        begin 
            FileUtils.remove_dir "#{base}#{cpuset}", :force => true if File.directory? "#{base}#{cpuset}" 
        rescue Exception => e
            puts "Tried to remove: #{base}#{cpuset} cpuset, I failed, exiting with Exception: #{e}"
            exit 
        end
    end


    # Query the current cgroup values:
    # the variable should be in the name of the file in the
    # cgroup mounted location
    # I also assume that results are only a single line!! (fails on tasks ...)
    def get_values( cpuset, variable )
        raise ArgumentError, "Argumetnt is null" unless defined? variable
        unless cpuset.eql? ""
            raise ArgumentError, "Cpuset does not exist" unless list_cpusets.include? cpuset
        end

        base = find_base_path
        ret = ""

        var = variable
        var = "cpuset.#{variable}" unless variable.include? "cpuset."
        begin 
            fn = "#{base}#{cpuset}/#{var}"
            File.open( fn , "r").each do |line|
            if line.eql?("\n")
                ret = ""
            else
                ret = line 
            end
        end
        rescue Exception => err
            puts "Failed trying to query the cpuset variable #{fn}, exiting"
            puts "The exception was: #{err}"
            exit
        end
        ret.chomp
    end


    # setter variable to change the values in the cpuset 
    def set_variable( cpuset, variable, value )
        raise ArgumentError, "Argument is tasks - we can not set tasks here" if variable.eql? "tasks"
        unless cpuset.eql? ""
            raise ArgumentError, "Cpuset does not exist" unless list_cpusets.include? cpuset
        end
    
        base = find_base_path

        var = variable
        var = "cpuset.#{variable}" unless variable.include? "cpuset."
        begin 
            File.open( "#{base}#{cpuset}/#{var}", "w") do |line|
                line.write value
            end
        rescue Exception => e 
            puts "Failed in setting the variable: #{@path}#{@name}/#{var} with #{value}"
            puts "Exiting due to exception #{e}"
            exit
        end
    end

    # migrate tasks to a new cpuset 
    def migrate_tasks( pid,  new_cpuset ) 
        raise ArgumentError, "Argument 1 does not look correct \"#{pid}\"" unless pid =~  /^\d+$/
        unless new_cpuset.eql? ""
            raise ArgumentError, "Argument 2 is not a valid cpuset \"#{new_cpuset}\"" unless list_cpusets.include?( new_cpuset )
        end
  
        base = find_base_path

        begin
            File.open( "#{base}#{new_cpuset}/tasks", "w") do |line|
                line.write pid
            end 
        rescue Exception => e
            puts "Failed in migrating the task: #{pid} to #{base}#{new_cpuset}/tasks"
            puts "Exiting due to exception #{e}"
            exit
        end
    end 

    # find the parents (in terms of memory) for each cpu,
    # this is useful for machines that can share l2/3 cache 
    # there does not seem to be a nice way to get access to this data 
    def find_memory_parents
        res = []
        @cpus.each do |c|
            begin 
                # check that the sysfs is mounted 
                sysfs =  `mount`.split("\n").grep(/sysfs/).map { |x| x.split(" ")[2]  }
                default = "#{sysfs}/devices/system/cpu/cpu#{c}"
                raise "sysfs does not look normal"  unless File.directory?(default)
                Dir.foreach(default) do |d|
                    d =~ /^node(.*)$/
                    res <<  $1.to_i if defined? $1 
                end
            rescue Exception => err
                puts "Have failed finding the memory nodes"
                puts "The specific exception is #{err}"
                exit
            end
        end
        return res
    end

    # find parent cpu set for nested cpusets 
    def find_parent( cpuset )
        raise ArgumentError, "Cpuset does not exist" unless list_cpusets.include? cpuset

        res = cpuset.split "/"
        if res.length > 1 
            res.pop
            return res.join("/")
        else 
            return ""
        end
    end


    # get the list of tasks in this cgroup
    def get_tasks( cpuset )
        unless cpuset.eql? ""
            raise ArgumentError, "Cpuset does not exist" unless list_cpusets.include? cpuset
        end

        base = find_base_path

        ret = []
        begin
            File.open("#{base}#{cpuset}/tasks").each do |t|
                ret << t.chomp
            end
        rescue Exception => e 
            puts "Failed getting the list of tasks in this cpuset #{@path}#{@name}/tasks "
            puts "Exiting. The exception was #{e} " 
            exit 
        end
        return ret
    end

end
