const path = require('path')

module.exports = {
  entry: {
    server: './server.js',
    auth: './auth.js'
  },
  mode: process.env.NODE_ENV || 'production',
  module: {
    rules: [
      {
        test: /\.js$/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: [
              [
                '@babel/preset-env',
                {
                  targets: {node: '8'}
                }
              ]
            ]
          }
        },
        exclude: /node_modules/
      }
    ]
  },
  resolve: {
    mainFields: ['main', 'module', 'browser'],
    extensions: ['.js']
  },
  target: 'node',
  output: {
    filename: '[name]/index.js',
    path: path.resolve(__dirname, 'dist'),
    libraryTarget: 'commonjs'
  }
}
