
#################################
# Percent change
#################################
function make_pctchange_traces(trace_data)
    plot_name = trace_data["plot_name"][1]
    trace_info = split(plot_name, '_')
    trace_name = trace_info[end-1] 

    release_size = trace_info[end-2]

    numbers_in_trace_name = collect(eachmatch(r"[0-9]+", trace_name))
    temp = round(temperature_key_map[trace_name], digits=2)

    numbers_in_release_size = collect(eachmatch(r"[0-9]+", release_size))
    release_scenario = numbers_in_release_size[1].match

    if length(numbers_in_trace_name) < 2
        temp_scenario = numbers_in_trace_name[1].match
        if numbers_in_trace_name[1].match == "27"
            temp_scenario = "Baseline (No Temperature Effects)"
            name_ = "$temp_scenario, Release:$release_scenario"
        else
            name_ = "$temp_scenario, $temp °C, Release:$release_scenario"
        end
    elseif length(numbers_in_trace_name) == 2
        has_shock = occursin("shock", trace_name)
        rcp_scenario = numbers_in_trace_name[1].match
        year = numbers_in_trace_name[2].match
        if has_shock
            temp_scenario = "$year RCP-$(rcp_scenario) Heatwave"
        else
            temp_scenario = "$year RCP-$(rcp_scenario)"
        end
        name_ = "$temp_scenario, $temp °C, Release:$release_scenario"
    else
        error("trace_name invalid $trace_name")
    end
    trace = scatter(; x = trace_data["timesteps"], 
        y = trace_data["percent_change"], name = name_)
    trace.fields[:base_series] = trace_name
    return trace
end

function make_pctchange_plots(trace_data)

    plotting_traces = PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]

    for (experiment_name, traces) in trace_data
        push!(plotting_traces, make_pctchange_traces(traces))
    end

    c1 = Colors.colorant"purple"
    c2 = Colors.colorant"lightblue"
    colors = range(c1, stop=c2, length=length(plotting_traces))
    layout = Layout(;
            plot_bgcolor = "white",
            #title= attr(text = "Percent Change Reduction under Alternative Operational Considerations<br>for Wolbachia-Infected Ae. Aegypti Mosquitoes", xanchor = "center", x=0.5, yanchor="top"),
            title= attr(text = "Percent Change Reduction under Alternative Operational Considerations<br>for OX513A-Modified Ae. Aegypti Mosquitoes", xanchor = "center", x=0.5, yanchor="top"),
            xaxis=attr(title="Time in Days (January - December)",  gridcolor = "LightGray", showgrid=true, #zeroline=false,
            tickfont_size = 11, tick0 = 0, dtick = 20),
            yaxis=attr(title="Percent Change in Wild Female Population",
            yanchor = "center", y=0.5, gridcolor = "LightGray", showgrid = true, zeroline=false),
            legend=attr(legendgrouptitle="Operational Details", font_size=11, yanchor="bottom", y=-.23, xanchor="center", x=0.5, orientation="h"),
            titlefont_size = 16, colorway=colors)
    sort!(plotting_traces, by = (t) -> temperature_key_map[t.fields[:base_series]])#, rev=true)
    return plot(plotting_traces, layout)
end

#################################
# Time to reduction target
#################################
function make_timetotarget_traces(trace_data)
    plot_name = trace_data["plot_name"][1]
    trace_info = split(plot_name, '_')
    trace_name = trace_info[end-1] # for heat shocks
    release_size = trace_info[end-2]

    numbers_in_trace_name = collect(eachmatch(r"[0-9]+", trace_name))
    temp = round(temperature_key_map[trace_name], digits=2)

    numbers_in_release_size = collect(eachmatch(r"[0-9]+", release_size))
    release_scenario = numbers_in_release_size[1].match

    if length(numbers_in_trace_name) < 2
        temp_scenario = numbers_in_trace_name[1].match
        if numbers_in_trace_name[1].match == "27"
            temp_scenario = "Baseline (No Temperature Effects)"
            name_ = "$temp_scenario, Release:$release_scenario"
        else
            name_ = "$temp_scenario, $temp °C, Release:$release_scenario"
        end
    elseif length(numbers_in_trace_name) == 2
        has_shock = occursin("shock", trace_name)
        rcp_scenario = numbers_in_trace_name[1].match
        year = numbers_in_trace_name[2].match
        if has_shock
            temp_scenario = "$year RCP-$(rcp_scenario) Heatwave" 
        else
            temp_scenario = "$year RCP-$(rcp_scenario)"
        end
        name_ = "$temp_scenario, $temp °C, Release:$release_scenario"
    else
        error("trace_name invalid $trace_name")
    end
    trace = scatter(; x = trace_data["days_to_achieve_reduction_thresholds"], 
        y = trace_data["reduction_thresholds_in_percent"], name = name_)
    trace.fields[:base_series] = trace_name
    return trace
end

function make_timetotarget_plots(trace_data)

    plotting_traces = PlotlyJS.GenericTrace{Dict{Symbol, Any}}[]

    for (experiment_name, traces) in trace_data
        push!(plotting_traces, make_timetotarget_traces(traces))
    end

    c1 = Colors.colorant"purple"
    c2 = Colors.colorant"lightblue"
    colors = range(c1, stop=c2, length=length(plotting_traces))
    layout = Layout(;
            plot_bgcolor = "white",
            #title=attr(text = "Time to Reduction Target under Alternative Operational Considerations<br>for Wolbachia-Infected Ae. Aegypti Mosquitoes", xanchor = "center", x=0.5, yanchor="top"),
            title=attr(text = "Time to Reduction Target under Alternative Operational Considerations<br>for OX513A-Modified Ae. Aegypti Mosquitoes", xanchor = "center", x=0.5, yanchor="top"),
            xaxis=attr(title="Time in Days (January - December)",  gridcolor = "LightGray", showgrid=true, zeroline=false,
            tickfont_size = 11, tick0 = 0, dtick = 20),
            yaxis=attr(title="Total Reduction Achieved (% of Population)",
            yanchor = "center", y=0.5, gridcolor = "LightGray", showgrid = true, zeroline=false),
            legend=attr(legendgrouptitle="Operational Details", font_size=11, yanchor="bottom", y=-.23, xanchor="center", x=0.5, orientation="h"),
            titlefont_size = 16, colorway=colors)
    sort!(plotting_traces, by = (t) -> temperature_key_map[t.fields[:base_series]])#, rev=true)
    return plot(plotting_traces, layout)
end

#################################
# Suppression efficacy score 
#################################

# Visuals = Tables made in Latex using outputs from analysis_*.jl files (df.eff_score)