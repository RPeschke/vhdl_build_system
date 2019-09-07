import plotly.plotly as py
import plotly.graph_objs as go

import pandas as pd

# generate 1,000 random numbers from Normal(0,1) distribution
data =  matrix(rnorm(1000), nc=10)
    colnames(data) = paste('data', 1:10, sep='')
 
# compute Pearson correlation of data and format it nicely
temp = compute.cor(data, 'pearson')
    temp[] = plota.format(100 * temp, 0, '', '%')
 
# plot temp with colorbar, display Correlation in (top, left) cell
plot.table(temp, smain='Correlation', highlight = TRUE, colorbar = TRUE)
