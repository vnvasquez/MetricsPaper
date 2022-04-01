# Move this data to GitHub folder 
results_path = "/Volumes/EMTEC_B250/WOLBACHIA_REVISEDmetrics/"
results_path = "/Volumes/EMTEC_B250/removed_from_wolb/"

# Options: "fixed100" vs "fixed50"
wolb = analyze_results(results_path, "wolbachia10", "fixed100", 4, 70);
check_data = first(values(wolb))
eff_score = [v["suppression_efficacy_score"] for v in values(wolb)]
avg_temp = [v["avg_temp"] for v in values(wolb )]
#std_temp = [v["std_temp"] for v in values(wolb )]
time_to_achieve_public_health_target = [v["time_to_achieve_public_health_target"] for v in values(wolb)]
days_to_achieve_reduction_thresholds = [v["days_to_achieve_reduction_thresholds"] for v in values(wolb)]

# Dataframe for plots, eff_score 
dfnames = collect(keys(wolb))
df_wolb = DataFrame(name = dfnames, eff_score = eff_score, 
    avg_temp = avg_temp, #std_temp = std_temp, 
    time_to_policy_goal = time_to_achieve_public_health_target, 
    time_to_each_reduction_threshold = days_to_achieve_reduction_thresholds)

# Run analyses x3 
p = make_pctchange_plots(wolb)
PlotlyJS.savefig(p, "./WOLBACHIA_percentchange.pdf",width = 900, height = 600,format = "pdf")

p = make_timetotarget_plots(wolb)
PlotlyJS.savefig(p, "./WOLBACHIA_timetotarget.pdf",width = 900, height = 600,format = "pdf")

df_wolb.eff_score # for table 
