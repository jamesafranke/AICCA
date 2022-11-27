#!/bin/bash
#SBATCH --job-name=himwari
#SBATCH --output=himwari.out
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=80G
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=jfranke@uchicago.edu
module load python/cpython-3.8.5
python make_training_stack.py

import os
from glob import glob 
import numpy as np
import xarray as xr
import cv2
#import pyarrow as pa

root = '/scratch/midway2/jfranke/himawari/'

for hour in [0,6,12,18]:
    filelist = [y for x in os.walk(root) for y in glob(os.path.join(x[0], f'*_{hour:02}00_*.nc'))]

    #### resize to 2**10 px-px and stack up samples #########
    x = np.empty( (len(filelist),1024,1024,3),  )
    for i, file in enumerate(filelist):
        ds = xr.open_dataset(file)
        x[i,:,:,0] = cv2.resize( ds.tbb_08.values, (1024, 1024) )
        x[i,:,:,1] = cv2.resize( ds.tbb_11.values, (1024, 1024) )
        x[i,:,:,2] = cv2.resize( ds.tbb_14.values, (1024, 1024) ) 

    ##### scale data from 0-1 ####
    x[:,:,:,0] = x[:,:,:,0] - x[:,:,:,0].min()
    x[:,:,:,0] = x[:,:,:,0] / (x[:,:,:,0].max() - x[:,:,:,0].min())

    x[:,:,:,1] = x[:,:,:,1] - x[:,:,:,1].min()
    x[:,:,:,1] = x[:,:,:,1] / (x[:,:,:,1].max() - x[:,:,:,1].min())

    x[:,:,:,2] = x[:,:,:,2] - x[:,:,:,2].min()
    x[:,:,:,2] = x[:,:,:,2] / (x[:,:,:,2].max() - x[:,:,:,2].min())

    np.save(f'{root}training_stack_{hour:02}00.npy', x.astype(np.float32))
    np.savetxt(f'{root}training_stack_{hour:02}00_file_order.csv', filelist, delimeter =',')


    ##### export to arrow tensor #####
    #pa.ipc.write_tensor(
        #pa.Tensor.from_numpy(x, dim_names=["sample","lon","lat","channel"]),
        #pa.OSFile(f'{root}him_8_11_14_{hour:02}00_training_stack.arrow','wb') 
        #)
