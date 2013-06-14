startPort = 8000
portCount = 1000
currentOffset = 0
module.exports = =>
  port = startPort + currentOffset++
  currentOffset %= portCount
  return port
