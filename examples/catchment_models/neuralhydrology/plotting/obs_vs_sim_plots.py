import pickle
import matplotlib.pyplot as plt
from neuralhydrology.evaluation import metrics
import os

def obs_vs_sim_plot(run_dir, epoch, basin_id = '7050039160'):
    parts = run_dir.split('_')
    split_name = f"{parts[0].upper()} {parts[1].capitalize()} {parts[2].capitalize()}"

    # Load the CSV file
    pickle_file = os.path.join(f'runs/{run_dir}/test/model_epoch0{epoch}/test_results.p')

    with open(pickle_file, "rb") as fp:
        results = pickle.load(fp)

    # extract observations and simulations. First key is basin number
    qobs = results[basin_id]['1D']['xr']['streamflow_obs']
    qsim = results[basin_id]['1D']['xr']['streamflow_sim']

    # plot figure
    fig, ax = plt.subplots(figsize=(16,10))
    ax.plot(qobs['date'], qobs, label='Observed')
    ax.plot(qsim['date'], qsim, label='Simulated')
    ax.legend()
    ax.set_ylabel("Discharge (mm/d)")
    ax.set_title(f"Test period - NSE {results[basin_id]['1D']['NSE']:.3f}")

    if not os.path.exists(f'plots/{run_dir}'):
        os.makedirs(f'plots/{run_dir}')

    fig_path = f'plots/{run_dir}/obs_vs_sim_{epoch}.png'
    plt.savefig(fig_path, dpi=300)
    plt.close()

    # print metrics
    # values = metrics.calculate_all_metrics(qobs.isel(time_step=-1), qsim.isel(time_step=-1))
    # for key, val in values.items():
    #     print(f"{key}: {val:.3f}")