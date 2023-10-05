Return 'This is a demo script file'

$p = Get-Process
$p.Count
$p is [array]
$p | sort WorkingSet -Descending | select -First 5
#There are limitations to working with arrays

#collections
$list = [System.Collections.Generic.List[string]]::New()
$list.Add('Hello')
$list.count
$list.PSBase
$list.PSBase | Get-Member
$list.GetType().FullName
Get-Process | select -ExpandProperty Name -Unique | ForEach-Object {
    $list.Add($_)
}
$list.Contains('pwsh')
$list.Remove('pwsh')
$i = $list.FindIndex({ $args -eq 'Code' })
$list[$i]

Measure-Command {
    $a = @()
    1..500 | ForEach-Object {
        $a += Get-Process
    }
}
$a.count
Measure-Command {
    $b = [System.Collections.Generic.List[System.Diagnostics.Process]]::new()
    1..500 | ForEach-Object {
        $b.AddRange([System.Diagnostics.process[]]$(Get-Process))
    }
}
$b.count
