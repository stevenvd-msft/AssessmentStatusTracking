# AssessmentStatusTracking
This script helps troubleshoot and provide insights on the status on the On-Demand Assessments that are available as part of Microsoft Unified Support or Microsoft Premier Support (RAP as a Service).

The Assessment-status-logging script provides insight in the status of the On-Demand assessment.

Start the script when the assessment is running. A timout is required to be added in seconds. Set it at least at 120 for smaller environments, possibly one hour (3600) for larger environments where data collection can take days to complete. 
Every time it reports the status, a corresponding event is written in the **On-Demand Assessment Status** Event Log that is created under **Applications and Services Logs**.
The script detects when multiple assessments are running and asks to select the one required. Today we cantrack one assessment with one instance of the script running.
Feel free to make modifications as to what you need. 
For more information on On-Demand Assessments check the following site: https://docs.microsoft.com/en-us/services-hub/unified/health/getting_started_with_on_demand_assessments 
