Return 'This is a demo script file'

$p = Get-Process
#the array object is a group of whatever the object is
$p | Get-Member | more
#it doesn't have its own properties and members with
#a few exceptions
$p.Count
#0 index
$p[0]
$p[-1]
$p[0..4]
#test
$p -is [array]
#work with saved output
$p | sort WorkingSet -Descending | select -First 5
#There are limitations to working with arrays

#collections
$list = [System.Collections.Generic.List[string]]::New()
$list.Add('Hello')
$list.count
#the collection is its own object
$list.PSBase
$list.PSBase | Get-Member
$list.GetType().FullName
Get-Process | Select-Object -ExpandProperty Name -Unique | ForEach-Object {
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
