import pandas as pd
import numpy as np
import tensorflow as tf
import pickle

# Seed for reproducibility
np.random.seed(123)

# Loading TCGA-BRCA data
data_matrix = pd.read_csv("../Data/TCGA_BRCA_0toAvg.csv", index_col=0)
data_tensor = tf.constant(data_matrix, dtype=tf.float32)

# Define the rank as 24
rank = 24

# Initialize W and H matrices
rows, cols = data_tensor.shape
W = tf.Variable(tf.random.uniform((rows, rank), 0, 1), dtype=tf.float32)
H = tf.Variable(tf.random.uniform((rank, cols), 0, 1), dtype=tf.float32)

# Set the number of iterations and learning rate for the Adam optimization
max_iter = 5000
lr = 0.01
optimizer = tf.optimizers.Adam(lr)

# Training loop
for i in range(max_iter):
    with tf.GradientTape() as tape:
        WH = tf.matmul(W, H)
        loss = tf.reduce_sum(tf.square(data_tensor - WH))

    grads = tape.gradient(loss, [W, H])
    optimizer.apply_gradients(zip(grads, [W, H]))

    # Ensure non-negativity constraints
    W.assign(tf.maximum(W, 0))
    H.assign(tf.maximum(H, 0))

# Convert W and H to numpy arrays so they can be saved as csv
W_np = W.numpy()
H_np = H.numpy()

# Save W and H matrices to .csv files
pd.DataFrame(W_np).to_csv("../Data/W_matrix_24_T.csv", index=False)
pd.DataFrame(H_np).to_csv("../Data/H_matrix_24_T.csv", index=False)

# Save the entire NMF model
with open("../Models/nmf_model_tf_24.pkl", "wb") as file:
    pickle.dump((W_np, H_np), file)