import express from 'express'
import passport from 'passport'
import serverless from 'serverless-http'
import session from 'express-session'
import createRedisStore from 'connect-redis'

import './config'

const app = express()

const RedisStore = createRedisStore(session)

app.use((...args) => {
  const [, res] = args

  const store = new RedisStore({
    host: process.env.REDIS_HOST,
    port: Number(process.env.REDIS_PORT)
  })

  res.on('finish', () => {
    store.client.quit()
  })

  const useSession = session({
    store,
    secret: 'keyboard catz',
    resave: false
  })

  useSession(...args)
})

app.use(passport.initialize())
app.use(passport.session())

app.get(
  '/login',
  (req, res, next) => {
    passport.authenticate('auth0', {
      domain: process.env.AUTH0_DOMAIN,
      clientID: process.env.AUTH0_CLIENT_ID,
      clientSecret: process.env.AUTH0_CLIENT_SECRET,
      callbackURL: process.env.CALLBACK_URL,
      audience: `https://${process.env.AUTH0_DOMAIN}/userinfo`,
      responseType: 'code',
      scope: 'openid profile email'
    }, (err, user, info) => {
      if (err) {
        next(err)
        return
      }
      console.log(user)
      res.redirect('/yay')
    })(req, res, next)
  }
)

function forRoute (route) {
  return {
    request (request, event, context) {
      request.path = route
    }
  }
}

export const login = serverless(app, forRoute('/login'))
export const callback = serverless(app, forRoute('/login'))
