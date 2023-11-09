import pandas as pd
import numpy as np
import tensorflow as tf
import matplotlib.pyplot as plt
from sklearn.decomposition import NMF

# Enable oneDNN optimization
TF_ENABLE_ONEDNN_OPTS=1

# List of GPUs set up for acceleration
print("Num GPUs Available: ", len(tf.config.experimental.list_physical_devices('GPU')))

# Seed for reproducibility
np.random.seed(5)

# Loading TCGA-BRCA data
data_matrix = pd.read_csv("../Data/TCGA_BRCA_0toAvg.csv", index_col=0)
data_tensor = tf.constant(data_matrix, dtype=tf.float32)

# NMF function
def compute_nmf(data, rank, max_iter=200, lr=0.01):
    rows, cols = data.shape
    W = tf.Variable(tf.abs(tf.random.normal((rows, rank))), dtype=tf.float32)
    H = tf.Variable(tf.abs(tf.random.normal((rank, cols))), dtype=tf.float32)
    optimizer = tf.optimizers.Adam(lr)

    for iteration in range(max_iter):
        with tf.GradientTape() as tape:
            WH = tf.matmul(W, H)
            loss = tf.reduce_sum(tf.square(data - WH))
        gradients = tape.gradient(loss, [W, H])
        optimizer.apply_gradients(zip(gradients, [W, H]))
    return W, H, loss.numpy()

# Compute NMF for a range of ranks
ranks = range(1, 50)
errors = []

for rank in ranks:
    W, H, error = compute_nmf(data_tensor, rank)
    errors.append(error)
    print(f"Rank {rank} error: {error}")

# Display errors
for rank, error in zip(ranks, errors):
    print(f"Rank {rank}: {error}")

plt.figure(figsize=(10, 6))
plt.plot(ranks, errors, marker='o', linestyle='-')
plt.title('Reconstruction Error vs Rank')
plt.xlabel('Rank')
plt.ylabel('Reconstruction Error')
plt.grid(True)
plt.savefig('"../Figures/rank_evolution_plot.pdf', format='pdf', bbox_inches='tight')
pd.DataFrame(errors).to_csv("../Results/RecErrors.csv", index=False)