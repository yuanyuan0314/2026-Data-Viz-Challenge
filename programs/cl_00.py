import pandas as pd
import openpyxl

f = "C:\\Users\\37493\\Dropbox\\AAEC Challenge\\data\\source\\2025+National+Food+Hub+Survey+Dashboard+Final.xlsx"

wb = openpyxl.load_workbook(f)

# read_excel sees hidden sheets just fine; protection is UI-only
df = pd.read_excel(f, sheet_name="Dataset")
df.to_csv("C:\\Users\\37493\\Dropbox\\AAEC Challenge\\data\\source\\food_hub_survey_2013_2025.csv", index=False)