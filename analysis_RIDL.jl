# Move this data to GitHub folder 
results_path = "/Volumes/EMTEC_B250/RIDL_REVISEDmetrics/"

# Options: "fixed40000" vs "fixed60000"
ridl = analyze_results(results_path, "ridlMID", "fixed40000", 21, 70); 
check_data = first(values(ridl))
eff_score = [v["suppression_efficacy_score"] for v in values(ridl)]
avg_temp = [v["avg_temp"] for v in values(ridl)]
#std_temp = [v["std_temp"] for v in values(ridl)]
time_to_achieve_public_health_target = [v["time_to_achieve_public_health_target"] for v in values(ridl)]
days_to_achieve_reduction_thresholds = [v["days_to_achieve_reduction_thresholds"] for v in values(ridl)]

# Dataframe for plots, eff_score 
dfnames = collect(keys(ridl))
df_ridl = DataFrame(name = dfnames, eff_score = eff_score, 
    avg_temp = avg_temp, #std_temp = std_temp, 
    time_to_policy_goal = time_to_achieve_public_health_target, 
    time_to_each_reduction_threshold = days_to_achieve_reduction_thresholds)

# Run analyses x3 
make_pctchange_plots(ridl)
make_timetotarget_plots(ridl)
df_ridl.eff_score