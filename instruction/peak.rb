#!/usr/bin/env ruby
require_relative  'src/lib'
require 'terminal-table'

#                
# |\/|  _. o ._  - peak edition 
# |  | (_| | | | 
#

#$logger.level = -1 #5  # -1 verbose, to 5 quiet 
$logger.level = 5 #5  # -1 verbose, to 5 quiet 
if ARGV.length != 7
    puts "./a.out inst datatype simd_length n_global n_outer n_inner"
    exit
end

l_inst = parse_input(ARGV[0], f: lambda { |inst|
   p = inst.to_s.gsub('_','.')
   unless $l_suported_inst.include? p
       puts "#{inst} not supported yet"
       puts "Choose one from #{$l_suported_inst.keys}"
       exit
   end
   p
})

l_datatype = parse_input(ARGV[1], f: lambda { |datatype|
    unless $type_to_bytes.include? datatype
       puts "#{datatype} not supported yet"
       puts "Choose one from #{$type_to_bytes}"
       exit
    end 
    datatype
    })

mode_l      = parse_input(ARGV[2], f: lambda { |i| DataDependency.new i } )
simd_size_l = parse_input(ARGV[3], f: :to_i)
n_global_l  = parse_input(ARGV[4], f: :to_i)
n_outer_l   = parse_input(ARGV[5], f: :to_i)
n_inner_l   = parse_input(ARGV[6], f: :to_i)

rows = mode_l.product(l_inst, l_datatype, simd_size_l, n_global_l, n_outer_l, n_inner_l).collect  { |mode, inst, datatype, simd_size, n_global, n_outer, n_inner|
   n_global = n_global.to_i
   b = bench(inst, datatype, mode, simd_size, n_global, n_inner, n_outer)
   t = b.best_time
   ninst = b.instructions_count
   neu = b.eu_used
   nthreads = b.threads
   flops= b.flops
   neu = [$dev.eu_number, n_global/simd_size].min 
   [inst, datatype, mode, simd_size, n_global, n_outer, n_inner, nthreads, "%10.3E" % flops, ninst, t, ns_to_clk(t), (flops.to_f/t).round(2), (ns_to_clk(t).to_f*neu/ninst).round(3), (ninst*simd_size/(neu*ns_to_clk(t).to_f)).round(3) ] 
}

#puts rows[0]
best_row = 0 
best_flops = 0
rows.each_with_index { |val, index| 
  if val[12].to_f > best_flops then
    best_flops = val[12].to_f
    best_row = index
  end
}
single_row = [rows[best_row]]

table = Terminal::Table.new  :headings =>  ['inst','T', 'mode', 'simd', 'global WG', 'outer','inner','threads', 'flops', "v.inst (#)", 'time (ns)', 'time (cycle)', 'GLOPS/s',"cycle/v.inst/EU","s.inst/cycle/EU"], :rows => single_row
puts table
