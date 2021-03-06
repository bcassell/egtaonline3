require 'backend/flux/pbs_creator'

describe PbsCreator do
  let(:simulators_path) { 'fake/path' }
  let(:local_data_path) { 'fake/local/path' }
  let(:remote_data_path) { 'fake/remote/path' }
  let(:pbs_creator) do
    PbsCreator.new(simulators_path, local_data_path, remote_data_path)
  end
  let(:simulator) do
    double(name: 'fake', fullname: 'fake-1', email: 'fake@example.com')
  end
  let(:node_count) { 1 }
  let(:scheduler) do
    double(simulator: simulator, process_memory: 1000,
           time_per_observation: 300, nodes: node_count)
  end
  let(:simulation) do
    double(id: 1, size: 10, scheduler: scheduler, qos: flux_value)
  end

  describe '#prepare' do
    let(:top) { "#!/bin/bash\n#PBS -S /bin/sh\n" }
    let(:middle) do
      "#PBS -q flux\n" + "#PBS -l nodes=#{scheduler.nodes}," \
      "pmem=#{scheduler.process_memory}mb,walltime=" \
      "#{walltime(scheduler.time_per_observation, simulation.size)}" \
      ",qos=flux\n" \
      "#PBS -N egta-#{simulator.name}\n#PBS -W umask=0007\n" \
      "#PBS -W group_list=wellman\n#PBS -o" \
      " #{remote_data_path}/#{simulation.id}/out\n" \
      "#PBS -e #{remote_data_path}/#{simulation.id}/error\n" \
      "#PBS -M #{simulator.email}\n" \
      "umask 0007\nmkdir /tmp/${PBS_JOBID}\ncp -r " \
      "#{simulators_path}/#{simulator.fullname}/#{simulator.name}/*" \
      " /tmp/${PBS_JOBID}\n" \
      "cp -r #{remote_data_path}/#{simulation.id} /tmp/${PBS_JOBID}\n" \
      "cd /tmp/${PBS_JOBID}\nscript/batch #{simulation.id} #{simulation.size}"
    end
    let(:bottom) do
      "\ncp -r /tmp/${PBS_JOBID}/#{simulation.id} " \
      "#{remote_data_path}\nrm -rf /tmp/${PBS_JOBID}\n"
    end

    context 'when the simulation is to be scheduled on flux' do
      let(:flux_value) { 'flux' }
      let(:response) { top + "#PBS -A wellman_flux\n" + middle + bottom }

      it 'writes out flux wrapper to right location and sets permissions' do
        f = double('file')
        f.should_receive(:write).with(response)
        File.should_receive(:open).with(
          "#{local_data_path}/#{simulation.id}/wrapper", 'w').and_yield(f)
        pbs_creator.prepare(simulation)
      end
    end

    context 'when the simulation is not to be scheduled on flux' do
      let(:flux_value) { 'cac' }
      let(:response) { top + "#PBS -A engin_flux\n" + middle + bottom }

      it 'writes out flux wrapper to right location and sets tpermissions' do
        f = double('file')
        f.should_receive(:write).with(response)
        File.should_receive(:open).with(
          "#{local_data_path}/#{simulation.id}/wrapper", 'w').and_yield(f)
        pbs_creator.prepare(simulation)
      end
    end

    context 'when the simulation requires multiple nodes' do
      let(:node_count) { 10 }
      let(:flux_value) { 'flux' }
      let(:response) do
        top + "#PBS -A wellman_flux\n" + middle + ' ${PBS_NODEFILE}' + bottom
      end

      it 'writes out flux wrapper to right location and sets permissions' do
        f = double('file')
        f.should_receive(:write).with(response)
        File.should_receive(:open).with(
          "#{local_data_path}/#{simulation.id}/wrapper", 'w').and_yield(f)
        pbs_creator.prepare(simulation)
      end
    end
  end
end

def walltime(time_per, number)
  walltime_val = number * time_per
  [walltime_val / 3600, (walltime_val / 60) % 60, walltime_val % 60]
    .map { |time| format('%02d', time) }.join(':')
end
