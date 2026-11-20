$word = New-Object -ComObject Word.Application
$word.Visible = $false
try {
    $docPath = "D:\Internship daily projects\care_connect\CareConnect_Weekly_Final_Report.docx"
    $doc = $word.Documents.Open($docPath, $false, $true)
    $pages = $doc.ComputeStatistics([Microsoft.Office.Interop.Word.WdStatistic]::wdStatisticPages)
    $words = $doc.ComputeStatistics([Microsoft.Office.Interop.Word.WdStatistic]::wdStatisticWords)
    Write-Output "PAGE_COUNT: $pages"
    Write-Output "WORD_COUNT: $words"
    $doc.Close([ref]$false)
} catch {
    Write-Error $_
} finally {
    $word.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
}
