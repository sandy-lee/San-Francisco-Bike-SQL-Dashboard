# San Francisco Bike SQL & Dashboard 

## 💬 About:
- This is a task I completed using the San Francisco Bike dataset in Big Query to build a dashboard to show interesting trends in the data. This was an interesting task because there is both geo and temporal data in the dataset and using Power BI is a perfect way to show trends in the data in an accessible way

## 💾 Files in this repo are:
- **Task_Outline.docx** - this document details the task I had to complete including the questions that needed answering from the dataset.
- **San_Francisco_Bike_Dashboard.sql** - this is a file that contains the SQL queries used to answer questions of the dataset. It was an interesting task because not all of the data was available from the dataset because the data contained in tables has changed fairly recently. I used a view to create a temporary table that the dashboard is built on, and this view is based on a query that contains examples of feature engineering. I used a view because it is performant and more secure to do so.
- **San_Francisco_Missing_Values_Notebook.ipynb** - this is a notebook file I used within Big Query to do an EDA step by looking for missing values (which there were many in the geographical data) and then writing a script to fill in missing latitudes and longitudes from the Google Maps API.
- **Dashboard_Screenshot_1 to 3.ipynb** - these are screenshots of the dashboard in Power BI to give an idea of what I created.

## ⚡ Next Steps:
- Power BI doesn't make it easy to share dashboards without a subscription so I shall remake this dashboard in Data Studio and share it with this repo
