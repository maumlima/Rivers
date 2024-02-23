using Rivers

# TODO: put these includes in the Rivers module
include("../../src/engineering/write_routing_levels.jl")
include("../../src/engineering/write_routing_timeseries.jl")
include("../../src/engineering/write_routing_attributes.jl")
include("../../src/routing/routing.jl")

let
    # 0. Pre setup
    base = "/path/to/Rivers/data"
    hydro_lv = "05"
    # Copy the graph dictionary to the folder where the routing will be done
    graph_dict_file = joinpath(base, "midway_data/graph_dicts/graph_lv$hydro_lv.json")
    cp(graph_dict_file, joinpath(base, "routing_lv05/graph_lv$hydro_lv.json"))
    graph_dict_file = joinpath(base, "routing_lv05/graph_lv$hydro_lv.json")
    
    # 1. Write routing levels
    hydroatlas_shp_file = joinpath(base, "source_data/BasinATLAS_v10_shp/BasinATLAS_v10_lev$hydro_lv.shp")
    routing_levels_dir = joinpath(base, "routing_lv05/routing_lvs")
    write_routing_levels(graph_dict_file, hydroatlas_shp_file, routing_levels_dir)

    # 2. Write the proper basin -> dict file
    grdc_nc_file = joinpath(base, "midway_data/GRDC-Globe/grdc-merged.nc")
    basin_gauge_dict_file = joinpath(base, "midway_data/mapping_dicts/gauge_to_basin_dict_lv05_grdc.json")
    gauges_to_basins(
        grdc_nc_file, 
        hydroatlas_shp_file, 
        basin_gauge_dict_file, 
        true,
        "grdc",
        graph_dict_file,
    )

    # 3. Write timeseries
    xd_dir = joinpath(base, "midway_data/xd_lv$hydro_lv")
    start_date = Date(1996, 01, 01)
    end_date = Date(1997, 12, 31)
    timeseries_dir = joinpath(base, "routing_lv05/timeseries")
    write_routing_timeseries(    
        xd_dir, 
        start_date, 
        end_date,
        grdc_nc_file, 
        basin_gauge_dict_file,
        timeseries_dir,
    )

    # 4. Write attributes
    attributes_dir = joinpath(base, "routing_lv05/attributes")
    write_routing_attributes(hydroatlas_shp_file, attributes_dir)

    # TODO: use .yml file to set the parameters
    # 5. Route route
    hillslope_method = "gamma"
    river_channel_method = "IRF"
    simulation_dir = joinpath(base, "routing_lv05/simulation_gamma_IRF")
    route(
        timeseries_dir,
        attributes_dir, 
        graph_dict_file, 
        routing_levels_dir,
        hillslope_method,
        true,
        river_channel_method,
        true,
        start_date,
        end_date,
        simulation_dir,
        1e-5,
        1,
        1e-4,
        2,
    )
end