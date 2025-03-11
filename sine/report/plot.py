import pandas as pd
import plotly.express as px

# Load the CSV file
df = pd.read_csv("readings.csv")  
df["time_us"] = (df["time"] - df["time"][0]) * 1e6

# Plot using Plotly
fig = px.scatter(df, x="time_us", y="dac", title="Sine Wave from 10-bit R2R DAC", labels={"time_us": "Time (µs)", "dac": "DAC Output (V)"}, opacity=0.5)

# Show the plot
fig.show()
