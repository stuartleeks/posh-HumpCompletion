function PesterMatchArrayUnordered($value, $expectedMatch) {
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

function PesterMatchArrayUnorderedFailureMessage($value, $expectedMatch) {
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

function NotPesterMatchArrayUnorderedFailureMessage($value, $expectedMatch) {
    return "Expected: ${value} to not match the expression ${expectedMatch}"
}

###################################################################################################

function PesterMatchArrayOrdered($value, $expectedMatch) {
    $value = @($value)
    if($value.Length -ne $expectedMatch.Length){
        return $false;
    }
    for($i=0; $i -lt $expectedMatch.Length; $i++){
        if(-not($value[$i] -eq $expectedMatch[$i])){
            return $false;
        }
    }
    return $true;
}

function PesterMatchArrayOrderedFailureMessage($value, $expectedMatch) {
    $value = @($value)
    for($i=0; $i -lt $expectedMatch.Length -and $i -lt $value.Length; $i++){
        if(-not($value[$i] -eq $expectedMatch[$i])){
            return "Differs at index $i. Expected: {$expectedMatch}. Actual: {$value}."
        }
    }
    if($value.Length -ne $expectedMatch.Length){
        return "Lengths differ - Expected length $($expectedMatch.Length), actual length $($value.Length)";
    }
}

function NotPesterMatchArrayOrderedFailureMessage($value, $expectedMatch) {
    return "Expected: ${value} to not match the expression ${expectedMatch}"
}
