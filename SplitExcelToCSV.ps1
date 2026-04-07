$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$excel.ScreenUpdating = $false
$excel.EnableEvents = $false

$workbookPath = "C:\Users\NickPatti\OneDrive - DataStrike\Customers\SSS\BRG Database Audit 20260223.xlsx"
$outputFolder = "C:\Users\NickPatti\OneDrive - DataStrike\Customers\SSS\CSV\"


$workbook = $excel.Workbooks.Open($workbookPath)

foreach ($sheet in $workbook.Worksheets) {

    $csvPath = Join-Path $outputFolder ($sheet.Name + ".csv")
    
    $sheet.SaveAs($csvPath, 62)  # 62 = xlCSVUTF8
}

$workbook.Close($false)
$excel.Quit()

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel)
