## 1 - Engineering (Julia)
The following can be found inside the `engineering` folder.

1. Create a set of .json mapping ERA5 grid points to HydroSHEDS basins with `grid_points_to_basins()`.
2. Compute dynamical variables for all basins with `compute_basins_timeseries()`. Currently using netCDF files from ERA5 Land divided by year and month. Note: this function takes a lot of time currently (days for level 07) and can be optimised in the future! If the cluster bugs and you have to use checkpoint option, make sure to use `select_uniques()`.
3. Merge and shift GRDC files from local time to UTC with `merge_and_shift_grdc_files()`.
4. (For the graph model only:) Use `create_graph()` to create the nested sub-basins relation in a .json file.
5. Connect GRDC gauges to HydroSHEDS basins with `gauges_to_basins()`. Note: different options for single and graph model here!
6. Merge ERA5 timeseries for each HydroSHEDS basin with the corresponding GRDC gauge with `merge_era5_grdc()`. This function has two additional argument for the graph model.
7. Get the statical attributes for each basin with `attribute_attributes()`. This function has an additional argument for the graph model.
8. Extract the basin lists for each model with `extract_basin_lists()`.

At the end of the process you should get a `timeseries/`, an `attributes/` and a `basin_lists/` folder ready to be used by the model.

The complete engineering approach is shown in `examples/engineering/`. For an overview on how to download the data see `examples/engineering/download_data_scripts/source_data_structure.txt`. The engineering process is used in HydroSHEDS level 05 in `examples/engineering/engineer_lv05.jl`.

## 2 - Neuralhydrology (Python)
This section is dedicated to training, evaluating and forecasting streamflow using the python library neuralhydrology.

Here we use a forked repository from NeuralHydrology (original: https://github.com/neuralhydrology/neuralhydrology) with an additional class to the created data set: Era5GrdcSheds. 

To use this part of the repository, make sure to:
```
cd neuralhydrology
pip install -e .
```
as shown in the documentation of the package.

All the configurations used to train the models for the paper are available as `.yml` files.

1. To train a model, use `nh-run train --config-file config.yml`. A `run_dir` will be created to store training info.
2. To evaluate this run for a given epoch, use `nh-run evaluate --run-dir /path/to/run_dir/ --epoch N`.
3. To simulate the streamflow timeseries over the test period + the metrics for each basin in csv files, use `simulate.py`.

## 3 - Analysis (Julia)
Illustrations of the engineering process and model scores are made in the `analysis/` folder.

## 4 - Optional (Julia)
For generating the benchmarking data, see `benchmarks`.

Considerations about precipitation, evaporation and runoff balance as well as the mass conservation of the different river models used on this work can be found in the `mass_balance/` folder.