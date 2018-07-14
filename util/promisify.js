exports.promisify = (stream) => new Promise((resolve, reject) => {
  stream.on('end', resolve)
  stream.on('error', reject)
})
