using CSV
using DataFrames
using Dates

function train_river_channel_routing(
    routing_lv_basins::Vector{Int64},
    graph_dict::Dict,
    timeseries_dir::String,
    attributes_dir::String,
    output_dir::String,
    physical::AbstractPhysicalModel,
    learning_rate::Real,
    epochs::Int64,
)
    error("Not sure it works.")
    
    # Define constant
    km_to_m = 1e3

    # Define time length
    first_basin_id = routing_lv_basins[1]
    time_length = length(CSV.read(joinpath(output_dir, "basin_$first_basin_id.csv"), DataFrame)[:,:streamflow])

    attributes_df = CSV.read(joinpath(attributes_dir, "attributes.csv"), DataFrame)

    # Allocate x and y
    x = zeros(time_length+1) # +1 for the mean distance
    y = zeros(time_length)

    # Allocate not-NaN indexes
    valid_idxs = Int64[]

    # Iterate over basins in the given routing level
    for basin_id in routing_lv_basins
        # Get current streamflow in the basin
        obs_streamflow = CSV.read(joinpath(timeseries_dir, "basin_$basin_id.csv"), DataFrame)[:,:streamflow]

        # Discard basins with NaN streamflow values on matched gauge dates
        if isnan(sum(obs_streamflow))
            continue
        end

        # Allocate streamflow from upstreams and mean distance in a new_x array
        new_x = zeros(time_length + 1)

        # Sum current streamflow from hillslope routing
        new_x[1:time_length] += CSV.read(joinpath(output_dir, "basin_$basin_id.csv"), DataFrame)[:,:streamflow]

        # Iterate over upstreams
        count_ups = 0
        for up_basin in graph_dict[string(basin_id)]
            # Add streamflow from upstream
            new_x[1:time_length] += CSV.read(joinpath(output_dir, "basin_$up_basin.csv"), DataFrame)[:,:streamflow]

            # Sum riverine distance until the outlet of the basin from HydroATLAS
            new_x[end] += attributes_df[attributes_df.HYBAS_ID .== up_basin, :DIST_MAIN][1] - attributes_df[attributes_df.HYBAS_ID .== basin_id, :DIST_MAIN][1]

            # Upload counter
            count_ups += 1
        end

        # Update summed distance to mean distance
        new_x[end] = new_x[end] / count_ups * km_to_m

        # Write upstream streamflow and mean distance
        x = hcat(x, new_x)
        y = hcat(y, obs_streamflow)
    end

    # Take out the initial zeros column
    x = x[:,2:end]
    y = y[:,2:end]

    # Check for valid basins
    if size(y) == time_length
        println("No valid basins in this routing level")
    else
        # Train
        physical = train(
            x, # Take out the initial zeros column
            y, # ||
            physical,
            learning_rate,
            epochs,
        )
    end

    return physical
end


function simulate_river_channel_routing(
    routing_lv_basins::Vector{Int64},
    graph_dict::Dict,
    attributes_dir::String,
    output_dir::String,
    physical::AbstractPhysicalModel,
)
    # Define constant
    km_to_m = 1e3

    # Read attributes DataFrame
    attributes_df = CSV.read(joinpath(attributes_dir, "attributes.csv"), DataFrame)

    # Iterate over basins in the given routing level
    for basin_id in routing_lv_basins
        # Get current streamflow in the basin
        timeseries_df = CSV.read(joinpath(output_dir, "basin_$basin_id.csv"), DataFrame)

        # Allocate streamflow from upstreams
        up_streamflow = zeros(length(timeseries_df[:,:streamflow]))

        # Iterate over upstreams
        for up_basin in graph_dict[string(basin_id)]
            # Read DataFrame with inputs from upstream
            up_timeseries_df = CSV.read(joinpath(output_dir, "basin_$up_basin.csv"), DataFrame)

            # Get riverine distance until the outlet of the basin from HydroATLAS
            dist = attributes_df[attributes_df.HYBAS_ID .== up_basin, :DIST_MAIN][1] - attributes_df[attributes_df.HYBAS_ID .== basin_id, :DIST_MAIN][1]
            
            # Sum the runoff and sub-surface runoff columns
            input = up_timeseries_df[:,:streamflow]
            
            up_streamflow += physical.model(vcat(input, dist*km_to_m), physical.params)
        end

        # Sum the upstreamflow with the current basin streamflow
        timeseries_df[!,:streamflow] += up_streamflow[:,1]

        # Get dates array
        dates = timeseries_df.date

        # Override streamflow timeseries
        CSV.write(joinpath(output_dir, "basin_$basin_id.csv"), timeseries_df)
    end
end

# Main
function river_channel_route(
    routing_lv_basins::Vector{Int64},
    graph_dict::Dict,
    timeseries_dir::String,
    attributes_dir::String,
    output_dir::String,
    model::AbstractPhysicalModel,
    is_training::Bool,
    learning_rate::Real=nothing,
    epochs::Int64=nothing,
)
    if is_training
        model = train_river_channel_routing(
            routing_lv_basins,
            graph_dict,
            timeseries_dir,
            attributes_dir,
            output_dir,
            model,
            learning_rate,
            epochs,
        )
    end

    simulate_river_channel_routing(
        routing_lv_basins,
        graph_dict,
        attributes_dir,
        output_dir,
        model,
    )

    return model
end