# memory.rb
# Additional Facts for memory/swap usage
#
# Copyright (C) 2006 Mooter Media Ltd
# Author: Matthew Palmer <matt@solutionsfirst.com.au>
#
#
require 'facter/util/memory'

{   :MemorySize => "MemTotal",
    :MemoryFree => "MemFree",
    :SwapSize   => "SwapTotal",
    :SwapFree   => "SwapFree"
}.each do |fact, name|
    Facter.add(fact) do
        confine :kernel => :linux
        setcode do
            Facter::Memory.meminfo_number(name)
        end
    end
end

if Facter.value(:kernel) == "AIX" and Facter.value(:id) == "root"
    swap = Facter::Util::Resolution.exec('swap -l')
    swapfree, swaptotal = 0, 0
    swap.each do |dev|
      if dev =~ /^\/\S+\s.*\s+(\S+)MB\s+(\S+)MB/
        swaptotal += $1.to_i
        swapfree  += $2.to_i
      end 
    end 
 
    Facter.add("SwapSize") do
        confine :kernel => :aix
        setcode do
            Facter::Memory.scale_number(swaptotal.to_f,"MB")
        end
    end

    Facter.add("SwapFree") do
        confine :kernel => :aix
        setcode do
            Facter::Memory.scale_number(swapfree.to_f,"MB")
        end
    end
end

if Facter.value(:kernel) == "OpenBSD"
    swap = Facter::Util::Resolution.exec('swapctl -l | sed 1d')
    swapfree, swaptotal = 0, 0
    swap.each do |dev|
        if dev =~ /^\S+\s+(\S+)\s+\S+\s+(\S+)\s+.*$/
            swaptotal += $1.to_i
            swapfree  += $2.to_i
        end
    end

    Facter.add("SwapSize") do
        confine :kernel => :openbsd
        setcode do
            Facter::Memory.scale_number(swaptotal.to_f,"kB")
        end
    end

    Facter.add("SwapFree") do
        confine :kernel => :openbsd
        setcode do
            Facter::Memory.scale_number(swapfree.to_f,"kB")
        end
    end

    Facter::Memory.vmstat_find_free_memory()

    Facter.add("MemoryTotal") do
        confine :kernel => :openbsd
        memtotal = Facter::Util::Resolution.exec("sysctl hw.physmem | cut -d'=' -f2")
        setcode do
            Facter::Memory.scale_number(memtotal.to_f,"")
        end
    end
end

if Facter.value(:kernel) == "SunOS"
    swap = Facter::Util::Resolution.exec('/usr/sbin/swap -l')
    swapfree, swaptotal = 0, 0
    swap.each do |dev|
        if dev =~ /^\/\S+\s.*\s+(\d+)\s+(\d+)$/
            swaptotal += $1.to_i / 2
            swapfree  += $2.to_i / 2
        end 
    end 
 
    Facter.add("SwapSize") do
        confine :kernel => :sunos
        setcode do
            Facter::Memory.scale_number(swaptotal.to_f,"kB")
        end
    end

    Facter.add("SwapFree") do
        confine :kernel => :sunos
        setcode do
            Facter::Memory.scale_number(swapfree.to_f,"kB")
        end
    end

    # Total memory size available from prtconf
    pconf = Facter::Util::Resolution.exec('/usr/sbin/prtconf')
    phymem = ""
    pconf.each do |line|
        if line =~ /^Memory size:\s+(\d+) Megabytes/
            phymem = $1
        end
    end

    Facter.add("MemorySize") do
        confine :kernel => :sunos
        setcode do
            Facter::Memory.scale_number(phymem.to_f,"MB")
        end
    end

    Facter::Memory.vmstat_find_free_memory()
end
