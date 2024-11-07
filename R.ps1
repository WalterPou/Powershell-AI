class bma {
    [int]levenshtein([string]$s1,[string]$s2) {
        if ($s1.Length -lt $s2.Length) {
            return $this.levenshtein($s2,$s1)
        }
        if ($s2.Length -eq 0) {
            return $s1.Length
        }
        $previous=0..$s2.Length
        for ($i=0;$i -lt $s1.Length;$i++) {
            $current=@($i+1)
            for ($j=0;$j -lt $s2.Length;$j++) {
                $insert=$previous[$j+1]+1
                $delete=$current[$j]+1
                $subs=$previous[$j]+($s1[$i] -ne $s2[$j])
                $current+=[System.Math]::Min($delete,[System.Math]::Min($insert,$subs))
            }

            $previous=$current
        }

        return $previous[$previous.Length-1]
    }

    [double]ratio([string]$s1,[string]$s2) {
        $distance=$this.levenshtein($s1,$s2)
        $maxLen=[System.Math]::Max($s1.Length,$s2.Length)

        return 1-($distance/$maxLen)
    }

    [PSCustomObject]keyExtract([string]$s1,[hashtable]$s2) {
        $m=$null
        $s=-1
        foreach ($choice in $s2.Keys) {
            $score=$this.ratio($s1,$choice)
            if ($score -gt $s) {
                $m=$choice
                $s=$score
            }
        }

        return [PSCustomObject]@{
            bestMatch=$m
            bestScore=$s
        }
    }
}

$bma=[bma]::new()

class ArtificialIntel {
    [string]$Source
    [hashtable]$data
    [bma]$bmaInstance

    ArtificialIntel([string]$dataFile='Network.json',$bmaInstance) {
        $this.data=@{}
        $this.bmaInstance=$bmaInstance
        $this.Source=$dataFile
        $this.loadData()
    }

    [void]loadData() {
        if (Test-Path $this.Source) {
            $content=Get-Content $this.Source | ConvertFrom-Json
            $this.data=@{}
            foreach ($key in $content.PSObject.Properties.Name) {
                $this.data[$key]=$content.$key
            }
        }
        else {
            $this.data=@{}
        }
    }

    [string]belowThreshold() {
        return "Couldn't answer that query."
    }

    [string]compareData([string]$query) {
        if ($query.Length -eq 0) {
            return $null
        }
        $questions=@{}
        foreach ($key in $this.data.Keys) {
            $questions[$key]=''
        }
        $results=$this.bmaInstance.keyExtract($query,$questions)
        $bestMatch=$results.bestMatch
        $bestScore=$results.bestScore
        $threshold=.2
        if ($bestScore -gt $threshold) {
            return $this.data[$bestMatch]
        }
        else {
            return $null
        }
    }

    [string]getResponse([string]$query) {
        $response=$this.compareData($query)
        if ($response) {
            return $response
        }
        else {
            return $this.belowThreshold()
        }
    }
}

$AI=[ArtificialIntel]::new('Network.json',$bma)

while ($true) {
    $query=read-host "You: "
    $response=$AI.getResponse($query)
    write-host "AI: $($response)"
}