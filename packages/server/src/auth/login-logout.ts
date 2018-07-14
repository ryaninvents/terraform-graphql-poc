import * as express from 'express'
import passport from 'passport'
import serverless from 'serverless-http'

import './config'

const app = express()

app.get(
  '/login',
  passport.authenticate('auth0', {
    domain: process.env.AUTH0_DOMAIN,
    clientID: process.env.AUTH0_CLIENT_ID,
    clientSecret: process.env.AUTH0_CLIENT_SECRET,
    redirectUri: 'http://localhost:3000/callback',
    audience: `https://${process.env.AUTH0_DOMAIN}/userinfo`,
    responseType: 'code',
    scope: 'openid'
  })
)

app.get(
  '/callback',
  passport.authenticate('auth0', {
    failureRedirect: '/'
  }),
  function(req, res) {
    res.redirect('/')
  }
)

function forRoute(route) {
  return {
    request(request, event, context) {
      request.path = route
    }
  }
}

export const login = serverless(app, forRoute('/login'))
export const callback = serverless(app, forRoute('/callback'))