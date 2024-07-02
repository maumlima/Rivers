#!/bin/bash

#SBATCH --job-name=usa_time
#SBATCH --partition=gpu
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --gres=gpu:v100:1 # remove :v100 for p100    
#SBATCH --time=1:00:00 # adjust as necessary
#SBATCH --mem-per-gpu=16GB # adjust as necessary
#SBATCH --mail-user=achiang@caltech.edu
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL

set -euo pipefail # kill the job if anything fails
set -x # echo script
nh-run train --config-file /home/achiang/CliMA/Rivers/examples/catchment_models/lstm_training/usa_time_split.yml
echo done