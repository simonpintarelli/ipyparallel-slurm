#!/bin/bash -l
#SBATCH --job-name=ipcluster
#SBATCH --nodes=2
#SBATCH --constraint=gpu
#SBATCH --ntasks-per-node 12
#SBATCH --mail-user=simon.pintarelli@cscs.ch
#SBATCH --mail-type=ALL
#SBATCH --time=00:20:00
#SBATCH --output jupyter-log-%J.out

module load daint-gpu
module load cray-python/3.6.5.1
module load EasyBuild-custom/cscs
module load PyExtensions
module load jupyter

profile=job_${SLURM_JOB_ID}
echo "creating profile: ${profile}"
ipython profile create ${profile}

echo "Launching controller"
ipcontroller --ip="*" --profile=${profile} &
sleep 10

echo "Launching engines"
srun ipengine --profile=${profile} --location=$(hostname) 2> /dev/null 1>&2 &

ipnport=$(shuf -i8000-9999 -n1)

XDG_RUNTIME_DIR=""
echo "${hostname}:${ipnport}" > jupyter-notebook-port-and-host
jupyter-notebook --no-browser --port=${ipnport} --ip=$(hostname -i)
