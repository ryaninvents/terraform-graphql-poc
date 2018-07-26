export function generatePolicy ({principalId, effect, resource, user}) {
  var authResponse = {}

  authResponse.principalId = principalId
  if (effect && resource) {
    var policyDocument = {}
    policyDocument.Version = '2012-10-17'
    policyDocument.Statement = []
    var statementOne = {}
    statementOne.Action = 'execute-api:Invoke'
    statementOne.Effect = effect
    statementOne.Resource = resource
    policyDocument.Statement[0] = statementOne
    authResponse.policyDocument = policyDocument
  }

  // Optional output with custom properties of the String, Number or Boolean type.
  authResponse.context = user ? {
    userData: JSON.stringify(user)
  } : {}
  return authResponse
}

export function generateAllowPolicy (opts) {
  return generatePolicy({
    ...opts,
    effect: 'Allow'
  })
}

export function generateDenyPolicy (opts) {
  return generatePolicy({
    ...opts,
    effect: 'Deny'
  })
}
