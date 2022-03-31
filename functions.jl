#################################
# Utils 
#################################
using CSV
using DataFrames 
using JSON 
using Colors
using PlotlyJS

#################################
# Run analysis 1: Percent change
#################################
function run_analysis_percent_change!(traces_data::Dict, time_first_release, threshold_success)
    
    # data 
    female_wild = traces_data["traces"]["Female"]["Female_Wild"][1:end-1]

    # percent change in wildtype  
    percent_change = [(d - female_wild[1])/female_wild[1] for d in female_wild].*100

    # area under wildtype trend line
    area_under_the_curve = [0.5*(female_wild[t - 1] + female_wild[t]) for t in range(2, length = length(female_wild) - 1)]

    # add to traces_data dict 
    traces_data["percent_change"] = percent_change
    traces_data["area_under_the_curve"] =  area_under_the_curve

    return
end

#################################
# Run analysis 2: Time to target
#################################
function run_analysis_time_to_reduction_target!(traces_data::Dict, time_first_release, threshold_success)
   
    # data 
    percent_change = traces_data["percent_change"]
    timesteps = traces_data["timesteps"][1:end-1]

    # error check 
    if all(isapprox.(percent_change, 0.0, atol = 1e-3))
        @warn("no change detected for $traces_data")
        return 
    end

    # downsample to make values daily
    common_ix = UnitRange{Int}(timesteps[1], timesteps[end])
    percent_changes_in_daily_timesteps = [percent_change[ix] for (ix, v) in enumerate(unique(timesteps)) if v ∈ common_ix]

    # error check 
    if length(percent_changes_in_daily_timesteps) != length(common_ix)
        @error "The resulting length of percent_changes_in_daily_timesteps isn't matching the number of days"
    else

    # set desired thresholds (%)
    thresholds = 20:5:95

    if isempty(common_ix[percent_changes_in_daily_timesteps .< -thresholds[1]])

        # If smallest threshold never achieved return end of horizon 
        time_to_achieve_public_health_target = timesteps[end] 
        @warn("First threshold was never met.")

        # If smallest threshold not met, none met; return empty  
        days_to_achieve_reduction_thresholds = [] 
        @warn("Threshold not met before the end of the study period.")
    else
        time_to_target_function = th -> begin
            max_valid_day_ = findfirst(x -> x > 0, percent_changes_in_daily_timesteps[time_first_release+1:end])
            max_valid_day = max_valid_day_ === nothing ? timesteps[end] : max_valid_day_ + time_first_release
            target_time = common_ix[percent_changes_in_daily_timesteps .< -th]
            isempty(target_time) && return missing
            return first(target_time) - time_first_release
        end
        time_to_achieve_public_health_target = time_to_target_function(threshold_success)
        days_to_achieve_reduction_thresholds = [time_to_target_function(th) for th in thresholds]
    end
    
    days_to_achieve_reduction_thresholds = [time_to_target_function(th) for th in thresholds] 
    end

    traces_data["time_to_achieve_public_health_target"] = time_to_achieve_public_health_target
    traces_data["days_to_achieve_reduction_thresholds"] = days_to_achieve_reduction_thresholds
    traces_data["reduction_thresholds_in_percent"] = thresholds

    return
end

#################################
# Run analysis 3: Efficacy score
#################################

function run_analysis_suppression_efficacy_score!(traces_data::Dict, time_first_release, threshold_success)
    # get percent change in wildtype in time over the whole time period and for every integrator step
    timesteps = traces_data["timesteps"]
    percent_change = traces_data["percent_change"]
    area_under_the_curve = traces_data["area_under_the_curve"]

    # Downsampled values of the percent changes to make the values daily
    common_ix = UnitRange{Int}(timesteps[1], timesteps[end])
    percent_changes_in_daily_timesteps = [percent_change[ix] for (ix, v) in enumerate(unique(timesteps)) if v ∈ common_ix]
    area_under_the_curve_in_daily_timesteps = [area_under_the_curve[ix] for (ix, v) in enumerate(unique(timesteps)) if v ∈ common_ix]

    #if length(percent_change) != length(common_ix)
    if length(percent_changes_in_daily_timesteps) != length(common_ix)
        @error "The resulting length of percent_changes_in_daily_timesteps isn't matching the number of days"
        return
    end

    # Measure of efficacy: total error (distance) over time from the ideal starting from first release
    area_discrepancy = traces_data["traces"]["Female"]["Female_Wild"][1]*timesteps[end] - sum(area_under_the_curve_in_daily_timesteps)

    # final score 
    traces_data["suppression_efficacy_score"] = (area_discrepancy/(traces_data["traces"]["Female"]["Female_Wild"][1]*timesteps[end]))*100
    return
end


#################################
# Helper functions 
#################################
function _make_traces_wolbachia(results::Dict)
    grouped_traces = Dict{String, Any}()

    grouped_traces["Female"] = Dict{String, Vector{Float64}}()

    grouped_traces["Female"]["Female_Mod"] = [v[1] for v in results["states"]["AedesAegypti"]["Female"]["WW"]] .+
                                            [v[1] for v in results["states"]["AedesAegypti"]["Female"]["ww"]]

    grouped_traces["Female"]["Female_Wild"] = [v[2] for v in results["states"]["AedesAegypti"]["Female"]["WW"]] .+
                                            [v[2] for v in results["states"]["AedesAegypti"]["Female"]["ww"]]

    grouped_traces["Male"] =  Dict{String, Vector{Float64}}()
    grouped_traces["Male"]["Male_Mod"] = [v[1] for v in results["states"]["AedesAegypti"]["Male"]["WW"]]
    grouped_traces["Male"]["Male_Wild"] = [v[1] for v in results["states"]["AedesAegypti"]["Male"]["ww"]]

    return grouped_traces
end

function _make_traces_ridl(results::Dict)
    grouped_traces = Dict{String, Any}()

    grouped_traces["Female"] = Dict{String, Vector{Float64}}()
    grouped_traces["Female"]["Female_Wild"] = [v[1] for v in results["states"]["AedesAegypti"]["Female"]["WW"]] .+
                                            [v[1] for v in results["states"]["AedesAegypti"]["Female"]["WR"]] .+
                                            [v[1] for v in results["states"]["AedesAegypti"]["Female"]["RR"]]

    grouped_traces["Female"]["Female_Hetero"] = [v[2] for v in results["states"]["AedesAegypti"]["Female"]["WW"]] .+
                                            [v[2] for v in results["states"]["AedesAegypti"]["Female"]["WR"]] .+
                                            [v[2] for v in results["states"]["AedesAegypti"]["Female"]["RR"]]

    grouped_traces["Female"]["Female_Mod"] = [v[3] for v in results["states"]["AedesAegypti"]["Female"]["WW"]] .+
                                            [v[3] for v in results["states"]["AedesAegypti"]["Female"]["WR"]] .+
                                            [v[3] for v in results["states"]["AedesAegypti"]["Female"]["RR"]]

    grouped_traces["Male"] =  Dict{String, Vector{Float64}}()
    grouped_traces["Male"]["Male_Wild"] = [v[1] for v in results["states"]["AedesAegypti"]["Male"]["WW"]]
    grouped_traces["Male"]["Male_Hetero"] = [v[1] for v in results["states"]["AedesAegypti"]["Male"]["WR"]]
    grouped_traces["Male"]["Male_Mod"] = [v[1] for v in results["states"]["AedesAegypti"]["Male"]["RR"]]

    return grouped_traces
end

plots_construct_map = Dict("WOLBACHIA" => _make_traces_wolbachia,
                           "RIDL" => _make_traces_ridl)

function make_traces(json_file::String)
    if occursin("._", json_file)
        @warn("not a JSON file $json_file")
        return Dict{String, Any}("traces" => [])
    end
    results = JSON.parsefile(json_file)
    traces_data = Dict{String, Any}()
    if haskey(results["states"], "STATUS")
        print("Solution $(plot_number[2]) unstable. Omitting plot. ")
        return Dict{String, Any}("traces" => [])
    else
        file_name = split(json_file, '/')[end]
        experiment_name = split(file_name, '.')[1]
        plot_properties = split(experiment_name, '_')
        construct = plot_properties[end]
        traces_data["traces"] = plots_construct_map[construct](results)
    end

    traces_data["title"] = construct
    traces_data["timesteps"] = Vector{Float64}(results["time"])

    return experiment_name, traces_data
end

function increment!(d::Dict{S, T}, k::S, i::T) where {T<:Real, S<:Any}
    if haskey(d, k)
            d[k] += i
    else
            d[k] = i
    end
end
increment!(d::Dict{S, T}, k::S ) where {T<:Real, S<:Any} = increment!( d, k, one(T))

function df2dict( df::DataFrame, key_col::Symbol; val_col::Symbol=:null)
    keytype = typeof(df[1,key_col])
    if val_col == :null
            valtype = Int
    else
            valtype = typeof(df[1,val_col])
    end
    D = Dict{keytype, valtype}()
    for i=1:size(df,1)
        if !ismissing(df[i,key_col])
            if val_col == :null
                increment!( D, df[i,key_col] )
            elseif valtype <: Real
                increment!( D, df[i,key_col], df[i,val_col] )
            else
                if haskey(D, df[i,key_col])
                    @warn("non-unique entry: $(df[i,key_col])")
                else
                    D[df[i,key_col]] = df[i,val_col]
                end
            end
        end
    end
return D
end

csv_path = "/Volumes/EMTEC_B250/"
original_file = CSV.read(joinpath(csv_path, "orderedTAVG.csv"), DataFrame)
new_file = original_file[(original_file.Year.>2015) .& (original_file.Year.<2019),:] 
CSV.write("metrics_orderedTAVG.csv", new_file)

temperature_key = sort!(CSV.read(joinpath(csv_path, "metrics_orderedTAVG.csv"), DataFrame),[:Order])[!,2:end];
# push!(temperature_key,[0 27.0 "temp" 0 "temp27lab"]) not using baseline anymore 
const temperature_key_map = df2dict(temperature_key, :Concatenated;  val_col=:AAVG)

#################################
# Dict for all analyses 
#################################

function analyze_results(json_dir::String, construct_cost::String, release_size::String, time_first_release, threshold_success, file_count = nothing)

    trace_results = Dict{String, Any}()

    file_list = readdir(json_dir)

        file_count = file_count === nothing ? length(file_list) : file_count

        if sum([occursin(construct_cost, v) for v in file_list]) < 1
            error("No files with the construct $construct_cost exist inside of $json_dir")
        end

        for file_name in file_list[1:file_count]

            if file_name in [".DS_Store"]
                continue
            end

            if any(occursin("._", file_name))
                continue
            end

            if any(occursin("noresponse", file_name))
                @warn("excluding results with no temperature response: $file_name")
                continue
            end

            #=
            if  any(occursin("lab", file_name)) | any(occursin("tmean", file_name)) #| any(occursin("tshock", file))
                @warn("excluding results with future or lab temperature response: $file_name")
                continue
            end
            =#

            file_path = joinpath(json_dir, file_name)

            # Metrics Paper:
            if occursin(construct_cost, file_name)
                experiment_name, traces_data = make_traces(file_path) 
                @show experiment_name
                isempty(traces_data["traces"]) && continue
                traces_data["plot_name"] = split(file_name, '.')

                # analysis details 
                run_analysis_percent_change!(traces_data, time_first_release, threshold_success)
                run_analysis_time_to_reduction_target!(traces_data, time_first_release, threshold_success)
                run_analysis_suppression_efficacy_score!(traces_data, time_first_release, threshold_success)

                # plotting details 
                plot_name = traces_data["plot_name"][1]
                trace_info = split(plot_name, '_')
                trace_name = trace_info[end-1] 
                traces_data["construct_cost"] = trace_info[end-5][6:end]
                traces_data["release_size"] = parse(Int64, match(r"[[:digit:]]+", trace_info[end-2]).match)
                traces_data["avg_temp"] = round(temperature_key_map[trace_name], digits=2)
                #traces_data["std_temp"] = round(stdev_key_map[trace_name], digits=2) decided to remove
                trace_results[experiment_name] = traces_data
            end
        end


    return trace_results

end