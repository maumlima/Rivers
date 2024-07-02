import pandas as pd
import matplotlib.pyplot as plt
import os

def cdf_plot(run_dir, epoch):
    parts = run_dir.split('_')
    split_name = f"{parts[0].upper()} {parts[1].capitalize()} {parts[2].capitalize()}"

    # Load the CSV file
    csv_path = os.path.join(f'runs/{run_dir}/test/model_epoch0{epoch}/test_metrics.csv')
    df = pd.read_csv(csv_path)

    # Sort the data by NSE
    df = df.sort_values('NSE')

    # Calculate the CDF values
    cdf = df['NSE'].rank(method='first', pct=True)

    # Plotting the CDF
    plt.figure(figsize=(8, 6))
    plt.plot(df['NSE'], cdf)
    plt.xlabel('NSE')
    plt.ylabel('CDF')
    plt.title(f'{split_name}: CDF of NSE for {epoch} epochs')
    plt.xlim(0,1)
    plt.grid(True)

    if not os.path.exists(f'plots/{run_dir}'):
        os.makedirs(f'plots/{run_dir}')

    fig_path = f'plots/{run_dir}/CDF_NSE_{epoch}.png'
    plt.savefig(fig_path, dpi=300)

    plt.close()

    return df['NSE'], cdf