using CSV
using DataFrames
using ProgressMeter

include("utils.jl")

function plot_histogram(diffs::Vector{Float64}, threshold::Real, n_outliers::Int)
    # Define figure and axis
    fig = Figure()
    ax = Axis(fig[1,1], title="(P-E) - (Rs+Rss)", ylabel="N of basins", xlabel="mm/yr")

    # Plot histogram
    hist!(ax, diffs, bins=100)
    text!(-threshold+0.1, 200, text="N of outliers: $n_outliers")

    # Save figure
    save("examples/catchment_models/examples/catchment_models/png_files/histogram_basins.png", fig)
end

function plot_map(shapefile::String, diffs_df::DataFrame, lv::String, output_file::String)
    # Define figure and axis
    fig = Figure()
    ax = Axis(fig[1, 1])
    
    # Read HydroBASINS lv to plot basins
    shp_df = Shapefile.Table(shapefile) |> DataFrame
    
    # Merge DataFrames
    merged_df = innerjoin(shp_df, diffs_df, on = :HYBAS_ID => :basin)

    # Define color range
    color_range = (-30,30)
    
    # Plot basins
    msg = "Plotting basins"
    @showprogress msg for row in eachrow(merged_df)
        if !ismissing(row.diff) & !isinf(row.diff)
            poly!(ax, row.geometry, color=row.diff, colormap=:RdBu, colorrange=color_range, strokewidth=2)
        else
            poly!(ax, row.geometry, color=:lightslateblue)
        end
    end
    Colorbar(fig[1,2], colormap = :RdBu, limits=color_range)

    # Define title of the plot
    ax.title = "(P-E) - (Rs+Rss) in mm/yr in lv$lv"
    
    # Save
    save(output_file, fig, px_per_unit = 4)
end

# Start run here
function main()
    # Empty array to store values to plot in the histogram
    histogram_diffs::Vector{Float64} = Float64[]

    # Define constant
    m_to_mm = 1000

    # Define threshold for n_outliers
    threshold = 30
    n_outliers = 0

    # Plot the difference in a map
    lv = "05"
    global_shapefile = "/central/scratch/mdemoura/Rivers/source_data/BasinATLAS_v10_shp/BasinATLAS_v10_lev01.shp"
    shapefile = "/central/scratch/mdemoura/Rivers/source_data/BasinATLAS_v10_shp/BasinATLAS_v10_lev$lv.shp"
    shp_df = Shapefile.Table(shapefile) |> DataFrame

    # Iterate over HydroSHEDS levels
    for lv in [lv]
        # Directories with lv information
        xd_dir = "/central/scratch/mdemoura/Rivers/midway_data/xd_lv$lv"
        xd_evaporation_dir = "/central/scratch/mdemoura/Rivers/midway_data/xd_lv$lv"*"_evaporation"

        # Take length of generic file in the evaporation folder
        file = readdir(xd_evaporation_dir, join=true)[1]
        time_length = length(CSV.read(file, DataFrame)[:,1])

        # Vector to save differences and basin ID
        diffs::Vector{Float64} = Float64[]
        basins::Vector{Int64} = Int64[]

        # Total differences
        total_p_minus_e_sum = 0
        total_runoff_sum = 0

        # Iterate over all basins
        msg = "Iterating over lv$lv..."
        @showprogress msg for file in readdir(xd_dir)
            basin = parse(Int, split(split(file, "_")[2], ".")[1])
            df = CSV.read(joinpath(xd_dir, file), DataFrame)
            e_df = CSV.read(joinpath(xd_evaporation_dir, file), DataFrame)

            # Check dimensions of evaporation DataFrame
            if length(e_df[:,1]) != time_length
                println("\nError in dimensions of ", basin)
                continue
            end

            # Proceed normaly
            p_minus_e_sum = sum(df[1:time_length, "tp_sum"]) + sum(e_df[1:time_length, "e_sum"])
            runoff_sum = sum(df[1:time_length, "sro_sum"]) + sum(df[1:time_length, "ssro_sum"])

            diff = (p_minus_e_sum - runoff_sum) * m_to_mm / 10 # TODO: solve hard coding
            push!(diffs, diff)
            push!(basins, basin)

            if abs(diff) < threshold
                total_p_minus_e_sum += p_minus_e_sum
                total_runoff_sum += runoff_sum
            else
                n_outliers += 1
            end
        end

        map_df = DataFrame(basin=basins, diff=diffs)
        output_file = "/examples/catchment_models/examples/catchment_models/mass_balance/png_files/map_lv$lv.png"
        plot_map(shapefile, map_df, lv, output_file)

        # Append into the histogram array
        append!(histogram_diffs, [x for x in diffs if abs(x) <= threshold])
    end

    # Plot histogram
    plot_histogram(histogram_diffs, threshold, n_outliers)
end

main()
