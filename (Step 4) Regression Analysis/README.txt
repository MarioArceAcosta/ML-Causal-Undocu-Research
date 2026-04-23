These files are executable versions built off your actual everify_ddd.do and everify_wage_robustness_v2.do.

Suggested placement in your project Code/ folder:
- 00_everify_setup.do
- 01a_everify_build_stack_baseline.do
- 01b_everify_build_stack_never.do
- 01c_everify_build_stack_strict.do
- 02_everify_wage_main.do
- 03_everify_wage_robustness.do
- 04_everify_secondary_outcomes.do
- 99_run_everify_pipeline.do

Important note:
These files preserve your existing factor-notation control approach so they stay close to the scripts you have already been running.


Updated version: intermediate datasets are saved in Data/ instead of Temp/.

Updated v2: strict-exclusion screening now uses the same $policy_covars list as the regression controls.

Updated v3: fixed esttab note formatting so LaTeX tables compile without nested \multicolumn/\noalign errors.
