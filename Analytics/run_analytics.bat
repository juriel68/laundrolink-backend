@echo OFF
ECHO Starting LaundroLink Analytics Job...

REM Navigate to the Analytics directory
cd C:\Users\Juriel\LaundroLink_Project\Analytics

REM Activate the Python virtual environment
CALL .\venv\Scripts\activate

REM Run the Python script
ECHO Running the Python analysis script...
python customer_segmentation.py

ECHO Analytics job finished.