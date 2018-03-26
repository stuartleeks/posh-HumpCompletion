function DebugMessage($message) {
    # $threadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    # $appDomainId = [AppDomain]::CurrentDomain.Id
    # [System.Diagnostics.Debug]::WriteLine("PoshHump: $threadId : $appDomainId :$message")
    [System.Diagnostics.Debug]::WriteLine("PoshHump: $message")

    # Add-Content -Path "C:\temp\__test.txt" -Value $message
}