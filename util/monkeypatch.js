require('stream').Readable.prototype.then = function then(...args) {
  return new Promise((res, rej) => {
    const bufs = [];
    this.on('error', rej)
      .on('data', buf => bufs.push(buf))
      .on('end', () => res(Buffer.concat(bufs)));
  })
  .then(...args);
};