Add-Type -AssemblyName System.Web.Extensions

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
		foreach ($key in $s2.Keys) {
			$score=$this.ratio($s1,$key)
			if ($score -gt $s) {
				$m=$key
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

class AI {
	[string]$Source
	[hashtable]$data
	[bma]$bmaInstance
	AI([string]$dataFile='Network.json',$bmaInstance) {
		$this.bmaInstance=$bmaInstance
		$this.data=@{}
		$this.Source=$dataFile
		$this.loadData()
	}

	[void]loadData() {
		if (Test-Path -Path $this.Source) {
			$jsonSerializer=New-Object System.Web.Script.Serialization.JavaScriptSerializer
			$jsonContent=Get-Content -Path $this.Source -Raw
			$jsonContent=$jsonSerializer.DeserializeObject($jsonContent)
			$this.data=@{}
			foreach ($key in $jsonContent.Keys) {
				$this.data[$key]=$jsonContent.$key
			}
		}
		else {
			$this.data=@{}
		}
	}

	[string]compareData([string]$query) {
		$questions=@{}
		foreach ($q in $this.data.Keys) {
			$questions[$q]=''
		}
		if ($query.Length -eq 0) {return $null}
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
			return "Couldn't answer that question."
		}
	}
}

$AI=[AI]::new('Network.json',$bma)

while ($true) {
	$userInput=read-host
	$response=$AI.getResponse($userInput)
	write-host "> $($response)"
}