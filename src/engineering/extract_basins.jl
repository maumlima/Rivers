# Define directory
timeseries_dir = "era5_grdc_merge/timeseries_lv07"

# Get a list of all files in the timeseries directory
basin_files = readdir(timeseries_dir)

# Get each basin ID by the file name
basins_ids = [parse(Int64, split(basename(basin_file), "_")[end][1:end-4]) for basin_file in basin_files]

# Open the file in write mode
file = open(joinpath("extractions", "na_lv07_selected.txt"), "w")

# Write each integer to the file
for basin_id in basins_ids
    write(file, "$basin_id\n")
end

# Close the file
close(file)