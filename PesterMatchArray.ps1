function PesterMatchArray($value, $expectedMatch) {
    $value = @($value)
    if($value.Length -ne $expectedMatch.Length){
        return $false;
    }
    for($i=0; $i -lt $expectedMatch.Length; $i++){
        if(-not($value -contains $expectedMatch[$i])){
            return $false;
        }
    }
    return $true;
}

function PesterMatchArrayFailureMessage($value, $expectedMatch) {
    $value = @($value)
    for($i=0; $i -lt $expectedMatch.Length; $i++){
        if(-not($value -contains $expectedMatch[$i])){
            return "Expected: {$expectedMatch}. Actual: {$value}. Actual is missing item: $($expectedMatch[$i])"
        }
    }
    for($i=0; $i -lt $value.Length; $i++){
        if(-not($expectedMatch -contains $value[$i])){
            return "Expected: {$expectedMatch}. Actual: {$value}. Actual contains extra item: $($value[$i])"
        }
    }
}

function NotPesterMatchArrayFailureMessage($value, $expectedMatch) {
    return "Expected: ${value} to not match the expression ${expectedMatch}"
}
