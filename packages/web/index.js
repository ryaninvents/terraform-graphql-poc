import './style'
import 'preact-compat'
import {Component} from 'preact'
import {Helmet} from 'react-helmet'

import config from './config'

export default class App extends Component {
  render () {
    return (
      <div class="container">
        <Helmet>
          <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootswatch/4.1.2/litera/bootstrap.min.css" />
          <title>terraform-graphql-poc</title>
        </Helmet>
        <h1>terraform-graphql-poc</h1>
        <a class="btn btn-success text-light" href={`${config.apiEndpoint}/login`}>Log in</a>
      </div>
    )
  }
}
