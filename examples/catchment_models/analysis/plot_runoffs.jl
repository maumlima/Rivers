using CairoMakie
using CSV
using DataFrames
using Dates
using Statistics

function main()
    # Define basin
    basin_id = 2070017000
    base = "/home/achiang/CliMA/Rivers_odunbar/data_from_sampo"
    ddf = CSV.read(joinpath(base, "single_model_data/timeseries/timeseries_lv07/basin_$basin_id.csv"), DataFrame)
    sdf = CSV.read(joinpath(base, "single_model_data/attributes/attributes_lv07/other_attributes.csv"), DataFrame)
    basin_area = sdf[sdf[:, :basin_id] .== basin_id, "area"]

    # Select date indexes
    min_date_idx = findfirst(date -> date == Date(1996, 01, 01), ddf[:, "date"])
    max_date_idx = findfirst(date -> date == Date(1998, 12, 31), ddf[:, "date"])

    # Plot Runoffs
    fig = Figure(resolution=(1000,500))
    ax = Axis(fig[1,1], xlabel="Dates", xlabelsize=17, ylabel="Discharge (m³/s)", ylabelsize=17)
    lines!(ax, min_date_idx:max_date_idx, ddf[min_date_idx:max_date_idx, "sro_sum"] .* ((basin_area*1000000) / (24*60*60)),label="Surface Runoff", transparency=true, color=:grey60, linewidth=2)
    lines!(ax, min_date_idx:max_date_idx, ddf[min_date_idx:max_date_idx, "ssro_sum"] .* ((basin_area*1000000) / (24*60*60)),label="Sub-surface Runoff", transparency=true, color=:grey40, linewidth=2)
    lines!(ax, min_date_idx:max_date_idx, ddf[min_date_idx:max_date_idx, "streamflow"], label="Streamflow", transparency=true, color=:dodgerblue, linewidth=2)
    ax.xticks = (min_date_idx+30:365:max_date_idx+30, string.(ddf[:, "date"])[min_date_idx+30:365:max_date_idx+30])
    ax.xticklabelrotation = π/4
    axislegend(ax)
    hidedecorations!(ax, ticklabels=false, ticks=false, label=false)
    hidespines!(ax, :t, :r)
    save("examples/catchment_models/analysis/png_files/runoffs.png", fig, px_per_unit=4)
end

main()