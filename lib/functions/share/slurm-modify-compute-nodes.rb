
action = ARGV[0]
node_name = ARGV[1]

slurm_config_file = ENV['cw_SLURM_CONFIG']
slurm_config_lock_file = "#{slurm_config_file}.lock"

File.open(slurm_config_lock_file, 'w') do |lock|
  # Obtain exclusive lock for this process on lock file, to prevent situation
  # where this script is near simultaneously run from multiple processes on
  # this node, and so one process' changes might not persist.
  lock.flock(File::LOCK_EX)

  slurm_config = File.readlines(slurm_config_file)
  node_name_regex = /(NodeName=)(\S*)([\s\S]*)/
  partition_name_regex = /(PartitionName=.*Nodes=)(\S*)([\s\S]*)/

  slurm_config.find { |line| line =~ node_name_regex}
  nodes = ($2 == 'PLACEHOLDER') ? [] : $2.split(',')

  case action
  when 'add'
    nodes << node_name
  when 'remove'
    nodes = nodes - [node_name]
  else
    exit 1
  end

  if nodes.empty?
    nodes = ['PLACEHOLDER']
  end

  # Get new list of node names with the addition of this node, ensuring that list
  # will always look the same no matter the order nodes join or if node joins
  # twice for some reason.
  node_names = nodes.sort.uniq.join(',')
  puts node_names

  new_slurm_config = slurm_config.map do |line|
    if line =~ node_name_regex || line =~ partition_name_regex
      before = $1
      after = $3
      "#{before}#{node_names}#{after}"
    else
      line
    end
  end
  .join

  File.write(slurm_config_file, new_slurm_config)
end
