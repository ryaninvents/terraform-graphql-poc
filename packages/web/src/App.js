import React, { Component } from 'react'
import './App.css'
import {Helmet} from 'react-helmet'
import GraphiQL from 'graphiql'
import fetch from 'isomorphic-fetch'
import config from './config'
import Loadable from 'react-loadable'

async function graphQlFetcher (graphQLParams) {
  const response = await fetch(`${config.apiEndpoint}/graphql`, {
    method: 'post',
    mode: 'cors',
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(graphQLParams)
  })
  return response.json()
}

// Unfortunately, the CodeMirror instance embedded in GraphiQL uses
// CSS to lay itself out. We don't load the CSS for GraphiQL until
// it's needed; what this means is that React renders GraphiQL before
// the browser has loaded the CSS for it.
//
// UGLY HACK: use `react-loadable` to set a timeout, to allow the CSS
// to load before GraphiQL mounts.
const LoadableGraphiQL = Loadable({
  loader: () => new Promise((resolve) => {
    setTimeout(() => {
      resolve(GraphiQL)
    }, 1000)
  }),
  loading: () => <div>Loading...</div>
})

class App extends Component {
  render () {
    return (
      <React.Fragment>
        <Helmet>
          <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/graphiql/0.11.11/graphiql.min.css" />
          <title>terraform-graphql-poc</title>
        </Helmet>
        <LoadableGraphiQL
          fetcher={graphQlFetcher}
        />
      </React.Fragment>
    )
  }
}

export default App
