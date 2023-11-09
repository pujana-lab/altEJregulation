import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split
import shap
import matplotlib.pyplot as plt
import scipy.stats

# Seed for reproducibility
np.random.seed(123)

# Load the data
data = pd.read_csv("../Data/W24_HRD_T.csv")

X = data.iloc[:, :-1]
y = data['HRD-sum']
X_train_df, X_test_df, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
X_train = X_train_df.values
X_test = X_test_df.values

# Neural network model for a rank 24 NMF
model = tf.keras.Sequential([
    tf.keras.layers.Dense(128, activation='relu', input_dim=24),
    tf.keras.layers.Dense(64, activation='relu'),
    tf.keras.layers.Dense(1)
])

# Compile the model
model.compile(optimizer='adam', loss='mean_squared_error')

# Train the model
model.fit(X_train, y_train, epochs=100, batch_size=32, validation_data=(X_test, y_test))

y_train_pred = model.predict(X_train).flatten()
y_test_pred = model.predict(X_test).flatten()

spearman_train = scipy.stats.spearmanr(y_train, y_train_pred)
spearman_test = scipy.stats.spearmanr(y_test, y_test_pred)

# Scatter plot for training data
plt.figure(figsize=(10, 5))

plt.subplot(1, 2, 1)
plt.scatter(y_train, y_train_pred, alpha=0.5)
plt.title(f'Training Data\nSpearman Correlation = {spearman_train.correlation:.2f}\np-value = {spearman_train.pvalue:.2e}')
plt.xlabel('True HRD-Sum')
plt.ylabel('Predicted HRD-Sum')
plt.plot([min(y_train), max(y_train)], [min(y_train), max(y_train)], color='red')

# Scatter plot for test data
plt.subplot(1, 2, 2)
plt.scatter(y_test, y_test_pred, alpha=0.5)
plt.title(f'Test Data\nSpearman Correlation = {spearman_test.correlation:.2f}\np-value = {spearman_test.pvalue:.2e}')
plt.xlabel('True HRD-Sum')
plt.ylabel('Predicted HRD-Sum')
plt.plot([min(y_test), max(y_test)], [min(y_test), max(y_test)], color='red') 

plt.tight_layout()
plt.savefig("../Figures/scatterplot_with_spearman_correlation.png")
plt.show()

# Save the model to a HDF5 file
model.save('../Models/HRD_nn_model_24.h5')

# If model is needed to be loaded:
# model = load_model('../Models/HRD_nn_model_24.h5')

predictions = model.predict(X_test)

predicted_df = pd.DataFrame({
    'ID_or_Index': X_test_df.index,  # Assuming X_test is a DataFrame. If not, adjust accordingly.
    'Predicted_SignC': predictions.flatten()
})


explainer = shap.KernelExplainer(model.predict, X_train[:50])  # Using only 50 samples as background
shap_values = explainer.shap_values(X_test)

# Visualize the SHAP values
shap.initjs()
shap.force_plot(explainer.expected_value[0], shap_values[0][0], X_test[0])
shap.summary_plot(shap_values, X_test)
plt.savefig('../Figures/shap_summary_plot1.pdf', format='pdf', bbox_inches='tight')
shap.summary_plot(shap_values[0], X_test)
plt.savefig('../Figures/shap_summary_plot2.pdf', format='pdf', bbox_inches='tight')
shap.plots.force(explainer.expected_value[0], shap_values[0][0,:], X_test.iloc[0, :], matplotlib = True)
plt.savefig('../Figures/shap_summary_plot3.pdf', format='pdf', bbox_inches='tight')
shap.decision_plot(explainer.expected_value[0], shap_values[0], X_test.columns)
plt.savefig('../Figures/shap_summary_plot4.pdf', format='pdf', bbox_inches='tight')
