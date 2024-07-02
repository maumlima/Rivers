import pandas as pd
import os
import matplotlib.pyplot as plt

def NSE_plot(run_dir, epoch):
    model_NSE = {}

    parts = run_dir.split('_')
    split_name = f"{parts[0].upper()} {parts[1].capitalize()} {parts[2].capitalize()}"

    base_dir = os.path.join('runs', run_dir, 'validation')

    # Get median NSE per epoch
    for item in os.listdir(base_dir):
        if os.path.isdir(os.path.join(base_dir, item)) and item.startswith('model_epoch0'):
            dir_path = os.path.join(base_dir, item)
            epoch_str = dir_path[-2:]
            for file in os.listdir(dir_path):
                file_path = os.path.join(dir_path, file)
                if os.path.splitext(file_path)[1] == '.csv':
                    df = pd.read_csv(file_path)
                    model_NSE[int(epoch_str)] = df.NSE.median()

    # Sort the dictionary by keys and extract x and y coordinates
    x = sorted(model_NSE.keys())
    y = [model_NSE[key] for key in x]

    # Create a plot
    plt.figure(figsize=(8, 5))
    plt.plot(x, y, 'o-')
    plt.xlabel('Epoch')
    plt.ylabel('NSE') 
    plt.title(split_name + ': Median NSE vs Epoch')
    plt.grid(True)

    plt.xlim(min(x) - 1, max(x) + 1)
    plt.ylim(min(y) - 0.1, max(y) + 0.1)

    if not os.path.exists(f'plots/{run_dir}'):
        os.makedirs(f'plots/{run_dir}')

    fig_path = f'plots/{run_dir}/NSE_per_epoch_{epoch}.png'
    plt.savefig(fig_path, dpi=300)
    plt.close()

    return x, y