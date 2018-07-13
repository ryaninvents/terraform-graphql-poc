const {Readable} = require('stream')

Readable.prototype.then = function then (...args) {
  return new Promise((resolve, reject) => {
    const bufs = []
    this.on('error', reject)
      .on('data', buf => bufs.push(buf))
      .on('end', () => resolve(Buffer.concat(bufs)))
  })
    .then(...args)
}

exports.promisify = (stream) => new Promise((resolve, reject) => {
  stream.on('end', resolve)
  stream.on('error', reject)
})
